//
//  TLWEditNicknameView.m
//  TL-PestIdentify
//

#import "TLWEditNicknameView.h"
#import <Masonry/Masonry.h>

@interface TLWEditNicknameView ()
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
    UIImageView *bg = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bgGradient"]];
    bg.contentMode = UIViewContentModeScaleAspectFill;
    [self addSubview:bg];
    [bg mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];

    [self setupPanel];
    [self setupContent];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _confirmGradient.frame = _confirmButton.bounds;
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
        make.top.equalTo(self.mas_safeAreaLayoutGuideTop).offset(52);
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
    UILabel *sectionTitle = [UILabel new];
    sectionTitle.text      = @"请输入您的昵称";
    sectionTitle.font      = [UIFont systemFontOfSize:20 weight:UIFontWeightMedium];
    sectionTitle.textColor = [UIColor colorWithRed:0.15 green:0.15 blue:0.15 alpha:1];
    [self addSubview:sectionTitle];
    [sectionTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.mas_safeAreaLayoutGuideTop).offset(70);
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
