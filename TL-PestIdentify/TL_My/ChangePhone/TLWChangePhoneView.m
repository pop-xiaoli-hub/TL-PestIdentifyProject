//
//  TLWChangePhoneView.m
//  TL-PestIdentify
//

#import "TLWChangePhoneView.h"
#import <Masonry/Masonry.h>

@interface TLWChangePhoneView ()

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

    [self setupPanel];
    [self setupCard];
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
        make.top.equalTo(self.mas_safeAreaLayoutGuideTop).offset(62);
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
        make.top.equalTo(self.mas_safeAreaLayoutGuideTop).offset(76);
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

    UILabel *tipLabel = [UILabel new];
    tipLabel.text = @"当前接口仅提交新手机号，不做短信验证码校验。";
    tipLabel.font = [UIFont systemFontOfSize:13];
    tipLabel.textColor = [UIColor colorWithWhite:0.45 alpha:1];
    tipLabel.numberOfLines = 0;
    [content addSubview:tipLabel];
    [tipLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_phoneField.mas_bottom).offset(16);
        make.left.equalTo(content).offset(20);
        make.right.equalTo(content).offset(-20);
    }];

    _codeField = [self buildTextFieldWithPlaceholder:@"当前版本未启用验证码校验" keyboard:UIKeyboardTypeNumberPad];
    _codeField.enabled = NO;
    _codeField.hidden = YES;
    [content addSubview:_codeField];

    _sendCodeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _sendCodeButton.hidden = YES;
    _sendCodeButton.enabled = NO;
    [content addSubview:_sendCodeButton];

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
        make.centerX.equalTo(_confirmButton);
        make.centerY.equalTo(_confirmButton).offset(-5);
    }];

    [content addSubview:_confirmButton];
    [_confirmButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(tipLabel.mas_bottom).offset(24);
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
