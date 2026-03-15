//
//  TLWRecordDetailView.m
//  TL-PestIdentify
//
//  Created by Tommy on 2026/3/13.
//

#import "TLWRecordDetailView.h"
#import <Masonry/Masonry.h>

static CGFloat const kNavOffset = 8;
static CGFloat const kNavHeight = 48;
static CGFloat const kCardGap   = 13;

@interface TLWRecordDetailView ()
@property (nonatomic, strong) UIButton *backButton;
@property (nonatomic, strong) UIImageView *photoView;
@property (nonatomic, strong) NSArray<UIButton *> *tabButtons;
@property (nonatomic, strong) UILabel *pestNameLabel;
@property (nonatomic, strong) UILabel *confidenceLabel;
@property (nonatomic, strong) UILabel *solutionLabel;
@property (nonatomic, strong) UIButton *aiButton;

// Tab 指示器
@property (nonatomic, strong) UIView *tabContainer;
@property (nonatomic, strong) UIView *pillView;
@property (nonatomic, assign) NSInteger selectedTabIndex;

// 病害标签卡片的渐变层（需在 layoutSubviews 里更新 frame）
@property (nonatomic, strong) CAGradientLayer *diseaseTagGradient;
@property (nonatomic, strong) UIView *diseaseTagView;
@end

@implementation TLWRecordDetailView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        CGFloat safeTop  = [UIApplication sharedApplication].windows.firstObject.safeAreaInsets.top;
        CGFloat navTop   = safeTop + kNavOffset;
        CGFloat cardTop  = navTop + kNavHeight + kCardGap;

        [self tl_setupBackground];
        [self tl_setupCardWithTop:cardTop];
        [self tl_setupNavBarWithTop:navTop];
    }
    return self;
}

#pragma mark - Setup

- (void)tl_setupBackground {
    self.layer.contents = (__bridge id)[UIImage imageNamed:@"hp_backView.png"].CGImage;
}

- (void)tl_setupNavBarWithTop:(CGFloat)navTop {
    _backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_backButton setImage:[UIImage imageNamed:@"iconBack"] forState:UIControlStateNormal];
    [self addSubview:_backButton];
    [_backButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self).offset(16);
        make.top.equalTo(self).offset(navTop);
        make.width.height.mas_equalTo(kNavHeight);
    }];

    // 标题："识别记录" + 时钟图标
    UIView *titleContainer = [[UIView alloc] init];
    [self addSubview:titleContainer];

    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = @"识别记录";
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.font = [UIFont systemFontOfSize:20 weight:UIFontWeightSemibold];
    [titleContainer addSubview:titleLabel];

    UIImageView *clockIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"records"]];
    clockIcon.contentMode = UIViewContentModeScaleAspectFit;
    [titleContainer addSubview:clockIcon];

    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.bottom.equalTo(titleContainer);
    }];
    [clockIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(titleLabel.mas_right).offset(5);
        make.right.equalTo(titleContainer);
        make.centerY.equalTo(titleLabel);
        make.width.height.mas_equalTo(20);
    }];
    [titleContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self);
        make.centerY.equalTo(_backButton);
    }];
}

- (void)tl_setupCardWithTop:(CGFloat)cardTop {
    // 毛玻璃卡片
    UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    UIVisualEffectView *cardView = [[UIVisualEffectView alloc] initWithEffect:blur];
    cardView.layer.cornerRadius = 20;
    cardView.layer.masksToBounds = YES;

    UIView *overlay = [[UIView alloc] init];
    overlay.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.55];
    [cardView.contentView addSubview:overlay];
    [overlay mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(cardView.contentView);
    }];

    [self addSubview:cardView];
    [cardView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self);
        make.top.equalTo(self).offset(cardTop);
    }];

    // 滚动区域（内容可能超出屏幕高度）
    UIScrollView *scrollView = [[UIScrollView alloc] init];
    scrollView.showsVerticalScrollIndicator = NO;
    scrollView.backgroundColor = [UIColor clearColor];
    [self addSubview:scrollView];
    [scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self);
        make.top.equalTo(self).offset(cardTop);
    }];

    UIView *contentView = [[UIView alloc] init];
    contentView.backgroundColor = [UIColor clearColor];
    [scrollView addSubview:contentView];
    [contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(scrollView);
        make.width.equalTo(scrollView); // 固定宽度，只允许纵向滚动
    }];

    [self tl_buildContentInView:contentView];
}

- (void)tl_buildContentInView:(UIView *)container {
    // ── 照片 ──────────────────────────────────────────────────────
    _photoView = [[UIImageView alloc] init];
    _photoView.contentMode = UIViewContentModeScaleAspectFill;
    _photoView.clipsToBounds = YES;
    _photoView.layer.cornerRadius = 15;
    _photoView.backgroundColor = [UIColor colorWithRed:0.85 green:0.90 blue:0.85 alpha:1];
    [container addSubview:_photoView];
    [_photoView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(container).offset(25);
        make.left.equalTo(container).offset(24);
        make.right.equalTo(container).offset(-24);
        make.height.mas_equalTo(280);
    }];

    // ── Tab 栏 ───────────────────────────────────────────────────
    _tabContainer = [[UIView alloc] init];
    _tabContainer.backgroundColor = [UIColor colorWithWhite:0 alpha:0.04];
    _tabContainer.layer.cornerRadius = 10;
    [container addSubview:_tabContainer];
    [_tabContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_photoView.mas_bottom).offset(26);
        make.left.equalTo(container).offset(24);
        make.right.equalTo(container).offset(-24);
        make.height.mas_equalTo(46);
    }];

    // Tab 滑动指示器（白色毛玻璃）
    _pillView = [[UIView alloc] init];
    _pillView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.75];
    _pillView.layer.cornerRadius = 9;
    _pillView.layer.shadowColor = [UIColor colorWithRed:0 green:0.28 blue:0.22 alpha:1].CGColor;
    _pillView.layer.shadowOpacity = 0.16;
    _pillView.layer.shadowRadius = 6;
    _pillView.layer.shadowOffset = CGSizeMake(0, 3);
    [_tabContainer addSubview:_pillView];
    // 初始 frame 在 layoutSubviews 里设置

    NSArray *tabTitles = @[@"结果一", @"结果二", @"结果三"];
    NSMutableArray *buttons = [NSMutableArray array];
    UIView *prevBtn = nil;
    for (int i = 0; i < 3; i++) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.tag = i;
        [btn setTitle:tabTitles[i] forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor colorWithRed:0.29 green:0.29 blue:0.29 alpha:0.7]
                  forState:UIControlStateNormal];
        btn.titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightRegular];
        [_tabContainer addSubview:btn];
        [btn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.bottom.equalTo(_tabContainer);
            if (prevBtn) {
                make.left.equalTo(prevBtn.mas_right);
                make.width.equalTo(prevBtn);
            } else {
                make.left.equalTo(_tabContainer);
                make.width.equalTo(_tabContainer).multipliedBy(1.0/3.0);
            }
        }];
        [buttons addObject:btn];
        prevBtn = btn;
    }
    _tabButtons = [buttons copy];
    _selectedTabIndex = 0;

    // ── 病害名称 ─────────────────────────────────────────────────
    UILabel *pestSectionLabel = [[UILabel alloc] init];
    pestSectionLabel.text = @"病害名称";
    pestSectionLabel.textColor = [UIColor colorWithRed:0.29 green:0.29 blue:0.29 alpha:1];
    pestSectionLabel.font = [UIFont systemFontOfSize:24 weight:UIFontWeightSemibold];
    [container addSubview:pestSectionLabel];
    [pestSectionLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_tabContainer.mas_bottom).offset(20);
        make.left.equalTo(container).offset(24);
    }];

    // 病害标签卡片（渐变背景）
    _diseaseTagView = [[UIView alloc] init];
    _diseaseTagView.layer.cornerRadius = 10;
    _diseaseTagView.layer.masksToBounds = YES;
    [container addSubview:_diseaseTagView];
    [_diseaseTagView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(pestSectionLabel.mas_bottom).offset(16);
        make.left.equalTo(container).offset(30);
        make.width.mas_equalTo(104);
        make.height.mas_equalTo(70);
    }];

    // 渐变层（frame 在 layoutSubviews 更新）
    _diseaseTagGradient = [CAGradientLayer layer];
    _diseaseTagGradient.colors = @[
        (__bridge id)[UIColor colorWithRed:0 green:0.627 blue:1 alpha:1].CGColor,
        (__bridge id)[UIColor colorWithRed:0 green:1 blue:0.808 alpha:1].CGColor
    ];
    _diseaseTagGradient.startPoint = CGPointMake(0.1, 0);
    _diseaseTagGradient.endPoint   = CGPointMake(1.0, 1);
    _diseaseTagGradient.cornerRadius = 10;
    [_diseaseTagView.layer insertSublayer:_diseaseTagGradient atIndex:0];

    _pestNameLabel = [[UILabel alloc] init];
    _pestNameLabel.textColor = [UIColor whiteColor];
    _pestNameLabel.font = [UIFont systemFontOfSize:20 weight:UIFontWeightSemibold];
    _pestNameLabel.textAlignment = NSTextAlignmentCenter;
    [_diseaseTagView addSubview:_pestNameLabel];
    [_pestNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(_diseaseTagView);
    }];

    // 置信度角标（橙色，浮在标签右上角）
    UIView *badgeView = [[UIView alloc] init];
    badgeView.backgroundColor = [UIColor colorWithRed:1 green:0.616 blue:0 alpha:1];
    badgeView.layer.cornerRadius = 11;
    badgeView.layer.shadowColor = [UIColor blackColor].CGColor;
    badgeView.layer.shadowOpacity = 0.25;
    badgeView.layer.shadowRadius = 1;
    badgeView.layer.shadowOffset = CGSizeMake(0, 1);
    [container addSubview:badgeView];
    [badgeView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(_diseaseTagView).offset(4);
        make.top.equalTo(_diseaseTagView).offset(-6);
        make.width.mas_equalTo(36);
        make.height.mas_equalTo(21);
    }];

    _confidenceLabel = [[UILabel alloc] init];
    _confidenceLabel.textColor = [UIColor whiteColor];
    _confidenceLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightSemibold];
    _confidenceLabel.textAlignment = NSTextAlignmentCenter;
    [badgeView addSubview:_confidenceLabel];
    [_confidenceLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(badgeView);
    }];

    // ── 解决方案 ─────────────────────────────────────────────────
    UILabel *solutionSectionLabel = [[UILabel alloc] init];
    solutionSectionLabel.text = @"解决方案";
    solutionSectionLabel.textColor = [UIColor colorWithRed:0.29 green:0.29 blue:0.29 alpha:1];
    solutionSectionLabel.font = [UIFont systemFontOfSize:24 weight:UIFontWeightSemibold];
    [container addSubview:solutionSectionLabel];
    [solutionSectionLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_diseaseTagView.mas_bottom).offset(30);
        make.left.equalTo(container).offset(24);
    }];

    _solutionLabel = [[UILabel alloc] init];
    _solutionLabel.textColor = [UIColor colorWithRed:0.29 green:0.29 blue:0.29 alpha:1];
    _solutionLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    _solutionLabel.numberOfLines = 0;
    _solutionLabel.lineBreakMode = NSLineBreakByWordWrapping;
    [container addSubview:_solutionLabel];
    [_solutionLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(solutionSectionLabel.mas_bottom).offset(12);
        make.left.equalTo(container).offset(24);
        make.right.equalTo(container).offset(-24);
    }];

    // ── AI 助手按钮 ───────────────────────────────────────────────
    // 橙色圆形按钮 + 下方文字，固定在左下角
    UIView *aiContainer = [[UIView alloc] init];
    [container addSubview:aiContainer];
    [aiContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_solutionLabel.mas_bottom).offset(30);
        make.left.equalTo(container).offset(24);
        make.bottom.equalTo(container).offset(-30); // 撑开 scrollView 内容高度
    }];

    _aiButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _aiButton.backgroundColor = [UIColor colorWithRed:1 green:0.710 blue:0.141 alpha:1];
    _aiButton.layer.cornerRadius = 22;
    _aiButton.layer.shadowColor = [UIColor colorWithRed:1 green:0.663 blue:0 alpha:1].CGColor;
    _aiButton.layer.shadowOpacity = 0.52;
    _aiButton.layer.shadowRadius = 5;
    _aiButton.layer.shadowOffset = CGSizeMake(0, 4);
    [_aiButton setImage:[UIImage imageNamed:@"aiAssistant"] forState:UIControlStateNormal];
    _aiButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [aiContainer addSubview:_aiButton];
    [_aiButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.equalTo(aiContainer);
        make.width.height.mas_equalTo(44);
    }];

    UILabel *aiLabel = [[UILabel alloc] init];
    aiLabel.text = @"AI助手";
    aiLabel.textColor = [UIColor colorWithRed:1 green:0.710 blue:0.141 alpha:1];
    aiLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
    aiLabel.textAlignment = NSTextAlignmentCenter;
    [aiContainer addSubview:aiLabel];
    [aiLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_aiButton.mas_bottom).offset(4);
        make.centerX.equalTo(_aiButton);
        make.bottom.equalTo(aiContainer);
    }];
}

#pragma mark - Layout

- (void)layoutSubviews {
    [super layoutSubviews];

    // CAGradientLayer 需手动跟随 bounds
    _diseaseTagGradient.frame = _diseaseTagView.bounds;

    // Tab 滑动指示器定位（依赖 tabContainer 实际 bounds）
    if (_tabContainer.bounds.size.width > 0) {
        CGFloat tabW = _tabContainer.bounds.size.width / 3.0;
        _pillView.frame = CGRectMake(_selectedTabIndex * tabW + 3, 3,
                                     tabW - 6,
                                     _tabContainer.bounds.size.height - 6);
    }
}

#pragma mark - Public

- (void)selectTabAtIndex:(NSInteger)index animated:(BOOL)animated {
    if (index < 0 || index > 2) return;
    _selectedTabIndex = index;

    CGFloat tabW = _tabContainer.bounds.size.width / 3.0;
    CGRect newPillFrame = CGRectMake(index * tabW + 3, 3,
                                     tabW - 6,
                                     _tabContainer.bounds.size.height - 6);

    [UIView animateWithDuration:animated ? 0.22 : 0 animations:^{
        self->_pillView.frame = newPillFrame;
    }];

    // 更新 tab 文字颜色和字重
    UIColor *activeColor   = [UIColor colorWithRed:0 green:0.812 blue:0.675 alpha:1];
    UIColor *inactiveColor = [UIColor colorWithRed:0.29 green:0.29 blue:0.29 alpha:0.7];
    for (int i = 0; i < 3; i++) {
        BOOL selected = (i == index);
        UIButton *btn = _tabButtons[i];
        [btn setTitleColor:selected ? activeColor : inactiveColor forState:UIControlStateNormal];
        btn.titleLabel.font = selected
            ? [UIFont systemFontOfSize:20 weight:UIFontWeightSemibold]
            : [UIFont systemFontOfSize:18 weight:UIFontWeightRegular];
    }
}

@end
