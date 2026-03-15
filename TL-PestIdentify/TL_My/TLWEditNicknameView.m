//
//  TLWEditNicknameView.m
//  TL-PestIdentify
//

#import "TLWEditNicknameView.h"
#import <Masonry/Masonry.h>

@interface TLWEditNicknameView ()
@property (nonatomic, strong, readwrite) UIButton    *backButton;
@property (nonatomic, strong, readwrite) UITextField *nicknameTextField;
@property (nonatomic, strong, readwrite) UIButton    *confirmButton;
@property (nonatomic, strong) CAGradientLayer        *confirmGradient;
@end

@implementation TLWEditNicknameView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) [self setupUI];
    return self;
}

- (void)setupUI {
    self.layer.contents = (__bridge id)[UIImage imageNamed:@"hp_backView"].CGImage;
    [self setupNavBar];
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
    title.text      = @"修改昵称";
    title.textColor = UIColor.whiteColor;
    title.font      = [UIFont systemFontOfSize:20 weight:UIFontWeightSemibold];
    [self addSubview:title];
    [title mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self);
        make.centerY.equalTo(_backButton);
    }];
}

#pragma mark - Content

- (void)setupContent {
    UILabel *sectionTitle = [UILabel new];
    sectionTitle.text      = @"请输入您的昵称";
    sectionTitle.font      = [UIFont systemFontOfSize:20 weight:UIFontWeightMedium];
    sectionTitle.textColor = [UIColor colorWithRed:0.15 green:0.15 blue:0.15 alpha:1];
    [self addSubview:sectionTitle];
    [sectionTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_backButton.mas_bottom).offset(28);
        make.left.equalTo(self).offset(20);
    }];

    _nicknameTextField = [UITextField new];
    _nicknameTextField.placeholder   = @"王建军";
    _nicknameTextField.font          = [UIFont systemFontOfSize:16];
    _nicknameTextField.textColor     = [UIColor colorWithRed:0.15 green:0.15 blue:0.15 alpha:1];
    _nicknameTextField.backgroundColor = UIColor.whiteColor;
    _nicknameTextField.layer.cornerRadius = 10;
    _nicknameTextField.layer.masksToBounds = YES;
    _nicknameTextField.clearButtonMode  = UITextFieldViewModeWhileEditing;
    UIView *leftPad = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 14, 1)];
    _nicknameTextField.leftView      = leftPad;
    _nicknameTextField.leftViewMode  = UITextFieldViewModeAlways;
    [self addSubview:_nicknameTextField];
    [_nicknameTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(sectionTitle.mas_bottom).offset(20);
        make.left.equalTo(self).offset(20);
        make.right.equalTo(self).offset(-20);
        make.height.mas_equalTo(52);
    }];

    _confirmButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_confirmButton setTitle:@"确认" forState:UIControlStateNormal];
    [_confirmButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    _confirmButton.titleLabel.font   = [UIFont systemFontOfSize:18 weight:UIFontWeightSemibold];
    _confirmButton.layer.cornerRadius = 26;
    _confirmButton.layer.masksToBounds = YES;

    _confirmGradient = [CAGradientLayer layer];
    _confirmGradient.colors      = @[
        (__bridge id)[UIColor colorWithRed:1.00 green:0.76 blue:0.20 alpha:1].CGColor,
        (__bridge id)[UIColor colorWithRed:0.97 green:0.50 blue:0.08 alpha:1].CGColor
    ];
    _confirmGradient.startPoint  = CGPointMake(0, 0.5);
    _confirmGradient.endPoint    = CGPointMake(1, 0.5);
    _confirmGradient.cornerRadius = 26;
    [_confirmButton.layer insertSublayer:_confirmGradient atIndex:0];

    [self addSubview:_confirmButton];
    [_confirmButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_nicknameTextField.mas_bottom).offset(24);
        make.left.equalTo(self).offset(20);
        make.right.equalTo(self).offset(-20);
        make.height.mas_equalTo(52);
    }];
}

@end
