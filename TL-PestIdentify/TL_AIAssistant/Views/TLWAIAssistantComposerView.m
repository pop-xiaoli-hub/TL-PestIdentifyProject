//
//  TLWAIAssistantComposerView.m
//  TL-PestIdentify
//
//  Created by Northern Lights on 2026/4/3.
//  职责：实现AI助手页面视图组件。
//
#import "TLWAIAssistantComposerView.h"
#import <Masonry/Masonry.h>

static CGFloat const kRoundBaseHeight = 53.0;
static CGFloat const kInputBoxHeight = 54.0;
static CGFloat const kTextViewBaseHeight = 34.0;
static CGFloat const kPreviewAreaHeight = 96.0;
static CGFloat const kVoicePanelHeight = 180.0;
static CGFloat const kPlusPanelHeight = 120.0;

@interface TLWAIAssistantComposerView () <UITextViewDelegate>
@property (nonatomic, strong, readwrite) UITextView *inputTextField;
@property (nonatomic, strong, readwrite) UIButton *cameraButton;
@property (nonatomic, strong, readwrite) UIButton *micButton;
@property (nonatomic, strong, readwrite) UIButton *plusButton;
@property (nonatomic, strong, readwrite) UIButton *sendButton;
@property (nonatomic, strong, readwrite) UIImageView *voiceSpeechImageView;
@property (nonatomic, strong, readwrite) UIButton *plusCameraButton;
@property (nonatomic, strong, readwrite) UIButton *plusAlbumButton;
@property (nonatomic, strong, readwrite) UIButton *plusAICallButton;
@property (nonatomic, strong, readwrite) UIButton *stopButton;
@property (nonatomic, assign) BOOL isAILoading;
@property (nonatomic, strong) MASConstraint *plusButtonRightConstraint;
@property (nonatomic, strong) UIView *inputBar;
@property (nonatomic, strong) UIView *voicePanel;
@property (nonatomic, strong) UIView *plusPanel;
@property (nonatomic, strong) UIView *roundContainer;
@property (nonatomic, strong) UIView *sendButtonWrapper;
@property (nonatomic, strong) UIView *previewRow;
@property (nonatomic, strong) UIScrollView *previewScrollView;
@property (nonatomic, strong) NSMutableArray<UIImage *> *previewImages;
@property (nonatomic, strong) MASConstraint *inputBarHeightConstraint;
@property (nonatomic, strong) MASConstraint *textViewHeightConstraint;
@property (nonatomic, strong) MASConstraint *roundContainerHeightConstraint;
@property (nonatomic, strong) MASConstraint *roundContainerCenterYConstraint;
@property (nonatomic, strong) MASConstraint *roundContainerTopConstraint;
@property (nonatomic, strong) MASConstraint *inputRowHeightConstraint;
@property (nonatomic, strong) MASConstraint *textViewRightConstraint;
@property (nonatomic, strong) MASConstraint *roundContainerRightConstraint;
@property (nonatomic, assign) CGFloat safeBottomInset;
@property (nonatomic, assign) CGFloat currentTextViewHeight;
@property (nonatomic, assign, readwrite) CGFloat preferredHeight;
@end

@implementation TLWAIAssistantComposerView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _safeBottomInset = [self tl_initialSafeBottomInset];
        _currentTextViewHeight = kTextViewBaseHeight;
        _preferredHeight = kRoundBaseHeight + _safeBottomInset;
        _previewImages = [NSMutableArray array];
        [self tl_setupViews];
        [self tl_updateInputBarHeight];
    }
    return self;
}

- (void)tl_setupViews {
    self.inputBar = [[UIView alloc] init];
    [self addSubview:self.inputBar];
    __block MASConstraint *inputBarHeightConstraint;
    [_inputBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
        inputBarHeightConstraint = make.height.mas_equalTo(self.preferredHeight);
    }];
    _inputBarHeightConstraint = inputBarHeightConstraint;

    UIImageView *frameBg = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"chatFrame"]];
    frameBg.contentMode = UIViewContentModeScaleToFill;
    [_inputBar addSubview:frameBg];
    [frameBg mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self->_inputBar);
    }];

    _sendButtonWrapper = [[UIView alloc] init];
    _sendButtonWrapper.backgroundColor = [UIColor whiteColor];
    _sendButtonWrapper.layer.cornerRadius = kInputBoxHeight / 2.0;
    _sendButtonWrapper.layer.masksToBounds = YES;
    _sendButtonWrapper.hidden = YES;
    _sendButtonWrapper.userInteractionEnabled = YES;
    [_inputBar addSubview:_sendButtonWrapper];
    UIView *sendButtonWrapper = _sendButtonWrapper;
    [sendButtonWrapper mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self->_inputBar).offset(-16);
        make.centerY.equalTo(self->_inputBar);
        make.width.height.mas_equalTo(kInputBoxHeight);
    }];

    _sendButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_sendButton setImage:[UIImage imageNamed:@"iconSend"] forState:UIControlStateNormal];
    _sendButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    _sendButton.clipsToBounds = YES;
    [sendButtonWrapper addSubview:_sendButton];
    [_sendButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(sendButtonWrapper);
        make.width.height.mas_equalTo(30);
    }];

    _roundContainer = [[UIView alloc] init];
    _roundContainer.backgroundColor = [UIColor whiteColor];
    _roundContainer.layer.cornerRadius = kInputBoxHeight / 2.0;
    _roundContainer.layer.masksToBounds = YES;
    [_inputBar addSubview:_roundContainer];
    __block MASConstraint *roundContainerHeightConstraint;
    __block MASConstraint *roundContainerCenterYConstraint;
    __block MASConstraint *roundContainerTopConstraint;
    __block MASConstraint *roundContainerRightConstraint;
    [_roundContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self->_inputBar).offset(16);
        roundContainerRightConstraint = make.right.equalTo(self->_inputBar).offset(-16);
        roundContainerCenterYConstraint = make.centerY.equalTo(self->_inputBar);
        roundContainerTopConstraint = make.top.equalTo(self->_inputBar).offset(8);
        roundContainerHeightConstraint = make.height.mas_equalTo(kInputBoxHeight);
    }];
    _roundContainerHeightConstraint = roundContainerHeightConstraint;
    _roundContainerCenterYConstraint = roundContainerCenterYConstraint;
    _roundContainerTopConstraint = roundContainerTopConstraint;
    _roundContainerRightConstraint = roundContainerRightConstraint;
    [_roundContainerTopConstraint deactivate];

    _previewRow = [[UIView alloc] init];
    _previewRow.hidden = YES;
    [_roundContainer addSubview:_previewRow];
    [_previewRow mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self->_roundContainer);
        make.height.mas_equalTo(kPreviewAreaHeight);
    }];

    _previewScrollView = [[UIScrollView alloc] init];
    _previewScrollView.showsHorizontalScrollIndicator = NO;
    _previewScrollView.showsVerticalScrollIndicator = NO;
    [_previewRow addSubview:_previewScrollView];
    [_previewScrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(4);
        make.left.mas_equalTo(16);
        make.right.mas_equalTo(-16);
        make.bottom.equalTo(self->_previewRow);
    }];

    UIView *inputRow = [[UIView alloc] init];
    inputRow.backgroundColor = [UIColor clearColor];
    [_roundContainer addSubview:inputRow];
    __block MASConstraint *inputRowHeightConstraint;
    [inputRow mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self->_roundContainer);
        inputRowHeightConstraint = make.height.mas_equalTo(kInputBoxHeight);
    }];
    _inputRowHeightConstraint = inputRowHeightConstraint;

    _cameraButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_cameraButton setImage:[UIImage imageNamed:@"iconCamera"] forState:UIControlStateNormal];
    _cameraButton.contentMode = UIViewContentModeScaleAspectFit;
    [inputRow addSubview:_cameraButton];
    [_cameraButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(14);
        make.centerY.equalTo(inputRow);
        make.width.height.mas_equalTo(24);
    }];

    _plusButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_plusButton setImage:[UIImage imageNamed:@"plus"] forState:UIControlStateNormal];
    _plusButton.contentMode = UIViewContentModeScaleAspectFit;
    [inputRow addSubview:_plusButton];
    __block MASConstraint *plusButtonRightConstraint;
    [_plusButton mas_makeConstraints:^(MASConstraintMaker *make) {
        plusButtonRightConstraint = make.right.mas_equalTo(-10);
        make.centerY.equalTo(inputRow);
        make.width.height.mas_equalTo(30);
    }];
    _plusButtonRightConstraint = plusButtonRightConstraint;

    _stopButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_stopButton setImage:[UIImage imageNamed:@"iconStop"] forState:UIControlStateNormal];
    _stopButton.contentMode = UIViewContentModeScaleAspectFit;
    _stopButton.hidden = YES;
    [inputRow addSubview:_stopButton];
    [_stopButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(-10);
        make.centerY.equalTo(inputRow);
        make.width.height.mas_equalTo(30);
    }];

    _micButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_micButton setImage:[UIImage imageNamed:@"iconMicrophone"] forState:UIControlStateNormal];
    _micButton.contentMode = UIViewContentModeScaleAspectFit;
    [inputRow addSubview:_micButton];
    [_micButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self->_plusButton.mas_left).offset(-8);
        make.centerY.equalTo(inputRow);
        make.width.height.mas_equalTo(24);
    }];

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
        make.left.equalTo(self->_cameraButton.mas_right).offset(6);
        textViewRightConstraint = make.right.equalTo(self->_micButton.mas_left).offset(-6);
        make.top.equalTo(self->_cameraButton.mas_top);
        self.textViewHeightConstraint = make.height.mas_equalTo(kTextViewBaseHeight);
    }];
    _textViewRightConstraint = textViewRightConstraint;

    _voicePanel = [[UIView alloc] init];
    _voicePanel.hidden = YES;
    [_inputBar addSubview:_voicePanel];
    [_voicePanel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self->_roundContainer.mas_bottom);
        make.left.right.equalTo(self->_inputBar);
        make.height.mas_equalTo(kVoicePanelHeight);
    }];

    _voiceSpeechImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"iconSpeechInput"]];
    _voiceSpeechImageView.contentMode = UIViewContentModeScaleAspectFit;
    _voiceSpeechImageView.userInteractionEnabled = YES;
    [_voicePanel addSubview:_voiceSpeechImageView];
    [_voiceSpeechImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self->_voicePanel);
        make.top.mas_equalTo(20);
        make.width.height.mas_equalTo(110);
    }];

    // Plus 面板
    _plusPanel = [[UIView alloc] init];
    _plusPanel.hidden = YES;
    [_inputBar addSubview:_plusPanel];
    [_plusPanel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self->_roundContainer.mas_bottom).offset(8);
        make.left.right.equalTo(self->_inputBar);
        make.height.mas_equalTo(kPlusPanelHeight);
    }];

    _plusCameraButton = [self tl_createPlusPanelButtonWithImage:@"plusCamera" title:@"相机"];
    _plusAlbumButton = [self tl_createPlusPanelButtonWithImage:@"plusAlbum" title:@"相册"];
    _plusAICallButton = [self tl_createPlusPanelButtonWithImage:@"plusAICall" title:@"AI通话"];

    [_plusPanel addSubview:_plusCameraButton];
    [_plusPanel addSubview:_plusAlbumButton];
    [_plusPanel addSubview:_plusAICallButton];

    CGFloat btnSize = 70;
    CGFloat btnGap = 26;
    [_plusCameraButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(24);
        make.top.mas_equalTo(4);
        make.width.mas_equalTo(btnSize);
    }];
    [_plusAlbumButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self->_plusCameraButton.mas_right).offset(btnGap);
        make.top.equalTo(self->_plusCameraButton);
        make.width.mas_equalTo(btnSize);
    }];
    [_plusAICallButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self->_plusAlbumButton.mas_right).offset(btnGap);
        make.top.equalTo(self->_plusCameraButton);
        make.width.mas_equalTo(btnSize);
    }];
}

- (UIButton *)tl_createPlusPanelButtonWithImage:(NSString *)imageName title:(NSString *)title {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];

    UIImageView *iconView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:imageName]];
    iconView.contentMode = UIViewContentModeScaleAspectFit;
    iconView.tag = 100;
    [btn addSubview:iconView];
    [iconView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(btn);
        make.centerX.equalTo(btn);
        make.width.height.mas_equalTo(70);
    }];

    UILabel *label = [[UILabel alloc] init];
    label.text = title;
    label.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
    label.textColor = [UIColor whiteColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.tag = 101;
    [btn addSubview:label];
    [label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(iconView.mas_bottom).offset(4);
        make.centerX.equalTo(btn);
        make.bottom.equalTo(btn);
    }];

    return btn;
}

- (void)layoutSubviews {
    [super layoutSubviews];
}

- (void)safeAreaInsetsDidChange {
    [super safeAreaInsetsDidChange];
    CGFloat newInset = self.safeAreaInsets.bottom;
    // 键盘弹起时系统可能把 safeBottom 变为 0，这里忽略，避免输入区高度突然缩小。
    if (newInset <= 0) return;
    if (ABS(newInset - self.safeBottomInset) < 0.5) return;
    self.safeBottomInset = newInset;
    [self tl_updateInputBarHeight];
    [self setNeedsLayout];
}

- (void)setInputText:(NSString *)text {
    self.inputTextField.text = text ?: @"";
    [self tl_refreshInputArea];
}

- (void)showSelectedImage:(UIImage *)image {
    [self showSelectedImages:@[image]];
}

- (void)showSelectedImages:(NSArray<UIImage *> *)images {
    [self.previewImages removeAllObjects];
    [self.previewImages addObjectsFromArray:images];
    [self tl_rebuildPreviewThumbnails];
    self.previewRow.hidden = NO;
    [self tl_updateSendButtonVisibility];
    [self tl_updateInputBarHeight];
    [UIView animateWithDuration:0.2 animations:^{
        [self layoutIfNeeded];
    }];
}

- (void)hideSelectedImage {
    self.previewRow.hidden = YES;
    [self.previewImages removeAllObjects];
    [self.previewScrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self tl_updateSendButtonVisibility];
    [self tl_updateInputBarHeight];
    [UIView animateWithDuration:0.2 animations:^{
        [self layoutIfNeeded];
    }];
}

- (void)showVoicePanel {
    self.voicePanel.hidden = NO;
    // 互斥：收起 plus 面板
    self.plusPanel.hidden = YES;
    [self.roundContainerCenterYConstraint deactivate];
    [self.roundContainerTopConstraint activate];
    [self tl_updateInputBarHeight];
    [UIView animateWithDuration:0.25 animations:^{
        [self layoutIfNeeded];
    }];
}

- (void)hideVoicePanel {
    self.voicePanel.hidden = YES;
    [self.roundContainerTopConstraint deactivate];
    [self.roundContainerCenterYConstraint activate];
    [self tl_updateInputBarHeight];
    [UIView animateWithDuration:0.25 animations:^{
        [self layoutIfNeeded];
    }];
}

- (void)showPlusPanel {
    self.plusPanel.hidden = NO;
    // 互斥：收起语音面板
    if (!self.voicePanel.hidden) {
        self.voicePanel.hidden = YES;
    }
    [self.roundContainerCenterYConstraint deactivate];
    [self.roundContainerTopConstraint activate];
    [self tl_updateInputBarHeight];
    [UIView animateWithDuration:0.25 animations:^{
        [self layoutIfNeeded];
    }];
}

- (void)hidePlusPanel {
    self.plusPanel.hidden = YES;
    [self.roundContainerTopConstraint deactivate];
    [self.roundContainerCenterYConstraint activate];
    [self tl_updateInputBarHeight];
    [UIView animateWithDuration:0.25 animations:^{
        [self layoutIfNeeded];
    }];
}

- (BOOL)isPlusPanelVisible {
    return !self.plusPanel.hidden;
}

- (void)enterAILoadingMode {
    self.isAILoading = YES;
    self.micButton.hidden = YES;
    self.stopButton.hidden = NO;
    // plus 移到 mic 的位置（stop 右侧偏左）
    self.plusButtonRightConstraint.offset = -(10 + 30 + 8);
    [UIView animateWithDuration:0.2 animations:^{
        [self layoutIfNeeded];
    }];
}

- (void)exitAILoadingMode {
    self.isAILoading = NO;
    self.micButton.hidden = NO;
    self.stopButton.hidden = YES;
    // plus 恢复原位
    self.plusButtonRightConstraint.offset = -10;
    [UIView animateWithDuration:0.2 animations:^{
        [self layoutIfNeeded];
    }];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if ([text isEqualToString:@"\n"]) {
        [textView insertText:@"\n"];
        return NO;
    }
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView {
    [self tl_refreshInputArea];
}

- (void)tl_refreshInputArea {
    UITextView *textView = self.inputTextField;
    CGSize size = [textView sizeThatFits:CGSizeMake(textView.frame.size.width, MAXFLOAT)];
    BOOL shouldScroll = size.height > 45;
    textView.scrollEnabled = shouldScroll;
    self.currentTextViewHeight = MAX(kTextViewBaseHeight, MIN(45, size.height));
    self.textViewHeightConstraint.offset = self.currentTextViewHeight;

    [self tl_updateSendButtonVisibility];
    [self tl_updateInputBarHeight];
    [UIView animateWithDuration:0.15 animations:^{
        [self layoutIfNeeded];
    }];
}

- (void)tl_updateSendButtonVisibility {
    BOOL hasContent = (self.inputTextField.text.length > 0) || (self.previewImages.count > 0);
    if (hasContent) {
        self.micButton.hidden = YES;
        self.plusButton.hidden = YES;
        self.sendButtonWrapper.hidden = NO;
        [self.inputBar bringSubviewToFront:self.sendButtonWrapper];
        self.roundContainerRightConstraint.offset = -(16 + kInputBoxHeight + 8);
        [self.textViewRightConstraint uninstall];
        [self.inputTextField mas_updateConstraints:^(MASConstraintMaker *make) {
            self.textViewRightConstraint = make.right.equalTo(self.roundContainer).offset(-14);
        }];
    } else {
        self.micButton.hidden = self.isAILoading;
        self.stopButton.hidden = !self.isAILoading;
        self.plusButton.hidden = NO;
        self.sendButtonWrapper.hidden = YES;
        self.roundContainerRightConstraint.offset = -16;
        [self.textViewRightConstraint uninstall];
        UIView *rightAnchor = self.isAILoading ? self.plusButton : self.micButton;
        [self.inputTextField mas_updateConstraints:^(MASConstraintMaker *make) {
            self.textViewRightConstraint = make.right.equalTo(rightAnchor.mas_left).offset(-6);
        }];
    }
    [self setNeedsLayout];
}

- (void)tl_updateInputBarHeight {
    CGFloat inputBoxVerticalPadding = (kRoundBaseHeight - kInputBoxHeight) / 2.0;
    CGFloat textViewExtra = self.currentTextViewHeight - kTextViewBaseHeight;
    CGFloat previewExtra = self.previewRow.hidden ? 0 : kPreviewAreaHeight;
    CGFloat voiceExtra = self.voicePanel.hidden ? 0 : kVoicePanelHeight;
    CGFloat plusExtra = self.plusPanel.hidden ? 0 : (kPlusPanelHeight + 8);
    CGFloat inputRowHeight = kInputBoxHeight + textViewExtra;
    CGFloat roundContainerHeight = inputRowHeight + previewExtra;
    CGFloat inputBarHeight = roundContainerHeight + self.safeBottomInset + inputBoxVerticalPadding * 2 + voiceExtra + plusExtra;

    self.inputRowHeightConstraint.offset = inputRowHeight;
    self.roundContainerHeightConstraint.offset = roundContainerHeight;
    self.inputBarHeightConstraint.offset = inputBarHeight;
    self.preferredHeight = inputBarHeight;
    if (self.onHeightDidChange) {
        self.onHeightDidChange(inputBarHeight);
    }
}

- (void)tl_rebuildPreviewThumbnails {
    [self.previewScrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];

    CGFloat thumbSize = 80;
    CGFloat gap = 10;
    CGFloat topInset = 4;

    for (NSUInteger i = 0; i < self.previewImages.count; i++) {
        CGFloat x = i * (thumbSize + gap);

        UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(x, topInset, thumbSize, thumbSize)];
        imgView.image = self.previewImages[i];
        imgView.contentMode = UIViewContentModeScaleAspectFill;
        imgView.clipsToBounds = YES;
        imgView.layer.cornerRadius = 8;
        imgView.userInteractionEnabled = YES;
        imgView.tag = 1000 + (NSInteger)i;
        [self.previewScrollView addSubview:imgView];

        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tl_previewThumbnailTapped:)];
        [imgView addGestureRecognizer:tap];

        UIButton *removeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        removeBtn.frame = CGRectMake(x + thumbSize - 18, topInset, 20, 20);
        [removeBtn setTitle:@"×" forState:UIControlStateNormal];
        [removeBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        removeBtn.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
        removeBtn.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
        removeBtn.layer.cornerRadius = 10;
        removeBtn.tag = 2000 + (NSInteger)i;
        [removeBtn addTarget:self action:@selector(tl_removePreviewImage:) forControlEvents:UIControlEventTouchUpInside];
        [self.previewScrollView addSubview:removeBtn];
    }

    CGFloat totalW = self.previewImages.count * (thumbSize + gap) - gap;
    self.previewScrollView.contentSize = CGSizeMake(MAX(totalW, 0), thumbSize + topInset);
}

- (void)tl_removePreviewImage:(UIButton *)sender {
    NSUInteger index = (NSUInteger)(sender.tag - 2000);
    if (index >= self.previewImages.count) return;

    [self.previewImages removeObjectAtIndex:index];
    if (self.previewImages.count == 0) {
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
    if (index >= self.previewImages.count) return;

    UIImage *image = self.previewImages[index];
    UIWindow *window = [self tl_activeWindow];

    UIView *overlay = [[UIView alloc] initWithFrame:window.bounds];
    overlay.backgroundColor = [UIColor colorWithWhite:0 alpha:0.9];

    UIImageView *fullImageView = [[UIImageView alloc] init];
    fullImageView.image = image;
    fullImageView.contentMode = UIViewContentModeScaleAspectFit;
    CGFloat padding = 20;
    fullImageView.frame = CGRectMake(padding, 80, window.bounds.size.width - padding * 2, window.bounds.size.height - 160);
    [overlay addSubview:fullImageView];

    UITapGestureRecognizer *dismiss = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tl_dismissFullscreenPreview:)];
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

- (CGFloat)tl_initialSafeBottomInset {
    UIWindow *window = [self tl_activeWindow];
    CGFloat inset = window.safeAreaInsets.bottom;
    if (inset > 0) return inset;
    return self.safeAreaInsets.bottom;
}

@end
