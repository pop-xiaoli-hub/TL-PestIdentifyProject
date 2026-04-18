//
//  TLWPasswordLoginView.m
//  TL-PestIdentify
//

#import "TLWPasswordLoginView.h"
#import <Masonry/Masonry.h>

@interface TLWPasswordLoginView ()

// Logo 区域
@property (nonatomic, strong) UIView           *logoBgView;
@property (nonatomic, strong) CAGradientLayer  *logoGradient;
@property (nonatomic, strong) UIImageView      *logoImageView;
@property (nonatomic, strong) UILabel          *titleLabel;
@property (nonatomic, strong) UILabel          *sectionLabel;

// 表单容器
@property (nonatomic, strong) UIView           *accountContainer;
@property (nonatomic, strong) UIView           *passwordContainer;

// 公开控件（readwrite）
@property (nonatomic, strong, readwrite) UITextField *accountField;
@property (nonatomic, strong, readwrite) UITextField *passwordField;
@property (nonatomic, strong, readwrite) UIButton *togglePasswordButton;
@property (nonatomic, strong, readwrite) UIButton *loginTapButton;
@property (nonatomic, strong, readwrite) UIButton *qqLoginButton;
@property (nonatomic, strong, readwrite) UIButton *phoneLoginButton;
@property (nonatomic, strong, readwrite) UIButton *backButton;
@property (nonatomic, strong, readwrite) UIButton *termsCheckButton;

@end

@implementation TLWPasswordLoginView

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
    _logoGradient.frame = _logoBgView.bounds;
}

#pragma mark - Setup

- (void)setupView {
    [self setupBackground];
    [self setupBackButton];
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

#pragma mark - 返回按钮

- (void)setupBackButton {
    _backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:20 weight:UIImageSymbolWeightMedium];
    UIImage *chevron = [UIImage systemImageNamed:@"chevron.left" withConfiguration:config];
    [_backButton setImage:chevron forState:UIControlStateNormal];
    _backButton.tintColor = [UIColor colorWithWhite:1.0 alpha:0.9];
    [self addSubview:_backButton];
    [_backButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.mas_safeAreaLayoutGuideTop).offset(10);
        make.left.equalTo(self).offset(16);
        make.width.height.mas_equalTo(44);
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
    _sectionLabel.text      = @"账号密码登录";
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

    // ── 账号容器 ──
    _accountContainer = [[UIView alloc] init];
    _accountContainer.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.85];
    _accountContainer.layer.cornerRadius = 27;
    _accountContainer.clipsToBounds = YES;
    [self addSubview:_accountContainer];
    [_accountContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_sectionLabel.mas_bottom).offset(13);
        make.left.equalTo(self.mas_safeAreaLayoutGuideLeft).offset(margin);
        make.right.equalTo(self.mas_safeAreaLayoutGuideRight).offset(-margin);
        make.height.mas_equalTo(fieldH);
    }];

    _accountField = [[UITextField alloc] init];
    _accountField.backgroundColor = UIColor.clearColor;
    _accountField.borderStyle   = UITextBorderStyleNone;
    _accountField.font          = [UIFont systemFontOfSize:16];
    _accountField.textColor     = [UIColor colorWithRed:0.20 green:0.20 blue:0.20 alpha:1.0];
    _accountField.tintColor     = [UIColor colorWithRed:0.0  green:0.74 blue:0.67 alpha:1.0];
    _accountField.autocorrectionType = UITextAutocorrectionTypeNo;
    _accountField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _accountField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"请输用户名" attributes:@{
        NSForegroundColorAttributeName: [UIColor colorWithRed:0.42 green:0.42 blue:0.42 alpha:1.0],
        NSFontAttributeName:            [UIFont systemFontOfSize:16],
    }];
    _accountField.leftView     = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 24, 0)];
    _accountField.leftViewMode = UITextFieldViewModeAlways;
    [_accountContainer addSubview:_accountField];
    [_accountField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(_accountContainer);
    }];

    // ── 密码容器 ──
    _passwordContainer = [[UIView alloc] init];
    _passwordContainer.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.85];
    _passwordContainer.layer.cornerRadius = 27;
    _passwordContainer.clipsToBounds = YES;
    [self addSubview:_passwordContainer];
    [_passwordContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_accountContainer.mas_bottom).offset(15);
        make.left.equalTo(self.mas_safeAreaLayoutGuideLeft).offset(margin);
        make.right.equalTo(self.mas_safeAreaLayoutGuideRight).offset(-margin);
        make.height.mas_equalTo(fieldH);
    }];

    _passwordField = [[UITextField alloc] init];
    _passwordField.secureTextEntry = YES;
    _passwordField.backgroundColor = UIColor.clearColor;
    _passwordField.borderStyle    = UITextBorderStyleNone;
    _passwordField.font           = [UIFont systemFontOfSize:16];
    _passwordField.textColor      = [UIColor colorWithRed:0.20 green:0.20 blue:0.20 alpha:1.0];
    _passwordField.tintColor      = [UIColor colorWithRed:0.0  green:0.74 blue:0.67 alpha:1.0];
    _passwordField.autocorrectionType = UITextAutocorrectionTypeNo;
    _passwordField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"请输入密码" attributes:@{
        NSForegroundColorAttributeName: [UIColor colorWithRed:0.42 green:0.42 blue:0.42 alpha:1.0],
        NSFontAttributeName:            [UIFont systemFontOfSize:16],
    }];
    _passwordField.leftView     = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 24, 0)];
    _passwordField.leftViewMode = UITextFieldViewModeAlways;
    [_passwordContainer addSubview:_passwordField];
    [_passwordField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.bottom.equalTo(_passwordContainer);
        make.right.equalTo(_passwordContainer).offset(-50);
    }];

    // 显示/隐藏密码按钮
    _togglePasswordButton = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImageSymbolConfiguration *eyeConfig = [UIImageSymbolConfiguration configurationWithPointSize:16 weight:UIImageSymbolWeightRegular];
    [_togglePasswordButton setImage:[UIImage systemImageNamed:@"eye.slash" withConfiguration:eyeConfig] forState:UIControlStateNormal];
    [_togglePasswordButton setImage:[UIImage systemImageNamed:@"eye" withConfiguration:eyeConfig] forState:UIControlStateSelected];
    _togglePasswordButton.tintColor = [UIColor colorWithRed:0.42 green:0.42 blue:0.42 alpha:1.0];
    [_passwordContainer addSubview:_togglePasswordButton];
    [_togglePasswordButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(_passwordContainer).offset(-16);
        make.centerY.equalTo(_passwordContainer);
        make.width.height.mas_equalTo(36);
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
        make.top.equalTo(_passwordContainer.mas_bottom).offset(22);
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

    _termsCheckButton = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *uncheckedImg = [[UIImage imageNamed:@"iconCheckbox"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    UIImage *checkedImg   = [[UIImage imageNamed:@"iconCheckbox"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [_termsCheckButton setImage:uncheckedImg forState:UIControlStateNormal];
    [_termsCheckButton setImage:checkedImg forState:UIControlStateSelected];
    _termsCheckButton.tintColor = [UIColor colorWithRed:76/255.0 green:175/255.0 blue:80/255.0 alpha:1.0];
    _termsCheckButton.contentMode = UIViewContentModeScaleAspectFit;
    [wrapper addSubview:_termsCheckButton];
    [_termsCheckButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(wrapper).offset(40);
        make.centerY.equalTo(wrapper);
        make.width.height.mas_equalTo(20);
    }];

    UIImageView *agreeImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"labelTermsPhone"]];
    agreeImageView.contentMode = UIViewContentModeScaleAspectFit;
    [wrapper addSubview:agreeImageView];
    [agreeImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_termsCheckButton.mas_right).offset(-7);
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

    // ── 微信登录（仅展示图标，无点击响应）──
    UIView *wechatPlaceholder = [[UIView alloc] init];
    [self addSubview:wechatPlaceholder];
    [wechatPlaceholder mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.mas_safeAreaLayoutGuideBottom).offset(-20);
        make.centerX.equalTo(self).offset(-90);
        make.width.mas_equalTo(90);
        make.height.mas_equalTo(78);
    }];

    UIImageView *wechatIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"iconWechat"]];
    wechatIcon.contentMode = UIViewContentModeScaleAspectFit;
    wechatIcon.clipsToBounds = YES;
    wechatIcon.layer.cornerRadius = 27;
    [wechatPlaceholder addSubview:wechatIcon];
    [wechatIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(wechatPlaceholder);
        make.centerX.equalTo(wechatPlaceholder);
        make.width.height.mas_equalTo(58);
    }];

    UILabel *wechatLabel = [[UILabel alloc] init];
    wechatLabel.text          = @"微信登录";
    wechatLabel.font          = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
    wechatLabel.textColor     = [UIColor colorWithRed:0.298 green:0.298 blue:0.298 alpha:0.8];
    wechatLabel.textAlignment = NSTextAlignmentCenter;
    [wechatPlaceholder addSubview:wechatLabel];
    [wechatLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(wechatIcon.mas_bottom).offset(2);
        make.centerX.equalTo(wechatPlaceholder);
        make.bottom.equalTo(wechatPlaceholder);
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

    // ── 手机号登录 ──
    _phoneLoginButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _phoneLoginButton.backgroundColor = UIColor.clearColor;
    [self addSubview:_phoneLoginButton];
    [_phoneLoginButton mas_makeConstraints:^(MASConstraintMaker *make) {
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
    [_phoneLoginButton addSubview:phoneIcon];
    [phoneIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_phoneLoginButton);
        make.centerX.equalTo(_phoneLoginButton);
        make.width.height.mas_equalTo(54);
    }];

    UILabel *phoneLabel = [[UILabel alloc] init];
    phoneLabel.text          = @"手机号登录";
    phoneLabel.font          = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
    phoneLabel.textColor     = [UIColor colorWithRed:0.298 green:0.298 blue:0.298 alpha:0.8];
    phoneLabel.textAlignment = NSTextAlignmentCenter;
    phoneLabel.userInteractionEnabled = NO;
    [_phoneLoginButton addSubview:phoneLabel];
    [phoneLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(phoneIcon.mas_bottom).offset(6);
        make.centerX.equalTo(_phoneLoginButton);
        make.bottom.equalTo(_phoneLoginButton);
    }];
}

- (UIView *)makeDividerLine {
    UIView *line = [[UIView alloc] init];
    line.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.18];
    return line;
}

@end
