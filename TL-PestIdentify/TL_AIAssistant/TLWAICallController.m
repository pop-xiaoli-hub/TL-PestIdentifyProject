//
//  TLWAICallController.m
//  TL-PestIdentify
//
//  AI电话页面控制器：负责 AI 实时语音通话的 UI 与引擎生命周期。
//

#import "TLWAICallController.h"
#import "TLWDialogManager.h"
#import "TLWToast.h"
#import <AVFoundation/AVFoundation.h>
#import <Masonry/Masonry.h>

@interface TLWAICallController () <SpeechEngineDelegate>
@property (nonatomic, strong) CAGradientLayer *gradientLayer;
@property (nonatomic, strong) UIView *aiIconContainer;
@property (nonatomic, strong) UIImageView *aiIconImageView;
@property (nonatomic, strong) UILabel *hintLabel;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UIButton *hangUpButton;
@property (nonatomic, strong) UILabel *hangUpLabel;
@property (nonatomic, assign) BOOL didTryStartingCall;
@property (nonatomic, assign) BOOL callActive;
@property (nonatomic, assign) BOOL isLeavingPage;
@end

@implementation TLWAICallController

- (instancetype)init {
    self = [super init];
    if (self) {
        self.hidesBottomBarWhenPushed = YES;
    }
    return self;
}

- (NSString *)navTitle {
    return @"AI电话";
}

- (NSString *)navTitleIconName {
    return @"aiAssisstantIcon";
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self tl_setupGradientBackground];
    [self tl_setupAIIcon];
    [self tl_setupHintLabel];
    [self tl_setupHangUpButton];
    [self tl_updateHint:@"正在准备 AI 通话..." status:@"将为您接通语音助手"];
    [self tl_startIconBreathingAnimation];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.gradientLayer.frame = self.view.bounds;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (!self.didTryStartingCall) {
        self.didTryStartingCall = YES;
        [self tl_requestMicrophonePermissionAndStartCall];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (!self.isLeavingPage) {
        [self tl_stopCallIfNeeded];
    }
}

- (void)dealloc {
    [self tl_stopCallIfNeeded];
}

#pragma mark - Base

- (void)onBackAction {
    [self tl_leaveCallPage];
}

#pragma mark - UI Setup

- (void)tl_setupGradientBackground {
    self.view.backgroundColor = [UIColor colorWithRed:0.0 green:0.59 blue:0.68 alpha:1.0];
    self.gradientLayer = [CAGradientLayer layer];
    self.gradientLayer.colors = @[
        (__bridge id)[UIColor colorWithRed:0.0 green:0.59 blue:0.68 alpha:1.0].CGColor,  // #0097AE
        (__bridge id)[UIColor colorWithRed:0.0 green:0.76 blue:0.72 alpha:1.0].CGColor,   // #00C2B8
        (__bridge id)[UIColor colorWithRed:0.0 green:0.83 blue:0.67 alpha:1.0].CGColor,   // #00D4AA
    ];
    self.gradientLayer.startPoint = CGPointMake(0, 0);
    self.gradientLayer.endPoint = CGPointMake(1, 1);
    self.gradientLayer.frame = self.view.bounds;
    [self.view.layer insertSublayer:self.gradientLayer atIndex:0];
}

- (void)tl_setupAIIcon {
    // 橙色圆形容器
    CGFloat iconContainerSize = 120;
    _aiIconContainer = [[UIView alloc] init];
    _aiIconContainer.backgroundColor = [UIColor colorWithRed:1.0 green:0.66 blue:0.0 alpha:1.0]; // #FFA800
    _aiIconContainer.layer.cornerRadius = iconContainerSize / 2.0;
    _aiIconContainer.layer.masksToBounds = YES;
    _aiIconContainer.layer.shadowColor = [UIColor colorWithWhite:1.0 alpha:0.55].CGColor;
    _aiIconContainer.layer.shadowOpacity = 1.0;
    _aiIconContainer.layer.shadowRadius = 26.0;
    _aiIconContainer.layer.shadowOffset = CGSizeZero;
    [self.contentView addSubview:_aiIconContainer];
    [_aiIconContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.contentView);
        make.centerY.equalTo(self.contentView).offset(-60);
        make.width.height.mas_equalTo(iconContainerSize);
    }];

    // AI助手图标
    _aiIconImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"aiAssisstantIcon"]];
    _aiIconImageView.contentMode = UIViewContentModeScaleAspectFit;
    [_aiIconContainer addSubview:_aiIconImageView];
    [_aiIconImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self->_aiIconContainer);
        make.width.height.mas_equalTo(60);
    }];
}

- (void)tl_setupHintLabel {
    _hintLabel = [[UILabel alloc] init];
    _hintLabel.text = @"正在准备 AI 通话...";
    _hintLabel.font = [UIFont systemFontOfSize:20 weight:UIFontWeightSemibold];
    _hintLabel.textColor = [UIColor whiteColor];
    _hintLabel.textAlignment = NSTextAlignmentCenter;
    _hintLabel.numberOfLines = 0;
    [self.contentView addSubview:_hintLabel];
    [_hintLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.contentView);
        make.left.equalTo(self.contentView).offset(32);
        make.right.equalTo(self.contentView).offset(-32);
        make.top.equalTo(self->_aiIconContainer.mas_bottom).offset(36);
    }];

    _statusLabel = [[UILabel alloc] init];
    _statusLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    _statusLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.88];
    _statusLabel.textAlignment = NSTextAlignmentCenter;
    _statusLabel.numberOfLines = 0;
    [self.contentView addSubview:_statusLabel];
    [_statusLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.contentView);
        make.left.equalTo(self.contentView).offset(36);
        make.right.equalTo(self.contentView).offset(-36);
        make.top.equalTo(self->_hintLabel.mas_bottom).offset(12);
    }];
}

- (void)tl_setupHangUpButton {
    CGFloat btnSize = 88;

    // 结束通话按钮
    _hangUpButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _hangUpButton.backgroundColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.8];
    _hangUpButton.layer.cornerRadius = btnSize / 2.0;
    _hangUpButton.layer.masksToBounds = YES;
    // 内发光效果
    _hangUpButton.layer.borderWidth = 2.6;
    _hangUpButton.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.9].CGColor;
    [_hangUpButton addTarget:self action:@selector(tl_hangUp) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:_hangUpButton];
    [_hangUpButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.contentView);
        make.bottom.equalTo(self.contentView.mas_safeAreaLayoutGuideBottom).offset(-80);
        make.width.height.mas_equalTo(btnSize);
    }];

    // 结束图标（红色X）
    UIImageView *stopIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Xicon"]];
    stopIcon.contentMode = UIViewContentModeScaleAspectFit;
    [_hangUpButton addSubview:stopIcon];
    [stopIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self->_hangUpButton);
        make.width.height.mas_equalTo(36);
    }];

    // "结束通话" 文字
    _hangUpLabel = [[UILabel alloc] init];
    _hangUpLabel.text = @"结束通话";
    _hangUpLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
    _hangUpLabel.textColor = [UIColor whiteColor];
    _hangUpLabel.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:_hangUpLabel];
    [_hangUpLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self->_hangUpButton);
        make.top.equalTo(self->_hangUpButton.mas_bottom).offset(12);
    }];
}

#pragma mark - Actions

- (void)tl_hangUp {
    [self tl_leaveCallPage];
}

#pragma mark - SpeechEngineDelegate

- (void)onMessageWithType:(SEMessageType)type andData:(NSData *)data {
    NSString *displayText = [self tl_extractPrimaryTextFromData:data];
    NSString *payloadText = [self tl_stringFromData:data];

    dispatch_async(dispatch_get_main_queue(), ^{
        switch (type) {
            case SEEventConnectionStarted:
                [self tl_updateHint:@"正在连接 AI 助手..." status:@"语音链路建立中"];
                break;
            case SEEventSessionStarted:
                self.callActive = YES;
                [self tl_updateHint:@"AI 通话已接通" status:@"现在可以直接说话，无需再按按钮"];
                break;
            case SEVadSpeech:
            case SEVadSil2Speech:
                [self tl_updateHint:@"正在聆听中..." status:@"继续说，我在实时接收您的声音"];
                break;
            case SEEventASRInfo:
            case SEEventASRResponse:
            case SEEventChatTextQueryConfirmed:
                if (displayText.length > 0) {
                    [self tl_updateHint:displayText status:@"已识别您的语音内容"];
                } else {
                    [self tl_updateHint:@"正在理解您的问题..." status:@"语音已接收，正在转成文本"];
                }
                break;
            case SEEventChatResponse:
            case SEEventTTSResponse:
                if (displayText.length > 0) {
                    [self tl_updateHint:displayText status:@"AI 正在为您语音播报"];
                } else {
                    [self tl_updateHint:@"AI 正在组织回复..." status:@"即将返回语音答案"];
                }
                break;
            case SEPlayerStartPlayAudio:
                [self tl_updateHint:self.hintLabel.text ?: @"AI 正在回答..." status:@"正在语音播报回复"];
                break;
            case SEPlayerFinishPlayAudio:
            case SEEventTTSEnded:
            case SEEventChatEnded:
            case SEEventASREnded:
                [self tl_updateHint:@"您可以继续说话..." status:@"本轮回复已结束，支持继续追问"];
                break;
            case SEEventConnectionFailed:
            case SEEventSessionFailed:
            case SEEngineError: {
                NSString *errorText = displayText.length > 0 ? displayText : payloadText;
                if (errorText.length == 0) {
                    errorText = @"AI 通话启动失败，请稍后重试";
                }
                self.callActive = NO;
                [self tl_stopIconBreathingAnimation];
                [self tl_updateHint:@"AI 通话异常中断" status:errorText];
                [TLWToast show:errorText];
                break;
            }
            case SEEngineStop:
            case SEEventConnectionFinished:
            case SEEventSessionCanceled:
            case SEEventSessionFinished:
                self.callActive = NO;
                [self tl_stopIconBreathingAnimation];
                if (!self.isLeavingPage) {
                    [self tl_updateHint:@"AI 通话已结束" status:@"返回上一页后可重新发起通话"];
                }
                break;
            default:
                break;
        }
    });
}

#pragma mark - Call Lifecycle

- (void)tl_requestMicrophonePermissionAndStartCall {
    NSInteger permission = [self tl_recordPermissionStatus];
    if (permission == 1) {
        [self tl_startCall];
        return;
    }

    if (permission == -1) {
        NSString *message = @"未开启麦克风权限，请在系统设置中允许访问后再试";
        [self tl_stopIconBreathingAnimation];
        [self tl_updateHint:@"无法开启 AI 通话" status:message];
        [TLWToast show:message];
        return;
    }

    __weak typeof(self) weakSelf = self;
    [self tl_requestRecordPermission:^(BOOL granted) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) return;
            if (granted) {
                [strongSelf tl_startCall];
            } else {
                NSString *message = @"需要麦克风权限才能进行 AI 通话";
                [strongSelf tl_stopIconBreathingAnimation];
                [strongSelf tl_updateHint:@"无法开启 AI 通话" status:message];
                [TLWToast show:message];
            }
        });
    }];
}

- (void)tl_startCall {
    [self tl_updateHint:@"正在接入 AI 通话..." status:@"请稍候，正在初始化语音引擎"];
    [[TLWDialogManager shared] setupEngineWithDelegate:self];
    SEEngineErrorCode result = [[TLWDialogManager shared] startEngine];
    if (result != SENoError) {
        NSString *message = [NSString stringWithFormat:@"AI 通话启动失败，错误码: %d", (int)result];
        [self tl_stopIconBreathingAnimation];
        [self tl_updateHint:@"无法开启 AI 通话" status:message];
        [TLWToast show:message];
    }
}

- (void)tl_stopCallIfNeeded {
    [[TLWDialogManager shared] stopEngine];
    [[TLWDialogManager shared] destroyEngine];
    self.callActive = NO;
}

- (NSInteger)tl_recordPermissionStatus {
    if (@available(iOS 17.0, *)) {
        switch ([AVAudioApplication sharedInstance].recordPermission) {
            case AVAudioApplicationRecordPermissionGranted:
                return 1;
            case AVAudioApplicationRecordPermissionDenied:
                return -1;
            case AVAudioApplicationRecordPermissionUndetermined:
            default:
                return 0;
        }
    }

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    AVAudioSessionRecordPermission permission = [AVAudioSession sharedInstance].recordPermission;
    if (permission == AVAudioSessionRecordPermissionGranted) {
        return 1;
    }
    if (permission == AVAudioSessionRecordPermissionDenied) {
        return -1;
    }
#pragma clang diagnostic pop
    return 0;
}

- (void)tl_requestRecordPermission:(void (^)(BOOL granted))completion {
    if (@available(iOS 17.0, *)) {
        [AVAudioApplication requestRecordPermissionWithCompletionHandler:completion];
        return;
    }

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [[AVAudioSession sharedInstance] requestRecordPermission:completion];
#pragma clang diagnostic pop
}

- (void)tl_leaveCallPage {
    self.isLeavingPage = YES;
    [self tl_stopCallIfNeeded];
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - UI State

- (void)tl_updateHint:(NSString *)hint status:(NSString *)status {
    self.hintLabel.text = hint.length > 0 ? hint : @"您可以开始说话...";
    self.statusLabel.text = status;
}

- (void)tl_startIconBreathingAnimation {
    if ([self.aiIconContainer.layer animationForKey:@"tl_ai_breathing"] != nil) {
        return;
    }

    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    animation.fromValue = @(1.0);
    animation.toValue = @(1.08);
    animation.duration = 1.15;
    animation.autoreverses = YES;
    animation.repeatCount = HUGE_VALF;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [self.aiIconContainer.layer addAnimation:animation forKey:@"tl_ai_breathing"];
}

- (void)tl_stopIconBreathingAnimation {
    [self.aiIconContainer.layer removeAnimationForKey:@"tl_ai_breathing"];
}

#pragma mark - Data Parsing

- (NSString *)tl_extractPrimaryTextFromData:(NSData *)data {
    id jsonObject = [self tl_JSONObjectFromData:data];
    if (!jsonObject) {
        return [self tl_sanitizedText:[self tl_stringFromData:data]];
    }

    NSString *foundText = [self tl_findTextInJSONObject:jsonObject];
    if (foundText.length > 0) {
        return foundText;
    }

    return [self tl_sanitizedText:[self tl_stringFromData:data]];
}

- (id)tl_JSONObjectFromData:(NSData *)data {
    if (data.length == 0) return nil;

    NSError *error = nil;
    id jsonObject = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
    if (error || !jsonObject) {
        return nil;
    }
    return jsonObject;
}

- (NSString *)tl_findTextInJSONObject:(id)object {
    if ([object isKindOfClass:[NSString class]]) {
        return [self tl_sanitizedText:(NSString *)object];
    }

    if ([object isKindOfClass:[NSNumber class]]) {
        return [(NSNumber *)object stringValue];
    }

    if ([object isKindOfClass:[NSArray class]]) {
        for (id item in (NSArray *)object) {
            NSString *text = [self tl_findTextInJSONObject:item];
            if (text.length > 0) return text;
        }
        return nil;
    }

    if (![object isKindOfClass:[NSDictionary class]]) {
        return nil;
    }

    NSDictionary *dictionary = (NSDictionary *)object;
    NSArray<NSString *> *preferredKeys = @[
        @"text",
        @"content",
        @"message",
        @"reply",
        @"answer",
        @"query",
        @"question",
        @"prompt",
        @"utterance",
        @"sentence",
        @"value"
    ];

    for (NSString *key in preferredKeys) {
        id value = dictionary[key];
        NSString *text = [self tl_findTextInJSONObject:value];
        if (text.length > 0) return text;
    }

    for (id value in dictionary.allValues) {
        NSString *text = [self tl_findTextInJSONObject:value];
        if (text.length > 0) return text;
    }

    return nil;
}

- (NSString *)tl_stringFromData:(NSData *)data {
    if (data.length == 0) return @"";

    NSString *rawText = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (rawText.length > 0) {
        return rawText;
    }

    return [NSString stringWithFormat:@"<binary %lu bytes>", (unsigned long)data.length];
}

- (NSString *)tl_sanitizedText:(NSString *)text {
    NSString *trimmed = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (trimmed.length == 0) {
        return nil;
    }
    return trimmed;
}

@end
