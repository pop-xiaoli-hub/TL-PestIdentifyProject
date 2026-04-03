//
//  TLWAIAssistantView.m
//  TL-PestIdentify
//

#import "TLWAIAssistantView.h"
#import "TLWAIAssistantComposerView.h"
#import "TLWAIAssistantMessageListView.h"
#import "TLWAIAssistantMessage.h"
#import <Masonry/Masonry.h>

static CGFloat const kNavOffset = 8.0;
static CGFloat const kNavHeight = 48.0;

@interface TLWAIAssistantView ()
@property (nonatomic, strong, readwrite) UIButton *backButton;
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
        UIWindow *window = [self tl_activeWindow];
        CGFloat safeTop = window.safeAreaInsets.top;
        CGFloat navTop = safeTop + kNavOffset;
        CGFloat contentTop = navTop + kNavHeight + 8.0;

        [self tl_setupBackground];
        [self tl_setupCardWithTop:contentTop];
        [self tl_setupNavBarWithTop:navTop];
        [self tl_setupContentWithTop:contentTop];
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

- (UIButton *)galleryButton {
    return self.composerView.galleryButton;
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

- (void)tl_setupCardWithTop:(CGFloat)cardTop {
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
        make.top.equalTo(self).offset(cardTop);
    }];
}

- (void)tl_setupNavBarWithTop:(CGFloat)navTop {
    _backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_backButton setImage:[UIImage imageNamed:@"iconBack"] forState:UIControlStateNormal];
    [self addSubview:_backButton];
    [_backButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(16);
        make.top.mas_equalTo(navTop);
        make.width.height.mas_equalTo(kNavHeight);
    }];

    UIView *titleContainer = [[UIView alloc] init];
    [self addSubview:titleContainer];

    UIImageView *aiIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"aiAssistant"]];
    aiIcon.contentMode = UIViewContentModeScaleAspectFit;
    [titleContainer addSubview:aiIcon];

    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = @"AI助手";
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.font = [UIFont systemFontOfSize:20 weight:UIFontWeightSemibold];
    [titleContainer addSubview:titleLabel];

    [aiIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.bottom.equalTo(titleContainer);
        make.width.height.mas_equalTo(50);
    }];
    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(aiIcon.mas_right).offset(8);
        make.right.equalTo(titleContainer);
        make.centerY.equalTo(aiIcon);
    }];
    [titleContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self);
        make.centerY.equalTo(self.backButton);
    }];
}

- (void)tl_setupContentWithTop:(CGFloat)contentTop {
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
        make.top.equalTo(self).offset(contentTop);
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

- (UIWindow *)tl_activeWindow {
    NSSet<UIScene *> *scenes = UIApplication.sharedApplication.connectedScenes;
    for (UIScene *scene in scenes) {
        if (![scene isKindOfClass:[UIWindowScene class]]) continue;
        UIWindowScene *windowScene = (UIWindowScene *)scene;
        for (UIWindow *window in windowScene.windows) {
            if (window.isKeyWindow) {
                return window;
            }
        }
        if (windowScene.windows.firstObject) {
            return windowScene.windows.firstObject;
        }
    }
    return [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
}

@end
