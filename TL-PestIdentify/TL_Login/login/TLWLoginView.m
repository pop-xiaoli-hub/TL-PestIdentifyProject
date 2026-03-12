//
//  TLWLoginView.m
//  TL-PestIdentify
//
//  Created by 吴桐 on 2026/3/12.
//

#import "TLWLoginView.h"
#import <Masonry/Masonry.h>

@interface TLWLoginView ()

// Logo 区域
@property (nonatomic, strong) UIView           *logoBgView;
@property (nonatomic, strong) CAGradientLayer  *logoGradient;
@property (nonatomic, strong) UIImageView      *logoImageView;
@property (nonatomic, strong) UILabel          *titleLabel;
@property (nonatomic, strong) UILabel          *sectionLabel;

// 表单 - 手机号
@property (nonatomic, strong) UIView           *phoneContainer;
@property (nonatomic, strong) UIView           *sendCodeBg;
@property (nonatomic, strong) CAGradientLayer  *sendCodeGradient;

// 表单 - 验证码
@property (nonatomic, strong) UIView           *codeContainer;

// 公开控件（readwrite）
@property (nonatomic, strong, readwrite) UITextField *phoneField;
@property (nonatomic, strong, readwrite) UIButton    *sendCodeButton;
@property (nonatomic, strong, readwrite) UITextField *codeField;
@property (nonatomic, strong, readwrite) UIButton    *loginTapButton;
@property (nonatomic, strong, readwrite) UIButton    *wechatLoginButton;
@property (nonatomic, strong, readwrite) UIButton    *qqLoginButton;
@property (nonatomic, strong, readwrite) UIButton    *localPhoneLoginButton;

@end

@implementation TLWLoginView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) [self setupView];
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) [self setupView];
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _logoGradient.frame     = _logoBgView.bounds;
    _sendCodeGradient.frame = _sendCodeBg.bounds;
}

#pragma mark - Setup

- (void)setupView {
    [self setupBackground];
    [self setupLogoArea];
    [self setupForm];
    [self setupTermsRow];
    [self setupBottomSection];
}

#pragma mark - 背景

- (void)setupBackground {
    UIImageView *bgImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bgGradient"]];
    bgImageView.contentMode = UIViewContentModeScaleAspectFill;
    bgImageView.clipsToBounds = YES;
    [self addSubview:bgImageView];
    [bgImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];

    UIImageView *rectView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bgCard"]];
    rectView.contentMode = UIViewContentModeScaleToFill;
    [self addSubview:rectView];
    [rectView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self);
        make.height.mas_equalTo(792);
    }];
}

#pragma mark - Logo 区域

- (void)setupLogoArea {
    _logoBgView = [[UIView alloc] init];
    _logoBgView.layer.cornerRadius = 22;
    _logoBgView.clipsToBounds = YES;
    [self addSubview:_logoBgView];
    [_logoBgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.mas_safeAreaLayoutGuideTop).offset(80);
        make.centerX.equalTo(self);
        make.width.height.mas_equalTo(88);
    }];

    _logoGradient = [CAGradientLayer layer];
    _logoGradient.colors = @[
        (__bridge id)[UIColor colorWithRed:0.0  green:0.416 blue:1.0   alpha:0.88].CGColor,
        (__bridge id)[UIColor colorWithRed:0.0  green:0.843 blue:0.773 alpha:0.88].CGColor,
    ];
    _logoGradient.startPoint   = CGPointMake(0.15, 0.09);
    _logoGradient.endPoint     = CGPointMake(0.93, 0.93);
    _logoGradient.cornerRadius = 22;
    [_logoBgView.layer insertSublayer:_logoGradient atIndex:0];

    _logoImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"iconAppMark"]];
    _logoImageView.contentMode = UIViewContentModeScaleAspectFit;
    [_logoBgView addSubview:_logoImageView];
    [_logoImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(_logoBgView);
        make.width.height.mas_equalTo(72);
    }];

    _titleLabel = [[UILabel alloc] init];
    NSMutableAttributedString *title = [[NSMutableAttributedString alloc] init];
    [title appendAttributedString:[[NSAttributedString alloc] initWithString:@"欢迎使用" attributes:@{
        NSFontAttributeName:            [UIFont systemFontOfSize:34 weight:UIFontWeightLight],
        NSForegroundColorAttributeName: [UIColor colorWithWhite:1.0 alpha:0.9],
    }]];
    [title appendAttributedString:[[NSAttributedString alloc] initWithString:@"植小保" attributes:@{
        NSFontAttributeName:            [UIFont systemFontOfSize:34 weight:UIFontWeightSemibold],
        NSForegroundColorAttributeName: [UIColor colorWithWhite:1.0 alpha:0.9],
    }]];
    _titleLabel.attributedText = title;
    [self addSubview:_titleLabel];
    [_titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(_logoBgView.mas_top).offset(-16);
        make.centerX.equalTo(self);
    }];

    _sectionLabel = [[UILabel alloc] init];
    _sectionLabel.text      = @"手机验证登录";
    _sectionLabel.font      = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    _sectionLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.9];
    [self addSubview:_sectionLabel];
    [_sectionLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_logoBgView.mas_bottom).offset(6);
        make.left.equalTo(self.mas_safeAreaLayoutGuideLeft).offset(43);
    }];
}

#pragma mark - 表单

- (void)setupForm {
    CGFloat margin = 43.0;
    CGFloat fieldH = 55.0;

    // ── 手机号容器 ──
    _phoneContainer = [[UIView alloc] init];
    _phoneContainer.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.85];
    _phoneContainer.layer.cornerRadius = 27;
    _phoneContainer.clipsToBounds = YES;
    [self addSubview:_phoneContainer];
    [_phoneContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_sectionLabel.mas_bottom).offset(13);
        make.left.equalTo(self.mas_safeAreaLayoutGuideLeft).offset(margin);
        make.right.equalTo(self.mas_safeAreaLayoutGuideRight).offset(-margin);
        make.height.mas_equalTo(fieldH);
    }];

    _phoneField = [[UITextField alloc] init];
    _phoneField.keyboardType  = UIKeyboardTypeNumberPad;
    _phoneField.backgroundColor = UIColor.clearColor;
    _phoneField.borderStyle   = UITextBorderStyleNone;
    _phoneField.font          = [UIFont systemFontOfSize:16];
    _phoneField.textColor     = [UIColor colorWithRed:0.20 green:0.20 blue:0.20 alpha:1.0];
    _phoneField.tintColor     = [UIColor colorWithRed:0.0  green:0.74 blue:0.67 alpha:1.0];
    _phoneField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"请输入手机号" attributes:@{
        NSForegroundColorAttributeName: [UIColor colorWithRed:0.42 green:0.42 blue:0.42 alpha:1.0],
        NSFontAttributeName:            [UIFont systemFontOfSize:16],
    }];
    _phoneField.leftView     = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 24, 0)];
    _phoneField.leftViewMode = UITextFieldViewModeAlways;
    [_phoneContainer addSubview:_phoneField];
    [_phoneField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.bottom.equalTo(_phoneContainer);
        make.right.equalTo(_phoneContainer).offset(-108);
    }];

    // 发送验证码绿色渐变胶囊
    _sendCodeBg = [[UIView alloc] init];
    _sendCodeBg.layer.cornerRadius = 20.5;
    _sendCodeBg.clipsToBounds = YES;
    [_phoneContainer addSubview:_sendCodeBg];
    [_sendCodeBg mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(_phoneContainer).offset(-6);
        make.centerY.equalTo(_phoneContainer);
        make.width.mas_equalTo(97);
        make.height.mas_equalTo(41);
    }];

    _sendCodeGradient = [CAGradientLayer layer];
    _sendCodeGradient.colors = @[
        (__bridge id)[UIColor colorWithRed:0.0  green:0.902 blue:0.549 alpha:1.0].CGColor,
        (__bridge id)[UIColor colorWithRed:0.0  green:0.745 blue:0.671 alpha:1.0].CGColor,
    ];
    _sendCodeGradient.startPoint   = CGPointMake(0, 0.5);
    _sendCodeGradient.endPoint     = CGPointMake(1, 0.5);
    _sendCodeGradient.cornerRadius = 20.5;
    [_sendCodeBg.layer insertSublayer:_sendCodeGradient atIndex:0];

    UILabel *sendLabel = [[UILabel alloc] init];
    sendLabel.text          = @"发送验证码";
    sendLabel.font          = [UIFont systemFontOfSize:14 weight:UIFontWeightBold];
    sendLabel.textColor     = UIColor.whiteColor;
    sendLabel.textAlignment = NSTextAlignmentCenter;
    [_sendCodeBg addSubview:sendLabel];
    [sendLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(_sendCodeBg);
    }];

    _sendCodeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _sendCodeButton.backgroundColor = UIColor.clearColor;
    [_phoneContainer addSubview:_sendCodeButton];
    [_sendCodeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(_phoneContainer).offset(-6);
        make.centerY.equalTo(_phoneContainer);
        make.width.mas_equalTo(97);
        make.height.mas_equalTo(41);
    }];

    // ── 验证码容器 ──
    _codeContainer = [[UIView alloc] init];
    _codeContainer.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.85];
    _codeContainer.layer.cornerRadius = 27;
    _codeContainer.clipsToBounds = YES;
    [self addSubview:_codeContainer];
    [_codeContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_phoneContainer.mas_bottom).offset(15);
        make.left.equalTo(self.mas_safeAreaLayoutGuideLeft).offset(margin);
        make.right.equalTo(self.mas_safeAreaLayoutGuideRight).offset(-margin);
        make.height.mas_equalTo(fieldH);
    }];

    _codeField = [[UITextField alloc] init];
    _codeField.keyboardType   = UIKeyboardTypeNumberPad;
    _codeField.backgroundColor = UIColor.clearColor;
    _codeField.borderStyle    = UITextBorderStyleNone;
    _codeField.font           = [UIFont systemFontOfSize:16];
    _codeField.textColor      = [UIColor colorWithRed:0.20 green:0.20 blue:0.20 alpha:1.0];
    _codeField.tintColor      = [UIColor colorWithRed:0.0  green:0.74 blue:0.67 alpha:1.0];
    _codeField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"请输入验证码" attributes:@{
        NSForegroundColorAttributeName: [UIColor colorWithRed:0.42 green:0.42 blue:0.42 alpha:1.0],
        NSFontAttributeName:            [UIFont systemFontOfSize:16],
    }];
    _codeField.leftView     = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 24, 0)];
    _codeField.leftViewMode = UITextFieldViewModeAlways;
    [_codeContainer addSubview:_codeField];
    [_codeField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(_codeContainer);
    }];

    // ── 登录按钮 ──
    _loginTapButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _loginTapButton.layer.cornerRadius = 27;
    _loginTapButton.clipsToBounds = YES;
    UIImage *loginBg = [[UIImage imageNamed:@"loginBtnBg"]
                        resizableImageWithCapInsets:UIEdgeInsetsMake(0, 62, 0, 62)
                        resizingMode:UIImageResizingModeStretch];
    [_loginTapButton setBackgroundImage:loginBg forState:UIControlStateNormal];
    [_loginTapButton setTitle:@"登录" forState:UIControlStateNormal];
    [_loginTapButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    _loginTapButton.titleLabel.font = [UIFont systemFontOfSize:21 weight:UIFontWeightMedium];
    [self addSubview:_loginTapButton];
    [_loginTapButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_codeContainer.mas_bottom).offset(22);
        make.left.equalTo(self.mas_safeAreaLayoutGuideLeft).offset(margin);
        make.right.equalTo(self.mas_safeAreaLayoutGuideRight).offset(-margin);
        make.height.mas_equalTo(54);
    }];
}

#pragma mark - 条款行

- (void)setupTermsRow {
    UIView *wrapper = [[UIView alloc] init];
    wrapper.userInteractionEnabled = YES;
    [self addSubview:wrapper];
    [wrapper mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_loginTapButton.mas_bottom).offset(14);
        make.centerX.equalTo(self);
        make.width.equalTo(_loginTapButton).offset(-40);
        make.height.mas_equalTo(36);
    }];

    UIImageView *checkImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"iconCheckbox"]];
    checkImageView.contentMode = UIViewContentModeScaleAspectFit;
    [wrapper addSubview:checkImageView];
    [checkImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(wrapper).offset(40);
        make.centerY.equalTo(wrapper);
        make.width.height.mas_equalTo(20);
    }];

    UIImageView *agreeImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"labelTermsPhone"]];
    agreeImageView.contentMode = UIViewContentModeScaleAspectFit;
    [wrapper addSubview:agreeImageView];
    [agreeImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(checkImageView.mas_right).offset(-10);
        make.right.equalTo(wrapper);
        make.centerY.equalTo(wrapper);
        make.height.mas_equalTo(32);
    }];
}

#pragma mark - 底部区域

- (void)setupBottomSection {
    // "其它方式登录" 分割线
    UIView *dividerView = [[UIView alloc] init];
    [self addSubview:dividerView];
    [dividerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.mas_safeAreaLayoutGuideBottom).offset(-115);
        make.left.equalTo(self).offset(60);
        make.right.equalTo(self).offset(-60);
        make.height.mas_equalTo(16);
    }];

    UILabel *divLabel = [[UILabel alloc] init];
    divLabel.text      = @"其它方式登录";
    divLabel.font      = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    divLabel.textColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.28];
    [dividerView addSubview:divLabel];

    UIView *leftLine  = [self makeDividerLine];
    UIView *rightLine = [self makeDividerLine];
    [dividerView addSubview:leftLine];
    [dividerView addSubview:rightLine];

    [divLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(dividerView);
    }];
    [leftLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(dividerView);
        make.right.equalTo(divLabel.mas_left).offset(-8);
        make.centerY.equalTo(dividerView);
        make.height.mas_equalTo(0.5);
    }];
    [rightLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(dividerView);
        make.left.equalTo(divLabel.mas_right).offset(8);
        make.centerY.equalTo(dividerView);
        make.height.mas_equalTo(0.5);
    }];

    // ── 微信登录 ──
    _wechatLoginButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _wechatLoginButton.backgroundColor = UIColor.clearColor;
    [self addSubview:_wechatLoginButton];
    [_wechatLoginButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.mas_safeAreaLayoutGuideBottom).offset(-20);
        make.centerX.equalTo(self).offset(-90);
        make.width.mas_equalTo(90);
        make.height.mas_equalTo(78);
    }];

    UIImageView *wechatIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"iconWechat"]];
    wechatIcon.contentMode = UIViewContentModeScaleAspectFit;
    wechatIcon.clipsToBounds = YES;
    wechatIcon.layer.cornerRadius = 27;
    wechatIcon.userInteractionEnabled = NO;
    [_wechatLoginButton addSubview:wechatIcon];
    [wechatIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_wechatLoginButton);
        make.centerX.equalTo(_wechatLoginButton);
        make.width.height.mas_equalTo(58);
    }];

    UILabel *wechatLabel = [[UILabel alloc] init];
    wechatLabel.text          = @"微信登录";
    wechatLabel.font          = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
    wechatLabel.textColor     = [UIColor colorWithRed:0.298 green:0.298 blue:0.298 alpha:0.8];
    wechatLabel.textAlignment = NSTextAlignmentCenter;
    wechatLabel.userInteractionEnabled = NO;
    [_wechatLoginButton addSubview:wechatLabel];
    [wechatLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(wechatIcon.mas_bottom).offset(2);
        make.centerX.equalTo(_wechatLoginButton);
        make.bottom.equalTo(_wechatLoginButton);
    }];

    // ── QQ登录 ──
    _qqLoginButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _qqLoginButton.backgroundColor = UIColor.clearColor;
    [self addSubview:_qqLoginButton];
    [_qqLoginButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.mas_safeAreaLayoutGuideBottom).offset(-20);
        make.centerX.equalTo(self);
        make.width.mas_equalTo(90);
        make.height.mas_equalTo(78);
    }];

    UIImageView *qqIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"iconQQ"]];
    qqIcon.contentMode = UIViewContentModeScaleAspectFit;
    qqIcon.clipsToBounds = YES;
    qqIcon.layer.cornerRadius = 27;
    qqIcon.userInteractionEnabled = NO;
    [_qqLoginButton addSubview:qqIcon];
    [qqIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_qqLoginButton);
        make.centerX.equalTo(_qqLoginButton);
        make.width.height.mas_equalTo(54);
    }];

    UILabel *qqLabel = [[UILabel alloc] init];
    qqLabel.text          = @"QQ登录";
    qqLabel.font          = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
    qqLabel.textColor     = [UIColor colorWithRed:0.298 green:0.298 blue:0.298 alpha:0.8];
    qqLabel.textAlignment = NSTextAlignmentCenter;
    qqLabel.userInteractionEnabled = NO;
    [_qqLoginButton addSubview:qqLabel];
    [qqLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(qqIcon.mas_bottom).offset(6);
        make.centerX.equalTo(_qqLoginButton);
        make.bottom.equalTo(_qqLoginButton);
    }];

    // ── 本机号码登录 ──
    _localPhoneLoginButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _localPhoneLoginButton.backgroundColor = UIColor.clearColor;
    [self addSubview:_localPhoneLoginButton];
    [_localPhoneLoginButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.mas_safeAreaLayoutGuideBottom).offset(-20);
        make.centerX.equalTo(self).offset(90);
        make.width.mas_equalTo(90);
        make.height.mas_equalTo(78);
    }];

    UIImageView *phoneIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"iconPhone"]];
    phoneIcon.contentMode = UIViewContentModeScaleAspectFit;
    phoneIcon.clipsToBounds = YES;
    phoneIcon.layer.cornerRadius = 27;
    phoneIcon.userInteractionEnabled = NO;
    [_localPhoneLoginButton addSubview:phoneIcon];
    [phoneIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_localPhoneLoginButton);
        make.centerX.equalTo(_localPhoneLoginButton);
        make.width.height.mas_equalTo(54);
    }];

    UILabel *phoneLabel = [[UILabel alloc] init];
    phoneLabel.text          = @"本机号码";
    phoneLabel.font          = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
    phoneLabel.textColor     = [UIColor colorWithRed:0.298 green:0.298 blue:0.298 alpha:0.8];
    phoneLabel.textAlignment = NSTextAlignmentCenter;
    phoneLabel.userInteractionEnabled = NO;
    [_localPhoneLoginButton addSubview:phoneLabel];
    [phoneLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(phoneIcon.mas_bottom).offset(6);
        make.centerX.equalTo(_localPhoneLoginButton);
        make.bottom.equalTo(_localPhoneLoginButton);
    }];
}

- (UIView *)makeDividerLine {
    UIView *line = [[UIView alloc] init];
    line.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.18];
    return line;
}

@end
