//
//  TLWVoiceInputViewController.m
//  TL-PestIdentify
//

#import "TLWVoiceInputViewController.h"
#import "TLWVoiceInputView.h"
#import "TWLSpeechManager.h"

@interface TLWVoiceInputViewController () <UITextFieldDelegate>

@property (nonatomic, strong) TLWVoiceInputView *voiceView;

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
  self.voiceView.searchTextField.delegate = self;
  self.voiceView.searchTextField.text = self.initialSearchText ?: @"";
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
    if (strongSelf.onSearchTextChanged) {
      strongSelf.onSearchTextChanged(recognizedText);
    }
  };

  self.voiceView.onRecordingEnd = ^{
    [[TWLSpeechManager sharedManager] stopRecording];
  };
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  [[TWLSpeechManager sharedManager] stopRecording];
  NSString *text = textField.text ?: @"";
  if (self.onSearchTextChanged) {
    self.onSearchTextChanged(text);
  }
  [textField resignFirstResponder];
  [self dismissViewControllerAnimated:YES completion:nil];
  return YES;
}

- (void)tl_backTapped {
  [[TWLSpeechManager sharedManager] stopRecording];
  if (self.onSearchTextChanged) {
    self.onSearchTextChanged(self.voiceView.searchTextField.text ?: @"");
  }
  [self dismissViewControllerAnimated:YES completion:nil];
}

@end
