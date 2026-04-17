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
#import "TLWAIStreamClient.h"
#import "TLWIdentifyPageController.h"
#import "TLWImagePickerManager.h"
#import "TWLSpeechManager.h"
#import "TLWToast.h"
#import "TLWSDKManager.h"
#import <AgriPestClient/AGChatRequest.h>
#import <AgriPestClient/AGDefaultConfiguration.h>
#import <AgriPestClient/AGResultChatProfileResponse.h>
#import <Masonry/Masonry.h>
#import <math.h>

static NSTimeInterval const kAIAssistantTypingFlushInterval = 0.09;
static NSUInteger const kAIAssistantTypingCharactersPerFlush = 2;
static BOOL const kAIAssistantEnableInterfaceCompareDebug = YES;

@interface TLWAIAssistantController () <TLWImagePickerDelegate, UIGestureRecognizerDelegate>
@property (nonatomic, strong) TLWAIAssistantView *myView;
@property (nonatomic, copy)   NSString           *initialQuestion;
@property (nonatomic, assign) BOOL                didSendInitialQuestion;
// 草稿态图片先留在 controller，真正发送后再固化成 message 进入 session。
@property (nonatomic, strong) NSMutableArray<UIImage *> *pendingImages;
@property (nonatomic, strong) TLWAIAssistantSession *session;
@property (nonatomic, weak)   TLWAIAssistantMessage *currentAIMessage;
@property (nonatomic, strong) NSURLSessionTask *currentUploadTask;
/// 当前活跃的流式客户端；tl_send 重建，tl_stopAI/onDone/onError 清理。
@property (nonatomic, strong) TLWAIStreamClient *streamClient;
/// 未 flush 的增量文本缓冲，由定时器分批追加到 planAccumulated，避免每帧刷 tableView 抖动。
@property (nonatomic, strong) NSMutableString *pendingDelta;
/// 本轮对话累积的完整方案文本。onPlanFinal 触发时整体替换。
@property (nonatomic, strong) NSMutableString *planAccumulated;
/// 病害头部（例 "病害：番茄早疫病(92%)"），来自 disease 事件，渲染在气泡开头。
@property (nonatomic, copy)   NSString *diseaseHeaderText;
/// 打字机节流定时器，分批合并 plan_delta 的 UI 刷新。
@property (nonatomic, strong) dispatch_source_t deltaFlushTimer;
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
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.initialQuestion.length > 0 && !self.didSendInitialQuestion) {
        self.didSendInitialQuestion = YES;
        [self.myView setInputText:self.initialQuestion];
        [self tl_send];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[TWLSpeechManager sharedManager] stopRecording];
}

#pragma mark - Actions

- (void)tl_camera {
    TLWIdentifyPageController *cameraVC = [[TLWIdentifyPageController alloc] init];
    cameraVC.mode = TLWIdentifyPageModePickerOnly;
    __weak typeof(self) weakSelf = self;
    cameraVC.onImagePicked = ^(UIImage * _Nonnull image) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf || !image) return;
        [strongSelf tl_applySelectedImages:@[image]];
    };
    cameraVC.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:cameraVC animated:YES];
}

- (void)tl_mic {
    // 键盘和语音面板互斥，避免两个输入态同时出现。
    if (self.myView.inputTextField.isFirstResponder) {
        // 先挂上语音面板，再让键盘同步退场，避免先缩到底再弹出的断层感。
        [self.myView showVoicePanel];
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
        // 先挂上 plus 面板，再让键盘同步退场，切换更接近无缝。
        if (self.myView.inputTextField.isFirstResponder) {
            [self.myView showPlusPanel];
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
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.myView scrollMessagesToBottomAnimated:NO];
    });
}

- (void)tl_keyboardWillHide:(NSNotification *)notification {
    NSTimeInterval duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    [self.myView adjustForKeyboardHeight:0 duration:duration];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.myView scrollMessagesToBottomAnimated:NO];
    });
}

- (void)dealloc {
    [self.currentUploadTask cancel];
    [self.streamClient cancel];
    [self tl_stopDeltaFlushTimer];
    [[TWLSpeechManager sharedManager] stopRecording];
    [TWLSpeechManager sharedManager].resultHandler = nil;
    [TWLSpeechManager sharedManager].errorHandler = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)tl_stopAI {
    TLWAIAssistantMessage *aiMessage = self.currentAIMessage;
    if (!aiMessage) return;

    [self.currentUploadTask cancel];
    self.currentUploadTask = nil;
    [self.streamClient cancel];
    self.streamClient = nil;
    // 停流前先把已经累积的增量落到气泡里，用户看到的内容不丢。
    [self tl_flushPendingDeltasIfNeeded];
    [self tl_stopDeltaFlushTimer];

    aiMessage.status = TLWAIAssistantMessageStatusIdle;
    if (aiMessage.text.length == 0 || [aiMessage.text isEqualToString:@"正在思考中..."]) {
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
    [self tl_applySelectedImages:@[image]];
}

- (void)imagePicker:(TLWImagePickerManager *)picker didSelectImages:(NSArray<UIImage *> *)images {
    [self tl_applySelectedImages:images];
}

- (void)tl_applySelectedImages:(NSArray<UIImage *> *)images {
    if (images.count == 0) return;
    [self tl_compressImages:images completion:^(NSArray<UIImage *> *results) {
        [self.pendingImages removeAllObjects];
        [self.pendingImages addObjectsFromArray:results];
        if (self.pendingImages.count <= 1) {
            [self.myView showSelectedImage:self.pendingImages.firstObject];
            return;
        }
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

    // 发送后把高清原图迁到 previewImages 留给点击放大用，localImages 改成 120px 缩略图给气泡渲染省内存
    if (userMessage.localImages.count > 0) {
        userMessage.previewImages = userMessage.localImages;
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

    // 3. 构建流式对话请求（图片先上传拿 URL，避免大 body 走 base64）
    AGChatRequest *request = [[AGChatRequest alloc] init];
    request.text = text;
    request.saveHistory = @(NO);
    request.useSingleModel = @(YES);

    // 初始化本次流式状态：三段缓冲 + 头部
    self.diseaseHeaderText = @"";
    self.planAccumulated = [NSMutableString string];
    self.pendingDelta = [NSMutableString string];

    __weak typeof(self) weakSelf = self;
    __block void (^streamOnce)(BOOL didRetryAuth) = nil;
    NSString *compareTag = [self tl_compareDebugTag];
    void (^startStream)(NSString *imageURL) = ^(NSString *imageURL) {
        if (imageURL.length > 0) request.imageUrl = imageURL;
        if (kAIAssistantEnableInterfaceCompareDebug) {
            [weakSelf tl_startProfileComparisonDebugWithRequest:request tag:compareTag];
        }

        streamOnce = ^(BOOL didRetryAuth) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) return;
            if (strongSelf.currentAIMessage != aiMessage) return;

            NSString *token = [AGDefaultConfiguration sharedConfig].accessToken;
            if (token.length == 0) {
                aiMessage.status = TLWAIAssistantMessageStatusFailed;
                aiMessage.text = @"登录已失效，请重新登录";
                strongSelf.currentAIMessage = nil;
                [strongSelf.myView exitAILoadingMode];
                [strongSelf.myView displayMessages:strongSelf.session.messages];
                return;
            }

            TLWAIStreamClient *client = [[TLWAIStreamClient alloc] init];

            client.onMeta = ^(NSDictionary *meta) {
                NSLog(@"[AI-STREAM][%@] parsed meta: %@", compareTag, meta);
            };

            client.onDiseaseList = ^(NSArray *diseases) {
                __strong typeof(weakSelf) s = weakSelf;
                if (!s || s.currentAIMessage != aiMessage) return;
                NSLog(@"[AI-STREAM][%@] parsed disease list: %@", compareTag, diseases);
                s.diseaseHeaderText = [s tl_headerTextFromDiseaseList:diseases];
                [s tl_refreshAIMessageText];
                [s.myView displayMessages:s.session.messages];
                [s.myView scrollMessagesToBottomAnimated:NO];
            };

            client.onPlanDelta = ^(NSString *delta) {
                __strong typeof(weakSelf) s = weakSelf;
                if (!s || s.currentAIMessage != aiMessage) return;
                NSLog(@"[AI-STREAM][%@] parsed plan delta: %@", compareTag, delta);
                [s.pendingDelta appendString:delta];
                // 等 60ms timer 合并 flush，避免每帧刷 tableView 抖动
            };

            client.onPlanFinal = ^(NSString *fullText) {
                __strong typeof(weakSelf) s = weakSelf;
                if (!s || s.currentAIMessage != aiMessage) return;
                NSLog(@"[AI-STREAM][%@] parsed plan final: %@", compareTag, fullText);
                [s.pendingDelta setString:@""];
                s.planAccumulated = [fullText mutableCopy];
                [s tl_refreshAIMessageText];
                [s.myView displayMessages:s.session.messages];
                [s.myView scrollMessagesToBottomAnimated:NO];
            };

            client.onDone = ^(NSDictionary *info) {
                __strong typeof(weakSelf) s = weakSelf;
                if (!s || s.currentAIMessage != aiMessage) return;
                NSLog(@"[AI-STREAM][%@] done info: %@", compareTag, info);
                [s tl_flushPendingDeltasIfNeeded];
                [s tl_stopDeltaFlushTimer];
                if (s.planAccumulated.length == 0 && s.diseaseHeaderText.length == 0) {
                    aiMessage.text = @"AI 暂时无法给出回复，请换个描述再试试。";
                }
                NSLog(@"[AI-STREAM][%@] visible text: %@", compareTag, aiMessage.text ?: @"");
                aiMessage.status = TLWAIAssistantMessageStatusIdle;
                s.currentAIMessage = nil;
                s.streamClient = nil;
                [s.myView exitAILoadingMode];
                [s.myView displayMessages:s.session.messages];
                [s.myView scrollMessagesToBottomAnimated:YES];
            };

            client.onError = ^(NSError *err, NSString *serverMsg) {
                __strong typeof(weakSelf) s = weakSelf;
                if (!s || s.currentAIMessage != aiMessage) return;
                NSLog(@"[AI-STREAM][%@] error: err=%@ serverMsg=%@", compareTag, err, serverMsg);
                [s tl_stopDeltaFlushTimer];
                aiMessage.status = TLWAIAssistantMessageStatusFailed;
                NSString *reason = serverMsg.length > 0 ? serverMsg : (err.localizedDescription ?: @"请求失败");
                aiMessage.text = [NSString stringWithFormat:@"请求失败：%@", reason];
                aiMessage.errorMessage = err.localizedDescription ?: serverMsg;
                s.currentAIMessage = nil;
                s.streamClient = nil;
                [s.myView exitAILoadingMode];
                [s.myView displayMessages:s.session.messages];
                [TLWToast show:@"AI 回复失败，请重试"];
            };

            client.onAuthFailure = ^{
                __strong typeof(weakSelf) s = weakSelf;
                if (!s || s.currentAIMessage != aiMessage) return;
                TLWSessionManager *sessionManager = [TLWSDKManager shared].sessionManager;
                if (didRetryAuth) {
                    // 续期成功后第二次又 401：按既有约定走登出，避免死循环
                    [s tl_stopDeltaFlushTimer];
                    [sessionManager invalidateSessionWithMessage:@"登录状态恢复失败，请重新登录"];
                    aiMessage.status = TLWAIAssistantMessageStatusFailed;
                    aiMessage.text = @"登录已失效，请重新登录";
                    s.currentAIMessage = nil;
                    s.streamClient = nil;
                    [s.myView exitAILoadingMode];
                    [s.myView displayMessages:s.session.messages];
                    return;
                }
                // 首次 401：走统一续期，成功后用新 token 重建一次 stream
                [sessionManager handleUnauthorizedWithRetry:^{
                    if (streamOnce) streamOnce(YES);
                }];
            };

            strongSelf.streamClient = client;
            [strongSelf tl_startDeltaFlushTimer];
            [client streamChatWithRequest:request accessToken:token];
        };

        streamOnce(NO);
    };

    // 4. 如果有图片，先上传拿 URL；没有图片直接发
    if (imagesToSend.count > 0) {
        self.currentUploadTask = [[TLWSDKManager shared] uploadImages:@[imagesToSend.firstObject]
                                                               prefix:@"ai_assistant/"
                                                           completion:^(NSArray<NSString *> * _Nullable urls, NSError * _Nullable uploadError) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) return;
            strongSelf.currentUploadTask = nil;
            if (strongSelf.currentAIMessage != aiMessage) return;

            if (uploadError || urls.count == 0) {
                strongSelf.currentAIMessage = nil;
                [strongSelf.myView exitAILoadingMode];
                aiMessage.status = TLWAIAssistantMessageStatusFailed;
                aiMessage.text = @"图片上传失败，请稍后重试";
                aiMessage.errorMessage = uploadError.localizedDescription ?: @"上传返回为空";
                [strongSelf.myView displayMessages:strongSelf.session.messages];
                [TLWToast show:@"图片上传失败"];
                return;
            }
            startStream(urls.firstObject);
        }];
    } else {
        startStream(nil);
    }
}

/// 统一处理 AI 对话响应
#pragma mark - 流式 UI 合并

- (NSString *)tl_compareDebugTag {
    return NSUUID.UUID.UUIDString.lowercaseString;
}

- (void)tl_startProfileComparisonDebugWithRequest:(AGChatRequest *)request tag:(NSString *)tag {
    if (!request || tag.length == 0) return;

    AGChatRequest *probeRequest = [[AGChatRequest alloc] init];
    probeRequest.text = request.text;
    probeRequest.imageUrl = request.imageUrl;
    probeRequest.useSingleModel = request.useSingleModel;
    probeRequest.extraInfo = request.extraInfo;
    probeRequest.saveHistory = request.saveHistory;

    NSLog(@"\n========== [AI-PROFILE] REQUEST [%@] ==========\ntext=%@\nimageUrl=%@\nuseSingleModel=%@\nsaveHistory=%@\nextraInfo=%@\n===============================================",
          tag,
          probeRequest.text ?: @"",
          probeRequest.imageUrl ?: @"",
          probeRequest.useSingleModel ?: @NO,
          probeRequest.saveHistory ?: @NO,
          probeRequest.extraInfo ?: @"");

    [[[TLWSDKManager shared] api] chatProfileWithChatRequest:probeRequest completionHandler:^(AGResultChatProfileResponse *output, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                NSLog(@"\n========== [AI-PROFILE] ERROR [%@] ==========\n%@\n============================================", tag, error);
                return;
            }

            NSString *answer = [self tl_trimmedStringFromValue:output.data.answer];
            id profileJSON = output.data.profile ? [output.data.profile toDictionary] : @{};
            NSLog(@"\n========== [AI-PROFILE] RESPONSE [%@] ==========\ncode=%@\nmessage=%@\nanswer=%@\nprofile=%@\nrawOutput=%@\n================================================",
                  tag,
                  output.code,
                  output.message,
                  answer ?: @"",
                  profileJSON ?: @{},
                  [output toDictionary] ?: @{});
        });
    }];
}

/// disease 事件 -> "番茄早疫病(92%)、番茄灰霉病(68%)"。
- (NSString *)tl_headerTextFromDiseaseList:(NSArray *)list {
    if (![list isKindOfClass:[NSArray class]] || list.count == 0) return @"";
    NSMutableArray<NSString *> *parts = [NSMutableArray array];
    for (id item in list) {
        if (![item isKindOfClass:[NSDictionary class]]) continue;
        NSDictionary *d = item;
        NSString *name = [self tl_trimmedStringFromValue:(d[@"diseaseName"] ?: d[@"name"] ?: d[@"title"])];
        if (name.length == 0) continue;
        NSString *conf = [self tl_confidenceTextFromValue:d[@"confidence"]];
        if (conf.length > 0) {
            [parts addObject:[NSString stringWithFormat:@"%@(%@)", name, conf]];
        } else {
            [parts addObject:name];
        }
    }
    if (parts.count == 0) return @"";
    return [parts componentsJoinedByString:@"、"];
}

/// 用 diseaseHeaderText + planAccumulated 重算 aiMessage.text。
- (void)tl_refreshAIMessageText {
    TLWAIAssistantMessage *aiMessage = self.currentAIMessage;
    if (!aiMessage) return;
    NSMutableString *composed = [NSMutableString string];
    if (self.diseaseHeaderText.length > 0) {
        [composed appendString:self.diseaseHeaderText];
    }
    if (self.planAccumulated.length > 0) {
        if (composed.length > 0) [composed appendString:@"\n\n"];
        [composed appendString:self.planAccumulated];
    }
    if (composed.length == 0) {
        [composed appendString:@"正在生成方案..."];
    }
    aiMessage.text = composed.copy;
}

/// 把 pendingDelta 分批累加到 planAccumulated 并刷新气泡。timer 定时触发，done/final 时手动兜底调用。
- (void)tl_flushPendingDeltasIfNeeded {
    if (!self.currentAIMessage) return;
    if (self.pendingDelta.length == 0) return;
    NSUInteger chunkLength = MIN(self.pendingDelta.length, kAIAssistantTypingCharactersPerFlush);
    NSString *chunk = [self.pendingDelta substringToIndex:chunkLength];
    [self.planAccumulated appendString:chunk];
    [self.pendingDelta deleteCharactersInRange:NSMakeRange(0, chunkLength)];
    [self tl_refreshAIMessageText];
    [self.myView displayMessages:self.session.messages];
    [self.myView scrollMessagesToBottomAnimated:NO];
}

- (void)tl_startDeltaFlushTimer {
    if (self.deltaFlushTimer) return;
    dispatch_source_t t = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
    dispatch_source_set_timer(t,
                              dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kAIAssistantTypingFlushInterval * NSEC_PER_SEC)),
                              (uint64_t)(kAIAssistantTypingFlushInterval * NSEC_PER_SEC),
                              (uint64_t)(20 * NSEC_PER_MSEC));
    __weak typeof(self) weakSelf = self;
    dispatch_source_set_event_handler(t, ^{
        [weakSelf tl_flushPendingDeltasIfNeeded];
    });
    dispatch_resume(t);
    self.deltaFlushTimer = t;
}

- (void)tl_stopDeltaFlushTimer {
    if (self.deltaFlushTimer) {
        dispatch_source_cancel(self.deltaFlushTimer);
        self.deltaFlushTimer = nil;
    }
}

#pragma mark - Helpers

- (NSString *)tl_confidenceTextFromValue:(id)value {
    if ([value isKindOfClass:[NSNumber class]]) {
        double number = [(NSNumber *)value doubleValue];
        if (number <= 1.0) {
            number *= 100.0;
        }
        if (fabs(number - round(number)) < 0.01) {
            return [NSString stringWithFormat:@"%.0f%%", number];
        }
        return [NSString stringWithFormat:@"%.1f%%", number];
    }

    NSString *text = [self tl_trimmedStringFromValue:value];
    if (text.length == 0) {
        return @"";
    }
    if ([text containsString:@"%"] || [text containsString:@"％"]) {
        return text;
    }
    double number = text.doubleValue;
    if (number <= 0.0) {
        return text;
    }
    if (number <= 1.0) {
        number *= 100.0;
    }
    if (fabs(number - round(number)) < 0.01) {
        return [NSString stringWithFormat:@"%.0f%%", number];
    }
    return [NSString stringWithFormat:@"%.1f%%", number];
}

- (NSString *)tl_trimmedStringFromValue:(id)value {
    if ([value isKindOfClass:[NSString class]]) {
        return [(NSString *)value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }
    if ([value isKindOfClass:[NSNumber class]]) {
        return [[(NSNumber *)value stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }
    return @"";
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
