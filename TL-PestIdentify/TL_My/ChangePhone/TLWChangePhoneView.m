//
//  TLWChangePhoneView.m
//  TL-PestIdentify
//

#import "TLWChangePhoneView.h"
#import <Masonry/Masonry.h>

@interface TLWChangePhoneView ()

@property (nonatomic, strong, readwrite) UIButton    *backButton;
@property (nonatomic, strong, readwrite) UILabel     *currentPhoneLabel;
@property (nonatomic, strong, readwrite) UITextField *phoneField;
@property (nonatomic, strong, readwrite) UITextField *codeField;
@property (nonatomic, strong, readwrite) UIButton    *sendCodeButton;
@property (nonatomic, strong, readwrite) UIButton    *confirmButton;

@end

@implementation TLWChangePhoneView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) [self setupUI];
    return self;
}

- (void)setupUI {
    // 背景
    UIImageView *bg = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bgGradient"]];
    bg.contentMode = UIViewContentModeScaleAspectFill;
    [self addSubview:bg];
    [bg mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];

    [self setupNavBar];
    [self setupPanel];
    [self setupCard];
}

#pragma mark - Nav Bar

- (void)setupNavBar {
    _backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_backButton setImage:[UIImage imageNamed:@"iconBack"] forState:UIControlStateNormal];
    [self addSubview:_backButton];
    [_backButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self).offset(16);
        make.top.equalTo(self.mas_safeAreaLayoutGuideTop).offset(8);
        make.width.height.mas_equalTo(44);
    }];

    UILabel *title = [UILabel new];
    title.text      = @"换绑手机号";
    title.textColor = UIColor.whiteColor;
    title.font      = [UIFont systemFontOfSize:20 weight:UIFontWeightSemibold];
    [self addSubview:title];
    [title mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self);
        make.centerY.equalTo(_backButton);
    }];
}

#pragma mark - Panel

- (void)setupPanel {
    UIVisualEffectView *panelBlur = [[UIVisualEffectView alloc] initWithEffect:
                                     [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight]];
    panelBlur.layer.cornerRadius  = 28;
    panelBlur.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
    panelBlur.layer.masksToBounds = YES;
    [self addSubview:panelBlur];
    [panelBlur mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_backButton.mas_bottom).offset(10);
        make.left.right.bottom.equalTo(self);
    }];

    UIView *panelOverlay = [UIView new];
    panelOverlay.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.82];
    [panelBlur.contentView addSubview:panelOverlay];
    [panelOverlay mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(panelBlur.contentView);
    }];
}

#pragma mark - Card

- (void)setupCard {
    UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    UIVisualEffectView *card = [[UIVisualEffectView alloc] initWithEffect:blur];
    card.layer.cornerRadius  = 20;
    card.layer.masksToBounds = YES;

    UIView *overlay = [UIView new];
    overlay.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.65];
    [card.contentView addSubview:overlay];
    [overlay mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(card.contentView);
    }];

    [self addSubview:card];
    [card mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_backButton.mas_bottom).offset(24);
        make.left.equalTo(self).offset(16);
        make.right.equalTo(self).offset(-16);
    }];

    UIView *content = card.contentView;

    // 当前手机号
    UILabel *currentTitle = [UILabel new];
    currentTitle.text      = @"当前绑定手机号";
    currentTitle.font      = [UIFont systemFontOfSize:14];
    currentTitle.textColor = [UIColor colorWithWhite:0.45 alpha:1];
    [content addSubview:currentTitle];
    [currentTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(content).offset(24);
        make.left.equalTo(content).offset(20);
    }];

    _currentPhoneLabel = [UILabel new];
    _currentPhoneLabel.font      = [UIFont systemFontOfSize:18 weight:UIFontWeightMedium];
    _currentPhoneLabel.textColor = [UIColor colorWithRed:0.20 green:0.20 blue:0.20 alpha:1];
    _currentPhoneLabel.text      = @"未绑定";
    [content addSubview:_currentPhoneLabel];
    [_currentPhoneLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(currentTitle.mas_bottom).offset(6);
        make.left.equalTo(content).offset(20);
    }];

    // 分隔线
    UIView *sep = [UIView new];
    sep.backgroundColor = [UIColor colorWithWhite:0.88 alpha:1];
    [content addSubview:sep];
    [sep mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_currentPhoneLabel.mas_bottom).offset(20);
        make.left.equalTo(content).offset(20);
        make.right.equalTo(content).offset(-20);
        make.height.mas_equalTo(0.5);
    }];

    // 新手机号
    UILabel *newTitle = [UILabel new];
    newTitle.text      = @"新手机号";
    newTitle.font      = [UIFont systemFontOfSize:14];
    newTitle.textColor = [UIColor colorWithWhite:0.45 alpha:1];
    [content addSubview:newTitle];
    [newTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(sep.mas_bottom).offset(20);
        make.left.equalTo(content).offset(20);
    }];

    _phoneField = [self buildTextFieldWithPlaceholder:@"请输入新手机号" keyboard:UIKeyboardTypePhonePad];
    [content addSubview:_phoneField];
    [_phoneField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(newTitle.mas_bottom).offset(8);
        make.left.equalTo(content).offset(20);
        make.right.equalTo(content).offset(-20);
        make.height.mas_equalTo(48);
    }];

    // 验证码行
    UILabel *codeTitle = [UILabel new];
    codeTitle.text      = @"验证码";
    codeTitle.font      = [UIFont systemFontOfSize:14];
    codeTitle.textColor = [UIColor colorWithWhite:0.45 alpha:1];
    [content addSubview:codeTitle];
    [codeTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_phoneField.mas_bottom).offset(16);
        make.left.equalTo(content).offset(20);
    }];

    _codeField = [self buildTextFieldWithPlaceholder:@"请输入验证码" keyboard:UIKeyboardTypeNumberPad];
    [content addSubview:_codeField];
    [_codeField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(codeTitle.mas_bottom).offset(8);
        make.left.equalTo(content).offset(20);
        make.right.equalTo(content).offset(-130);
        make.height.mas_equalTo(48);
    }];

    // 发送验证码按钮
    _sendCodeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _sendCodeButton.layer.cornerRadius = 24;
    _sendCodeButton.clipsToBounds      = YES;
    _sendCodeButton.titleLabel.font    = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    [_sendCodeButton setTitle:@"发送验证码" forState:UIControlStateNormal];
    [_sendCodeButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    [_sendCodeButton setTitleColor:[UIColor colorWithWhite:1 alpha:0.5] forState:UIControlStateDisabled];
    _sendCodeButton.backgroundColor = [UIColor colorWithRed:0.97 green:0.60 blue:0.15 alpha:1.0];
    [content addSubview:_sendCodeButton];
    [_sendCodeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(_codeField);
        make.right.equalTo(content).offset(-20);
        make.width.mas_equalTo(104);
        make.height.mas_equalTo(48);
    }];

    // 确认按钮
    _confirmButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _confirmButton.layer.cornerRadius = 14;
    _confirmButton.clipsToBounds      = YES;

    UIImage *commitBg = [[UIImage imageNamed:@"commitRectangle"]
                         resizableImageWithCapInsets:UIEdgeInsetsMake(0, 40, 0, 40)
                         resizingMode:UIImageResizingModeStretch];
    [_confirmButton setBackgroundImage:commitBg forState:UIControlStateNormal];

    UILabel *confirmLabel = [UILabel new];
    confirmLabel.text                   = @"确认换绑";
    confirmLabel.textColor              = UIColor.whiteColor;
    confirmLabel.font                   = [UIFont systemFontOfSize:18 weight:UIFontWeightSemibold];
    confirmLabel.userInteractionEnabled = NO;
    [_confirmButton addSubview:confirmLabel];
    [confirmLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(_confirmButton);
    }];

    [content addSubview:_confirmButton];
    [_confirmButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_codeField.mas_bottom).offset(32);
        make.left.equalTo(content).offset(20);
        make.right.equalTo(content).offset(-20);
        make.height.mas_equalTo(52);
        make.bottom.equalTo(content).offset(-24);
    }];
}

#pragma mark - Helpers

- (UITextField *)buildTextFieldWithPlaceholder:(NSString *)placeholder keyboard:(UIKeyboardType)type {
    UITextField *tf = [[UITextField alloc] init];
    tf.placeholder       = placeholder;
    tf.font              = [UIFont systemFontOfSize:16];
    tf.textColor         = [UIColor colorWithRed:0.20 green:0.20 blue:0.20 alpha:1];
    tf.backgroundColor   = [UIColor colorWithWhite:0.96 alpha:1];
    tf.layer.cornerRadius = 12;
    tf.keyboardType      = type;
    tf.clearButtonMode   = UITextFieldViewModeWhileEditing;

    UIView *left = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 14, 1)];
    tf.leftView     = left;
    tf.leftViewMode = UITextFieldViewModeAlways;
    return tf;
}

@end
