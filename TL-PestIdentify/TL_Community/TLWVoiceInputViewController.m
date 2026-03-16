//
//  TLWVoiceInputViewController.m
//  TL-PestIdentify
//

#import "TLWVoiceInputViewController.h"
#import "TLWVoiceInputView.h"

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
}

- (void)tl_backTapped {
  [self dismissViewControllerAnimated:YES completion:nil];
}

@end
