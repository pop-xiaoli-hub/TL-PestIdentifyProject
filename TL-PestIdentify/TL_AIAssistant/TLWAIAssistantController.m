//
//  TLWAIAssistantController.m
//  TL-PestIdentify
//
//  Created by Tommy-MrWu on 2026/3/15.
//  职责：编排AI助手页面交互与业务流程。
//
#import "TLWAIAssistantController.h"
#import "TLWAICallController.h"
#import "TLWAIAssistantMessage.h"
#import "TLWAIAssistantSession.h"
#import "TLWAIAssistantView.h"
#import "TLWImagePickerManager.h"
#import "TWLSpeechManager.h"
#import "TLWToast.h"
#import "TLWSDKManager.h"
#import <AgriPestClient/AGChatRequest.h>
#import <AgriPestClient/AGResultChatProfileResponse.h>
#import <AgriPestClient/AGChatProfileResponse.h>
#import <Masonry/Masonry.h>

@interface TLWAIAssistantController () <TLWImagePickerDelegate, UIGestureRecognizerDelegate>
@property (nonatomic, strong) TLWAIAssistantView *myView;
@property (nonatomic, copy)   NSString           *initialQuestion;
@property (nonatomic, assign) BOOL                showVoicePanelAfterKeyboardHide;
@property (nonatomic, assign) BOOL                showPlusPanelAfterKeyboardHide;
// 草稿态图片先留在 controller，真正发送后再固化成 message 进入 session。
@property (nonatomic, strong) NSMutableArray<UIImage *> *pendingImages;
@property (nonatomic, strong) TLWAIAssistantSession *session;
@property (nonatomic, weak)   TLWAIAssistantMessage *currentAIMessage;
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

- (NSString *)navTitle         { return @"AI助手"; }
- (NSString *)navTitleIconName { return @"aiAssisstantIcon"; }

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

    [self.myView.plusButton addTarget:self
                                action:@selector(tl_togglePlusPanel)
                      forControlEvents:UIControlEventTouchUpInside];
    [self.myView.plusCameraButton addTarget:self
                                     action:@selector(tl_camera)
                           forControlEvents:UIControlEventTouchUpInside];
    [self.myView.plusAlbumButton addTarget:self
                                    action:@selector(tl_gallery)
                          forControlEvents:UIControlEventTouchUpInside];
    [self.myView.plusAICallButton addTarget:self
                                     action:@selector(tl_aiCall)
                           forControlEvents:UIControlEventTouchUpInside];
    [self.myView.sendButton addTarget:self
                               action:@selector(tl_send)
                     forControlEvents:UIControlEventTouchUpInside];
    [self.myView.stopButton addTarget:self
                               action:@selector(tl_stopAI)
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
    tap.delegate = self;
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

- (void)tl_togglePlusPanel {
    // 收起语音面板
    [self.myView hideVoicePanel];

    if (self.myView.isPlusPanelVisible) {
        [self.myView hidePlusPanel];
    } else {
        // 键盘和 plus 面板互斥：先收键盘，等键盘动画结束再展开
        if (self.myView.inputTextField.isFirstResponder) {
            self.showPlusPanelAfterKeyboardHide = YES;
            [self.myView endEditing:YES];
        } else {
            [self.myView showPlusPanel];
        }
    }
}

- (void)tl_dismissKeyboard {
    [self.myView endEditing:YES];
    [self.myView hideVoicePanel];
    [self.myView hidePlusPanel];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    UIView *view = touch.view;
    if (!view) return YES;
    if ([view isDescendantOfView:self.myView.sendButton]) return NO;
    if ([view isDescendantOfView:self.myView.cameraButton]) return NO;
    if ([view isDescendantOfView:self.myView.micButton]) return NO;
    if ([view isDescendantOfView:self.myView.plusButton]) return NO;
    if ([view isDescendantOfView:self.myView.plusCameraButton]) return NO;
    if ([view isDescendantOfView:self.myView.plusAlbumButton]) return NO;
    if ([view isDescendantOfView:self.myView.plusAICallButton]) return NO;
    if ([view isDescendantOfView:self.myView.stopButton]) return NO;
    if ([view isDescendantOfView:self.myView.inputTextField]) return NO;
    return YES;
}

#pragma mark - Keyboard

- (void)tl_keyboardWillShow:(NSNotification *)notification {
    NSDictionary *info = notification.userInfo;
    CGRect keyboardFrame = [info[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGFloat keyboardHeight = CGRectGetHeight(keyboardFrame);
    NSTimeInterval duration = [info[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    // 键盘弹出时收起语音面板和 plus 面板（三者互斥）
    [self.myView hideVoicePanel];
    [self.myView hidePlusPanel];
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
    if (self.showPlusPanelAfterKeyboardHide) {
        self.showPlusPanelAfterKeyboardHide = NO;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            [self.myView showPlusPanel];
        });
    }
}

- (void)dealloc {
    [[TWLSpeechManager sharedManager] stopRecording];
    [TWLSpeechManager sharedManager].resultHandler = nil;
    [TWLSpeechManager sharedManager].errorHandler = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)tl_stopAI {
    TLWAIAssistantMessage *aiMessage = self.currentAIMessage;
    if (!aiMessage) return;

    // 标记已停止
    aiMessage.status = TLWAIAssistantMessageStatusIdle;
    if ([aiMessage.text isEqualToString:@"正在思考中..."]) {
        aiMessage.text = @"已停止回复";
    }
    self.currentAIMessage = nil;

    [self.myView exitAILoadingMode];
    [self.myView displayMessages:self.session.messages];
}

- (void)tl_aiCall {
    [self.myView hidePlusPanel];
    TLWAICallController *vc = [[TLWAICallController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)tl_gallery {
    TLWImagePickerManager *picker = [[TLWImagePickerManager alloc] init];
    picker.delegate = self;
    picker.maxCount = 1; // 后端 AI 接口暂只支持单张图片
    [picker openAlbumFrom:self];
}

#pragma mark - TLWImagePickerDelegate

- (void)imagePicker:(TLWImagePickerManager *)picker didSelectImage:(UIImage *)image {
    [self tl_compressImages:@[image] completion:^(NSArray<UIImage *> *results) {
        [self.pendingImages removeAllObjects];
        [self.pendingImages addObjectsFromArray:results];
        [self.myView showSelectedImage:results.firstObject];
    }];
}

- (void)imagePicker:(TLWImagePickerManager *)picker didSelectImages:(NSArray<UIImage *> *)images {
    if (images.count == 0) return;
    [self tl_compressImages:images completion:^(NSArray<UIImage *> *results) {
        [self.pendingImages removeAllObjects];
        [self.pendingImages addObjectsFromArray:results];
        [self.myView showSelectedImages:self.pendingImages];
    }];
}

- (void)tl_send {
    // 先确认中文输入法的候选词
    UITextRange *markedRange = self.myView.inputTextField.markedTextRange;
    if (markedRange) {
        UITextPosition *start = markedRange.start;
        UITextPosition *end = markedRange.end;
        if (start && end) {
            NSString *marked = [self.myView.inputTextField textInRange:markedRange];
            if (marked.length > 0) {
                [self.myView.inputTextField replaceRange:markedRange withText:marked];
            }
        }
    }
    NSString *text = [self.myView.inputTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (text.length == 0 && self.pendingImages.count == 0) return;

    // 1. 把草稿态固化成一条本地用户消息
    NSArray<UIImage *> *imagesToSend = self.pendingImages.copy;
    TLWAIAssistantMessage *userMessage = [TLWAIAssistantMessage messageWithRole:TLWAIAssistantMessageRoleUser
                                                                           text:text
                                                                    localImages:imagesToSend
                                                                remoteImageURLs:nil];
    // 记录第一张图片的原始尺寸，供 cell 按比例渲染
    if (imagesToSend.count > 0) {
        userMessage.imageDisplaySize = imagesToSend.firstObject.size;
    }
    [self.session appendMessage:userMessage];

    // 发送后立刻把消息里的原图替换为缩略图，释放大图内存
    if (userMessage.localImages.count > 0) {
        NSMutableArray<UIImage *> *thumbnails = [NSMutableArray arrayWithCapacity:userMessage.localImages.count];
        for (UIImage *img in userMessage.localImages) {
            [thumbnails addObject:[self tl_thumbnailFromImage:img maxEdge:120]];
        }
        userMessage.localImages = thumbnails.copy;
    }

    // 2. 追加一条 AI 占位消息（"思考中..."）
    TLWAIAssistantMessage *aiMessage = [TLWAIAssistantMessage messageWithRole:TLWAIAssistantMessageRoleAssistant
                                                                         text:@"正在思考中..."];
    aiMessage.status = TLWAIAssistantMessageStatusSending;
    [self.session appendMessage:aiMessage];
    self.currentAIMessage = aiMessage;

    // 进入 AI 加载态：隐藏 mic，plus 左移，显示 stop
    [self.myView enterAILoadingMode];

    // 会话过长时裁剪早期消息的图片
    [self.session trimImageMemoryIfNeeded];

    [self.myView displayMessages:self.session.messages];
    [self.myView scrollMessagesToBottomAnimated:YES];

    // 清空输入区
    [self.myView setInputText:@""];
    [self.pendingImages removeAllObjects];
    [self.myView hideSelectedImage];

    // 3. 构建 SDK 请求
    AGChatRequest *request = [[AGChatRequest alloc] init];
    request.text = text;

    // 如果有图片，取第一张转 Base64 传给后端（SDK 只支持单张 imageUrl）
    if (imagesToSend.count > 0) {
        NSData *imageData = UIImageJPEGRepresentation(imagesToSend.firstObject, 0.8);
        if (imageData) {
            request.imageUrl = [imageData base64EncodedStringWithOptions:0];
        }
    }

    // 4. 发起请求
    __weak typeof(self) weakSelf = self;
    [[TLWSDKManager shared].api chatProfileWithChatRequest:request completionHandler:^(AGResultChatProfileResponse *output, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) return;

            // 用户已手动停止，忽略回调
            if (strongSelf.currentAIMessage != aiMessage) return;

            if (error) {
                strongSelf.currentAIMessage = nil;
                [strongSelf.myView exitAILoadingMode];
                aiMessage.status = TLWAIAssistantMessageStatusFailed;
                aiMessage.text = @"网络请求失败，请稍后重试";
                aiMessage.errorMessage = error.localizedDescription;
                [strongSelf.myView displayMessages:strongSelf.session.messages];
                [TLWToast show:@"请求失败，请检查网络"];
                return;
            }

            // 鉴权失效（401/403），自动续期后重试
            if ([[TLWSDKManager shared].sessionManager shouldAttemptTokenRefreshForCode:output.code]) {
                [[TLWSDKManager shared].sessionManager handleUnauthorizedWithRetry:^{
                    [[TLWSDKManager shared].api chatProfileWithChatRequest:request completionHandler:^(AGResultChatProfileResponse *retryOutput, NSError *retryError) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            __strong typeof(weakSelf) strongSelf2 = weakSelf;
                            if (!strongSelf2) return;
                            [strongSelf2 tl_handleChatResponse:retryOutput error:retryError forMessage:aiMessage];
                        });
                    }];
                }];
                return;
            }

            [strongSelf tl_handleChatResponse:output error:nil forMessage:aiMessage];
        });
    }];
}

/// 统一处理 AI 对话响应
- (void)tl_handleChatResponse:(AGResultChatProfileResponse *)output
                         error:(NSError *)error
                    forMessage:(TLWAIAssistantMessage *)aiMessage {
    // 退出 AI 加载态
    self.currentAIMessage = nil;
    [self.myView exitAILoadingMode];

    if (error || !output || !output.code || output.code.integerValue != 200) {
        aiMessage.status = TLWAIAssistantMessageStatusFailed;
        NSString *serverMsg = output.message ?: @"服务异常";
        aiMessage.text = [NSString stringWithFormat:@"请求失败：%@", serverMsg];
        aiMessage.errorMessage = error.localizedDescription ?: serverMsg;
        [self.myView displayMessages:self.session.messages];
        [TLWToast show:@"AI 回复失败，请重试"];
        return;
    }

    NSString *answer = output.data.answer;
    if (answer.length == 0) {
        answer = @"AI 暂时无法给出回复，请换个描述再试试。";
    }
    aiMessage.text = answer;
    aiMessage.status = TLWAIAssistantMessageStatusIdle;
    [self.myView displayMessages:self.session.messages];
    [self.myView scrollMessagesToBottomAnimated:YES];
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
