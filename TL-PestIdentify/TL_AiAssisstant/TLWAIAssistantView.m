//
//  TLWAIAssistantView.m
//  TL-PestIdentify
//

#import "TLWAIAssistantView.h"
#import <Masonry/Masonry.h>

static CGFloat const kNavOffset          = 8.0;
static CGFloat const kNavHeight          = 48.0;
static CGFloat const kRoundBaseHeight    = 53.0;   // inputBar 可见区域高度
static CGFloat const kInputBoxHeight     = 54.0;   // 圆角输入框高度
static CGFloat const kTextViewBaseHeight = 34.0;   // inputTextField 初始高度
static CGFloat const kPreviewAreaHeight  = 96.0;   // 8(上边距) + 80(图片) + 8(与inputRow间距)

@interface TLWAIAssistantView () <UITextViewDelegate>
@property (nonatomic, strong, readwrite) UIButton    *backButton;
@property (nonatomic, strong, readwrite) UIButton    *cameraButton;
@property (nonatomic, strong, readwrite) UIButton    *micButton;
@property (nonatomic, strong, readwrite) UIButton    *galleryButton;
@property (nonatomic, strong, readwrite) UIButton    *removePreviewButton;
@property (nonatomic, strong) UIView        *inputBar;
@property (nonatomic, strong) UIView        *roundContainer;
@property (nonatomic, strong) UIView        *previewRow;
@property (nonatomic, strong) UIImageView   *previewImageView;
@property (nonatomic, strong) MASConstraint *inputBarBottomConstraint;
@property (nonatomic, strong) MASConstraint *inputBarHeightConstraint;
@property (nonatomic, strong) MASConstraint *chatScrollBottomConstraint;
@property (nonatomic, strong) MASConstraint *textViewHeightConstraint;
@property (nonatomic, strong) MASConstraint *roundContainerHeightConstraint;
@property (nonatomic, strong) MASConstraint *inputRowHeightConstraint;
@property (nonatomic, assign) CGFloat        safeBottomInset;
@property (nonatomic, assign) CGFloat        currentTextViewHeight;
@property (nonatomic, assign) CGFloat        keyboardHeight;
@end

@implementation TLWAIAssistantView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        UIWindow *window = [UIApplication sharedApplication].windows.firstObject;
        CGFloat safeTop    = window.safeAreaInsets.top;
        CGFloat safeBottom = window.safeAreaInsets.bottom;
        CGFloat navTop  = safeTop + kNavOffset;
        CGFloat chatTop = navTop + kNavHeight + 8.0;

        _safeBottomInset       = safeBottom;
        _currentTextViewHeight = kTextViewBaseHeight;
        _keyboardHeight        = 0;

        [self tl_setupBackground];
        [self tl_setupCardWithTop:chatTop];
        [self tl_setupNavBarWithTop:navTop];
        [self tl_setupChatAreaWithTop:chatTop];
        [self tl_setupInputBar];
    }
    return self;
}

#pragma mark - Background

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

#pragma mark - Nav Bar

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

    UIImageView *aiIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"aiAssisstant"]];
    aiIcon.contentMode = UIViewContentModeScaleAspectFit;
    [titleContainer addSubview:aiIcon];

    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text      = @"AI助手";
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.font      = [UIFont systemFontOfSize:20 weight:UIFontWeightSemibold];
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
        make.centerY.equalTo(_backButton);
    }];
}

#pragma mark - Chat Area

- (void)tl_setupChatAreaWithTop:(CGFloat)chatTop {
    UIScrollView *chatScroll = [[UIScrollView alloc] init];
    chatScroll.backgroundColor = [UIColor clearColor];
    chatScroll.alwaysBounceVertical = YES;
    [self addSubview:chatScroll];
    __block MASConstraint *chatBottomConstraint;
    [chatScroll mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(chatTop);
        make.left.right.equalTo(self);
        chatBottomConstraint = make.bottom.equalTo(self).offset(-(kRoundBaseHeight + _safeBottomInset));
    }];
    _chatScrollBottomConstraint = chatBottomConstraint;
}

#pragma mark - Input Bar

- (void)tl_setupInputBar {
    // ── inputBar ──────────────────────────────────────────
    self.inputBar = [[UIView alloc] init];
    [self addSubview:self.inputBar];
    __block MASConstraint *inputBarBottomConstraint;
    __block MASConstraint *inputBarHeightConstraint;
    [_inputBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self);
        inputBarBottomConstraint = make.bottom.equalTo(self).offset(0);
        inputBarHeightConstraint = make.height.mas_equalTo(kRoundBaseHeight + _safeBottomInset);  // kRoundBaseHeight = kInputBoxHeight + 2*padding
    }];
    _inputBarBottomConstraint = inputBarBottomConstraint;
    _inputBarHeightConstraint = inputBarHeightConstraint;

    UIImageView *frameBg = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"chatFrame"]];
    frameBg.contentMode = UIViewContentModeScaleToFill;
    [_inputBar addSubview:frameBg];
    [frameBg mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(_inputBar);
    }];

    // ── roundContainer（白色圆角容器，bottom-pinned，高度随内容动态增长）──
    _roundContainer = [[UIView alloc] init];
    _roundContainer.backgroundColor = [UIColor whiteColor];
    _roundContainer.layer.cornerRadius = kInputBoxHeight / 2.0;
    _roundContainer.layer.masksToBounds = YES;
    [_inputBar addSubview:_roundContainer];
    CGFloat inputBoxVerticalPadding = (kRoundBaseHeight - kInputBoxHeight) / 2.0;
    __block MASConstraint *roundContainerHeightConstraint;
    [_roundContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_inputBar).offset(16);
        make.right.equalTo(_inputBar).offset(-16);
        // bottom 锚定：底部距离 = 安全区 + 居中留白，向上增长
        make.centerY.equalTo(_inputBar);
        roundContainerHeightConstraint = make.height.mas_equalTo(kInputBoxHeight);
    }];
    _roundContainerHeightConstraint = roundContainerHeightConstraint;

    // ── previewRow（roundContainer 顶部，图片选中后显示）──
    _previewRow = [[UIView alloc] init];
    _previewRow.hidden = YES;
    [_roundContainer addSubview:_previewRow];
    [_previewRow mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(_roundContainer);
        make.height.mas_equalTo(kPreviewAreaHeight);
    }];

    _previewImageView = [[UIImageView alloc] init];
    _previewImageView.contentMode = UIViewContentModeScaleAspectFill;
    _previewImageView.clipsToBounds = YES;
    _previewImageView.layer.cornerRadius = 8;
    _previewImageView.userInteractionEnabled = YES;
    [_previewRow addSubview:_previewImageView];
    [_previewImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(8);
        make.left.mas_equalTo(25);
        make.width.height.mas_equalTo(80);
    }];

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                          action:@selector(tl_showFullscreenPreview)];
    [_previewImageView addGestureRecognizer:tap];

    _removePreviewButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_removePreviewButton setTitle:@"×" forState:UIControlStateNormal];
    [_removePreviewButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    _removePreviewButton.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    _removePreviewButton.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    _removePreviewButton.layer.cornerRadius = 10;
    [_previewRow addSubview:_removePreviewButton];
    [_removePreviewButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_previewImageView);
        make.left.equalTo(_previewImageView.mas_right).offset(-10);
        make.width.height.mas_equalTo(20);
    }];
    [_removePreviewButton addTarget:self action:@selector(hideSelectedImage) forControlEvents:UIControlEventTouchUpInside];

    // ── inputRow（透明，roundContainer 底部，高度随 textView 动态增长）──
    UIView *inputRow = [[UIView alloc] init];
    inputRow.backgroundColor = [UIColor clearColor];
    [_roundContainer addSubview:inputRow];
    __block MASConstraint *inputRowHeightConstraint;
    [inputRow mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(_roundContainer);
        inputRowHeightConstraint = make.height.mas_equalTo(kInputBoxHeight);
    }];
    _inputRowHeightConstraint = inputRowHeightConstraint;

    // Camera button（左侧）
    _cameraButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_cameraButton setImage:[UIImage imageNamed:@"iconCamera"] forState:UIControlStateNormal];
    _cameraButton.contentMode = UIViewContentModeScaleAspectFit;
    [inputRow addSubview:_cameraButton];
    [_cameraButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(14);
        make.centerY.equalTo(inputRow);
        make.width.height.mas_equalTo(24);
    }];

    // Gallery button（最右）
    _galleryButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_galleryButton setImage:[UIImage imageNamed:@"iconAlbum"] forState:UIControlStateNormal];
    _galleryButton.contentMode = UIViewContentModeScaleAspectFit;
    [inputRow addSubview:_galleryButton];
    [_galleryButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(-14);
        make.centerY.equalTo(inputRow);
        make.width.height.mas_equalTo(24);
    }];

    // Mic button（gallery 左侧）
    _micButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_micButton setImage:[UIImage imageNamed:@"iconMicrophone"] forState:UIControlStateNormal];
    _micButton.contentMode = UIViewContentModeScaleAspectFit;
    [inputRow addSubview:_micButton];
    [_micButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(_galleryButton.mas_left).offset(-8);
        make.centerY.equalTo(inputRow);
        make.width.height.mas_equalTo(24);
    }];

    // Text field（camera 右侧 → mic 左侧）
    _inputTextField = [[UITextView alloc] init];
    _inputTextField.backgroundColor = [UIColor clearColor];
    _inputTextField.font = [UIFont systemFontOfSize:15];
    _inputTextField.textColor = [UIColor colorWithRed:0.16 green:0.16 blue:0.16 alpha:1.0];
    _inputTextField.scrollEnabled = NO;
    _inputTextField.textContainer.lineBreakMode = NSLineBreakByWordWrapping;
    _inputTextField.textContainerInset = UIEdgeInsetsMake(0, 4, 0, 4);
    _inputTextField.returnKeyType = UIReturnKeyDefault;
    _inputTextField.delegate = self;
    [inputRow addSubview:_inputTextField];
    [_inputTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_cameraButton.mas_right).offset(6);
        make.right.equalTo(_micButton.mas_left).offset(-6);
        make.top.equalTo(_cameraButton.mas_top);
        self.textViewHeightConstraint = make.height.mas_equalTo(kTextViewBaseHeight);
    }];
}

#pragma mark - Height update

- (void)tl_updateInputBarHeight {
    CGFloat inputBoxVerticalPadding = (kRoundBaseHeight - kInputBoxHeight) / 2.0;
    CGFloat textViewExtra        = _currentTextViewHeight - kTextViewBaseHeight;
    CGFloat previewExtra         = _previewRow.hidden ? 0 : kPreviewAreaHeight;
    CGFloat inputRowHeight       = kInputBoxHeight + textViewExtra;
    CGFloat roundContainerHeight = inputRowHeight + previewExtra;
    CGFloat inputBarHeight       = roundContainerHeight + _safeBottomInset + inputBoxVerticalPadding * 2;

    _inputRowHeightConstraint.offset       = inputRowHeight;
    _roundContainerHeightConstraint.offset = roundContainerHeight;
    _inputBarHeightConstraint.offset       = inputBarHeight;
    _chatScrollBottomConstraint.offset     = -(inputBarHeight + _keyboardHeight);
}

#pragma mark - UITextViewDelegate

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if ([text isEqualToString:@"\n"]) {
        [textView insertText:@"\n"];
        return NO;
    }
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView {
    CGSize size = [textView sizeThatFits:CGSizeMake(textView.frame.size.width, MAXFLOAT)];
    BOOL shouldScroll = size.height > 45;
    textView.scrollEnabled = shouldScroll;
    _currentTextViewHeight = MAX(kTextViewBaseHeight, MIN(45, size.height));
    self.textViewHeightConstraint.offset = _currentTextViewHeight;

    [self tl_updateInputBarHeight];
    [UIView animateWithDuration:0.15 animations:^{
        [self layoutIfNeeded];
    }];
}

#pragma mark - Image Preview

- (void)showSelectedImage:(UIImage *)image {
    _previewImageView.image = image;
    _previewRow.hidden = NO;
    [self tl_updateInputBarHeight];
    [UIView animateWithDuration:0.2 animations:^{
        [self layoutIfNeeded];
    }];
}

- (void)hideSelectedImage {
    _previewRow.hidden = YES;
    _previewImageView.image = nil;
    [self tl_updateInputBarHeight];
    [UIView animateWithDuration:0.2 animations:^{
        [self layoutIfNeeded];
    }];
}

- (void)tl_showFullscreenPreview {
    UIWindow *window = UIApplication.sharedApplication.windows.firstObject;

    UIView *overlay = [[UIView alloc] initWithFrame:window.bounds];
    overlay.backgroundColor = [UIColor colorWithWhite:0 alpha:0.9];

    UIImageView *fullImageView = [[UIImageView alloc] init];
    fullImageView.image = _previewImageView.image;
    fullImageView.contentMode = UIViewContentModeScaleAspectFit;
    CGFloat padding = 20;
    fullImageView.frame = CGRectMake(padding, 80,
                                     window.bounds.size.width - padding * 2,
                                     window.bounds.size.height - 160);
    [overlay addSubview:fullImageView];

    UITapGestureRecognizer *dismiss = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                              action:@selector(tl_dismissFullscreenPreview:)];
    [overlay addGestureRecognizer:dismiss];

    [window addSubview:overlay];
    overlay.alpha = 0;
    [UIView animateWithDuration:0.25 animations:^{
        overlay.alpha = 1;
    }];
}

- (void)tl_dismissFullscreenPreview:(UITapGestureRecognizer *)tap {
    UIView *overlay = tap.view;
    [UIView animateWithDuration:0.2 animations:^{
        overlay.alpha = 0;
    } completion:^(BOOL finished) {
        [overlay removeFromSuperview];
    }];
}

#pragma mark - Keyboard

- (void)adjustForKeyboardHeight:(CGFloat)height duration:(NSTimeInterval)duration {
    _keyboardHeight = height;
    _inputBarBottomConstraint.offset = -height;
    [self tl_updateInputBarHeight];
    [UIView animateWithDuration:duration animations:^{
        [self layoutIfNeeded];
    }];
}

@end
