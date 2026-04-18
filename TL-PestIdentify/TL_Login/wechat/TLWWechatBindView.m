//
//  TLWWechatBindView.m
//  TL-PestIdentify
//
//  Created by 吴桐 on 2026/3/12.
//

#import "TLWWechatBindView.h"
#import <Masonry/Masonry.h>

@interface TLWWechatBindView ()

// 公开控件（readwrite）
@property (nonatomic, strong, readwrite) UIButton *wechatAuthButton;
@property (nonatomic, strong, readwrite) UIButton *qqLoginButton;
@property (nonatomic, strong, readwrite) UIButton *smsLoginButton;
@property (nonatomic, strong, readwrite) UIButton *passwordLoginButton;
@property (nonatomic, strong, readwrite) UIButton *termsCheckButton;

@end

@implementation TLWWechatBindView

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

#pragma mark - Setup

- (void)setupView {
    [self setupBackground];
    [self setupBindingIcons];
    [self setupAuthButton];
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

#pragma mark - 绑定图标区域（与登录页 logo 顶部对齐：safeAreaTop + 80）

- (void)setupBindingIcons {
    // 植小保图标
    UIImageView *appIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"iconAppLogo"]];
    appIcon.contentMode = UIViewContentModeScaleAspectFit;
    [self addSubview:appIcon];
    [appIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.mas_safeAreaLayoutGuideTop).offset(80);
        make.centerX.equalTo(self).offset(-82);
        make.width.height.mas_equalTo(140);
    }];

    // 微信图标
    UIImageView *wechatIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"iconWechatLogo"]];
    wechatIcon.contentMode = UIViewContentModeScaleAspectFit;
    [self addSubview:wechatIcon];
    [wechatIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(appIcon);
        make.centerX.equalTo(self).offset(62);
        make.width.height.mas_equalTo(180);
    }];

    // 植小保 标签
    UILabel *appLabel = [[UILabel alloc] init];
    appLabel.text      = @"植小保";
    appLabel.font      = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    appLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.85];
    appLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:appLabel];
    [appLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(appIcon.mas_bottom).offset(8);
        make.centerX.equalTo(appIcon);
    }];

    // 微信 标签
    UILabel *wechatLabel = [[UILabel alloc] init];
    wechatLabel.text      = @"微信";
    wechatLabel.font      = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    wechatLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.85];
    wechatLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:wechatLabel];
    [wechatLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(appLabel);
        make.centerX.equalTo(wechatIcon).offset(30);
    }];

    // 说明文字
    UILabel *descLabel = [[UILabel alloc] init];
    descLabel.text          = @"申请获取你的微信账号信息";
    descLabel.font          = [UIFont systemFontOfSize:17 weight:UIFontWeightMedium];
    descLabel.textColor     = [UIColor colorWithWhite:1.0 alpha:0.9];
    descLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:descLabel];
    [descLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self);
        make.centerX.equalTo(self);
    }];
}

#pragma mark - 一键授权按钮（垂直居中，与登录页登录按钮视觉位置对应）

- (void)setupAuthButton {
    _wechatAuthButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _wechatAuthButton.layer.cornerRadius = 27;
    _wechatAuthButton.clipsToBounds = YES;
    UIImage *loginBg = [[UIImage imageNamed:@"loginBtnBg"]
                        resizableImageWithCapInsets:UIEdgeInsetsMake(0, 62, 0, 62)
                        resizingMode:UIImageResizingModeStretch];
    [_wechatAuthButton setBackgroundImage:loginBg forState:UIControlStateNormal];
    [_wechatAuthButton setTitle:@"一键授权" forState:UIControlStateNormal];
    [_wechatAuthButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    _wechatAuthButton.titleLabel.font = [UIFont systemFontOfSize:21 weight:UIFontWeightMedium];

    [self addSubview:_wechatAuthButton];
    [_wechatAuthButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self).offset(60);
        make.left.equalTo(self.mas_safeAreaLayoutGuideLeft).offset(43);
        make.right.equalTo(self.mas_safeAreaLayoutGuideRight).offset(-43);
        make.height.mas_equalTo(54);
    }];
}

#pragma mark - 条款行

- (void)setupTermsRow {
    UIView *wrapper = [[UIView alloc] init];
    wrapper.userInteractionEnabled = YES;
    [self addSubview:wrapper];
    [wrapper mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_wechatAuthButton.mas_bottom).offset(14);
        make.centerX.equalTo(self);
        make.width.equalTo(_wechatAuthButton).offset(-40);
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

#pragma mark - 底部区域（与登录页相同位置：safeAreaBottom - 100）

- (void)setupBottomSection {
    UIView *dividerView = [[UIView alloc] init];
    dividerView.backgroundColor = UIColor.clearColor;
    [self addSubview:dividerView];
    [dividerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.mas_safeAreaLayoutGuideBottom).offset(-120);
        make.left.equalTo(self).offset(34);
        make.right.equalTo(self).offset(-34);
        make.height.mas_equalTo(20);
    }];

    UILabel *divLabel = [[UILabel alloc] init];
    divLabel.text = @"其它方式登录";
    divLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightRegular];
    divLabel.textColor = [UIColor colorWithRed:0.298 green:0.298 blue:0.298 alpha:0.65];
    divLabel.textAlignment = NSTextAlignmentCenter;
    [dividerView addSubview:divLabel];
    [divLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(dividerView);
    }];

    UIView *leftLine = [[UIView alloc] init];
    leftLine.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.18];
    [dividerView addSubview:leftLine];
    [leftLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(dividerView);
        make.right.equalTo(divLabel.mas_left).offset(-8);
        make.centerY.equalTo(dividerView);
        make.height.mas_equalTo(0.5);
    }];

    UIView *rightLine = [[UIView alloc] init];
    rightLine.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.18];
    [dividerView addSubview:rightLine];
    [rightLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(dividerView);
        make.left.equalTo(divLabel.mas_right).offset(8);
        make.centerY.equalTo(dividerView);
        make.height.mas_equalTo(0.5);
    }];

    // ── QQ登录 ──
    _qqLoginButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _qqLoginButton.backgroundColor = UIColor.clearColor;
    [self addSubview:_qqLoginButton];
    [_qqLoginButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.mas_safeAreaLayoutGuideBottom).offset(-20);
        make.centerX.equalTo(self).offset(-90);
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
    _smsLoginButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _smsLoginButton.backgroundColor = UIColor.clearColor;
    [self addSubview:_smsLoginButton];
    [_smsLoginButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.mas_safeAreaLayoutGuideBottom).offset(-20);
        make.centerX.equalTo(self);
        make.width.mas_equalTo(90);
        make.height.mas_equalTo(78);
    }];

    UIImageView *phoneIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"iconPhone"]];
    phoneIcon.contentMode = UIViewContentModeScaleAspectFit;
    phoneIcon.clipsToBounds = YES;
    phoneIcon.layer.cornerRadius = 27;
    phoneIcon.userInteractionEnabled = NO;
    [_smsLoginButton addSubview:phoneIcon];
    [phoneIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_smsLoginButton);
        make.centerX.equalTo(_smsLoginButton);
        make.width.height.mas_equalTo(54);
    }];

    UILabel *phoneLabel = [[UILabel alloc] init];
    phoneLabel.text          = @"手机号登录";
    phoneLabel.font          = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
    phoneLabel.textColor     = [UIColor colorWithRed:0.298 green:0.298 blue:0.298 alpha:0.8];
    phoneLabel.textAlignment = NSTextAlignmentCenter;
    phoneLabel.userInteractionEnabled = NO;
    [_smsLoginButton addSubview:phoneLabel];
    [phoneLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(phoneIcon.mas_bottom).offset(6);
        make.centerX.equalTo(_smsLoginButton);
        make.bottom.equalTo(_smsLoginButton);
    }];

    // ── 账号密码登录 ──
    _passwordLoginButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _passwordLoginButton.backgroundColor = UIColor.clearColor;
    [self addSubview:_passwordLoginButton];
    [_passwordLoginButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.mas_safeAreaLayoutGuideBottom).offset(-20);
        make.centerX.equalTo(self).offset(90);
        make.width.mas_equalTo(90);
        make.height.mas_equalTo(78);
    }];

    UIImageView *passwordIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"iconPhone"]];
    passwordIcon.contentMode = UIViewContentModeScaleAspectFit;
    passwordIcon.clipsToBounds = YES;
    passwordIcon.layer.cornerRadius = 27;
    passwordIcon.userInteractionEnabled = NO;
    [_passwordLoginButton addSubview:passwordIcon];
    [passwordIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_passwordLoginButton);
        make.centerX.equalTo(_passwordLoginButton);
        make.width.height.mas_equalTo(54);
    }];

    UILabel *passwordLabel = [[UILabel alloc] init];
    passwordLabel.text          = @"账号密码登录";
    passwordLabel.font          = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
    passwordLabel.textColor     = [UIColor colorWithRed:0.298 green:0.298 blue:0.298 alpha:0.8];
    passwordLabel.textAlignment = NSTextAlignmentCenter;
    passwordLabel.userInteractionEnabled = NO;
    [_passwordLoginButton addSubview:passwordLabel];
    [passwordLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(passwordIcon.mas_bottom).offset(6);
        make.centerX.equalTo(_passwordLoginButton);
        make.bottom.equalTo(_passwordLoginButton);
    }];
}

@end
