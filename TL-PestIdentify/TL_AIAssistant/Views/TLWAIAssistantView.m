//
//  TLWAIAssistantView.m
//  TL-PestIdentify
//
//  Created by Northern Lights on 2026/4/3.
//  职责：实现AI助手页面视图组件。
//
#import "TLWAIAssistantView.h"
#import "TLWAIAssistantComposerView.h"
#import "TLWAIAssistantMessageListView.h"
#import "TLWAIAssistantMessage.h"
#import <Masonry/Masonry.h>

static CGFloat const kNavOffset = 8.0;
static CGFloat const kNavHeight = 48.0;

@interface TLWAIAssistantView ()
// 主 view 自己不渲染消息和输入细节，只负责把两个子组件拼成完整页面。
@property (nonatomic, strong) TLWAIAssistantMessageListView *messageListView;
@property (nonatomic, strong) TLWAIAssistantComposerView *composerView;
@property (nonatomic, strong) MASConstraint *composerBottomConstraint;
@property (nonatomic, strong) MASConstraint *composerHeightConstraint;
@end

@implementation TLWAIAssistantView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self tl_setupBackground];
        [self tl_setupCard];
        [self tl_setupContent];
        [self tl_bindComposerHeight];
    }
    return self;
}

- (UIButton *)cameraButton {
    return self.composerView.cameraButton;
}

- (UIButton *)micButton {
    return self.composerView.micButton;
}

- (UIButton *)plusButton {
    return self.composerView.plusButton;
}

- (UIButton *)plusCameraButton {
    return self.composerView.plusCameraButton;
}

- (UIButton *)plusAlbumButton {
    return self.composerView.plusAlbumButton;
}

- (UIButton *)plusAICallButton {
    return self.composerView.plusAICallButton;
}

- (UIButton *)sendButton {
    return self.composerView.sendButton;
}

- (UITextView *)inputTextField {
    return self.composerView.inputTextField;
}

- (UIImageView *)voiceSpeechImageView {
    return self.composerView.voiceSpeechImageView;
}

- (void)setOnRemoveImageAtIndex:(void (^)(NSUInteger))onRemoveImageAtIndex {
    _onRemoveImageAtIndex = [onRemoveImageAtIndex copy];
    self.composerView.onRemoveImageAtIndex = _onRemoveImageAtIndex;
}

- (void)adjustForKeyboardHeight:(CGFloat)height duration:(NSTimeInterval)duration {
    // 键盘位移只作用在 composer，消息列表天然跟着顶部约束和底部锚点收缩。
    self.composerBottomConstraint.offset = -height;
    [UIView animateWithDuration:duration animations:^{
        [self layoutIfNeeded];
    }];
}

- (void)setInputText:(NSString *)text {
    [self.composerView setInputText:text];
}

- (void)showSelectedImage:(UIImage *)image {
    [self.composerView showSelectedImage:image];
}

- (void)showSelectedImages:(NSArray<UIImage *> *)images {
    [self.composerView showSelectedImages:images];
}

- (void)hideSelectedImage {
    [self.composerView hideSelectedImage];
}

- (void)showVoicePanel {
    [self.composerView showVoicePanel];
}

- (void)hideVoicePanel {
    [self.composerView hideVoicePanel];
}

- (BOOL)isPlusPanelVisible {
    return self.composerView.isPlusPanelVisible;
}

- (void)showPlusPanel {
    [self.composerView showPlusPanel];
}

- (void)hidePlusPanel {
    [self.composerView hidePlusPanel];
}

- (UIButton *)stopButton {
    return self.composerView.stopButton;
}

- (void)enterAILoadingMode {
    [self.composerView enterAILoadingMode];
}

- (void)exitAILoadingMode {
    [self.composerView exitAILoadingMode];
}

- (void)displayMessages:(NSArray<TLWAIAssistantMessage *> *)messages {
    [self.messageListView displayMessages:messages];
}

- (void)appendMessage:(TLWAIAssistantMessage *)message {
    [self.messageListView appendMessage:message];
}

- (void)scrollMessagesToBottomAnimated:(BOOL)animated {
    [self.messageListView scrollToBottomAnimated:animated];
}

#pragma mark - Setup

- (void)tl_setupBackground {
    UIImage *bg = [UIImage imageNamed:@"hp_backView.png"];
    self.layer.contents = (__bridge id)bg.CGImage;
}

- (void)tl_setupCard {
    UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    UIVisualEffectView *cardView = [[UIVisualEffectView alloc] initWithEffect:blur];
    cardView.layer.cornerRadius = 20;
    cardView.layer.masksToBounds = YES;

    UIView *overlay = [[UIView alloc] init];
    overlay.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.65];
    [cardView.contentView addSubview:overlay];
    [overlay mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(cardView.contentView);
    }];

    [self addSubview:cardView];
    [cardView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self);
        make.top.equalTo(self.mas_safeAreaLayoutGuideTop).offset(kNavOffset + kNavHeight + 8.0);
    }];
}

- (void)tl_setupContent {
    self.messageListView = [[TLWAIAssistantMessageListView alloc] initWithFrame:CGRectZero];
    [self addSubview:self.messageListView];

    self.composerView = [[TLWAIAssistantComposerView alloc] initWithFrame:CGRectZero];
    self.composerView.onRemoveImageAtIndex = self.onRemoveImageAtIndex;
    [self addSubview:self.composerView];

    __weak typeof(self) weakSelf = self;
    [self.composerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self);
        weakSelf.composerBottomConstraint = make.bottom.equalTo(weakSelf);
        weakSelf.composerHeightConstraint = make.height.mas_equalTo(weakSelf.composerView.preferredHeight);
    }];

    [self.messageListView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.mas_safeAreaLayoutGuideTop).offset(kNavOffset + kNavHeight + 8.0);
        make.left.right.equalTo(self);
        // 让消息区始终贴着输入区上沿，composer 高度变化时列表可自动重排。
        make.bottom.equalTo(self.composerView.mas_top);
    }];
}

- (void)tl_bindComposerHeight {
    __weak typeof(self) weakSelf = self;
    self.composerView.onHeightDidChange = ^(CGFloat height) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        // 输入区内部会因为文本、预览图、语音面板变化而增高，这里只同步外层容器高度。
        strongSelf.composerHeightConstraint.offset = height;
        [strongSelf setNeedsLayout];
    };
}

@end
