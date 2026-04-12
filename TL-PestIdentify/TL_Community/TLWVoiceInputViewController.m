//
//  TLWVoiceInputViewController.m
//  TL-PestIdentify
//

#import "TLWVoiceInputViewController.h"
#import "TLWVoiceInputView.h"
#import "TWLSpeechManager.h"
#import "TLWSDKManager.h"
#import "TLWToast.h"
#import "TLWCommunityPost.h"
#import "TL_SearchResult/TLWSearchResultController.h"
#import <AgriPestClient/AGPostResponseDto.h>
#import <AgriPestClient/AGSearchResultResponse.h>

@interface TLWVoiceInputViewController () <UITextFieldDelegate>

@property (nonatomic, strong) TLWVoiceInputView *voiceView;
@property (nonatomic, assign) BOOL hasActivatedSearchLayout;
@property (nonatomic, assign) BOOL isSearching;

@end

@implementation TLWVoiceInputViewController

- (void)loadView {
  self.view = [[TLWVoiceInputView alloc] initWithFrame:UIScreen.mainScreen.bounds];
  self.voiceView = (TLWVoiceInputView *)self.view;
  UITapGestureRecognizer* tap =  [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tl_hideKeyboard)];
  [self.voiceView addGestureRecognizer:tap];
}

-(void)tl_hideKeyboard {
  [self.voiceView endEditing:YES];
}

- (void)viewDidLoad {
  [super viewDidLoad];
  [self.voiceView.backButton addTarget:self action:@selector(tl_backTapped) forControlEvents:UIControlEventTouchUpInside];
  [self.voiceView.searchButton addTarget:self action:@selector(tl_searchButtonTapped) forControlEvents:UIControlEventTouchUpInside];
  self.voiceView.searchTextField.delegate = self;
  [self.voiceView.searchTextField addTarget:self action:@selector(tl_searchTextDidChange:) forControlEvents:UIControlEventEditingChanged];
  self.voiceView.searchTextField.text = self.initialSearchText ?: @"";
  self.hasActivatedSearchLayout = self.voiceView.searchTextField.text.length > 0;
  [self.voiceView updateSearchActionVisible:self.hasActivatedSearchLayout animated:NO];
  [self tl_setupSpeechRecognition];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [self.navigationController setNavigationBarHidden:YES animated:animated];
  self.navigationController.interactivePopGestureRecognizer.delegate = nil;
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  [[TWLSpeechManager sharedManager] stopRecording];
}

- (void)tl_setupSpeechRecognition {
  __weak typeof(self) weakSelf = self;

  __block NSString *textBeforeRecording = @"";

  self.voiceView.onRecordingStart = ^{
    textBeforeRecording = weakSelf.voiceView.searchTextField.text ?: @"";
    [weakSelf.voiceView.searchTextField resignFirstResponder];
    [[TWLSpeechManager sharedManager] startRecording];
  };

  [TWLSpeechManager sharedManager].resultHandler = ^(NSString *text, BOOL isFinal) {
    __strong typeof(weakSelf) strongSelf = weakSelf;
    if (!strongSelf) return;
    NSString *recognizedText = [textBeforeRecording stringByAppendingString:(text ?: @"")];
    strongSelf.voiceView.searchTextField.text = recognizedText;
    [strongSelf tl_updateSearchLayoutForText:recognizedText animated:YES];
    if (strongSelf.onSearchTextChanged) {
      strongSelf.onSearchTextChanged(recognizedText);
    }
  };

  self.voiceView.onRecordingEnd = ^{
    [[TWLSpeechManager sharedManager] stopRecording];
  };
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  [self tl_executeSearch];
  return YES;
}

- (void)tl_searchTextDidChange:(UITextField *)textField {
  [self tl_updateSearchLayoutForText:textField.text animated:YES];
}

- (void)tl_searchButtonTapped {
  [self tl_executeSearch];
}

- (void)tl_executeSearch {
  [[TWLSpeechManager sharedManager] stopRecording];
  NSString *text = [self.voiceView.searchTextField.text ?: @"" stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
  [self tl_updateSearchLayoutForText:text animated:NO];
  if (text.length == 0) {
    [TLWToast show:@"请输入搜索内容"];
    return;
  }
  if (self.isSearching) {
    return;
  }
  if (self.onSearchTextChanged) {
    self.onSearchTextChanged(text);
  }
  [self.voiceView.searchTextField resignFirstResponder];
  self.isSearching = YES;

  __weak typeof(self) weakSelf = self;
  [[TLWSDKManager shared] searchPostsWithQ:text page:@0 size:@20 completionHandler:^(AGResultSearchResultResponse *output, NSError *error) {
    dispatch_async(dispatch_get_main_queue(), ^{
      __strong typeof(weakSelf) strongSelf = weakSelf;
      if (!strongSelf) return;
      strongSelf.isSearching = NO;

      if (error || !output || output.code.integerValue != 200 || !output.data) {
        if (!error && [[TLWSDKManager shared].sessionManager shouldAttemptTokenRefreshForCode:output.code]) {
          [[TLWSDKManager shared].sessionManager handleUnauthorizedWithRetry:^{
            [strongSelf tl_executeSearch];
          }];
          return;
        }
        [TLWToast show:(output.message.length > 0 ? output.message : @"搜索失败，请稍后重试")];
        return;
      }

      TLWSearchResultController *resultVC = [[TLWSearchResultController alloc] init];
      resultVC.queryText = text;
      resultVC.posts = [[strongSelf tl_postsFromDtoList:output.data.matches.list] mutableCopy];
      resultVC.recommendations = [strongSelf tl_postsFromDtoList:output.data.recommendations];
      resultVC.keywordSuggestions = output.data.suggestions ?: @[];
      resultVC.hasCollectedPosts = strongSelf.hasCollectedPosts;

      UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:resultVC];
      nav.modalPresentationStyle = UIModalPresentationFullScreen;
      nav.navigationBarHidden = YES;

      UIViewController *presenter = strongSelf.presentingViewController;
      [strongSelf dismissViewControllerAnimated:YES completion:^{
        if (presenter) {
          [presenter presentViewController:nav animated:YES completion:nil];
        }
      }];
    });
  }];
}

- (void)tl_updateSearchLayoutForText:(nullable NSString *)text animated:(BOOL)animated {
  if (self.hasActivatedSearchLayout) {
    return;
  }
  NSString *trimmedText = [text ?: @"" stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
  if (trimmedText.length == 0) {
    return;
  }
  self.hasActivatedSearchLayout = YES;
  [self.voiceView updateSearchActionVisible:YES animated:animated];
}

- (NSArray<TLWCommunityPost *> *)tl_postsFromDtoList:(NSArray<AGPostResponseDto *> *)dtoList {
  NSMutableArray<TLWCommunityPost *> *posts = [NSMutableArray array];
  for (AGPostResponseDto *dto in dtoList) {
    TLWCommunityPost *post = [self tl_postFromDto:dto];
    if (post) {
      [posts addObject:post];
    }
  }
  return [posts copy];
}

- (TLWCommunityPost *)tl_postFromDto:(AGPostResponseDto *)dto {
  if (!dto) {
    return nil;
  }

  TLWCommunityPost *post = [TLWCommunityPost new];
  post._id = dto._id;
  post.title = dto.title ?: @"";
  post.content = dto.content ?: @"";
  post.images = dto.images ?: @[];
  post.tags = dto.tags ?: @[];
  post.authorName = dto.authorName ?: @"";
  post.authorAvatar = dto.authorAvatar ?: @"";
  post.likeCount = dto.likeCount ?: @0;
  post.isLiked = dto.isLiked.boolValue;
  post.isCollected = dto.isFavorited.boolValue;
  post.favoriteCount = dto.favoriteCount ?: @0;
  return post;
}

- (void)tl_backTapped {
  [[TWLSpeechManager sharedManager] stopRecording];
  if (self.onSearchTextChanged) {
    self.onSearchTextChanged(self.voiceView.searchTextField.text ?: @"");
  }
  [self dismissViewControllerAnimated:YES completion:nil];
}

@end
