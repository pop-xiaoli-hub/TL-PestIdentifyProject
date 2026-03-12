//
//  TLWGuideView.m
//  TL-PestIdentify
//
//  引导页 View
//

#import "TLWGuideView.h"
#import <Masonry/Masonry.h>

@interface TLWGuideView ()

@property (nonatomic, strong) UILabel  *titleLabel;

@property (nonatomic, strong, readwrite) UIButton *needButton;
@property (nonatomic, strong, readwrite) UIButton *noNeedButton;
@property (nonatomic, strong, readwrite) UIButton *confirmButton;

@end

@implementation TLWGuideView

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
    [self setupTitle];
    [self setupCards];
    [self setupConfirmButton];
}

#pragma mark - 背景（复用登录页相同资源）

- (void)setupBackground {
    UIImageView *bgImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bgGradient"]];
    bgImageView.contentMode = UIViewContentModeScaleAspectFill;
    bgImageView.clipsToBounds = YES;
    [self addSubview:bgImageView];
    [bgImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];

    UIImageView *bgCard = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bgCard"]];
    bgCard.contentMode = UIViewContentModeScaleToFill;
    [self addSubview:bgCard];
    [bgCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self);
        make.height.mas_equalTo(792);
    }];
}

#pragma mark - 标题

- (void)setupTitle {
    _titleLabel = [[UILabel alloc] init];
    _titleLabel.numberOfLines = 1;

    NSDictionary *normalAttr = @{
        NSFontAttributeName:            [UIFont systemFontOfSize:22 weight:UIFontWeightMedium],
        NSForegroundColorAttributeName: UIColor.whiteColor,
    };
    NSDictionary *boldAttr = @{
        NSFontAttributeName:            [UIFont systemFontOfSize:32 weight:UIFontWeightSemibold],
        NSForegroundColorAttributeName: UIColor.whiteColor,
    };
    NSMutableAttributedString *title = [[NSMutableAttributedString alloc] init];
    [title appendAttributedString:[[NSAttributedString alloc] initWithString:@"您是否需要更适合" attributes:normalAttr]];
    [title appendAttributedString:[[NSAttributedString alloc] initWithString:@"老年人" attributes:boldAttr]];
    [title appendAttributedString:[[NSAttributedString alloc] initWithString:@"的页面" attributes:normalAttr]];
    _titleLabel.attributedText = title;

    [self addSubview:_titleLabel];
    [_titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.mas_safeAreaLayoutGuideTop).offset(30);
        make.left.equalTo(self).offset(38);
    }];
}

#pragma mark - 选项卡 + 人物角色

- (void)setupCards {
    UIImage *modeBg = [[UIImage imageNamed:@"modeRectangle"]
                       resizableImageWithCapInsets:UIEdgeInsetsMake(20, 20, 20, 20)
                       resizingMode:UIImageResizingModeStretch];

    // ── 「需要」卡片 ──
    _needButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _needButton.clipsToBounds = NO;   // 允许人物图标从卡片上方溢出
    [_needButton setBackgroundImage:modeBg forState:UIControlStateNormal];
    [self addSubview:_needButton];
    [_needButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_titleLabel.mas_bottom).offset(90); // 为头部溢出留空间
        make.centerX.equalTo(self);
        make.width.mas_equalTo(274);
        make.height.mas_equalTo(190);
    }];

    UILabel *needLabel = [[UILabel alloc] init];
    needLabel.text          = @"需要";
    needLabel.font          = [UIFont systemFontOfSize:32 weight:UIFontWeightMedium];
    needLabel.textColor     = UIColor.blackColor;
    needLabel.userInteractionEnabled = NO;
    [_needButton addSubview:needLabel];
    [needLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(_needButton);
        make.right.equalTo(_needButton).offset(-40);
    }];

    // ── 「不需要」卡片 ──
    _noNeedButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _noNeedButton.clipsToBounds = NO;
    [_noNeedButton setBackgroundImage:modeBg forState:UIControlStateNormal];
    [self addSubview:_noNeedButton];
    [_noNeedButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_needButton.mas_bottom).offset(30);
        make.centerX.equalTo(self);
        make.width.mas_equalTo(274);
        make.height.mas_equalTo(188);
    }];

    UILabel *noNeedLabel = [[UILabel alloc] init];
    noNeedLabel.text          = @"不需要";
    noNeedLabel.font          = [UIFont systemFontOfSize:32 weight:UIFontWeightMedium];
    noNeedLabel.textColor     = UIColor.blackColor;
    noNeedLabel.userInteractionEnabled = NO;
    [_noNeedButton addSubview:noNeedLabel];
    [noNeedLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(_noNeedButton);
        make.left.equalTo(_noNeedButton).offset(30);
    }];

    // ── 老人图标（左侧，头部溢出卡片上方）──
    UIImageView *oldIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"iconOld"]];
    oldIcon.contentMode = UIViewContentModeScaleAspectFit;
    oldIcon.userInteractionEnabled = NO;
    [self addSubview:oldIcon];   // 作为兄弟视图叠在卡片上
    [oldIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(_needButton.mas_bottom).offset(-15);
        make.left.equalTo(_needButton.mas_left).offset(5);
        make.width.mas_equalTo(120);
        make.height.mas_equalTo(240);
    }];

    // ── 年轻人图标（右侧，头部溢出卡片上方）──
    UIImageView *youngIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"iconYoung"]];
    youngIcon.contentMode = UIViewContentModeScaleAspectFit;
    youngIcon.userInteractionEnabled = NO;
    [self addSubview:youngIcon];
    [youngIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(_noNeedButton.mas_bottom).offset(-10);
        make.right.equalTo(_noNeedButton.mas_right).offset(-5);
        make.width.mas_equalTo(120);
        make.height.mas_equalTo(230);
    }];
}

#pragma mark - 确认按钮

- (void)setupConfirmButton {
    _confirmButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _confirmButton.layer.cornerRadius = 14;
    _confirmButton.clipsToBounds = YES;

    UIImage *commitBg = [[UIImage imageNamed:@"commitRectangle"]
                         resizableImageWithCapInsets:UIEdgeInsetsMake(0, 40, 0, 40)
                         resizingMode:UIImageResizingModeStretch];
    [_confirmButton setBackgroundImage:commitBg forState:UIControlStateNormal];

    UILabel *confirmLabel = [[UILabel alloc] init];
    confirmLabel.text = @"确认";
    confirmLabel.textColor = UIColor.whiteColor;
    confirmLabel.font = [UIFont systemFontOfSize:21 weight:UIFontWeightSemibold];
    confirmLabel.userInteractionEnabled = NO;
    [_confirmButton addSubview:confirmLabel];

    [confirmLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(_confirmButton);
        make.centerY.equalTo(_confirmButton).offset(-10);
    }];

    [self addSubview:_confirmButton];
    [_confirmButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.mas_safeAreaLayoutGuideBottom).offset(-34);
        make.left.equalTo(self.mas_safeAreaLayoutGuideLeft).offset(21);
        make.right.equalTo(self.mas_safeAreaLayoutGuideRight).offset(-21);
        make.height.mas_equalTo(80);
    }];
}

#pragma mark - 选中状态高亮

- (void)setSelectedOption:(NSInteger)option {
    CGColorRef teal   = [UIColor colorWithRed:0.0 green:0.745 blue:0.671 alpha:1.0].CGColor;
    CGColorRef clear  = [UIColor clearColor].CGColor;

    _needButton.layer.cornerRadius  = 20;
    _needButton.layer.borderColor   = (option == 0) ? teal : clear;
    _needButton.layer.borderWidth   = (option == 0) ? 2.5 : 0;
    _needButton.alpha               = (option == 1) ? 0.6 : 1.0;

    _noNeedButton.layer.cornerRadius = 20;
    _noNeedButton.layer.borderColor  = (option == 1) ? teal : clear;
    _noNeedButton.layer.borderWidth  = (option == 1) ? 2.5 : 0;
    _noNeedButton.alpha              = (option == 0) ? 0.6 : 1.0;
}

@end
