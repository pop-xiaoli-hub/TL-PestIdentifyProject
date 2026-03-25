//
//  TLWEditProfileView.m
//  TL-PestIdentify
//

#import "TLWEditProfileView.h"
#import <Masonry/Masonry.h>

static CGFloat const kRowH = 56.0;

@interface TLWEditProfileView ()
@property (nonatomic, strong, readwrite) UIButton    *backButton;
@property (nonatomic, strong, readwrite) UIButton    *avatarRowButton;
@property (nonatomic, strong, readwrite) UIButton    *nicknameRowButton;
@property (nonatomic, strong, readwrite) UIButton    *backgroundRowButton;
@property (nonatomic, strong, readwrite) UIImageView *avatarImageView;
@property (nonatomic, strong, readwrite) UILabel     *nicknameValueLabel;
@property (nonatomic, strong, readwrite) UILabel     *phoneValueLabel;
@property (nonatomic, strong, readwrite) UILabel     *cropValueLabel;
@end

@implementation TLWEditProfileView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) [self setupUI];
    return self;
}

- (void)setupUI {
    self.layer.contents = (__bridge id)[UIImage imageNamed:@"hp_backView"].CGImage;
    [self setupNavBar];
    [self setupCard];
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
    title.text      = @"编辑资料";
    title.textColor = UIColor.whiteColor;
    title.font      = [UIFont systemFontOfSize:20 weight:UIFontWeightSemibold];
    [self addSubview:title];
    [title mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self);
        make.centerY.equalTo(_backButton);
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
        make.top.equalTo(_backButton.mas_bottom).offset(16);
        make.left.equalTo(self).offset(16);
        make.right.equalTo(self).offset(-16);
    }];

    // Build rows
    UIView *r1 = [self buildAvatarRow];
    UIView *r2 = [self buildNicknameRow];
    UIView *r3 = [self buildBackgroundRow];
    UIView *r4 = [self buildPhoneRow];
    UIView *r5 = [self buildCropRow];

    NSArray *rows = @[r1, r2, r3, r4, r5];
    UIView *prev  = nil;
    for (NSInteger i = 0; i < rows.count; i++) {
        UIView *row = rows[i];
        [card.contentView addSubview:row];
        [row mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(card.contentView);
            make.height.mas_equalTo(kRowH);
            if (prev) make.top.equalTo(prev.mas_bottom);
            else       make.top.equalTo(card.contentView);
            if (i == (NSInteger)rows.count - 1) make.bottom.equalTo(card.contentView);
        }];

        if (i < (NSInteger)rows.count - 1) {
            UIView *sep = [UIView new];
            sep.backgroundColor = [UIColor colorWithRed:0.88 green:0.88 blue:0.88 alpha:1];
            [card.contentView addSubview:sep];
            [sep mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(card.contentView).offset(16);
                make.right.equalTo(card.contentView).offset(-16);
                make.bottom.equalTo(row.mas_bottom);
                make.height.mas_equalTo(0.5);
            }];
        }
        prev = row;
    }
}

#pragma mark - Row builders

- (UIView *)buildAvatarRow {
    UIView *row = [self baseRowWithTitle:@"头像"];

    _avatarImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"avatar"]];
    _avatarImageView.contentMode    = UIViewContentModeScaleAspectFill;
    _avatarImageView.clipsToBounds  = YES;
    _avatarImageView.layer.cornerRadius = 16;
    [row addSubview:_avatarImageView];
    [_avatarImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(row).offset(-36);
        make.centerY.equalTo(row);
        make.width.height.mas_equalTo(32);
    }];

    UILabel *chev = [self chevronLabel];
    [row addSubview:chev];
    [chev mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(row).offset(-16);
        make.centerY.equalTo(row);
    }];

    _avatarRowButton = [self overlayButtonOn:row];
    return row;
}

- (UIView *)buildNicknameRow {
    UIView *row = [self baseRowWithTitle:@"昵称"];

    _nicknameValueLabel = [self valueLabel];
    [row addSubview:_nicknameValueLabel];
    [_nicknameValueLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(row).offset(-36);
        make.centerY.equalTo(row);
    }];

    UILabel *chev = [self chevronLabel];
    [row addSubview:chev];
    [chev mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(row).offset(-16);
        make.centerY.equalTo(row);
    }];

    _nicknameRowButton = [self overlayButtonOn:row];
    return row;
}

- (UIView *)buildBackgroundRow {
    UIView *row = [self baseRowWithTitle:@"更换背景"];

    UILabel *chev = [self chevronLabel];
    [row addSubview:chev];
    [chev mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(row).offset(-16);
        make.centerY.equalTo(row);
    }];

    _backgroundRowButton = [self overlayButtonOn:row];
    return row;
}

- (UIView *)buildPhoneRow {
    UIView *row = [self baseRowWithTitle:@"绑定手机号"];

    _phoneValueLabel = [self valueLabel];
    [row addSubview:_phoneValueLabel];
    [_phoneValueLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(row).offset(-16);
        make.centerY.equalTo(row);
    }];
    return row;
}

- (UIView *)buildCropRow {
    UIView *row = [self baseRowWithTitle:@"关注的作物"];

    _cropValueLabel = [self valueLabel];
    [row addSubview:_cropValueLabel];
    [_cropValueLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(row).offset(-16);
        make.centerY.equalTo(row);
    }];
    return row;
}

#pragma mark - Helpers

- (UIView *)baseRowWithTitle:(NSString *)title {
    UIView *row = [UIView new];
    row.backgroundColor = UIColor.clearColor;

    UILabel *lbl = [UILabel new];
    lbl.text      = title;
    lbl.font      = [UIFont systemFontOfSize:16];
    lbl.textColor = [UIColor colorWithRed:0.20 green:0.20 blue:0.20 alpha:1];
    [row addSubview:lbl];
    [lbl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(row).offset(16);
        make.centerY.equalTo(row);
    }];
    return row;
}

- (UILabel *)valueLabel {
    UILabel *lbl = [UILabel new];
    lbl.font      = [UIFont systemFontOfSize:15];
    lbl.textColor = [UIColor colorWithRed:0.55 green:0.55 blue:0.55 alpha:1];
    return lbl;
}

- (UILabel *)chevronLabel {
    UILabel *lbl = [UILabel new];
    lbl.text      = @"›";
    lbl.font      = [UIFont systemFontOfSize:22];
    lbl.textColor = [UIColor colorWithRed:0.70 green:0.70 blue:0.70 alpha:1];
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
