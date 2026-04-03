//
//  TLWAIAssistantController.m
//  TL-PestIdentify
//

#import "TLWAIAssistantController.h"
#import "TLWAIAssistantMessage.h"
#import "TLWAIAssistantSession.h"
#import "TLWAIAssistantView.h"
#import "TLWImagePickerManager.h"
#import "TWLSpeechManager.h"
#import "TLWToast.h"
#import <Masonry/Masonry.h>

@interface TLWAIAssistantController () <TLWImagePickerDelegate>
@property (nonatomic, strong) TLWAIAssistantView *myView;
@property (nonatomic, copy)   NSString           *initialQuestion;
@property (nonatomic, assign) BOOL                showVoicePanelAfterKeyboardHide;
// 草稿态图片先留在 controller，真正发送后再固化成 message 进入 session。
@property (nonatomic, strong) NSMutableArray<UIImage *> *pendingImages;
@property (nonatomic, strong) TLWAIAssistantSession *session;
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

- (NSString *)navTitle { return @"AI助手"; }

- (void)viewDidLoad {
    [super viewDidLoad];

    // Controller 只做事件编排：会话数据交给 session，展示交给组合后的主 view。
    [self.view addSubview:self.myView];
    [self.myView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    [self.view bringSubviewToFront:self.navBar];

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
    [self.myView.sendButton addTarget:self
                               action:@selector(tl_send)
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

    // 删除预览图回调
    __weak typeof(self) weakSelf = self;
    self.myView.onRemoveImageAtIndex = ^(NSUInteger index) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf || index >= strongSelf.pendingImages.count) return;
        [strongSelf.pendingImages removeObjectAtIndex:index];
    };

    _pendingImages = [NSMutableArray array];
    _session = [[TLWAIAssistantSession alloc] init];

    // 语音识别错误提示
    [TWLSpeechManager sharedManager].errorHandler = ^(NSString *errorMessage) {
        [TLWToast show:errorMessage];
    };

    [self tl_seedConversation];
    if (self.initialQuestion.length > 0) {
        [self.myView setInputText:self.initialQuestion];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[TWLSpeechManager sharedManager] stopRecording];
}

#pragma mark - Actions

- (void)tl_camera {
    TLWImagePickerManager *picker = [[TLWImagePickerManager alloc] init];
    picker.delegate = self;
    [picker openCameraFrom:self];
}

- (void)tl_mic {
    // 键盘和语音面板互斥，避免两个输入态同时出现。
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
            [weakSelf.myView setInputText:[originalText stringByAppendingString:text]];
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
    [[TWLSpeechManager sharedManager] stopRecording];
    [TWLSpeechManager sharedManager].resultHandler = nil;
    [TWLSpeechManager sharedManager].errorHandler = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)tl_gallery {
    TLWImagePickerManager *picker = [[TLWImagePickerManager alloc] init];
    picker.delegate = self;
    picker.maxCount = 9;
    [picker openAlbumFrom:self];
}

#pragma mark - TLWImagePickerDelegate

- (void)imagePicker:(TLWImagePickerManager *)picker didSelectImage:(UIImage *)image {
    [self tl_compressImages:@[image] completion:^(NSArray<UIImage *> *results) {
        [self.pendingImages removeAllObjects];
        [self.pendingImages addObjectsFromArray:results];
        [self.myView showSelectedImage:results.firstObject];
        [self tl_uploadImageToAI:results.firstObject];
    }];
}

- (void)imagePicker:(TLWImagePickerManager *)picker didSelectImages:(NSArray<UIImage *> *)images {
    if (images.count == 0) return;
    [self tl_compressImages:images completion:^(NSArray<UIImage *> *results) {
        [self.pendingImages removeAllObjects];
        [self.pendingImages addObjectsFromArray:results];
        [self.myView showSelectedImages:self.pendingImages];
        for (UIImage *img in self.pendingImages) {
            [self tl_uploadImageToAI:img];
        }
    }];
}

- (void)tl_send {
    NSString *text = [self.myView.inputTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (text.length == 0 && self.pendingImages.count == 0) return;

    // 发送动作先把草稿态固化成一条本地用户消息，远端请求链路后续再接进来。
    TLWAIAssistantMessage *message = [TLWAIAssistantMessage messageWithRole:TLWAIAssistantMessageRoleUser
                                                                       text:text
                                                                localImages:self.pendingImages.copy
                                                            remoteImageURLs:nil];
    [self.session appendMessage:message];

    // 发送后立刻把消息里的原图替换为缩略图，释放大图内存
    if (message.localImages.count > 0) {
        NSMutableArray<UIImage *> *thumbnails = [NSMutableArray arrayWithCapacity:message.localImages.count];
        for (UIImage *img in message.localImages) {
            [thumbnails addObject:[self tl_thumbnailFromImage:img maxEdge:120]];
        }
        message.localImages = thumbnails.copy;
    }

    // 会话过长时裁剪早期消息的图片
    [self.session trimImageMemoryIfNeeded];

    [self.myView displayMessages:self.session.messages];
    [self.myView scrollMessagesToBottomAnimated:YES];

    [self.myView setInputText:@""];
    [self.pendingImages removeAllObjects];
    [self.myView hideSelectedImage];
}

/// 异步批量压缩图片，完成后回到主线程
- (void)tl_compressImages:(NSArray<UIImage *> *)images
                completion:(void (^)(NSArray<UIImage *> *results))completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableArray<UIImage *> *compressed = [NSMutableArray arrayWithCapacity:images.count];
        for (UIImage *image in images) {
            @autoreleasepool {
                [compressed addObject:[self tl_compressImage:image]];
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) completion(compressed.copy);
        });
    });
}

/// 压缩单张图片：最大边不超过 1280px，JPEG 质量 0.7
- (UIImage *)tl_compressImage:(UIImage *)image {
    CGFloat maxEdge = 1280.0;
    CGFloat w = image.size.width;
    CGFloat h = image.size.height;
    if (w <= maxEdge && h <= maxEdge) {
        NSData *data = UIImageJPEGRepresentation(image, 0.7);
        return data ? [UIImage imageWithData:data] : image;
    }
    CGFloat scale = (w > h) ? (maxEdge / w) : (maxEdge / h);
    CGSize newSize = CGSizeMake(floor(w * scale), floor(h * scale));
    UIGraphicsBeginImageContextWithOptions(newSize, YES, 1.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *resized = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    NSData *data = UIImageJPEGRepresentation(resized, 0.7);
    return data ? [UIImage imageWithData:data] : resized;
}

/// 生成缩略图，最大边不超过 maxEdge
- (UIImage *)tl_thumbnailFromImage:(UIImage *)image maxEdge:(CGFloat)maxEdge {
    CGFloat w = image.size.width;
    CGFloat h = image.size.height;
    if (w <= maxEdge && h <= maxEdge) return image;
    CGFloat scale = (w > h) ? (maxEdge / w) : (maxEdge / h);
    CGSize newSize = CGSizeMake(floor(w * scale), floor(h * scale));
    UIGraphicsBeginImageContextWithOptions(newSize, YES, 1.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *thumb = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return thumb ?: image;
}

- (void)tl_uploadImageToAI:(UIImage *)image {
    // TODO: POST /api/ai/chat，参数为 image（转 Base64 或 multipart）
    //   成功回调：将 AI 返回的文字结果追加到对话列表
    //   失败回调：弹 toast 提示用户重试
}

- (void)tl_seedConversation {
    // 先放一条本地欢迎语，保证页面在未接历史记录前也有明确的起始状态。
    TLWAIAssistantMessage *welcomeMessage = [TLWAIAssistantMessage messageWithRole:TLWAIAssistantMessageRoleAssistant
                                                                              text:@"你好，我可以帮你整理病虫害现象。你可以直接输入描述，或先选择图片再发送。"];
    [self.session appendMessage:welcomeMessage];
    [self.myView displayMessages:self.session.messages];
    [self.myView scrollMessagesToBottomAnimated:NO];
}

#pragma mark - Lazy

- (TLWAIAssistantView *)myView {
    if (!_myView) {
        _myView = [[TLWAIAssistantView alloc] initWithFrame:CGRectZero];
    }
    return _myView;
}

@end
