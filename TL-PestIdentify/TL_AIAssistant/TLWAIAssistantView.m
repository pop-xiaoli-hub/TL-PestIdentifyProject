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
static CGFloat const kVoicePanelHeight   = 180.0;  // 语音输入面板高度

@interface TLWAIAssistantView () <UITextViewDelegate>
@property (nonatomic, strong, readwrite) UIButton    *backButton;
@property (nonatomic, strong, readwrite) UIButton    *cameraButton;
@property (nonatomic, strong, readwrite) UIButton    *micButton;
@property (nonatomic, strong, readwrite) UIButton    *galleryButton;
@property (nonatomic, strong, readwrite) UIButton    *sendButton;
@property (nonatomic, strong, readwrite) UIImageView *voiceSpeechImageView;
@property (nonatomic, strong) UIView                 *voicePanel;
@property (nonatomic, strong) UIView        *inputBar;
@property (nonatomic, strong) UIView        *roundContainer;
@property (nonatomic, strong) UIView        *previewRow;
@property (nonatomic, strong) UIScrollView  *previewScrollView;
@property (nonatomic, strong) NSMutableArray<UIImage *> *previewImages;
@property (nonatomic, strong) MASConstraint *inputBarBottomConstraint;
@property (nonatomic, strong) MASConstraint *inputBarHeightConstraint;
@property (nonatomic, strong) MASConstraint *chatScrollBottomConstraint;
@property (nonatomic, strong) MASConstraint *textViewHeightConstraint;
@property (nonatomic, strong) MASConstraint *roundContainerHeightConstraint;
@property (nonatomic, strong) MASConstraint *roundContainerCenterYConstraint;
@property (nonatomic, strong) MASConstraint *roundContainerTopConstraint;
@property (nonatomic, strong) MASConstraint *inputRowHeightConstraint;
@property (nonatomic, strong) MASConstraint *textViewRightConstraint;
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

    UIImageView *aiIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"aiAssistant"]];
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
    __block MASConstraint *roundContainerCenterYConstraint;
    __block MASConstraint *roundContainerTopConstraint;
    [_roundContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_inputBar).offset(16);
        make.right.equalTo(_inputBar).offset(-16);
        roundContainerCenterYConstraint = make.centerY.equalTo(_inputBar);
        roundContainerTopConstraint = make.top.equalTo(_inputBar).offset(8);
        roundContainerHeightConstraint = make.height.mas_equalTo(kInputBoxHeight);
    }];
    _roundContainerHeightConstraint = roundContainerHeightConstraint;
    _roundContainerCenterYConstraint = roundContainerCenterYConstraint;
    _roundContainerTopConstraint = roundContainerTopConstraint;
    [_roundContainerTopConstraint deactivate];

    // ── previewRow（roundContainer 顶部，图片选中后显示）──
    _previewRow = [[UIView alloc] init];
    _previewRow.hidden = YES;
    [_roundContainer addSubview:_previewRow];
    [_previewRow mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(_roundContainer);
        make.height.mas_equalTo(kPreviewAreaHeight);
    }];

    _previewScrollView = [[UIScrollView alloc] init];
    _previewScrollView.showsHorizontalScrollIndicator = NO;
    _previewScrollView.showsVerticalScrollIndicator   = NO;
    [_previewRow addSubview:_previewScrollView];
    [_previewScrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(4);
        make.left.mas_equalTo(16);
        make.right.mas_equalTo(-16);
        make.bottom.equalTo(_previewRow);
    }];

    _previewImages = [NSMutableArray array];

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

    // Send button（右侧，有内容时替换 mic+gallery）
    _sendButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_sendButton setImage:[UIImage imageNamed:@"iconSend"] forState:UIControlStateNormal];
    _sendButton.contentMode = UIViewContentModeScaleAspectFit;
    _sendButton.hidden = YES;
    [inputRow addSubview:_sendButton];
    [_sendButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(-14);
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
    __block MASConstraint *textViewRightConstraint;
    [_inputTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_cameraButton.mas_right).offset(6);
        textViewRightConstraint = make.right.equalTo(_micButton.mas_left).offset(-6);
        make.top.equalTo(_cameraButton.mas_top);
        self.textViewHeightConstraint = make.height.mas_equalTo(kTextViewBaseHeight);
    }];
    _textViewRightConstraint = textViewRightConstraint;

    // ── voicePanel（roundContainer 下方，语音模式时展开）──
    _voicePanel = [[UIView alloc] init];
    _voicePanel.hidden = YES;
    [_inputBar addSubview:_voicePanel];
    [_voicePanel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_roundContainer.mas_bottom);
        make.left.right.equalTo(_inputBar);
        make.height.mas_equalTo(kVoicePanelHeight);
    }];

    // 语音图标
    _voiceSpeechImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"iconSpeechInput"]];
    _voiceSpeechImageView.contentMode = UIViewContentModeScaleAspectFit;
    _voiceSpeechImageView.userInteractionEnabled = YES;
    [_voicePanel addSubview:_voiceSpeechImageView];
    [_voiceSpeechImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(_voicePanel);
        make.top.mas_equalTo(20);
        make.width.height.mas_equalTo(110);
    }];

}

#pragma mark - Send Button Visibility

- (void)tl_updateSendButtonVisibility {
    BOOL hasContent = (_inputTextField.text.length > 0) || (_previewImages.count > 0);
    if (hasContent) {
        _micButton.hidden    = YES;
        _galleryButton.hidden = YES;
        _sendButton.hidden   = NO;
        [_textViewRightConstraint uninstall];
        [_inputTextField mas_updateConstraints:^(MASConstraintMaker *make) {
            self->_textViewRightConstraint = make.right.equalTo(self->_sendButton.mas_left).offset(-6);
        }];
    } else {
        _micButton.hidden    = NO;
        _galleryButton.hidden = NO;
        _sendButton.hidden   = YES;
        [_textViewRightConstraint uninstall];
        [_inputTextField mas_updateConstraints:^(MASConstraintMaker *make) {
            self->_textViewRightConstraint = make.right.equalTo(self->_micButton.mas_left).offset(-6);
        }];
    }
    [self setNeedsLayout];
}

#pragma mark - Height update

- (void)tl_updateInputBarHeight {
    CGFloat inputBoxVerticalPadding = (kRoundBaseHeight - kInputBoxHeight) / 2.0;
    CGFloat textViewExtra        = _currentTextViewHeight - kTextViewBaseHeight;
    CGFloat previewExtra         = _previewRow.hidden ? 0 : kPreviewAreaHeight;
    CGFloat voiceExtra           = _voicePanel.hidden ? 0 : kVoicePanelHeight;
    CGFloat inputRowHeight       = kInputBoxHeight + textViewExtra;
    CGFloat roundContainerHeight = inputRowHeight + previewExtra;
    CGFloat inputBarHeight       = roundContainerHeight + _safeBottomInset + inputBoxVerticalPadding * 2 + voiceExtra;

    _inputRowHeightConstraint.offset       = inputRowHeight;
    _roundContainerHeightConstraint.offset = roundContainerHeight;
    _inputBarHeightConstraint.offset       = inputBarHeight;
    _chatScrollBottomConstraint.offset     = -(inputBarHeight + _keyboardHeight);
}

#pragma mark - Voice Panel

- (void)showVoicePanel {
    _voicePanel.hidden = NO;
    [_roundContainerCenterYConstraint deactivate];
    [_roundContainerTopConstraint activate];
    [self tl_updateInputBarHeight];
    [UIView animateWithDuration:0.25 animations:^{
        [self layoutIfNeeded];
    }];
}

- (void)hideVoicePanel {
    _voicePanel.hidden = YES;
    [_roundContainerTopConstraint deactivate];
    [_roundContainerCenterYConstraint activate];
    [self tl_updateInputBarHeight];
    [UIView animateWithDuration:0.25 animations:^{
        [self layoutIfNeeded];
    }];
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

    [self tl_updateSendButtonVisibility];
    [self tl_updateInputBarHeight];
    [UIView animateWithDuration:0.15 animations:^{
        [self layoutIfNeeded];
    }];
}

#pragma mark - Image Preview

- (void)showSelectedImage:(UIImage *)image {
    [self showSelectedImages:@[image]];
}

- (void)showSelectedImages:(NSArray<UIImage *> *)images {
    [_previewImages removeAllObjects];
    [_previewImages addObjectsFromArray:images];
    [self tl_rebuildPreviewThumbnails];
    _previewRow.hidden = NO;
    [self tl_updateSendButtonVisibility];
    [self tl_updateInputBarHeight];
    [UIView animateWithDuration:0.2 animations:^{
        [self layoutIfNeeded];
    }];
}

- (void)hideSelectedImage {
    _previewRow.hidden = YES;
    [_previewImages removeAllObjects];
    [_previewScrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self tl_updateSendButtonVisibility];
    [self tl_updateInputBarHeight];
    [UIView animateWithDuration:0.2 animations:^{
        [self layoutIfNeeded];
    }];
}

- (void)tl_rebuildPreviewThumbnails {
    [_previewScrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];

    CGFloat thumbSize = 80;
    CGFloat gap       = 10;
    CGFloat topInset  = 4;

    for (NSUInteger i = 0; i < _previewImages.count; i++) {
        CGFloat x = i * (thumbSize + gap);

        // 缩略图
        UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(x, topInset, thumbSize, thumbSize)];
        imgView.image = _previewImages[i];
        imgView.contentMode = UIViewContentModeScaleAspectFill;
        imgView.clipsToBounds = YES;
        imgView.layer.cornerRadius = 8;
        imgView.userInteractionEnabled = YES;
        imgView.tag = 1000 + (NSInteger)i;
        [_previewScrollView addSubview:imgView];

        // 点击大图预览
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                              action:@selector(tl_previewThumbnailTapped:)];
        [imgView addGestureRecognizer:tap];

        // × 删除按钮
        UIButton *removeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        removeBtn.frame = CGRectMake(x + thumbSize - 18, topInset, 20, 20);
        [removeBtn setTitle:@"×" forState:UIControlStateNormal];
        [removeBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        removeBtn.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
        removeBtn.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
        removeBtn.layer.cornerRadius = 10;
        removeBtn.tag = 2000 + (NSInteger)i;
        [removeBtn addTarget:self action:@selector(tl_removePreviewImage:) forControlEvents:UIControlEventTouchUpInside];
        [_previewScrollView addSubview:removeBtn];
    }

    CGFloat totalW = _previewImages.count * (thumbSize + gap) - gap;
    _previewScrollView.contentSize = CGSizeMake(MAX(totalW, 0), thumbSize + topInset);
}

- (void)tl_removePreviewImage:(UIButton *)sender {
    NSUInteger index = (NSUInteger)(sender.tag - 2000);
    if (index >= _previewImages.count) return;

    [_previewImages removeObjectAtIndex:index];

    if (_previewImages.count == 0) {
        [self hideSelectedImage];
    } else {
        [self tl_rebuildPreviewThumbnails];
    }

    if (self.onRemoveImageAtIndex) {
        self.onRemoveImageAtIndex(index);
    }
}

- (void)tl_previewThumbnailTapped:(UITapGestureRecognizer *)tap {
    NSUInteger index = (NSUInteger)(tap.view.tag - 1000);
    if (index >= _previewImages.count) return;

    UIImage *image = _previewImages[index];
    UIWindow *window = UIApplication.sharedApplication.windows.firstObject;

    UIView *overlay = [[UIView alloc] initWithFrame:window.bounds];
    overlay.backgroundColor = [UIColor colorWithWhite:0 alpha:0.9];

    UIImageView *fullImageView = [[UIImageView alloc] init];
    fullImageView.image = image;
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
