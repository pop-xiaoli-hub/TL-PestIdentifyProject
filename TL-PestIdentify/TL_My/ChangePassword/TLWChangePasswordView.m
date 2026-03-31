//
//  TLWChangePasswordView.m
//  TL-PestIdentify
//

#import "TLWChangePasswordView.h"
#import <Masonry/Masonry.h>

@interface TLWChangePasswordView ()
@property (nonatomic, strong, readwrite) UIButton    *backButton;
@property (nonatomic, strong, readwrite) UITextField *passwordField;
@property (nonatomic, strong, readwrite) UITextField *confirmPasswordField;
@property (nonatomic, strong, readwrite) UIButton    *confirmButton;
@property (nonatomic, strong) CAGradientLayer        *confirmGradient;
@property (nonatomic, strong) UIView                 *currentPwdBox;
@end

@implementation TLWChangePasswordView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) [self setupUI];
    return self;
}

- (void)setupUI {
    UIImageView *bg = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bgGradient"]];
    bg.contentMode = UIViewContentModeScaleAspectFill;
    [self addSubview:bg];
    [bg mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];

    [self setupNavBar];
    [self setupPanel];
    [self setupContent];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _confirmGradient.frame = _confirmButton.bounds;
}

#pragma mark - Nav

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
    title.text      = @"修改密码";
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

#pragma mark - Content

- (void)setupContent {
    // 当前密码显示区（默认隐藏，setCurrentPassword 时显示）
    _currentPwdBox = [UIView new];
    _currentPwdBox.backgroundColor = [UIColor colorWithWhite:1 alpha:0.85];
    _currentPwdBox.layer.cornerRadius = 12;
    _currentPwdBox.hidden = YES;
    [self addSubview:_currentPwdBox];
    [_currentPwdBox mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_backButton.mas_bottom).offset(28);
        make.left.equalTo(self).offset(20);
        make.right.equalTo(self).offset(-20);
        make.height.mas_equalTo(52);
    }];

    UILabel *pwdTitleLabel = [UILabel new];
    pwdTitleLabel.text      = @"当前密码";
    pwdTitleLabel.font      = [UIFont systemFontOfSize:15];
    pwdTitleLabel.textColor = [UIColor colorWithWhite:0.45 alpha:1];
    pwdTitleLabel.tag       = 101;
    [_currentPwdBox addSubview:pwdTitleLabel];
    [pwdTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_currentPwdBox).offset(14);
        make.centerY.equalTo(_currentPwdBox);
    }];

    UILabel *pwdValueLabel = [UILabel new];
    pwdValueLabel.font      = [UIFont monospacedSystemFontOfSize:16 weight:UIFontWeightMedium];
    pwdValueLabel.textColor = [UIColor colorWithRed:0.15 green:0.15 blue:0.15 alpha:1];
    pwdValueLabel.tag       = 102;
    [_currentPwdBox addSubview:pwdValueLabel];
    [pwdValueLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(_currentPwdBox).offset(-14);
        make.centerY.equalTo(_currentPwdBox);
    }];

    // 新密码
    UILabel *newTitle = [UILabel new];
    newTitle.text      = @"请输入新密码";
    newTitle.font      = [UIFont systemFontOfSize:20 weight:UIFontWeightMedium];
    newTitle.textColor = [UIColor colorWithRed:0.15 green:0.15 blue:0.15 alpha:1];
    [self addSubview:newTitle];
    [newTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_currentPwdBox.mas_bottom).offset(20);
        make.left.equalTo(self).offset(20);
    }];

    _passwordField = [self buildPasswordFieldWithPlaceholder:@"6-20位密码"];
    [self addSubview:_passwordField];
    [_passwordField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(newTitle.mas_bottom).offset(16);
        make.left.equalTo(self).offset(20);
        make.right.equalTo(self).offset(-20);
        make.height.mas_equalTo(52);
    }];

    // 确认密码
    UILabel *confirmTitle = [UILabel new];
    confirmTitle.text      = @"再次确认密码";
    confirmTitle.font      = [UIFont systemFontOfSize:20 weight:UIFontWeightMedium];
    confirmTitle.textColor = [UIColor colorWithRed:0.15 green:0.15 blue:0.15 alpha:1];
    [self addSubview:confirmTitle];
    [confirmTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_passwordField.mas_bottom).offset(20);
        make.left.equalTo(self).offset(20);
    }];

    _confirmPasswordField = [self buildPasswordFieldWithPlaceholder:@"请再次输入密码"];
    [self addSubview:_confirmPasswordField];
    [_confirmPasswordField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(confirmTitle.mas_bottom).offset(16);
        make.left.equalTo(self).offset(20);
        make.right.equalTo(self).offset(-20);
        make.height.mas_equalTo(52);
    }];

    // 确认按钮
    _confirmButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_confirmButton setTitle:@"确认修改" forState:UIControlStateNormal];
    [_confirmButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    _confirmButton.titleLabel.font   = [UIFont systemFontOfSize:18 weight:UIFontWeightSemibold];
    _confirmButton.layer.cornerRadius = 26;
    _confirmButton.layer.masksToBounds = YES;

    _confirmGradient = [CAGradientLayer layer];
    _confirmGradient.colors = @[
        (__bridge id)[UIColor colorWithRed:1.00 green:0.76 blue:0.20 alpha:1].CGColor,
        (__bridge id)[UIColor colorWithRed:0.97 green:0.50 blue:0.08 alpha:1].CGColor
    ];
    _confirmGradient.startPoint  = CGPointMake(0, 0.5);
    _confirmGradient.endPoint    = CGPointMake(1, 0.5);
    _confirmGradient.cornerRadius = 26;
    [_confirmButton.layer insertSublayer:_confirmGradient atIndex:0];

    [self addSubview:_confirmButton];
    [_confirmButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_confirmPasswordField.mas_bottom).offset(28);
        make.left.equalTo(self).offset(20);
        make.right.equalTo(self).offset(-20);
        make.height.mas_equalTo(52);
    }];
}

- (void)setCurrentPassword:(NSString *)currentPassword {
    _currentPassword = [currentPassword copy];
    if (currentPassword.length > 0) {
        _currentPwdBox.hidden = NO;
        UILabel *val = [_currentPwdBox viewWithTag:102];
        val.text = currentPassword;
    } else {
        _currentPwdBox.hidden = YES;
    }
}

#pragma mark - Helpers

- (UITextField *)buildPasswordFieldWithPlaceholder:(NSString *)placeholder {
    UITextField *tf = [UITextField new];
    tf.placeholder       = placeholder;
    tf.font              = [UIFont systemFontOfSize:16];
    tf.textColor         = [UIColor colorWithRed:0.15 green:0.15 blue:0.15 alpha:1];
    tf.backgroundColor   = UIColor.whiteColor;
    tf.layer.cornerRadius = 10;
    tf.layer.masksToBounds = YES;
    tf.secureTextEntry   = YES;
    tf.clearButtonMode   = UITextFieldViewModeWhileEditing;

    UIView *left = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 14, 1)];
    tf.leftView     = left;
    tf.leftViewMode = UITextFieldViewModeAlways;
    return tf;
}

@end
