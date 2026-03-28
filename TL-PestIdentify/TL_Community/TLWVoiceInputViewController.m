//
//  TLWVoiceInputViewController.m
//  TL-PestIdentify
//

#import "TLWVoiceInputViewController.h"
#import "TLWVoiceInputView.h"
#import "TWLSpeechManager.h"

@interface TLWVoiceInputViewController ()

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
  [self tl_setupSpeechRecognition];
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  [[TWLSpeechManager sharedManager] stopRecording];
}

- (void)tl_setupSpeechRecognition {
  __weak typeof(self) weakSelf = self;

  [TWLSpeechManager sharedManager].resultHandler = ^(NSString *text, BOOL isFinal) {
    weakSelf.voiceView.searchTextField.text = text;
  };

  self.voiceView.onRecordingStart = ^{
    [[TWLSpeechManager sharedManager] startRecording];
  };

  self.voiceView.onRecordingEnd = ^{
    [[TWLSpeechManager sharedManager] stopRecording];
  };
}

- (void)tl_backTapped {
  [self dismissViewControllerAnimated:YES completion:nil];
}

@end
