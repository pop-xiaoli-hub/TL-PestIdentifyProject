//
//  TLWEditProfileView.m
//  TL-PestIdentify
//

#import "TLWEditProfileView.h"
#import <Masonry/Masonry.h>

static CGFloat const kCardH      = 58.0;
static CGFloat const kCardRadius = 17.0;
static CGFloat const kCardGap    = 8.0;
static CGFloat const kSidePad    = 23.0;

@interface TLWEditProfileView ()
@property (nonatomic, strong, readwrite) UIButton    *avatarRowButton;
@property (nonatomic, strong, readwrite) UIButton    *nicknameRowButton;
@property (nonatomic, strong, readwrite) UIImageView *avatarImageView;
@property (nonatomic, strong, readwrite) UILabel     *nicknameValueLabel;
@property (nonatomic, strong, readwrite) UIButton    *phoneRowButton;
@property (nonatomic, strong, readwrite) UILabel     *phoneValueLabel;
@property (nonatomic, strong, readwrite) UIButton    *passwordRowButton;
@property (nonatomic, strong, readwrite) UILabel     *cropValueLabel;
@end

@implementation TLWEditProfileView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) [self setupUI];
    return self;
}

- (void)setupUI {
    // bgGradient 背景
    UIImageView *bg = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bgGradient"]];
    bg.contentMode = UIViewContentModeScaleAspectFill;
    [self addSubview:bg];
    [bg mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];

    [self setupPanel];
    [self setupCards];
}

#pragma mark - Panel (大蒙版底板)

- (void)setupPanel {
    // 从导航栏下方开始、延伸到屏幕底部的白色半透明毛玻璃面板
    // 顶部圆角，4 张卡片浮在其上方
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

#pragma mark - Cards

- (void)setupCards {
    UIView *card1 = [self buildAvatarCard];
    UIView *card2 = [self buildNicknameCard];
    UIView *card3 = [self buildPhoneCard];
    UIView *card4 = [self buildPasswordCard];
    UIView *card5 = [self buildCropCard];

    NSArray *cards = @[card1, card2, card3, card4, card5];
    UIView *prev = nil;
    for (UIView *card in cards) {
        [self addSubview:card];
        [card mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self).offset(kSidePad);
            make.right.equalTo(self).offset(-kSidePad);
            make.height.mas_equalTo(kCardH);
            if (prev) {
                make.top.equalTo(prev.mas_bottom).offset(kCardGap);
            } else {
                make.top.equalTo(self.mas_safeAreaLayoutGuideTop).offset(68);
            }
        }];
        prev = card;
    }
}

#pragma mark - Card builders

- (UIView *)buildAvatarCard {
    UIView *card = [self glassCard];

    UILabel *lbl = [self titleLabelWithText:@"头像"];
    [card addSubview:lbl];
    [lbl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(card).offset(16);
        make.centerY.equalTo(card);
    }];

    UILabel *chev = [self chevronLabel];
    [card addSubview:chev];
    [chev mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(card).offset(-16);
        make.centerY.equalTo(card);
    }];

    _avatarImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"avatar"]];
    _avatarImageView.contentMode    = UIViewContentModeScaleAspectFill;
    _avatarImageView.clipsToBounds  = YES;
    _avatarImageView.layer.cornerRadius = 23;
    [card addSubview:_avatarImageView];
    [_avatarImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(chev.mas_left).offset(-10);
        make.centerY.equalTo(card);
        make.width.height.mas_equalTo(46);
    }];

    _avatarRowButton = [self overlayButtonOn:card];
    return card;
}

- (UIView *)buildNicknameCard {
    UIView *card = [self glassCard];

    UILabel *lbl = [self titleLabelWithText:@"昵称"];
    [card addSubview:lbl];
    [lbl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(card).offset(16);
        make.centerY.equalTo(card);
    }];

    UILabel *chev = [self chevronLabel];
    [card addSubview:chev];
    [chev mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(card).offset(-16);
        make.centerY.equalTo(card);
    }];

    _nicknameValueLabel = [self valueLabelText:nil];
    [card addSubview:_nicknameValueLabel];
    [_nicknameValueLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(chev.mas_left).offset(-8);
        make.centerY.equalTo(card);
    }];

    _nicknameRowButton = [self overlayButtonOn:card];
    return card;
}

- (UIView *)buildPhoneCard {
    UIView *card = [self glassCard];

    UILabel *lbl = [self titleLabelWithText:@"绑定手机号"];
    [card addSubview:lbl];
    [lbl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(card).offset(16);
        make.centerY.equalTo(card);
    }];

    _phoneValueLabel = [self valueLabelText:nil];
    [card addSubview:_phoneValueLabel];
    [_phoneValueLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(card).offset(-16);
        make.centerY.equalTo(card);
    }];

    _phoneRowButton = [self overlayButtonOn:card];
    return card;
}

- (UIView *)buildPasswordCard {
    UIView *card = [self glassCard];

    UILabel *lbl = [self titleLabelWithText:@"修改密码"];
    [card addSubview:lbl];
    [lbl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(card).offset(16);
        make.centerY.equalTo(card);
    }];

    UILabel *chev = [self chevronLabel];
    [card addSubview:chev];
    [chev mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(card).offset(-16);
        make.centerY.equalTo(card);
    }];

    _passwordRowButton = [self overlayButtonOn:card];
    return card;
}

- (UIView *)buildCropCard {
    UIView *card = [self glassCard];

    UILabel *lbl = [self titleLabelWithText:@"关注的作物"];
    [card addSubview:lbl];
    [lbl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(card).offset(16);
        make.centerY.equalTo(card);
    }];

    _cropValueLabel = [self valueLabelText:nil];
    [card addSubview:_cropValueLabel];
    [_cropValueLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(card).offset(-16);
        make.centerY.equalTo(card);
    }];

    return card;
}

#pragma mark - Glass card factory

- (UIView *)glassCard {
    UIView *container = [UIView new];
    container.layer.cornerRadius  = kCardRadius;
    container.layer.masksToBounds = NO;

    // 外阴影: rgba(70, 145, 150, 0.11), y=6, blur=12.6
    container.layer.shadowColor   = [UIColor colorWithRed:70/255.0 green:145/255.0 blue:150/255.0 alpha:1].CGColor;
    container.layer.shadowOpacity = 0.11;
    container.layer.shadowRadius  = 6.3;
    container.layer.shadowOffset  = CGSizeMake(0, 6);

    // 毛玻璃 + 白色半透明背景
    UIVisualEffectView *blur = [[UIVisualEffectView alloc] initWithEffect:
                                [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight]];
    blur.layer.cornerRadius  = kCardRadius;
    blur.layer.masksToBounds = YES;
    [container addSubview:blur];
    [blur mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(container);
    }];

    UIView *overlay = [UIView new];
    overlay.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.75];
    [blur.contentView addSubview:overlay];
    [overlay mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(blur.contentView);
    }];

    // 内阴影模拟: 上方青色 + 下方白色边框
    UIView *innerShadow = [UIView new];
    innerShadow.userInteractionEnabled = NO;
    innerShadow.layer.cornerRadius  = kCardRadius;
    innerShadow.layer.masksToBounds = YES;
    innerShadow.layer.borderWidth   = 1.5;
    innerShadow.layer.borderColor   = [UIColor colorWithRed:0.85 green:1.0 blue:0.98 alpha:0.6].CGColor;
    [container addSubview:innerShadow];
    [innerShadow mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(container);
    }];

    return container;
}

#pragma mark - Helpers

- (UILabel *)titleLabelWithText:(NSString *)text {
    UILabel *lbl = [UILabel new];
    lbl.text      = text;
    lbl.font      = [UIFont systemFontOfSize:20 weight:UIFontWeightMedium];
    lbl.textColor = [UIColor colorWithRed:0.20 green:0.20 blue:0.20 alpha:1];
    return lbl;
}

- (UILabel *)valueLabelText:(NSString *)text {
    UILabel *lbl = [UILabel new];
    lbl.text      = text;
    lbl.font      = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    lbl.textColor = [UIColor colorWithRed:0.42 green:0.42 blue:0.42 alpha:1];
    return lbl;
}

- (UILabel *)chevronLabel {
    UILabel *lbl = [UILabel new];
    lbl.text      = @"›";
    lbl.font      = [UIFont systemFontOfSize:24 weight:UIFontWeightMedium];
    lbl.textColor = [UIColor colorWithRed:0.55 green:0.55 blue:0.55 alpha:1];
    return lbl;
}

- (UIButton *)overlayButtonOn:(UIView *)view {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.backgroundColor = UIColor.clearColor;
    [view addSubview:btn];
    [btn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(view);
    }];
    return btn;
}

@end
