//
//  TLWAIAssistantController.m
//  TL-PestIdentify
//

#import "TLWAIAssistantController.h"
#import "TLWAIAssistantView.h"
#import "TLWCameraManager.h"
#import "TWLSpeechManager.h"
#import <Masonry/Masonry.h>

@interface TLWAIAssistantController () <TLWCameraManagerDelegate>
@property (nonatomic, strong) TLWAIAssistantView *myView;
@property (nonatomic, copy)   NSString           *initialQuestion;
@property (nonatomic, strong) TLWCameraManager   *cameraManager;
@property (nonatomic, assign) BOOL                showVoicePanelAfterKeyboardHide;
@property (nonatomic, strong) UIImage            *pendingImage; // 待上传给 AI 的图片
@end

@implementation TLWAIAssistantController

- (instancetype)initWithInitialQuestion:(NSString *)question {
    self = [super init];
    if (self) {
        _initialQuestion = question;
        self.hidesBottomBarWhenPushed = YES;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view addSubview:self.myView];
    [self.myView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];

    self.cameraManager = [[TLWCameraManager alloc] initWithHostViewController:self];
    self.cameraManager.delegate = self;

    [self.myView.backButton addTarget:self
                               action:@selector(tl_back)
                     forControlEvents:UIControlEventTouchUpInside];
    [self.myView.cameraButton addTarget:self
                                 action:@selector(tl_camera)
                       forControlEvents:UIControlEventTouchUpInside];
    [self.myView.micButton addTarget:self
                              action:@selector(tl_mic)
                    forControlEvents:UIControlEventTouchUpInside];

    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc]
                                              initWithTarget:self
                                              action:@selector(tl_micLongPress:)];
    longPress.minimumPressDuration = 0.3;
    [self.myView.voiceSpeechImageView addGestureRecognizer:longPress];

    [self.myView.galleryButton addTarget:self
                                  action:@selector(tl_gallery)
                        forControlEvents:UIControlEventTouchUpInside];

    // 键盘通知
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(tl_keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(tl_keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];

    // 点击页面收起键盘
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                          action:@selector(tl_dismissKeyboard)];
    tap.cancelsTouchesInView = NO;
    [self.myView addGestureRecognizer:tap];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = YES;
    self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    self.navigationController.interactivePopGestureRecognizer.delegate = nil;
}

#pragma mark - Actions

- (void)tl_back {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)tl_camera {
    [self.cameraManager setupCamera];
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    picker.allowsEditing = YES;
    picker.delegate = self.cameraManager;
    picker.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)tl_mic {
    if (self.myView.inputTextField.isFirstResponder) {
        self.showVoicePanelAfterKeyboardHide = YES;
        [self.myView endEditing:YES];
    } else {
        [self.myView showVoicePanel];
    }
}

- (void)tl_micLongPress:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan) {
        NSString *originalText = self.myView.inputTextField.text ?: @"";

        __weak typeof(self) weakSelf = self;
        [TWLSpeechManager sharedManager].resultHandler = ^(NSString *text, BOOL isFinal) {
            weakSelf.myView.inputTextField.text = [originalText stringByAppendingString:text];
            if (isFinal) {
                [weakSelf.myView hideVoicePanel];
            }
        };
        [[TWLSpeechManager sharedManager] startRecording];

    } else if (gesture.state == UIGestureRecognizerStateEnded ||
               gesture.state == UIGestureRecognizerStateCancelled) {
        [[TWLSpeechManager sharedManager] stopRecording];
    }
}

- (void)tl_dismissKeyboard {
    [self.myView endEditing:YES];
}

#pragma mark - Keyboard

- (void)tl_keyboardWillShow:(NSNotification *)notification {
    NSDictionary *info = notification.userInfo;
    //  分别拿出键盘大小和动画时间
    CGRect keyboardFrame = [info[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGFloat keyboardHeight = CGRectGetHeight(keyboardFrame);
    NSTimeInterval duration = [info[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    [self.myView adjustForKeyboardHeight:keyboardHeight duration:duration];
}

- (void)tl_keyboardWillHide:(NSNotification *)notification {
    NSTimeInterval duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    [self.myView adjustForKeyboardHeight:0 duration:duration];
    if (self.showVoicePanelAfterKeyboardHide) {
        self.showVoicePanelAfterKeyboardHide = NO;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            [self.myView showVoicePanel];
        });
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)tl_gallery {
    [self.cameraManager openPhotoAlbum];
}

#pragma mark - TLWCameraManagerDelegate

- (void)cameraManager:(TLWCameraManager *)manager didCapturePhoto:(UIImage *)image {
    self.pendingImage = image;
    [self.myView showSelectedImage:image];
    [self tl_uploadImageToAI:image];
}

- (void)tl_uploadImageToAI:(UIImage *)image {
    // TODO: POST /api/ai/chat，参数为 image（转 Base64 或 multipart）
    //   成功回调：将 AI 返回的文字结果追加到对话列表
    //   失败回调：弹 toast 提示用户重试
}

#pragma mark - Lazy

- (TLWAIAssistantView *)myView {
    if (!_myView) {
        _myView = [[TLWAIAssistantView alloc] initWithFrame:CGRectZero];
    }
    return _myView;
}

@end
