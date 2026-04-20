//
//  TLWRecordDetailView.m
//  TL-PestIdentify
//
//  Created by Tommy on 2026/3/13.
//

#import "TLWRecordDetailView.h"
#import <Masonry/Masonry.h>

static CGFloat const kRecordPhotoHeight = 198.0;
static CGFloat const kCardCornerRadius = 22.0;
static NSInteger const kResultPageCount = 3;

@interface TLWRecordDetailView () <UIScrollViewDelegate>

@property (nonatomic, strong, readwrite) UIButton *backButton;
@property (nonatomic, strong, readwrite) UIImageView *photoView;
@property (nonatomic, strong, readwrite) NSArray<UIButton *> *tabButtons;
@property (nonatomic, strong, readwrite) UILabel *pestNameLabel;
@property (nonatomic, strong, readwrite) UILabel *confidenceLabel;
@property (nonatomic, strong, readwrite) UILabel *solutionLabel;
@property (nonatomic, strong, readwrite) UIButton *aiButton;

@property (nonatomic, strong) CAGradientLayer *backgroundGradientLayer;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIImageView *titleIconView;
@property (nonatomic, strong) UIVisualEffectView *cardView;
@property (nonatomic, strong) UIView *cardOverlayView;
@property (nonatomic, strong) UIView *tabContainer;
@property (nonatomic, strong) UIView *pillView;
@property (nonatomic, strong) UIScrollView *resultScrollView;
@property (nonatomic, strong) UIView *pagesContainer;
@property (nonatomic, strong) UIView *aiActionContainer;
@property (nonatomic, strong) UIImageView *aiHintImageView;
@property (nonatomic, strong) UILabel *aiHintLabel;
@property (nonatomic, strong) UILabel *aiTextLabel;
@property (nonatomic, strong) NSArray<TLWRecordResult *> *results;
@property (nonatomic, assign) NSInteger selectedTabIndex;

@property (nonatomic, strong) NSMutableArray<UIScrollView *> *verticalPageScrollViews;
@property (nonatomic, strong) NSMutableArray<UIView *> *pageContentViews;
@property (nonatomic, strong) NSMutableArray<UILabel *> *pagePestTitleLabels;
@property (nonatomic, strong) NSMutableArray<UIView *> *pageTagContainerViews;
@property (nonatomic, strong) NSMutableArray<CAGradientLayer *> *pageTagGradientLayers;
@property (nonatomic, strong) NSMutableArray<UILabel *> *pageTagLabels;
@property (nonatomic, strong) NSMutableArray<UIView *> *pageConfidenceBadgeViews;
@property (nonatomic, strong) NSMutableArray<UILabel *> *pageConfidenceLabels;
@property (nonatomic, strong) NSMutableArray<UILabel *> *pageSolutionTitleLabels;
@property (nonatomic, strong) NSMutableArray<UILabel *> *pageSolutionLabels;

@end

@implementation TLWRecordDetailView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _selectedTabIndex = 0;
        _verticalPageScrollViews = [NSMutableArray array];
        _pageContentViews = [NSMutableArray array];
        _pagePestTitleLabels = [NSMutableArray array];
        _pageTagContainerViews = [NSMutableArray array];
        _pageTagGradientLayers = [NSMutableArray array];
        _pageTagLabels = [NSMutableArray array];
        _pageConfidenceBadgeViews = [NSMutableArray array];
        _pageConfidenceLabels = [NSMutableArray array];
        _pageSolutionTitleLabels = [NSMutableArray array];
        _pageSolutionLabels = [NSMutableArray array];

        [self tl_setupBackground];
        [self tl_setupHeader];
        [self tl_setupPhotoView];
        [self tl_setupBottomCard];
        [self tl_setupFloatingActionArea];
    }
    return self;
}

#pragma mark - Setup

- (void)tl_setupBackground {
    self.backgroundColor = [UIColor colorWithRed:0.95 green:0.98 blue:0.97 alpha:1.0];

    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.colors = @[
        (__bridge id)[UIColor colorWithRed:0.38 green:0.64 blue:0.95 alpha:1.0].CGColor,
        (__bridge id)[UIColor colorWithRed:0.42 green:0.92 blue:0.76 alpha:1.0].CGColor,
        (__bridge id)[UIColor colorWithRed:0.94 green:0.97 blue:0.95 alpha:1.0].CGColor
    ];
    gradientLayer.locations = @[@0.0, @0.32, @1.0];
    gradientLayer.startPoint = CGPointMake(0.0, 0.0);
    gradientLayer.endPoint = CGPointMake(0.85, 1.0);
    [self.layer insertSublayer:gradientLayer atIndex:0];
    self.backgroundGradientLayer = gradientLayer;
}

- (void)tl_setupHeader {
    UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *backImage = [UIImage imageNamed:@"iconBack"];
    if (backImage) {
        [backButton setImage:backImage forState:UIControlStateNormal];
    } else {
        [backButton setTitle:@"<" forState:UIControlStateNormal];
        [backButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    }
    backButton.backgroundColor = [UIColor clearColor];
    backButton.layer.cornerRadius = 22.0;
    backButton.layer.borderWidth = 0.0;
    backButton.layer.borderColor = [UIColor clearColor].CGColor;
    [self addSubview:backButton];
    self.backButton = backButton;

    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = @"识别记录";
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.font = [UIFont systemFontOfSize:22 weight:UIFontWeightBold];
    [self addSubview:titleLabel];
    self.titleLabel = titleLabel;

    UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:20.0
                                                                                         weight:UIImageSymbolWeightBold];
    UIImage *clockImage = [UIImage systemImageNamed:@"clock.fill" withConfiguration:config];
    UIImageView *titleIconView = [[UIImageView alloc] initWithImage:clockImage];
    titleIconView.tintColor = [[UIColor whiteColor] colorWithAlphaComponent:0.96];
    titleIconView.contentMode = UIViewContentModeScaleAspectFit;
    [self addSubview:titleIconView];
    self.titleIconView = titleIconView;

    [backButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.mas_safeAreaLayoutGuideTop).offset(8.0);
        make.left.equalTo(self).offset(16.0);
        make.width.height.mas_equalTo(44.0);
    }];

    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self).offset(-8.0);
        make.centerY.equalTo(backButton).offset(-1.0);
    }];

    [titleIconView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(titleLabel.mas_right).offset(6.0);
        make.centerY.equalTo(titleLabel).offset(1.0);
        make.width.height.mas_equalTo(18.0);
    }];
}

- (void)tl_setupPhotoView {
    UIImageView *photoView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"hp_eg1"]];
    photoView.contentMode = UIViewContentModeScaleAspectFill;
    photoView.clipsToBounds = YES;
    photoView.layer.cornerRadius = 18.0;
    photoView.backgroundColor = [UIColor colorWithWhite:0.86 alpha:1.0];
    self.photoView = photoView;
}

- (void)tl_setupBottomCard {
    UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemMaterialLight];
    UIVisualEffectView *cardView = [[UIVisualEffectView alloc] initWithEffect:blur];
    cardView.layer.cornerRadius = kCardCornerRadius;
    cardView.layer.masksToBounds = YES;
    [self addSubview:cardView];
    self.cardView = cardView;

    UIView *overlay = [[UIView alloc] init];
    overlay.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.58];
    [cardView.contentView addSubview:overlay];
    self.cardOverlayView = overlay;
    [overlay mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(cardView.contentView);
    }];

    UIView *tabContainer = [[UIView alloc] init];
    tabContainer.backgroundColor = [[UIColor colorWithRed:0.74 green:0.86 blue:0.86 alpha:1.0] colorWithAlphaComponent:0.42];
    tabContainer.layer.cornerRadius = 13.0;
    tabContainer.layer.borderWidth = 1.0;
    tabContainer.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.26].CGColor;
    [cardView.contentView addSubview:tabContainer];
    self.tabContainer = tabContainer;

    UIView *pillView = [[UIView alloc] init];
    pillView.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.92];
    pillView.layer.shadowColor = [UIColor colorWithRed:0.21 green:0.56 blue:0.59 alpha:0.22].CGColor;
    pillView.layer.shadowOpacity = 1.0;
    pillView.layer.shadowOffset = CGSizeMake(0, 3);
    pillView.layer.shadowRadius = 8.0;
    [tabContainer addSubview:pillView];
    self.pillView = pillView;

    NSArray<NSString *> *titles = @[@"结果一", @"结果二", @"结果三"];
    NSMutableArray<UIButton *> *buttons = [NSMutableArray array];
    UIView *previousButton = nil;
    for (NSInteger idx = 0; idx < titles.count; idx++) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.tag = idx;
        [button setTitle:titles[idx] forState:UIControlStateNormal];
        [button setTitleColor:[UIColor colorWithWhite:0.48 alpha:1.0] forState:UIControlStateNormal];
        button.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
        [tabContainer addSubview:button];

        [button mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.bottom.equalTo(tabContainer);
            if (previousButton) {
                make.left.equalTo(previousButton.mas_right);
                make.width.equalTo(previousButton);
            } else {
                make.left.equalTo(tabContainer);
                make.width.equalTo(tabContainer).multipliedBy(1.0 / 3.0);
            }
        }];
        previousButton = button;
        [buttons addObject:button];
    }
    self.tabButtons = buttons.copy;

    UIScrollView *pagingScrollView = [[UIScrollView alloc] init];
    pagingScrollView.pagingEnabled = YES;
    pagingScrollView.delegate = self;
    pagingScrollView.showsHorizontalScrollIndicator = NO;
    pagingScrollView.showsVerticalScrollIndicator = NO;
    pagingScrollView.bounces = YES;
    pagingScrollView.alwaysBounceHorizontal = YES;
    pagingScrollView.alwaysBounceVertical = NO;
    pagingScrollView.backgroundColor = [UIColor clearColor];
    [cardView.contentView addSubview:pagingScrollView];
    self.resultScrollView = pagingScrollView;

    UIView *pagesContainer = [[UIView alloc] init];
    pagesContainer.backgroundColor = [UIColor clearColor];
    [pagingScrollView addSubview:pagesContainer];
    self.pagesContainer = pagesContainer;

    for (NSInteger idx = 0; idx < kResultPageCount; idx++) {
        UIScrollView *verticalScrollView = [self tl_buildVerticalPageAtIndex:idx];
        [pagingScrollView addSubview:verticalScrollView];
        [self.verticalPageScrollViews addObject:verticalScrollView];
    }

    [self.cardView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.mas_safeAreaLayoutGuideTop).offset(56.0);
        make.left.right.equalTo(self);
        make.bottom.equalTo(self);
    }];

    [self.cardView.contentView addSubview:self.photoView];
    [self.photoView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.cardView.contentView).offset(20.0);
        make.left.equalTo(self.cardView.contentView).offset(18.0);
        make.right.equalTo(self.cardView.contentView).offset(-18.0);
        make.height.mas_equalTo(kRecordPhotoHeight);
    }];

    [self.tabContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.photoView.mas_bottom).offset(16.0);
        make.left.equalTo(self.cardView.contentView).offset(18.0);
        make.right.equalTo(self.cardView.contentView).offset(-18.0);
        make.height.mas_equalTo(48.0);
    }];

    [self.resultScrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tabContainer.mas_bottom).offset(12.0);
        make.left.equalTo(self.cardView.contentView).offset(18.0);
        make.right.equalTo(self.cardView.contentView).offset(-18.0);
        make.bottom.equalTo(self.mas_safeAreaLayoutGuideBottom).offset(-132.0);
    }];

    [self.pagesContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.resultScrollView);
        make.height.equalTo(self.resultScrollView);
    }];

    UIScrollView *previousPage = nil;
    for (UIScrollView *pageScrollView in self.verticalPageScrollViews) {
        [pageScrollView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.bottom.equalTo(self.resultScrollView);
            make.width.equalTo(self.resultScrollView);
            if (previousPage) {
                make.left.equalTo(previousPage.mas_right);
            } else {
                make.left.equalTo(self.resultScrollView);
            }
        }];
        previousPage = pageScrollView;
    }

    [previousPage mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.resultScrollView);
    }];

    [self selectTabAtIndex:0 animated:NO];
}

- (void)tl_setupFloatingActionArea {
    UIView *aiActionContainer = [[UIView alloc] init];
    [self addSubview:aiActionContainer];
    self.aiActionContainer = aiActionContainer;

    UIImageView *aiHintImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"iconClickShowDetail"]];
    aiHintImageView.contentMode = UIViewContentModeScaleToFill;
    [aiActionContainer addSubview:aiHintImageView];
    self.aiHintImageView = aiHintImageView;

    UILabel *aiHintLabel = [[UILabel alloc] init];
    aiHintLabel.text = @"点击AI小助手\n查询详细方案";
    aiHintLabel.textColor = [UIColor colorWithRed:0.98 green:0.68 blue:0.13 alpha:1.0];
    aiHintLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightBold];
    aiHintLabel.textAlignment = NSTextAlignmentCenter;
    aiHintLabel.numberOfLines = 2;
    aiHintLabel.adjustsFontSizeToFitWidth = YES;
    aiHintLabel.minimumScaleFactor = 0.9;
    [aiActionContainer addSubview:aiHintLabel];
    self.aiHintLabel = aiHintLabel;

    UIButton *aiButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [aiButton setImage:[UIImage imageNamed:@"Ip_AI"] forState:UIControlStateNormal];
    aiButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [aiActionContainer addSubview:aiButton];
    self.aiButton = aiButton;

    UILabel *aiTextLabel = [[UILabel alloc] init];
    aiTextLabel.text = @"AI助手";
    aiTextLabel.textColor = [UIColor colorWithRed:1.0 green:0.69 blue:0.18 alpha:1.0];
    aiTextLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    aiTextLabel.textAlignment = NSTextAlignmentCenter;
    [aiActionContainer addSubview:aiTextLabel];
    self.aiTextLabel = aiTextLabel;

    [aiActionContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self).offset(20.0);
        make.bottom.equalTo(self.mas_safeAreaLayoutGuideBottom).offset(18.0);
        make.width.mas_equalTo(132.0);
        make.height.mas_equalTo(150.0);
    }];

    [aiHintImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.equalTo(aiActionContainer);
        make.width.mas_equalTo(128.0);
        make.height.mas_equalTo(72.0);
    }];

    [aiHintLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(aiHintImageView);
        make.centerY.equalTo(aiHintImageView).offset(-7.0);
        make.width.equalTo(aiHintImageView).offset(2.0);
        make.height.mas_lessThanOrEqualTo(40.0);
    }];

    [aiButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(aiHintImageView.mas_bottom).offset(4.0);
        make.left.equalTo(aiActionContainer);
        make.width.height.mas_equalTo(55.0);
    }];

    [aiTextLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(aiButton.mas_bottom).offset(-9.0);
        make.centerX.equalTo(aiButton);
        make.width.mas_equalTo(72.0);
        make.bottom.equalTo(aiActionContainer);
    }];
}

- (UIScrollView *)tl_buildVerticalPageAtIndex:(NSInteger)index {
    UIScrollView *verticalScrollView = [[UIScrollView alloc] init];
    verticalScrollView.backgroundColor = [UIColor clearColor];
    verticalScrollView.alwaysBounceVertical = YES;
    verticalScrollView.alwaysBounceHorizontal = NO;
    verticalScrollView.showsVerticalScrollIndicator = NO;
    verticalScrollView.showsHorizontalScrollIndicator = NO;
    verticalScrollView.directionalLockEnabled = YES;
    verticalScrollView.bounces = YES;

    UIView *contentView = [[UIView alloc] init];
    contentView.backgroundColor = [UIColor clearColor];
    [verticalScrollView addSubview:contentView];

    [contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(verticalScrollView);
        make.width.equalTo(verticalScrollView);
    }];
    [self.pageContentViews addObject:contentView];

    UILabel *pestTitleLabel = [[UILabel alloc] init];
    pestTitleLabel.text = @"病害名称";
    pestTitleLabel.textColor = [UIColor colorWithWhite:0.22 alpha:1.0];
    pestTitleLabel.font = [UIFont systemFontOfSize:22 weight:UIFontWeightSemibold];
    [contentView addSubview:pestTitleLabel];
    [self.pagePestTitleLabels addObject:pestTitleLabel];

    UIView *tagContainerView = [[UIView alloc] init];
    tagContainerView.layer.masksToBounds = YES;
    [contentView addSubview:tagContainerView];
    [self.pageTagContainerViews addObject:tagContainerView];

    CAGradientLayer *tagGradientLayer = [CAGradientLayer layer];
    tagGradientLayer.colors = @[
        (__bridge id)[UIColor colorWithRed:0.31 green:0.70 blue:0.98 alpha:1.0].CGColor,
        (__bridge id)[UIColor colorWithRed:0.43 green:0.90 blue:0.83 alpha:1.0].CGColor
    ];
    tagGradientLayer.startPoint = CGPointMake(0.0, 0.5);
    tagGradientLayer.endPoint = CGPointMake(1.0, 0.5);
    [tagContainerView.layer insertSublayer:tagGradientLayer atIndex:0];
    [self.pageTagGradientLayers addObject:tagGradientLayer];

    UILabel *pestNameLabel = [[UILabel alloc] init];
    pestNameLabel.text = @"无结果";
    pestNameLabel.textColor = [UIColor whiteColor];
    pestNameLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
    pestNameLabel.textAlignment = NSTextAlignmentCenter;
    pestNameLabel.backgroundColor = [UIColor clearColor];
    [tagContainerView addSubview:pestNameLabel];
    [self.pageTagLabels addObject:pestNameLabel];

    UIView *confidenceBadgeView = [[UIView alloc] init];
    confidenceBadgeView.backgroundColor = [UIColor colorWithRed:1.0 green:0.70 blue:0.26 alpha:1.0];
    confidenceBadgeView.layer.cornerRadius = 11.0;
    confidenceBadgeView.hidden = YES;
    [contentView addSubview:confidenceBadgeView];
    [self.pageConfidenceBadgeViews addObject:confidenceBadgeView];

    UILabel *confidenceLabel = [[UILabel alloc] init];
    confidenceLabel.textColor = [UIColor whiteColor];
    confidenceLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightSemibold];
    confidenceLabel.textAlignment = NSTextAlignmentCenter;
    [confidenceBadgeView addSubview:confidenceLabel];
    [self.pageConfidenceLabels addObject:confidenceLabel];

    UILabel *solutionTitleLabel = [[UILabel alloc] init];
    solutionTitleLabel.text = @"解决方案";
    solutionTitleLabel.textColor = [UIColor colorWithWhite:0.22 alpha:1.0];
    solutionTitleLabel.font = [UIFont systemFontOfSize:22 weight:UIFontWeightSemibold];
    [contentView addSubview:solutionTitleLabel];
    [self.pageSolutionTitleLabels addObject:solutionTitleLabel];

    UILabel *solutionLabel = [[UILabel alloc] init];
    solutionLabel.numberOfLines = 0;
    solutionLabel.textColor = [UIColor colorWithWhite:0.32 alpha:1.0];
    solutionLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    solutionLabel.text = @"当前未返回该候选结果";
    [self tl_applySolutionStyleToLabel:solutionLabel];
    [contentView addSubview:solutionLabel];
    [self.pageSolutionLabels addObject:solutionLabel];

    [pestTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(contentView).offset(10.0);
        make.left.equalTo(contentView).offset(2.0);
    }];

    [tagContainerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(pestTitleLabel.mas_bottom).offset(14.0);
        make.left.equalTo(contentView).offset(8.0);
        make.width.mas_equalTo([self tl_widthForTagText:pestNameLabel.text]);
        make.height.mas_equalTo(54.0);
    }];

    [pestNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(tagContainerView);
    }];

    [confidenceBadgeView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(tagContainerView).offset(-8.0);
        make.right.equalTo(tagContainerView).offset(8.0);
        make.width.mas_equalTo(36.0);
        make.height.mas_equalTo(22.0);
    }];

    [confidenceLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(confidenceBadgeView);
    }];

    [solutionTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(tagContainerView.mas_bottom).offset(24.0);
        make.left.equalTo(contentView).offset(2.0);
    }];

    [solutionLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(solutionTitleLabel.mas_bottom).offset(12.0);
        make.left.equalTo(contentView).offset(2.0);
        make.right.equalTo(contentView).offset(-6.0);
    }];

    [contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(solutionLabel.mas_bottom).offset(72.0);
    }];

    if (index == 0) {
        self.pestNameLabel = pestNameLabel;
        self.confidenceLabel = confidenceLabel;
        self.solutionLabel = solutionLabel;
    }

    return verticalScrollView;
}

#pragma mark - Public

- (void)configureWithResults:(NSArray<TLWRecordResult *> *)results {
    self.results = results ?: @[];

    for (NSInteger idx = 0; idx < kResultPageCount; idx++) {
        UIButton *button = idx < self.tabButtons.count ? self.tabButtons[idx] : nil;
        NSString *defaultTitle = [NSString stringWithFormat:@"结果%ld", (long)(idx + 1)];
        [button setTitle:defaultTitle forState:UIControlStateNormal];

        UILabel *tagLabel = self.pageTagLabels[idx];
        tagLabel.text = @"无结果";

        UIView *tagContainerView = self.pageTagContainerViews[idx];
        [tagContainerView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.width.mas_equalTo([self tl_widthForTagText:tagLabel.text]);
        }];

        UILabel *confidenceLabel = self.pageConfidenceLabels[idx];
        confidenceLabel.text = @"";
        self.pageConfidenceBadgeViews[idx].hidden = YES;

        UILabel *solutionLabel = self.pageSolutionLabels[idx];
        solutionLabel.text = @"当前未返回该候选结果";
        [self tl_applySolutionStyleToLabel:solutionLabel];
    }

    [self.results enumerateObjectsUsingBlock:^(TLWRecordResult * _Nonnull result, NSUInteger idx, BOOL * _Nonnull stop) {
        if (idx >= kResultPageCount) {
            *stop = YES;
            return;
        }

        NSString *title = result.title.length > 0 ? result.title : [NSString stringWithFormat:@"结果%lu", (unsigned long)(idx + 1)];
        [self.tabButtons[idx] setTitle:title forState:UIControlStateNormal];

        NSString *pestName = result.pestName.length > 0 ? result.pestName : @"无结果";
        UILabel *tagLabel = self.pageTagLabels[idx];
        tagLabel.text = pestName;
        [self.pageTagContainerViews[idx] mas_updateConstraints:^(MASConstraintMaker *make) {
            make.width.mas_equalTo([self tl_widthForTagText:pestName]);
        }];

        NSString *confidence = [result displayConfidenceText];
        self.pageConfidenceLabels[idx].text = confidence;
        self.pageConfidenceBadgeViews[idx].hidden = (confidence.length == 0 || [confidence isEqualToString:@"--"]);

        UILabel *solutionLabel = self.pageSolutionLabels[idx];
        solutionLabel.text = result.solution.length > 0 ? result.solution : @"当前未返回该候选结果";
        [self tl_applySolutionStyleToLabel:solutionLabel];
    }];

    NSInteger targetIndex = self.results.count > 0 ? MIN(self.selectedTabIndex, self.results.count - 1) : 0;
    [self selectTabAtIndex:targetIndex animated:NO];
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

- (void)selectTabAtIndex:(NSInteger)index animated:(BOOL)animated {
    if (index < 0 || index >= self.tabButtons.count) {
        return;
    }

    self.selectedTabIndex = index;

    CGFloat pageWidth = CGRectGetWidth(self.resultScrollView.bounds);
    if (pageWidth > 0) {
        CGPoint offset = CGPointMake(pageWidth * index, 0);
        [self.resultScrollView setContentOffset:offset animated:animated];
    }

    [self tl_applyTabVisualStateAnimated:animated];
}

#pragma mark - Layout

- (void)layoutSubviews {
    [super layoutSubviews];

    self.backgroundGradientLayer.frame = self.bounds;

    [self.pageTagGradientLayers enumerateObjectsUsingBlock:^(CAGradientLayer * _Nonnull gradientLayer, NSUInteger idx, BOOL * _Nonnull stop) {
        if (idx >= self.pageTagContainerViews.count) {
            return;
        }
        UIView *containerView = self.pageTagContainerViews[idx];
        containerView.layer.cornerRadius = containerView.bounds.size.height * 0.28;
        gradientLayer.frame = containerView.bounds;
        gradientLayer.cornerRadius = containerView.layer.cornerRadius;
    }];

    CGFloat pageWidth = CGRectGetWidth(self.resultScrollView.bounds);
    if (pageWidth > 0) {
        CGPoint targetOffset = CGPointMake(pageWidth * self.selectedTabIndex, 0);
        if (fabs(self.resultScrollView.contentOffset.x - targetOffset.x) > 0.5) {
            [self.resultScrollView setContentOffset:targetOffset animated:NO];
        }
    }

    [self tl_applyTabVisualStateAnimated:NO];

    [self bringSubviewToFront:self.cardView];
    [self bringSubviewToFront:self.aiActionContainer];
    [self bringSubviewToFront:self.backButton];
    [self bringSubviewToFront:self.titleLabel];
    [self bringSubviewToFront:self.titleIconView];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (scrollView != self.resultScrollView) {
        return;
    }
    [self tl_syncTabWithPagingScrollView];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    if (scrollView != self.resultScrollView) {
        return;
    }
    [self tl_syncTabWithPagingScrollView];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (scrollView != self.resultScrollView || decelerate) {
        return;
    }
    [self tl_syncTabWithPagingScrollView];
}

#pragma mark - Private

- (void)tl_syncTabWithPagingScrollView {
    CGFloat pageWidth = CGRectGetWidth(self.resultScrollView.bounds);
    if (pageWidth <= 0) {
        return;
    }

    NSInteger index = (NSInteger)lround(self.resultScrollView.contentOffset.x / pageWidth);
    index = MAX(0, MIN(index, self.tabButtons.count - 1));
    self.selectedTabIndex = index;
    [self tl_applyTabVisualStateAnimated:YES];
}

- (void)tl_applyTabVisualStateAnimated:(BOOL)animated {
    [self.tabButtons enumerateObjectsUsingBlock:^(UIButton * _Nonnull button, NSUInteger idx, BOOL * _Nonnull stop) {
        UIColor *titleColor = (idx == self.selectedTabIndex)
            ? [UIColor colorWithRed:0.25 green:0.72 blue:0.76 alpha:1.0]
            : [UIColor colorWithWhite:0.48 alpha:1.0];
        [button setTitleColor:titleColor forState:UIControlStateNormal];
    }];

    if (self.tabContainer.bounds.size.width <= 0 || self.tabButtons.count == 0) {
        return;
    }

    CGFloat tabWidth = self.tabContainer.bounds.size.width / self.tabButtons.count;
    CGRect targetFrame = CGRectMake(self.selectedTabIndex * tabWidth + 4.0,
                                    4.0,
                                    tabWidth - 8.0,
                                    self.tabContainer.bounds.size.height - 8.0);
    void (^animations)(void) = ^{
        self.pillView.frame = targetFrame;
        self.pillView.layer.cornerRadius = self.pillView.bounds.size.height * 0.5;
    };

    if (animated) {
        [UIView animateWithDuration:0.22 animations:animations];
    } else {
        animations();
    }
}

- (CGFloat)tl_widthForTagText:(NSString *)text {
    NSString *safeText = text.length > 0 ? text : @"";
    UIFont *font = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
    CGSize textSize = [safeText sizeWithAttributes:@{NSFontAttributeName: font}];
    return MAX(96.0, ceil(textSize.width) + 38.0);
}

- (void)tl_applySolutionStyleToLabel:(UILabel *)label {
    if (![label.text isKindOfClass:[NSString class]] || label.text.length == 0) {
        return;
    }

    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineSpacing = 7.0;
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;

    NSDictionary *attributes = @{
        NSParagraphStyleAttributeName: paragraphStyle,
        NSForegroundColorAttributeName: label.textColor ?: [UIColor colorWithWhite:0.32 alpha:1.0],
        NSFontAttributeName: label.font ?: [UIFont systemFontOfSize:16 weight:UIFontWeightMedium]
    };
    label.attributedText = [[NSAttributedString alloc] initWithString:label.text attributes:attributes];
}

@end
