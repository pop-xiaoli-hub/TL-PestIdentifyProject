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
@property (nonatomic, strong, readwrite) UIButton *phoneLoginButton;

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
        make.height.mas_equalTo(44);
    }];

    UIImageView *checkImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"iconCheckbox"]];
    checkImageView.contentMode = UIViewContentModeScaleAspectFit;
    [wrapper addSubview:checkImageView];
    [checkImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(wrapper);
        make.centerY.equalTo(wrapper);
        make.width.height.mas_equalTo(24);
    }];

    NSMutableAttributedString *attr = [[NSMutableAttributedString alloc] initWithString:@"我已阅读并同意 " attributes:@{
        NSForegroundColorAttributeName: [UIColor colorWithWhite:0 alpha:0.6],
        NSFontAttributeName:            [UIFont systemFontOfSize:13],
    }];
    [attr appendAttributedString:[[NSAttributedString alloc] initWithString:@"用户协议" attributes:@{
        NSForegroundColorAttributeName: [UIColor colorWithRed:0.0 green:0.6 blue:1.0 alpha:1.0],
        NSFontAttributeName:            [UIFont systemFontOfSize:13],
    }]];
    [attr appendAttributedString:[[NSAttributedString alloc] initWithString:@" 和 " attributes:@{
        NSForegroundColorAttributeName: [UIColor colorWithWhite:0 alpha:0.6],
        NSFontAttributeName:            [UIFont systemFontOfSize:13],
    }]];
    [attr appendAttributedString:[[NSAttributedString alloc] initWithString:@"隐私政策" attributes:@{
        NSForegroundColorAttributeName: [UIColor colorWithRed:0.0 green:0.6 blue:1.0 alpha:1.0],
        NSFontAttributeName:            [UIFont systemFontOfSize:13],
    }]];

    UILabel *agreeLabel = [[UILabel alloc] init];
    agreeLabel.attributedText = attr;
    agreeLabel.numberOfLines  = 1;
    [wrapper addSubview:agreeLabel];
    [agreeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(checkImageView.mas_right).offset(4);
        make.right.equalTo(wrapper);   // 定义 wrapper 宽度
        make.centerY.equalTo(wrapper);
    }];
}

#pragma mark - 底部区域（与登录页相同位置：safeAreaBottom - 100）

- (void)setupBottomSection {
    // "其它方式登录" 图片分割线
    UIImageView *dividerImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"dividerOtherLogin"]];
    dividerImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self addSubview:dividerImageView];
    [dividerImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.mas_safeAreaLayoutGuideBottom).offset(-120);
        make.left.equalTo(self).offset(60);
        make.right.equalTo(self).offset(-60);
        make.height.mas_equalTo(16);
    }];

    // ── QQ登录 ──
    _qqLoginButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _qqLoginButton.backgroundColor = UIColor.clearColor;
    [self addSubview:_qqLoginButton];
    [_qqLoginButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.mas_safeAreaLayoutGuideBottom).offset(-20);
        make.centerX.equalTo(self).offset(-60);
        make.width.mas_equalTo(90);
        make.height.mas_equalTo(78);
    }];

    UIImageView *qqIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"iconQQ"]];
    qqIcon.contentMode = UIViewContentModeScaleAspectFit;
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
        make.centerX.equalTo(self).offset(60);
        make.width.mas_equalTo(90);
        make.height.mas_equalTo(78);
    }];

    UIImageView *phoneIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"iconPhone"]];
    phoneIcon.contentMode = UIViewContentModeScaleAspectFit;
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

@end
