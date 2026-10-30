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
#import "TLWAIConversationTurn.h"
#import "TLWAIAssistantView.h"
#import "TLWAIStreamClient.h"
#import "TLWAIJobStreamClient.h"
#import "TLWAIStreamDebugConfiguration.h"
#import "TLWAIFramePacer.h"
#import "TLWAIKeyboardGeometry.h"
#import "TLWAIGestureCoordinator.h"
#import "TLWAITrace.h"
#import "TLWAITextPresentation.h"
#import "TLWAIEventEnvelope.h"
#import "TLWAITurnStore.h"
#import "TLWAITurnPersistence.h"
#import "TLWAIProductPolicy.h"
#import "TLWAIImageArchive.h"
#import "TLWLocationManager.h"
#import "TLWLocalIdentifyManager.h"
@import Network;
#import "TLWIdentifyPageController.h"
#import "TLWImagePickerManager.h"
#import "TWLSpeechManager.h"
#import "TLWToast.h"
#import "TLWSDKManager.h"
#import "TLWPerfLog.h"
#import <AgriPestClient/AGDefaultConfiguration.h>
#import <AgriPestClient/AGResultChatProfileResponse.h>
#import <Masonry/Masonry.h>
#import <math.h>

static NSTimeInterval const kAIAssistantSlowStreamHintDelay = 8.0;
/// 本轮流的终态：done/stop 保留已解析正文；incomplete/error 保留正文并标记中断原因。
typedef NS_ENUM(NSUInteger, TLWAIStreamTerminalState) {
    TLWAIStreamTerminalStateCompleted = 0,  // 收到业务 done
    TLWAIStreamTerminalStateCancelled,      // 用户点击停止
    TLWAIStreamTerminalStateIncomplete,     // HTTP 正常结束但没收到业务 done/error
    TLWAIStreamTerminalStateFailed          // 流内 error、网络错误或鉴权失败
};
#ifdef DEBUG
/// Debug 下可临时打开的 chat-profile 对比探针；Release 强制关闭，避免额外推理与耗时干扰。
static BOOL const kAIAssistantEnableInterfaceCompareDebug = NO;
#endif

@interface TLWAIAssistantController () <TLWImagePickerDelegate, UIGestureRecognizerDelegate>
@property (nonatomic, strong) TLWAIAssistantView *myView;
@property (nonatomic, copy)   NSString           *initialQuestion;
@property (nonatomic, assign) BOOL                didSendInitialQuestion;
// 草稿态图片先留在 controller，真正发送后再固化成 message 进入 session。
@property (nonatomic, strong) NSMutableArray<UIImage *> *pendingImages;
@property (nonatomic, strong) TLWAIAssistantSession *session;
@property (nonatomic, strong) TLWAIConversationTurn *activeTurn;
/// 无网络活动观察：同一时刻最多一个定时任务，终态作废旧任务。
@property (nonatomic, assign) NSUInteger slowStreamHintGeneration;
@property (nonatomic, assign) BOOL slowStreamHintScheduled;
@property (nonatomic, strong) TLWAIGestureCoordinator *gestureCoordinator;
@property (nonatomic, strong) TLWAITurnStore *turnStore;
@property (nonatomic, strong) TLWAITurnPersistence *persistence;
@property (nonatomic, strong) nw_path_monitor_t pathMonitor;
@property (nonatomic, assign) BOOL locationContextAuthorized;
@property (nonatomic, assign) BOOL continueRegeneration;
@property (nonatomic, assign) BOOL networkPathAvailable;
@property (nonatomic, copy) NSString *voiceBaseText;
@property (nonatomic, copy) NSString *voicePartial;
@property (nonatomic, assign) CGPoint voiceStart;
@property (nonatomic, strong) UITapGestureRecognizer *keyboardDismissTap;
@property (nonatomic, assign) BOOL voiceCancelled;
@end

@implementation TLWAIAssistantController

- (instancetype)initWithInitialQuestion:(NSString *)question {
    self = [super init];
    if (self) {
        _initialQuestion = question;
        _networkPathAvailable = YES;
        self.hidesBottomBarWhenPushed = YES;
    }
    return self;
}

- (NSString *)navTitle {
#if DEBUG
    if (TLWAIStreamTestEndpoint() != nil) return @"AI助手 · 本地测试";
#endif
    return @"AI助手";
}
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
    longPress.allowableMovement = 10000;
    self.myView.voiceSpeechImageView.exclusiveTouch = YES;
    [self.myView.voiceSpeechImageView addGestureRecognizer:longPress];

    [self.myView.plusButton addTarget:self action:@selector(tl_togglePlusPanel) forControlEvents:UIControlEventTouchUpInside];
    [self.myView.plusCameraButton addTarget:self action:@selector(tl_camera) forControlEvents:UIControlEventTouchUpInside];
    [self.myView.plusAlbumButton addTarget:self action:@selector(tl_gallery) forControlEvents:UIControlEventTouchUpInside];
    [self.myView.plusAICallButton addTarget:self action:@selector(tl_aiCall) forControlEvents:UIControlEventTouchUpInside];
    [self.myView.plusSessionButton addTarget:self action:@selector(tl_showSessions) forControlEvents:UIControlEventTouchUpInside];
    [self.myView.plusLocationButton addTarget:self action:@selector(tl_authorizeLocationContext) forControlEvents:UIControlEventTouchUpInside];
    [self.myView.sendButton addTarget:self
                               action:@selector(tl_send)
                     forControlEvents:UIControlEventTouchUpInside];
    [self.myView.stopButton addTarget:self
                               action:@selector(tl_stopAI)
                     forControlEvents:UIControlEventTouchUpInside];

    // 键盘通知
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(tl_keyboardFrameChanged:)
                                                 name:UIKeyboardWillChangeFrameNotification
                                               object:nil];

    // 点击页面收起键盘
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                          action:@selector(tl_dismissKeyboard)];
    self.keyboardDismissTap = tap;
    tap.cancelsTouchesInView = NO;
    tap.delegate = self;
    [tap requireGestureRecognizerToFail:longPress];
    [self.myView addGestureRecognizer:tap];

    // 删除预览图回调
    __weak typeof(self) weakSelf = self;
    self.myView.onRemoveImageAtIndex = ^(NSUInteger index) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf || index >= strongSelf.pendingImages.count) return;
        [strongSelf.pendingImages removeObjectAtIndex:index];
    };
    for (NSNotificationName name in @[UIApplicationDidBecomeActiveNotification, UIApplicationWillResignActiveNotification, UIApplicationDidEnterBackgroundNotification, NSProcessInfoPowerStateDidChangeNotification]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tl_pacerEnvironmentChanged:) name:name object:nil];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tl_applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    self.myView.onContinueMessage = ^(TLWAIAssistantMessage *message) {
        [weakSelf tl_continueFromMessage:message];
    };
    _pendingImages = [NSMutableArray array];
    [self tl_openStore];

    // 语音识别错误提示
    [TWLSpeechManager sharedManager].errorHandler = ^(NSString *errorMessage) {
        [TLWToast show:errorMessage];
    };

    [self tl_seedConversation];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (!self.gestureCoordinator) self.gestureCoordinator = [TLWAIGestureCoordinator new];
    [self.gestureCoordinator installForController:self];
    self.myView.gestureCoordinator = self.gestureCoordinator;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self tl_updateFramePacer];
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

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.gestureCoordinator uninstall];
    // 只有真正离页才取消；交互式返回被取消时不能截断生成。
    [self tl_stopAI];
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
        self.voiceStart = [gesture locationInView:gesture.view];
        self.voiceBaseText = self.myView.inputTextField.text ?: @"";
        self.voicePartial = @"";
        self.voiceCancelled = NO;
        [self.myView setVoiceCancelArmed:NO];
        __weak typeof(self) weakSelf = self;
        [TWLSpeechManager sharedManager].resultHandler = ^(NSString *text, BOOL isFinal) {
            if (!TLWAIShouldCommitSpeechPartial(NO, weakSelf.voiceCancelled)) return;
            weakSelf.voicePartial = text ?: @"";
            if (isFinal) {
                [weakSelf.myView setInputText:[weakSelf.voiceBaseText stringByAppendingString:weakSelf.voicePartial]];
                [weakSelf.myView hideVoicePanel];
            }
        };
        [[TWLSpeechManager sharedManager] startRecording];
        return;
    }
    BOOL cancelZone = self.voiceStart.y - [gesture locationInView:gesture.view].y > 48.0;
    if (gesture.state == UIGestureRecognizerStateChanged) {
        [self.myView setVoiceCancelArmed:cancelZone];
        return;
    }
    if (gesture.state != UIGestureRecognizerStateEnded && gesture.state != UIGestureRecognizerStateCancelled) return;
    BOOL cancelled = gesture.state == UIGestureRecognizerStateCancelled || cancelZone;
    self.voiceCancelled = cancelled;
    [self.myView setVoiceCancelArmed:NO];
    if (!TLWAIShouldCommitSpeechPartial(cancelZone, cancelled)) {
        [[TWLSpeechManager sharedManager] cancelRecording];
        [TWLSpeechManager sharedManager].resultHandler = nil;
        [self.myView setInputText:self.voiceBaseText];
        return;
    }
    [[TWLSpeechManager sharedManager] stopRecording];
    if (self.voicePartial.length) [self.myView setInputText:[self.voiceBaseText stringByAppendingString:self.voicePartial]];
    [self.myView hideVoicePanel];
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
    if (UIAccessibilityIsVoiceOverRunning()) return NO;
    for (UIView *view = touch.view; view && view != self.myView; view = view.superview) {
        if ([view isKindOfClass:UIControl.class]) return NO;
        if ([view isKindOfClass:UITextView.class]) {
            UITextView *textView = (UITextView *)view;
            if (textView.editable || textView.selectedRange.length > 0) return NO;
        }
    }
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gesture shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)other {
    // 只放行本页收键盘的 tap 与原生文本手势；不会让两个纵向 pan 同时消费。
    return gesture == self.keyboardDismissTap || other == self.keyboardDismissTap;
}

#pragma mark - Keyboard

- (void)tl_keyboardFrameChanged:(NSNotification *)notification {
    NSDictionary *info = notification.userInfo;
    CGRect frame = [self.view convertRect:[info[UIKeyboardFrameEndUserInfoKey] CGRectValue] fromView:nil];
    CGFloat overlap = TLWAIKeyboardOverlap(frame, self.view.bounds);
    NSTimeInterval duration = [info[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationOptions curve = [info[UIKeyboardAnimationCurveUserInfoKey] unsignedIntegerValue] << 16;
    if (overlap > 0) {
        [self.myView hideVoicePanel];
        [self.myView hidePlusPanel];
    }
    [self.myView adjustForKeyboardHeight:overlap duration:duration
        options:curve | UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState];
    [self.myView followMessagesToBottomIfNeededAnimated:NO];
}

- (void)dealloc {
    if (self.pathMonitor) {
        nw_path_monitor_cancel(self.pathMonitor);
        self.pathMonitor = nil;
    }
    [self.gestureCoordinator uninstall];
    [self.activeTurn finishWithState:TLWAIConversationTurnStateCancelled];
    [[TWLSpeechManager sharedManager] stopRecording];
    [TWLSpeechManager sharedManager].resultHandler = nil;
    [TWLSpeechManager sharedManager].errorHandler = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)tl_stopAI {
    TLWAIAssistantMessage *aiMessage = self.activeTurn.assistantMessage;
    if (!aiMessage) return;
    if ([self.activeTurn.streamClient isKindOfClass:TLWAIJobStreamClient.class] &&
        ![(TLWAIJobStreamClient *)self.activeTurn.streamClient cancelJob])
        [aiMessage appendSupplementalText:@"已本地停止，但停止状态保存失败"];
    [self tl_finishCurrentAIMessage:aiMessage state:TLWAIStreamTerminalStateCancelled reasonText:nil];
}

/// 所有流式终态的唯一出口：完整排空已解析正文 → 定状态 → 退出 loading → 刷新 → 清引用。
/// @discussion 只排空 pendingDelta（UI 层已完整解析的缓冲）；未闭合 SSE 残帧由 parser 丢弃，不会被当正文。
- (void)tl_finishCurrentAIMessage:(TLWAIAssistantMessage *)aiMessage
                            state:(TLWAIStreamTerminalState)state
                       reasonText:(NSString *)reasonText {
    if (!aiMessage) return;
    if (![self.activeTurn.assistantMessage.identifier isEqualToString:aiMessage.identifier] || self.activeTurn.isTerminal) return;

    // 1. 终态统一完整 drain：停止 timer 后一次性并入正文，不再按字形簇限速。
    [self tl_cancelSlowStreamHint];
    [self tl_stopFramePacer];
    [self tl_flushPendingDeltasDraining:YES];

    // 2. 按终态定状态与文案。已完成/已取消保留正文；中断态在正文后追加原因。
    BOOL hasContent = self.activeTurn.planAccumulated.length > 0 || aiMessage.auxiliaryText.length > 0;
    aiMessage.hasAssistantOutput = hasContent;
    NSString *body = self.activeTurn.planAccumulated;
    NSString *reason = [reasonText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    switch (state) {
        case TLWAIStreamTerminalStateCompleted:
            aiMessage.status = TLWAIAssistantMessageStatusIdle;
            aiMessage.text = hasContent ? self.activeTurn.textPresentation.visibleText : @"AI 暂时无法给出回复，请换个描述再试试。";
            break;

        case TLWAIStreamTerminalStateCancelled:
            aiMessage.status = TLWAIAssistantMessageStatusIdle;
            aiMessage.text = hasContent ? self.activeTurn.textPresentation.visibleText : @"已停止回复";
            break;

        case TLWAIStreamTerminalStateIncomplete:
            aiMessage.status = TLWAIAssistantMessageStatusFailed;
            aiMessage.errorMessage = reason.length > 0 ? reason : @"连接中断，未收到完整回复";
            aiMessage.text = hasContent
                ? [NSString stringWithFormat:@"%@%@（%@）", body, body.length ? @"\n\n" : @"", aiMessage.errorMessage]
                : @"连接中断，请稍后重试";
            break;

        case TLWAIStreamTerminalStateFailed:
            aiMessage.status = TLWAIAssistantMessageStatusFailed;
            aiMessage.errorMessage = reason.length > 0 ? reason : @"请求失败";
            aiMessage.text = hasContent
                ? [NSString stringWithFormat:@"%@%@（请求失败：%@）", body, body.length ? @"\n\n" : @"", aiMessage.errorMessage]
                : [NSString stringWithFormat:@"请求失败：%@", aiMessage.errorMessage];
            break;
    }

    if (state == TLWAIStreamTerminalStateIncomplete) {
        aiMessage.canContinue = YES;
        NSString *checkpointStatus = aiMessage.recoveryCheckpoint[@"status"];
        aiMessage.canResumeJob = self.activeTurn.streamClient.supportsJobRecovery &&
            ([checkpointStatus isEqual:@"running"] || [checkpointStatus isEqual:@"creating"]);
    }
    if (state == TLWAIStreamTerminalStateCompleted || state == TLWAIStreamTerminalStateCancelled) {
        aiMessage.canContinue = NO;
        aiMessage.canResumeJob = NO;
    }
    if (TLWAITextNeedsLabelDisclaimer(aiMessage.text)) [aiMessage appendSupplementalText:TLWAILabelDisclaimer()];
    aiMessage.moderationNote = TLWAIModerationPlaceholder();
    TLWAIConversationTurnState terminalStates[] = {TLWAIConversationTurnStateCompleted, TLWAIConversationTurnStateCancelled, TLWAIConversationTurnStateIncomplete, TLWAIConversationTurnStateFailed};
    [self.activeTurn finishWithState:terminalStates[state]];
    self.activeTurn = nil;
    [self.persistence upsertSession:self.session];
    [self.myView exitAILoadingMode];
    [self.myView reloadMessage:aiMessage];
}


/// 只刷新当前生成中的一行；外层消息列表仅在用户仍贴底时跟随。
- (void)tl_refreshCurrentAIMessageRow {
    TLWAIAssistantMessage *aiMessage = self.activeTurn.assistantMessage;
    if (!aiMessage) return;
    [self.myView reloadMessage:aiMessage];
}

- (void)tl_aiCall {
    [self tl_stopAI];
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
    // 先确认中文输入法的候选词，还没进入搜索框的
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
    NSString *text = self.myView.inputTextField.text ?: @"";
    if ([text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet].length == 0 && self.pendingImages.count == 0) return;

    // UI 生成中只提供停止；程序化发送采取抢占而非 FIFO，旧正文先完整收尾。
    if (self.activeTurn) [self tl_stopAI];

    // 1. 把草稿态固化成一条本地用户消息
    NSArray<UIImage *> *imagesToSend = self.pendingImages.copy;
    TLWAIAssistantMessage *userMessage = [TLWAIAssistantMessage messageWithRole:TLWAIAssistantMessageRoleUser
                                                                           text:text
                                                                    localImages:imagesToSend
                                                                remoteImageURLs:nil];
    // 记录第一张图片的原始尺寸，供 cell 按比例渲染
    if (imagesToSend.count > 0) {
        userMessage.imageDisplaySize = imagesToSend.firstObject.size;
        if (TLWAIStreamTestEndpoint() == nil) {
            NSString *relative = [TLWAIImageArchive writeImage:imagesToSend.firstObject userIdentifier:self.turnStore.userIdentifier root:nil messageIdentifier:userMessage.identifier index:0];
            if (relative.length) userMessage.imageRelativePaths = @[relative];
        }
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
    BOOL regenerated = self.continueRegeneration;
    NSString *placeholder = regenerated ? @"已重新生成" : @"正在思考中...";
    self.continueRegeneration = NO;
    TLWAIAssistantMessage *aiMessage = [TLWAIAssistantMessage messageWithRole:TLWAIAssistantMessageRoleAssistant text:placeholder];
    if (regenerated) [aiMessage appendSupplementalText:@"已重新生成"];
#if DEBUG
    if (TLWAIStreamTestEndpoint() != nil) [self tl_attachLocalGestureSurfacesToMessage:aiMessage];
#endif
    aiMessage.status = TLWAIAssistantMessageStatusSending;
    [self.session appendMessage:aiMessage];
    self.activeTurn = [[TLWAIConversationTurn alloc] initWithUserMessage:userMessage assistantMessage:aiMessage];
    if (imagesToSend.count > 0) [self tl_startLocalHypothesisForImage:imagesToSend.firstObject message:aiMessage];

    [self.myView enterAILoadingMode];
    [self.session trimImageMemoryIfNeeded];
    [self.persistence upsertSession:self.session];
    [self.myView displayMessages:self.session.messages];
    [self.myView scrollMessagesToBottomAnimated:YES];
    [self tl_scheduleSlowStreamHintForMessage:aiMessage];
    [self.myView setInputText:@""];
    [self.pendingImages removeAllObjects];
    [self.myView hideSelectedImage];

    AGChatRequest *request = [[AGChatRequest alloc] init];
    request.text = text;
    request.saveHistory = @(NO);
    request.useSingleModel = @(YES);
    NSString *location = (TLWAIStreamTestEndpoint() == nil && self.locationContextAuthorized && !TLWLocationManager.shared.locationDenied) ? TLWLocationManager.shared.displayLocationName : nil;
    NSString *extra = TLWAIComposeExtraInfo([self.session recentContextWithMaxCharacters:2400 excludingUserIdentifier:userMessage.identifier], location);
    request.extraInfo = extra.length ? extra : nil;

    self.activeTurn.request = request;
    NSString *turnIdentifier = self.activeTurn.identifier;
    __weak typeof(self) weakSelf = self;
    [self tl_prepareStreamRequest:request];
    void (^startStream)(NSString *) = ^(NSString *imageURL) {
        __strong typeof(weakSelf) owner = weakSelf;
        if (![owner.activeTurn.identifier isEqualToString:turnIdentifier]) return;
        if (imageURL.length) request.imageUrl = imageURL;
#ifdef DEBUG
        if (kAIAssistantEnableInterfaceCompareDebug && TLWAIStreamTestEndpoint() == nil) [owner tl_startProfileComparisonDebugWithRequest:request tag:turnIdentifier];
#endif
        dispatch_block_t restart = owner.activeTurn.authRestart;
        if (restart) restart();
    };
    if (imagesToSend.count > 0 && TLWAIStreamTestEndpoint() == nil) {
        [self.activeTurn beginUpload];
        self.activeTurn.uploadTask = [[TLWSDKManager shared] uploadImages:@[imagesToSend.firstObject] prefix:@"ai_assistant/"
            completion:^(NSArray<NSString *> *urls, NSError *error) {
                __strong typeof(weakSelf) owner = weakSelf;
                if (![owner.activeTurn.identifier isEqualToString:turnIdentifier] || owner.activeTurn.state != TLWAIConversationTurnStateUploading) return;
                owner.activeTurn.uploadTask = nil;
                if (error || urls.count == 0) {
                    [owner tl_finishCurrentAIMessage:aiMessage state:TLWAIStreamTerminalStateFailed reasonText:@"图片上传失败，请稍后重试"];
                    return;
                }
                startStream(urls.firstObject);
            }];
    } else {
        startStream(nil);
    }
}

- (void)tl_prepareStreamRequest:(AGChatRequest *)request {
    NSString *turnIdentifier = self.activeTurn.identifier;
    __weak typeof(self) weakSelf = self;
    TLWAIAssistantMessage *aiMessage = self.activeTurn.assistantMessage;
    self.activeTurn.authRestart = ^{
        __strong typeof(weakSelf) owner = weakSelf;
        if (!owner || ![owner.activeTurn.identifier isEqualToString:turnIdentifier] || ![owner.activeTurn beginConnection]) return;
        NSUInteger generation = owner.activeTurn.generation;
        NSString *token = AGDefaultConfiguration.sharedConfig.accessToken;
        if (token.length == 0 && TLWAIStreamTestEndpoint() == nil) {
            [owner tl_finishCurrentAIMessage:aiMessage state:TLWAIStreamTerminalStateFailed reasonText:@"登录已失效，请重新登录"];
            return;
        }
        TLWAIStreamClient *client = [owner tl_makeStreamClient];
        client.clientRequestId = owner.activeTurn.clientRequestId;
        client.trace = owner.activeTurn.trace;
        BOOL jobProtocol = client.supportsJobRecovery;
        if ([client isKindOfClass:TLWAIJobStreamClient.class]) {
            TLWAIJobStreamClient *job = (id)client;
            job.onRestoreCheckpoint = ^(NSDictionary *record) {
                __strong typeof(weakSelf) s = weakSelf;
                if (![s tl_acceptTurnIdentifier:turnIdentifier generation:generation]) return;
                [s tl_restoreCheckpoint:record message:aiMessage active:YES];
            };
            job.onRecoveryStateChanged = ^(BOOL recovering) {
                __strong typeof(weakSelf) s = weakSelf;
                if (![s tl_acceptTurnIdentifier:turnIdentifier generation:generation]) return;
                [s.activeTurn setRecovering:recovering generation:generation];
                aiMessage.status = recovering ? TLWAIAssistantMessageStatusRecovering : TLWAIAssistantMessageStatusSending;
                [s tl_refreshCurrentAIMessageRow];
            };
            job.onServerCancelled = ^{
                __strong typeof(weakSelf) s = weakSelf;
                if (![s tl_acceptTurnIdentifier:turnIdentifier generation:generation]) return;
                [s tl_finishCurrentAIMessage:aiMessage state:TLWAIStreamTerminalStateCancelled reasonText:nil];
            };
        }
        client.onActivity = ^{
            __strong typeof(weakSelf) s = weakSelf;
            if (![s tl_acceptTurnIdentifier:turnIdentifier generation:generation]) return;
            [s tl_noteStreamActivityForMessage:aiMessage];
        };
        client.onMetadata = ^(NSString *eventID, NSNumber *retry) {
            __strong typeof(weakSelf) s = weakSelf;
            if (![s tl_acceptTurnIdentifier:turnIdentifier generation:generation]) return;
            s.activeTurn.lastEventID = eventID;
            s.activeTurn.retryMilliseconds = retry;
        };
        client.onHeartbeat = ^(NSString *comment) {
            __strong typeof(weakSelf) s = weakSelf;
            if (![s tl_acceptTurnIdentifier:turnIdentifier generation:generation]) return;
            [s tl_noteStreamActivityForMessage:aiMessage];
        };
        client.onMeta = ^(NSDictionary *meta) {
            __strong typeof(weakSelf) s = weakSelf;
            if (![s tl_acceptTurnIdentifier:turnIdentifier generation:generation]) return;
            [s.activeTurn recordFrameForGeneration:generation];
            if ([meta[@"requestId"] isKindOfClass:NSString.class]) s.activeTurn.serverRequestId = meta[@"requestId"];
        };
        client.onDiseaseList = ^(NSArray *diseases) {
            __strong typeof(weakSelf) s = weakSelf;
            if (![s tl_acceptTurnIdentifier:turnIdentifier generation:generation]) return;
            [s.activeTurn recordFrameForGeneration:generation];
            [s tl_applyDiseaseList:diseases toMessage:aiMessage];
            [s tl_refreshAIMessageText];
            [s tl_refreshCurrentAIMessageRow];
        };
        client.onPlanDelta = ^(NSString *delta) {
            __strong typeof(weakSelf) s = weakSelf;
            if (![s tl_acceptTurnIdentifier:turnIdentifier generation:generation]) return;
            [s tl_noteStreamActivityForMessage:aiMessage];
            [s.activeTurn appendDelta:delta generation:generation];
            [s tl_updateFramePacer];
        };
        client.onPlanFinal = ^(NSString *text) {
            __strong typeof(weakSelf) s = weakSelf;
            if (![s tl_acceptTurnIdentifier:turnIdentifier generation:generation]) return;
            [s tl_noteStreamActivityForMessage:aiMessage];
            [s.activeTurn replacePlan:text generation:generation];
            [s tl_refreshAIMessageText];
            [s tl_refreshCurrentAIMessageRow];
        };
        client.onUnknownEvent = ^(TLWAIEventEnvelope *envelope) {
            __strong typeof(weakSelf) s = weakSelf;
            if (![s tl_acceptTurnIdentifier:turnIdentifier generation:generation]) return;
            [s.activeTurn recordFrameForGeneration:generation];
            [aiMessage.eventEnvelopes addObject:envelope];
            [aiMessage appendSupplementalText:envelope.fallbackText];
            [s tl_refreshAIMessageText];
            [s tl_refreshCurrentAIMessageRow];
        };
        client.onDone = ^(NSDictionary *info) {
            __strong typeof(weakSelf) s = weakSelf;
            if (![s tl_acceptTurnIdentifier:turnIdentifier generation:generation]) return;
            [s.activeTurn recordFrameForGeneration:generation];
            aiMessage.completionInfo = info;
            if ([info[@"info"] isKindOfClass:NSString.class]) [aiMessage appendSupplementalText:info[@"info"]];
            if ([info[@"suggestions"] isKindOfClass:NSArray.class]) {
                for (id suggestion in info[@"suggestions"])
                    if ([suggestion isKindOfClass:NSString.class]) [aiMessage appendSupplementalText:suggestion];
            }
            [s tl_finishCurrentAIMessage:aiMessage state:TLWAIStreamTerminalStateCompleted reasonText:nil];
        };
        client.onError = ^(NSError *error, NSString *message) {
            __strong typeof(weakSelf) s = weakSelf;
            if (![s tl_acceptTurnIdentifier:turnIdentifier generation:generation]) return;
            BOOL recoverable = [error.domain isEqualToString:NSURLErrorDomain] &&
                (error.code == NSURLErrorNetworkConnectionLost || error.code == NSURLErrorNotConnectedToInternet ||
                 error.code == NSURLErrorTimedOut);
            aiMessage.canResumeJob = jobProtocol && [error.userInfo[@"canResumeJob"] boolValue];
            aiMessage.canContinue = jobProtocol ? (aiMessage.canResumeJob || [error.userInfo[@"offersRegeneration"] boolValue]) : TLWAIOffersContinue(recoverable, NO);
            [s tl_finishCurrentAIMessage:aiMessage state:TLWAIStreamTerminalStateFailed
                reasonText:message.length ? message : (error.localizedDescription ?: @"请求失败")];
        };
        client.onIncompleteEOF = ^(NSUInteger bytes) {
            __strong typeof(weakSelf) s = weakSelf;
            if (![s tl_acceptTurnIdentifier:turnIdentifier generation:generation]) return;
            aiMessage.canContinue = TLWAIOffersContinue(NO, YES);
            [s tl_finishCurrentAIMessage:aiMessage state:TLWAIStreamTerminalStateIncomplete reasonText:@"连接中断，未收到完整回复"];
        };
        client.onAuthFailure = ^{
            __strong typeof(weakSelf) s = weakSelf;
            if (![s tl_acceptTurnIdentifier:turnIdentifier generation:generation]) return;
            if (TLWAIStreamTestEndpoint() != nil) {
                [s tl_finishCurrentAIMessage:aiMessage state:TLWAIStreamTerminalStateFailed reasonText:@"本地测试服务不应要求登录；不会刷新正式账号"];
                return;
            }
            if (![s.activeTurn prepareAuthRefresh]) {
                [[TLWSDKManager shared].sessionManager invalidateSessionWithMessage:@"登录状态恢复失败，请重新登录"];
                [s tl_finishCurrentAIMessage:aiMessage state:TLWAIStreamTerminalStateFailed reasonText:@"登录已失效，请重新登录"];
                return;
            }
            if (jobProtocol) aiMessage.status = TLWAIAssistantMessageStatusRecovering;
            else aiMessage.text = @"正在重新建立回复...";
            [s tl_refreshCurrentAIMessageRow];
            [s tl_refreshAuthWithRetry:^{
                __strong typeof(weakSelf) refreshed = weakSelf;
                if (![refreshed.activeTurn.identifier isEqualToString:turnIdentifier] || refreshed.activeTurn.state != TLWAIConversationTurnStateAuthRefresh) return;
                dispatch_block_t restart = refreshed.activeTurn.authRestart;
                if (restart) restart();
            } failure:^{
                __strong typeof(weakSelf) refreshed = weakSelf;
                if (![refreshed.activeTurn.identifier isEqualToString:turnIdentifier]) return;
                [refreshed tl_finishCurrentAIMessage:aiMessage state:TLWAIStreamTerminalStateFailed reasonText:@"登录已失效，请重新登录"];
            }];
        };
        owner.activeTurn.streamClient = client;
        [owner tl_startFramePacer];
        [client streamChatWithRequest:request accessToken:token];
    };
}

- (TLWAIStreamClient *)tl_makeStreamClient {
    TLWAIAssistantMessage *message = self.activeTurn.assistantMessage;
    if (!TLWAIJobProtocolEnabled() && !message.recoveryCheckpoint) return [[TLWAIStreamClient alloc] init];
    NSString *test = TLWAIStreamTestEndpoint();
    NSURL *url = test != nil ? TLWAIValidatedStreamTestURL(test) :
        [[NSURL URLWithString:AGDefaultConfiguration.sharedConfig.host] URLByAppendingPathComponent:@"api/v1/agent/jobs"];
    NSInteger ownerID = self.turnStore.userIdentifier;
    TLWAIAssistantSession *session = self.session;
    NSDictionary *record = [message.recoveryCheckpoint isKindOfClass:NSDictionary.class] ? message.recoveryCheckpoint : nil;
    if (message.recoveryCheckpoint && !record) record = @{};
    if (record && (![record[@"ownerId"] isKindOfClass:NSNumber.class] || [record[@"ownerId"] integerValue] != ownerID ||
        ![record[@"sessionId"] isEqual:session.identifier] || ![record[@"messageId"] isEqual:message.identifier])) record = @{};
    if (!record) record = @{@"version":@1, @"clientRequestId":self.activeTurn.clientRequestId, @"jobId":@"",
        @"seq":@0, @"cursor":@"", @"status":@"creating", @"text":@"", @"diseases":@[], @"meta":@{},
        @"completionInfo":@{}, @"fallbackTexts":@[], @"errorMessage":@"", @"request":@{}, @"ownerId":@(ownerID),
        @"sessionId":session.identifier, @"messageId":message.identifier, @"userMessageId":self.activeTurn.userMessage.identifier};
    NSString *identifier = self.activeTurn.identifier;
    NSUInteger generation = self.activeTurn.generation;
    __weak typeof(self) weakSelf = self;
    TLWAIJobStreamClient *client = [[TLWAIJobStreamClient alloc] initWithJobsURL:url localTest:test != nil checkpoint:record
        commit:^BOOL(NSDictionary *checkpoint) {
            __strong typeof(weakSelf) owner = weakSelf;
            if (![owner tl_acceptTurnIdentifier:identifier generation:generation] || owner.session != session ||
                owner.turnStore.userIdentifier != ownerID || ![checkpoint[@"ownerId"] isEqual:@(ownerID)]) return NO;
            if (owner.persistence) return [owner.persistence saveRecoveryCheckpoint:checkpoint forMessage:message session:session];
            message.recoveryCheckpoint = checkpoint;
            return YES;
        }];
    client.networkAvailable = self.networkPathAvailable;
    return client;
}

- (BOOL)tl_acceptTurnIdentifier:(NSString *)identifier generation:(NSUInteger)generation {
    return [self.activeTurn acceptsIdentifier:identifier generation:generation];
}
- (void)tl_refreshAuthWithRetry:(dispatch_block_t)retry failure:(dispatch_block_t)failure {
    [[TLWSDKManager shared].sessionManager handleUnauthorizedWithRetry:retry failure:failure];
}

- (BOOL)tl_restoreCheckpoint:(NSDictionary *)record message:(TLWAIAssistantMessage *)message active:(BOOL)active {
    if (![[TLWAIRecoveryState alloc] initWithCheckpoint:record] ||
        ![record[@"ownerId"] isEqual:@(self.turnStore.userIdentifier)] ||
        ![record[@"messageId"] isEqual:message.identifier] || ![record[@"sessionId"] isEqual:self.session.identifier]) return NO;
    [message resetAssistantMetadata];
    [self tl_applyDiseaseList:record[@"diseases"] toMessage:message];
    for (NSString *fallback in record[@"fallbackTexts"]) [message appendSupplementalText:fallback];
    message.completionInfo = record[@"completionInfo"];
    NSString *status = record[@"status"];
    if (active) {
        [self.activeTurn restoreReceivedPlan:record[@"text"] generation:self.activeTurn.generation];
        [self tl_refreshAIMessageText];
        [self tl_refreshCurrentAIMessageRow];
    } else {
        message.text = record[@"text"];
        message.hasAssistantOutput = message.text.length || message.auxiliaryText.length;
        message.completed = [status isEqual:@"completed"];
        message.canResumeJob = [status isEqual:@"running"] || [status isEqual:@"creating"];
        message.canContinue = message.canResumeJob || TLWAIJobFlag(record, @"offersRegeneration");
        message.status = message.completed || [status isEqual:@"cancelled"] ? TLWAIAssistantMessageStatusIdle : TLWAIAssistantMessageStatusFailed;
        message.errorMessage = message.canResumeJob ? @"上次连接未完成，可继续接收原任务" : record[@"errorMessage"];
        if (message.completed) {
            id info = message.completionInfo[@"info"];
            if ([info isKindOfClass:NSString.class]) [message appendSupplementalText:info];
            id suggestions = message.completionInfo[@"suggestions"];
            if ([suggestions isKindOfClass:NSArray.class])
                for (id suggestion in suggestions)
                    if ([suggestion isKindOfClass:NSString.class]) [message appendSupplementalText:suggestion];
        }
        if (!message.text.length && [status isEqual:@"cancelled"]) message.text = @"已停止回复";
        if (TLWAITextNeedsLabelDisclaimer(message.text)) [message appendSupplementalText:TLWAILabelDisclaimer()];
        message.moderationNote = TLWAIModerationPlaceholder();
    }
    return YES;
}

/// 统一处理 AI 对话响应
#pragma mark - 流式 UI 合并

#ifdef DEBUG
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

    [[[TLWSDKManager shared] api] chatProfileWithChatRequest:probeRequest completionHandler:^(AGResultChatProfileResponse *output, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            (void)tag; (void)output; (void)error;
            // [AI-PROFILE] 调试打印已下线，按需在断点中查看 output。
        });
    }];
}
#endif

/// 退化卡只接受实际字符串名称与有效置信度，不推测新的服务端 block 字段。
- (void)tl_applyDiseaseList:(NSArray *)list toMessage:(TLWAIAssistantMessage *)message {
    NSMutableArray<NSString *> *parts = [NSMutableArray array], *names = [NSMutableArray array];
    for (id item in list) {
        if (![item isKindOfClass:NSDictionary.class]) continue;
        id value = item[@"diseaseName"] ?: item[@"name"] ?: item[@"title"];
        if (![value isKindOfClass:NSString.class]) continue;
        NSString *name = [value stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        if (!name.length) continue;
        NSString *confidence = [self tl_confidenceTextFromValue:item[@"confidence"]];
        [parts addObject:confidence.length ? [NSString stringWithFormat:@"%@ (%@)", name, confidence] : name];
        [names addObject:name];
    }
    message.diseaseSummary = [parts componentsJoinedByString:@"、"];
    message.diseaseNames = names;
}

- (void)tl_noteStreamActivityForMessage:(TLWAIAssistantMessage *)message {
    self.activeTurn.lastByteAt = NSProcessInfo.processInfo.systemUptime;
    if (message.status == TLWAIAssistantMessageStatusWaiting) {
        message.status = TLWAIAssistantMessageStatusSending;
        if ([message.text isEqualToString:@"仍在生成，网络可能较慢"]) message.text = @"正在思考中...";
        [self tl_refreshCurrentAIMessageRow];
    }
    [self tl_scheduleSlowStreamHintForMessage:message];
}

- (void)tl_scheduleSlowStreamHintForMessage:(TLWAIAssistantMessage *)aiMessage {
    if (self.slowStreamHintScheduled || ![self.activeTurn.assistantMessage.identifier isEqualToString:aiMessage.identifier]) return;
    NSTimeInterval now = NSProcessInfo.processInfo.systemUptime;
    if (self.activeTurn.lastByteAt <= 0) self.activeTurn.lastByteAt = now;
    NSTimeInterval delay = MAX(0, kAIAssistantSlowStreamHintDelay - (now - self.activeTurn.lastByteAt));
    self.slowStreamHintScheduled = YES;
    NSUInteger generation = self.slowStreamHintGeneration;
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) owner = weakSelf;
        if (!owner || generation != owner.slowStreamHintGeneration) return;
        owner.slowStreamHintScheduled = NO;
        if (![owner.activeTurn.assistantMessage.identifier isEqualToString:aiMessage.identifier]) return;
        if (NSProcessInfo.processInfo.systemUptime - owner.activeTurn.lastByteAt < kAIAssistantSlowStreamHintDelay) {
            [owner tl_scheduleSlowStreamHintForMessage:aiMessage];
            return;
        }
        aiMessage.status = TLWAIAssistantMessageStatusWaiting;
        if (owner.activeTurn.state == TLWAIConversationTurnStateRecovering)
            aiMessage.status = TLWAIAssistantMessageStatusRecovering;
        if (owner.activeTurn.planAccumulated.length == 0 && owner.activeTurn.pendingDelta.length == 0 &&
            aiMessage.auxiliaryText.length == 0) aiMessage.text = @"仍在生成，网络可能较慢";
        // 已输出的正文保持原样；等待提示只改变状态，不重发请求。
        [owner tl_refreshCurrentAIMessageRow];
    });
}

- (void)tl_cancelSlowStreamHint {
    self.slowStreamHintGeneration += 1;
    self.slowStreamHintScheduled = NO;
}


/// 展示门控只提供累计可见正文；分块和富文本由 BodyView 独立维护。
- (void)tl_refreshAIMessageText {
    TLWAIAssistantMessage *message = self.activeTurn.assistantMessage;
    if (!message) return;
    NSString *visiblePlan = self.activeTurn.textPresentation.visibleText;
    message.hasAssistantOutput = visiblePlan.length > 0 || message.auxiliaryText.length > 0;
    message.text = visiblePlan.length ? visiblePlan : @"正在生成方案...";
}

/// 帧驱动消费；终态将已解析 pending 完整并入正文，不包含 SSE 残帧。
- (void)tl_flushPendingDeltasIfNeeded {
    [self tl_flushPendingDeltasDraining:NO];
    [self tl_updateFramePacer];
}

/// @param draining YES 表示终态收尾：一次性把 pendingDelta 全部并入正文，不按字形簇限速。
///                 只排空“已经解析完成的 UI 缓冲”，不会把未闭合 SSE 残帧当正文（残帧在 parser 层丢弃）。
- (void)tl_flushPendingDeltasDraining:(BOOL)draining {
    if (!self.activeTurn) return;
    NSString *previousVisible = self.activeTurn.textPresentation.visibleText;
    __block NSUInteger backlog = 0;
    if (!draining) {
        [self.activeTurn.pendingDelta enumerateSubstringsInRange:NSMakeRange(0, self.activeTurn.pendingDelta.length)
            options:NSStringEnumerationByComposedCharacterSequences usingBlock:^(NSString *substring, NSRange range, NSRange enclosing, BOOL *stop) { backlog++; }];
    }
    [self.activeTurn consumePendingWithBudget:draining ? NSUIntegerMax : TLWAIFrameBudget(backlog)];
    if (draining) [self.activeTurn.textPresentation finish];
    else [self.activeTurn.textPresentation releaseExpiredAtTime:NSProcessInfo.processInfo.systemUptime];
    if ([previousVisible isEqualToString:self.activeTurn.textPresentation.visibleText]) return;
    [self tl_refreshAIMessageText];
    [self tl_refreshCurrentAIMessageRow];
}

- (void)tl_startFramePacer {
    if (self.activeTurn.framePacer) return;
    __weak typeof(self) weakSelf = self;
    self.activeTurn.framePacer = [[TLWAIFramePacer alloc] initWithTick:^{ [weakSelf tl_flushPendingDeltasIfNeeded]; }];
    [self tl_updateFramePacer];
}

- (void)tl_updateFramePacer {
    self.activeTurn.framePacer.paused = !self.view.window || UIApplication.sharedApplication.applicationState != UIApplicationStateActive ||
        NSProcessInfo.processInfo.lowPowerModeEnabled ||
        (self.activeTurn.pendingDelta.length == 0 && !self.activeTurn.textPresentation.hasHeldTail);
}
- (void)tl_pacerEnvironmentChanged:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{ [self tl_updateFramePacer]; });
}
- (void)tl_stopFramePacer {
    [self.activeTurn.framePacer invalidate];
    self.activeTurn.framePacer = nil;
}

#pragma mark - Helpers

- (NSString *)tl_confidenceTextFromValue:(id)value {
    double number = 0;
    BOOL explicitPercent = NO;
    if ([value isKindOfClass:NSNumber.class]) number = [value doubleValue];
    else if ([value isKindOfClass:NSString.class]) {
        NSString *text = [value stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        explicitPercent = [text hasSuffix:@"%"] || [text hasSuffix:@"％"];
        if (explicitPercent) text = [text substringToIndex:text.length - 1];
        NSScanner *scanner = [NSScanner scannerWithString:text];
        scanner.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        if (![scanner scanDouble:&number] || !scanner.isAtEnd) return @"";
    } else return @"";
    if (!isfinite(number) || number < 0 || number > 100) return @"";
    if (!explicitPercent && number <= 1) number *= 100;
    return fabs(number - round(number)) < 0.01 ? [NSString stringWithFormat:@"%.0f%%", number] : [NSString stringWithFormat:@"%.1f%%", number];
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
    if (self.session.hasMessages) {
        [self.myView displayMessages:self.session.messages];
        return;
    }
#if DEBUG
    if (TLWAIStreamTestEndpoint() != nil) {
        for (NSUInteger index = 1; index <= 6; index++) {
            [self.session appendMessage:[TLWAIAssistantMessage messageWithRole:TLWAIAssistantMessageRoleUser
                text:[NSString stringWithFormat:@"本地测试历史 %lu：用于外层列表滚动，不是真实问诊。", (unsigned long)index]]];
            TLWAIAssistantMessage *history = [TLWAIAssistantMessage messageWithRole:TLWAIAssistantMessageRoleAssistant
                text:index == 6 ? @"# 已完成富文本样本\n\n这张是**完成后**的卡片。新回复在生成时也会增量渲染，不必等结束。\n\n- 普通正文自然展开\n- 上方灰色识别卡保留有界内滚\n- 图片、长代码和宽表格支持横滑\n\n```json\n{\"gesture\":\"horizontal-images\",\"very_long_value\":\"abcdefghijklmnopqrstuvwxyz_abcdefghijklmnopqrstuvwxyz_abcdefghijklmnopqrstuvwxyz\"}\n```\n\n|区域|方向|职责|边界|\n|---|---|---|---|\n|正文|纵向|外层列表|保留阅读位置|\n|识别卡|纵向|卡内优先|剩余位移交接|\n\n[测试链接](https://example.org/sse-test)" : [NSString stringWithFormat:@"**历史阅读锚点 %lu**\n从普通正文拖动列表，再从灰色识别卡内部拖动，对比滚动职责。", (unsigned long)index]];
            history.hasAssistantOutput = YES;
            history.completed = YES;
            [self tl_attachLocalGestureSurfacesToMessage:history];
            [self.session appendMessage:history];
        }
        [self.myView displayMessages:self.session.messages];
        [self.myView scrollMessagesToBottomAnimated:NO];
        return;
    }
#endif
    TLWAIAssistantMessage *welcomeMessage = [TLWAIAssistantMessage messageWithRole:TLWAIAssistantMessageRoleAssistant
                                                                              text:@"你好，我可以帮你整理病虫害现象。你可以直接输入描述，或先选择图片再发送。"];
    [self.session appendMessage:welcomeMessage];
    [self.myView displayMessages:self.session.messages];
    [self.myView scrollMessagesToBottomAnimated:NO];
}
#if DEBUG
- (NSArray<UIImage *> *)tl_localGestureImages {
    static NSArray<UIImage *> *cachedImages;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        NSMutableArray<UIImage *> *images = [NSMutableArray array];
        for (NSUInteger index = 1; index <= 4; index++) {
            UIGraphicsBeginImageContextWithOptions(CGSizeMake(180, 120), YES, 1);
            [[UIColor colorWithHue:index / 7.0 saturation:0.35 brightness:0.95 alpha:1] setFill];
            UIRectFill(CGRectMake(0, 0, 180, 120));
            [[NSString stringWithFormat:@"横滑 %lu", (unsigned long)index] drawAtPoint:CGPointMake(46, 46)
                withAttributes:@{NSFontAttributeName:[UIFont boldSystemFontOfSize:22], NSForegroundColorAttributeName:UIColor.blackColor}];
            UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            if (image) [images addObject:image];
        }
        cachedImages = images.copy;
    });
    return cachedImages;
}
- (void)tl_attachLocalGestureSurfacesToMessage:(TLWAIAssistantMessage *)message {
    message.localImages = [self tl_localGestureImages];
    message.imageDisplaySize = CGSizeMake(180, 120);
    message.diseaseSummary = @"识别卡第 01 行：在这张灰色卡片内部上下拖。\n识别卡第 02 行：到边界后才接力外层列表。\n识别卡第 03 行：反向拖动优先回到卡内。\n识别卡第 04 行：这不是诊断结果。\n识别卡第 05 行：图片条请左右滑。\n识别卡第 06 行：普通正文自然展开，由外层列表滚动。";
}
#endif
- (void)tl_openStore {
#if DEBUG
    if (TLWAIStreamTestEndpoint() != nil) {
        self.turnStore = [[TLWAITurnStore alloc] initWithUserIdentifier:0];
        self.session = self.turnStore.currentSession;
        [self tl_startPathMonitor];
        return; // 本地测试只使用内存；不打开正式数据库或切换正式图片归档。
    }
#endif
    NSInteger userId = [TLWSDKManager shared].sessionManager.userId;
    [TLWAIImageArchive activateUserIdentifier:userId root:nil];
    self.turnStore = [[TLWAITurnStore alloc] initWithUserIdentifier:userId];
    self.persistence = [[TLWAITurnPersistence alloc] initWithUserIdentifier:userId directory:nil];
    NSArray<TLWAIAssistantSession *> *loaded = [self.persistence loadSessions];
    if (loaded.count) [self.turnStore replaceWithSessions:loaded currentIdentifier:loaded.firstObject.identifier];
    self.session = self.turnStore.currentSession;
    [self tl_restoreCurrentSessionCheckpoints];
    [self tl_startPathMonitor];
}
- (void)tl_restoreCurrentSessionCheckpoints {
    for (TLWAIAssistantMessage *message in self.session.messages) {
        if (message.recoveryCheckpoint &&
            ![self tl_restoreCheckpoint:message.recoveryCheckpoint message:message active:NO]) {
            message.recoveryCheckpoint = nil;
            message.canResumeJob = NO;
        }
    }
}
- (void)tl_startPathMonitor {
    if (self.pathMonitor) return;
    self.pathMonitor = nw_path_monitor_create();
    __weak typeof(self) weakSelf = self;
    nw_path_monitor_set_update_handler(self.pathMonitor, ^(nw_path_t path) {
        if (TLWAIShouldRepostAfterPathChange()) return;
        nw_path_status_t status = nw_path_get_status(path);
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.activeTurn.trace mark:TLWAITraceStagePathChange count:status];
            __strong typeof(weakSelf) owner = weakSelf;
            owner.networkPathAvailable = status == nw_path_status_satisfied;
            if ([owner.activeTurn.streamClient isKindOfClass:TLWAIJobStreamClient.class])
                [(TLWAIJobStreamClient *)owner.activeTurn.streamClient setNetworkAvailable:owner.networkPathAvailable];
        });
    });
    nw_path_monitor_set_queue(self.pathMonitor, dispatch_get_global_queue(QOS_CLASS_UTILITY, 0));
    nw_path_monitor_start(self.pathMonitor);
}
- (void)tl_showSessions {
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"问诊会话" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    for (TLWAIAssistantSession *session in self.turnStore.sessions) {
        NSString *title = session.title.length ? session.title : @"未命名";
        if ([session.identifier isEqualToString:self.session.identifier]) title = [title stringByAppendingString:@" · 当前"];
        [sheet addAction:[UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(__kindof UIAlertAction *action) {
            [self tl_selectSessionIdentifier:session.identifier];
        }]];
    }
    [sheet addAction:[UIAlertAction actionWithTitle:@"新会话" style:UIAlertActionStyleDefault handler:^(__kindof UIAlertAction *action) {
        [self tl_startNewSession];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:sheet animated:YES completion:nil];
}
- (void)tl_selectSessionIdentifier:(NSString *)identifier {
    if (self.activeTurn) [self tl_stopAI];
    [self.persistence upsertSession:self.session];
    if (![self.turnStore selectSessionWithIdentifier:identifier]) return;
    self.session = self.turnStore.currentSession;
    [self tl_restoreCurrentSessionCheckpoints];
    [self.myView displayMessages:self.session.messages];
}
- (void)tl_startNewSession {
    if (self.activeTurn) [self tl_stopAI];
    [self.persistence upsertSession:self.session];
    self.session = [self.turnStore createSession];
    [self.persistence upsertSession:self.session];
    [self.myView displayMessages:self.session.messages];
}
- (void)tl_authorizeLocationContext {
    if (TLWLocationManager.shared.locationDenied) {
        self.locationContextAuthorized = NO;
        [self.myView.plusLocationButton setTitle:@"附带定位" forState:UIControlStateNormal];
        [TLWToast show:@"定位未授权，发送不受影响"];
        return;
    }
    self.locationContextAuthorized = YES;
    [self.myView.plusLocationButton setTitle:@"定位已授权" forState:UIControlStateNormal];
    [[TLWLocationManager shared] requestLocationPermission];
}
- (void)tl_resumeJobFromMessage:(TLWAIAssistantMessage *)message {
    NSDictionary *record = message.recoveryCheckpoint;
    if (![self tl_restoreCheckpoint:record message:message active:NO] || !message.canResumeJob) return;
    if (self.activeTurn) [self tl_stopAI];
    NSDictionary *body = record[@"request"];
    TLWAIAssistantMessage *user = nil;
    for (TLWAIAssistantMessage *candidate in self.session.messages)
        if ([candidate.identifier isEqual:record[@"userMessageId"]]) { user = candidate; break; }
    if (!user) {
        // 历史裁剪后仍用可靠保存的真实输入快照，不向列表追加一条伪造的新提问。
        user = [TLWAIAssistantMessage messageWithRole:TLWAIAssistantMessageRoleUser text:body[@"text"]];
        user.identifier = record[@"userMessageId"];
    }
    AGChatRequest *request = [AGChatRequest new];
    request.text = body[@"text"]; request.imageUrl = body[@"imageUrl"];
    request.useSingleModel = body[@"useSingleModel"]; request.saveHistory = body[@"saveHistory"];
    request.extraInfo = body[@"extraInfo"];
    message.canContinue = NO; message.canResumeJob = NO; message.completed = NO;
    message.errorMessage = nil; message.status = TLWAIAssistantMessageStatusSending;
    self.activeTurn = [[TLWAIConversationTurn alloc] initWithUserMessage:user assistantMessage:message];
    self.activeTurn.request = request;
    [self.myView enterAILoadingMode];
    [self tl_prepareStreamRequest:request];
    [self tl_scheduleSlowStreamHintForMessage:message];
    dispatch_block_t restart = self.activeTurn.authRestart;
    if (restart) restart();
}

- (void)tl_continueFromMessage:(TLWAIAssistantMessage *)message {
    if (!message.canContinue) return;
    if (message.canResumeJob && message.recoveryCheckpoint) {
        [self tl_resumeJobFromMessage:message];
        return;
    }
    NSArray<TLWAIAssistantMessage *> *messages = self.session.messages;
    NSUInteger index = [messages indexOfObjectPassingTest:^BOOL(TLWAIAssistantMessage *item, NSUInteger idx, BOOL *stop) {
        return [item.identifier isEqualToString:message.identifier];
    }];
    TLWAIAssistantMessage *user = nil;
    if (index != NSNotFound) {
        for (NSInteger i = (NSInteger)index - 1; i >= 0; i--) {
            if (messages[i].role == TLWAIAssistantMessageRoleUser) { user = messages[i]; break; }
        }
    }
    if (!user) return;
    message.canContinue = NO;
    self.continueRegeneration = YES;
    [self.myView setInputText:user.text ?: @""];
    [self.pendingImages removeAllObjects];
    if (user.previewImages.count) [self.pendingImages addObjectsFromArray:user.previewImages];
    else if (user.localImages.count) [self.pendingImages addObjectsFromArray:user.localImages];
    else if (user.imageRelativePaths.count) {
        UIImage *image = [TLWAIImageArchive activeImageForRelativePath:user.imageRelativePaths.firstObject];
        if (image) [self.pendingImages addObject:image];
    }
    [self tl_send];
}
- (void)tl_startLocalHypothesisForImage:(UIImage *)image message:(TLWAIAssistantMessage *)message {
    NSString *identifier = message.identifier;
    [[TLWLocalIdentifyManager shared] identifyImage:image completion:^(NSArray<TLWLocalIdentifyResult *> *results, NSError *error) {
        TLWLocalIdentifyResult *top = results.firstObject;
        NSString *hypothesis = TLWAILocalHypothesisText(top.name, top.confidence);
        if (!hypothesis.length || ![message.identifier isEqualToString:identifier]) return;
        message.localHypothesis = hypothesis;
        [self.myView reloadMessage:message];
    }];
}
- (void)tl_applicationDidEnterBackground:(NSNotification *)notification {
    if (!self.activeTurn || self.activeTurn.isTerminal) {
        [self.persistence upsertSession:self.session];
        return;
    }
    __block UIBackgroundTaskIdentifier task = UIBackgroundTaskInvalid;
    task = [UIApplication.sharedApplication beginBackgroundTaskWithName:@"tlw-ai-incomplete" expirationHandler:^{
        if (task != UIBackgroundTaskInvalid) {
            [UIApplication.sharedApplication endBackgroundTask:task];
            task = UIBackgroundTaskInvalid;
        }
    }];
    TLWAIAssistantMessage *message = self.activeTurn.assistantMessage;
    message.canContinue = YES;
    [self tl_finishCurrentAIMessage:message state:TLWAIStreamTerminalStateIncomplete reasonText:@"已转入后台，回复未完成"];
    if (task != UIBackgroundTaskInvalid) [UIApplication.sharedApplication endBackgroundTask:task];
}

#pragma mark - Lazy

- (TLWAIAssistantView *)myView {
    if (!_myView) {
        _myView = [[TLWAIAssistantView alloc] initWithFrame:CGRectZero];
    }
    return _myView;
}

@end
