//
//  TLWIdentifyResultView.m
//  TL-PestIdentify
//
//  Created by xiaoli pop on 2026/4/3.
//

#import "TLWIdentifyResultView.h"
#import <Masonry/Masonry.h>

static CGFloat const kTopPhotoHeight = 326.0;
static CGFloat const kCardCornerRadius = 22.0;
static NSInteger const kResultPageCount = 3;

@interface TLWIdentifyResultView () <UIScrollViewDelegate>

@property (nonatomic, strong, readwrite) UIButton *backButton;
@property (nonatomic, strong, readwrite) UIImageView *photoView;
@property (nonatomic, strong, readwrite) UIScrollView *resultScrollView;
@property (nonatomic, strong, readwrite) NSArray<UIButton *> *tabButtons;
@property (nonatomic, strong, readwrite) UILabel *pestNameLabel;
@property (nonatomic, strong, readwrite) UILabel *confidenceLabel;
@property (nonatomic, strong, readwrite) UILabel *solutionLabel;
@property (nonatomic, strong, readwrite) UIButton *aiButton;
@property (nonatomic, strong, readwrite) UIButton *retakeButton;
@property (nonatomic, strong) UILabel *aiTextLabel;
@property (nonatomic, strong) UIImageView *aiHintImageView;
@property (nonatomic, strong) UILabel *aiHintLabel;

@property (nonatomic, strong) UILabel *headerTitleLabel;
@property (nonatomic, strong) UIView *headerTitleContainer;
@property (nonatomic, strong) UIImageView *headerTitleIconView;
@property (nonatomic, strong) UIVisualEffectView *effectiveView;
@property (nonatomic, strong) UIView *effectiveOverlayView;
@property (nonatomic, strong) UIVisualEffectView *cardView;
@property (nonatomic, strong) UIView *cardOverlayView;
@property (nonatomic, strong) UIView *tabContainer;
@property (nonatomic, strong) UIView *pillView;
@property (nonatomic, strong) UIView *pagesContainer;
@property (nonatomic, strong) NSMutableArray<UIScrollView *> *verticalPageScrollViews;
@property (nonatomic, strong) NSMutableArray<UIView *> *pageContentViews;
@property (nonatomic, strong) NSMutableArray<UILabel *> *pagePestTitleLabels;
@property (nonatomic, strong) NSMutableArray<UILabel *> *pageTagLabels;
@property (nonatomic, strong) NSMutableArray<UIView *> *pageConfidenceBadgeViews;
@property (nonatomic, strong) NSMutableArray<UILabel *> *pageConfidenceLabels;
@property (nonatomic, strong) NSMutableArray<UILabel *> *pageSolutionTitleLabels;
@property (nonatomic, strong) NSMutableArray<UILabel *> *pageSolutionLabels;
@property (nonatomic, strong) NSMutableArray<UIImageView *> *pageAIHintBackgroundViews;
@property (nonatomic, strong) NSMutableArray<UIImageView *> *pageWarnIconViews;
@property (nonatomic, strong) NSMutableArray<UIView *> *pageTagContainerViews;
@property (nonatomic, strong) NSMutableArray<CAGradientLayer *> *pageTagGradientLayers;
@property (nonatomic, strong) UIView *firstPageContentView;
@property (nonatomic, strong) UILabel *firstPagePestTitleLabel;
@property (nonatomic, strong) UIView *firstPageConfidenceBadgeView;
@property (nonatomic, strong) UILabel *firstPageSolutionTitleLabel;
@property (nonatomic, strong) UIView *aiActionContainer;
@property (nonatomic, strong) CAGradientLayer *retakeGradientLayer;
@property (nonatomic, strong) CAGradientLayer *backgroundGradientLayer;
@property (nonatomic, assign) NSInteger selectedTabIndex;
@property (nonatomic, assign) BOOL usesRecordStyleLayout;

- (void)applyRecordStyleLayout;
- (void)tl_setupBottomCardLayout;
- (void)tl_applySolutionStyleToLabel:(UILabel *)label;

@end

@implementation TLWIdentifyResultView

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    self.verticalPageScrollViews = [NSMutableArray array];
    self.pageContentViews = [NSMutableArray array];
    self.pagePestTitleLabels = [NSMutableArray array];
    self.pageTagLabels = [NSMutableArray array];
    self.pageConfidenceBadgeViews = [NSMutableArray array];
    self.pageConfidenceLabels = [NSMutableArray array];
    self.pageSolutionTitleLabels = [NSMutableArray array];
    self.pageSolutionLabels = [NSMutableArray array];
    self.pageAIHintBackgroundViews = [NSMutableArray array];
    self.pageWarnIconViews = [NSMutableArray array];
    self.pageTagContainerViews = [NSMutableArray array];
    self.pageTagGradientLayers = [NSMutableArray array];
    [self tl_setupBackground];
    [self tl_setupPhotoArea];
    [self tl_setupBackButton];
    [self tl_setupHeaderTitle];
    [self tl_setupEffectiveView];
    [self tl_setupBottomCard];
    [self tl_setupFloatingActionButtons];
  }
  return self;
}

- (void)layoutSubviews {
  [super layoutSubviews];

  self.retakeGradientLayer.frame = self.retakeButton.bounds;
  self.retakeGradientLayer.cornerRadius = self.retakeButton.bounds.size.height * 0.5;

  [self.pageTagGradientLayers enumerateObjectsUsingBlock:^(CAGradientLayer * _Nonnull gradientLayer, NSUInteger idx, BOOL * _Nonnull stop) {
    if (idx >= self.pageTagContainerViews.count) {
      return;
    }
    UIView *containerView = self.pageTagContainerViews[idx];
    containerView.layer.cornerRadius = containerView.bounds.size.height * 0.28;
    gradientLayer.frame = containerView.bounds;
    gradientLayer.cornerRadius = containerView.bounds.size.height * 0.28;
  }];

  CGFloat pageWidth = CGRectGetWidth(self.resultScrollView.bounds);
  if (pageWidth > 0) {
    CGPoint targetOffset = CGPointMake(pageWidth * self.selectedTabIndex, 0);
    if (fabs(self.resultScrollView.contentOffset.x - targetOffset.x) > 0.5) {
      [self.resultScrollView setContentOffset:targetOffset animated:NO];
    }
  }

  [self tl_applyTabVisualStateAnimated:NO];
  [self tl_updateTabIndicatorAnimated:NO];

  self.backgroundGradientLayer.frame = self.bounds;

  if (self.aiActionContainer) {
    [self bringSubviewToFront:self.aiActionContainer];
  }
  if (self.retakeButton) {
    [self bringSubviewToFront:self.retakeButton];
  }
  if (self.headerTitleContainer) {
    [self bringSubviewToFront:self.headerTitleContainer];
  }
}

#pragma mark - Setup

- (void)tl_setupBackground {
  self.backgroundColor = [UIColor blackColor];
}

- (void)tl_setupHeaderTitle {
  UIView *headerTitleContainer = [[UIView alloc] init];
  headerTitleContainer.hidden = YES;
  [self addSubview:headerTitleContainer];
  self.headerTitleContainer = headerTitleContainer;

  UILabel *headerTitleLabel = [[UILabel alloc] init];
  headerTitleLabel.text = @"识别记录";
  headerTitleLabel.textColor = [UIColor whiteColor];
  headerTitleLabel.font = [UIFont systemFontOfSize:20 weight:UIFontWeightBold];
  headerTitleLabel.textAlignment = NSTextAlignmentCenter;
  [headerTitleContainer addSubview:headerTitleLabel];
  self.headerTitleLabel = headerTitleLabel;

  UIImageSymbolConfiguration *iconConfig =
    [UIImageSymbolConfiguration configurationWithPointSize:16.0 weight:UIImageSymbolWeightSemibold];
  UIImage *iconImage = [UIImage systemImageNamed:@"clock.fill" withConfiguration:iconConfig];
  UIImageView *headerTitleIconView = [[UIImageView alloc] initWithImage:iconImage];
  headerTitleIconView.tintColor = [UIColor colorWithWhite:0.96 alpha:0.92];
  headerTitleIconView.contentMode = UIViewContentModeScaleAspectFit;
  [headerTitleContainer addSubview:headerTitleIconView];
  self.headerTitleIconView = headerTitleIconView;

  [headerTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.top.bottom.equalTo(headerTitleContainer);
  }];

  [headerTitleIconView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.equalTo(headerTitleLabel.mas_right).offset(6.0);
    make.centerY.equalTo(headerTitleLabel).offset(1.0);
    make.right.equalTo(headerTitleContainer);
    make.width.height.mas_equalTo(18.0);
  }];
}

- (void)tl_setupEffectiveView {
  UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
  UIVisualEffectView *effectiveView = [[UIVisualEffectView alloc] initWithEffect:blur];
  effectiveView.hidden = YES;
  effectiveView.layer.cornerRadius = 22.0;
  effectiveView.layer.masksToBounds = YES;
  [self addSubview:effectiveView];
  self.effectiveView = effectiveView;

  UIView *overlay = [[UIView alloc] init];
  overlay.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.65];
  [effectiveView.contentView addSubview:overlay];
  [overlay mas_makeConstraints:^(MASConstraintMaker *make) {
    make.edges.equalTo(effectiveView.contentView);
  }];
  self.effectiveOverlayView = overlay;
}

- (void)tl_setupPhotoArea {
  UIImageView *photoView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"hp_eg1"]];
  photoView.contentMode = UIViewContentModeScaleAspectFill;
  photoView.clipsToBounds = YES;
  photoView.backgroundColor = [UIColor colorWithWhite:0.86 alpha:1.0];
  [self addSubview:photoView];
  self.photoView = photoView;

  [photoView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.left.right.equalTo(self);
    make.height.mas_equalTo(kTopPhotoHeight);
  }];

  UIView *maskView = [[UIView alloc] init];
  maskView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.10];
  [photoView addSubview:maskView];
  [maskView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.edges.equalTo(photoView);
  }];
}

- (void)tl_setupBackButton {
  UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
  UIImage *backImage = [UIImage imageNamed:@"iconBack"];
  if (backImage) {
    [backButton setImage:backImage forState:UIControlStateNormal];
  } else {
    [backButton setTitle:@"<" forState:UIControlStateNormal];
    [backButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
  }
  backButton.accessibilityLabel = @"返回";
  backButton.accessibilityHint = @"返回上一页";
  backButton.accessibilityIdentifier = @"tl_nav_back_button";
  [self addSubview:backButton];
  self.backButton = backButton;

  [backButton mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(self.mas_safeAreaLayoutGuideTop).offset(8.0);
    make.left.equalTo(self).offset(16.0);
    make.width.height.mas_equalTo(44.0);
  }];
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
  self.tabButtons = [buttons copy];

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
  
  [self tl_setupBottomCardLayout];

  self.selectedTabIndex = 0;
  [self selectTabAtIndex:0 animated:NO];
}

- (void)tl_setupFloatingActionButtons {
  UIView *aiActionContainer = [[UIView alloc] init];
  [self addSubview:aiActionContainer];
  self.aiActionContainer = aiActionContainer;

  UIImageView *aiHintImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"iconClickShowDetail"]];
  aiHintImageView.contentMode = UIViewContentModeScaleToFill;
  [aiActionContainer addSubview:aiHintImageView];

  UILabel *aiHintLabel = [[UILabel alloc] init];
  aiHintLabel.text = @"点击AI小助手\n查询详细方案";
  aiHintLabel.textColor = [UIColor colorWithRed:0.98 green:0.68 blue:0.13 alpha:1.0];
  aiHintLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightBold];
  aiHintLabel.textAlignment = NSTextAlignmentCenter;
  aiHintLabel.numberOfLines = 2;
  aiHintLabel.adjustsFontSizeToFitWidth = YES;
  aiHintLabel.minimumScaleFactor = 0.9;
  [aiActionContainer addSubview:aiHintLabel];

  UIButton *aiButton = [UIButton buttonWithType:UIButtonTypeCustom];
  [aiButton setImage:[UIImage imageNamed:@"Ip_AI"] forState:UIControlStateNormal];
  aiButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
  [aiActionContainer addSubview:aiButton];

  UILabel *aiTextLabel = [[UILabel alloc] init];
  aiTextLabel.text = @"AI助手";
  aiTextLabel.textColor = [UIColor colorWithRed:1.0 green:0.69 blue:0.18 alpha:1.0];
  aiTextLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
  aiTextLabel.textAlignment = NSTextAlignmentCenter;
  [aiActionContainer addSubview:aiTextLabel];

  UIButton *retakeButton = [UIButton buttonWithType:UIButtonTypeCustom];
  [retakeButton setImage:[UIImage imageNamed:@"Ip_newCap"] forState:UIControlStateNormal];
  retakeButton.imageView.contentMode = UIViewContentModeScaleToFill;
  [self addSubview:retakeButton];

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

  [retakeButton mas_makeConstraints:^(MASConstraintMaker *make) {
    make.right.equalTo(self).offset(-24.0);
    make.bottom.equalTo(self.mas_safeAreaLayoutGuideBottom).offset(18.0);
    make.width.mas_equalTo(200.0);
    make.height.mas_equalTo(80.0);
  }];

  self.aiHintImageView = aiHintImageView;
  self.aiHintLabel = aiHintLabel;
  self.aiButton = aiButton;
  self.aiTextLabel = aiTextLabel;
  self.retakeButton = retakeButton;
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

  UILabel *pestTitleLabel = [[UILabel alloc] init];
  pestTitleLabel.text = @"病害名称";
  pestTitleLabel.textColor = [UIColor colorWithWhite:0.22 alpha:1.0];
  pestTitleLabel.font = [UIFont systemFontOfSize:22 weight:UIFontWeightSemibold];
  [contentView addSubview:pestTitleLabel];
  [self.pagePestTitleLabels addObject:pestTitleLabel];

  UILabel *pestNameLabel = [[UILabel alloc] init];
  pestNameLabel.text = @"无结果";
  pestNameLabel.textColor = [UIColor whiteColor];
  pestNameLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
  pestNameLabel.textAlignment = NSTextAlignmentCenter;
  pestNameLabel.backgroundColor = [UIColor clearColor];
  pestNameLabel.hidden = YES;

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

  [tagContainerView addSubview:pestNameLabel];
  [self.pageTagLabels addObject:pestNameLabel];

  UIView *confidenceBadgeView = [[UIView alloc] init];
  confidenceBadgeView.backgroundColor = [UIColor colorWithRed:1.0 green:0.70 blue:0.26 alpha:1.0];
  confidenceBadgeView.layer.cornerRadius = 11.0;
  [contentView addSubview:confidenceBadgeView];
  [self.pageConfidenceBadgeViews addObject:confidenceBadgeView];

  UILabel *confidenceLabel = [[UILabel alloc] init];
  confidenceLabel.text = @"";
  confidenceLabel.textColor = [UIColor whiteColor];
  confidenceLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightSemibold];
  confidenceLabel.textAlignment = NSTextAlignmentCenter;
  [confidenceBadgeView addSubview:confidenceLabel];
  [self.pageConfidenceLabels addObject:confidenceLabel];
  confidenceBadgeView.hidden = YES;

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
  solutionLabel.hidden = NO;
  [self tl_applySolutionStyleToLabel:solutionLabel];
  [contentView addSubview:solutionLabel];
  [self.pageSolutionLabels addObject:solutionLabel];


  [pestTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(contentView).offset(10.0);
    make.left.equalTo(contentView).offset(18.0);
  }];

  CGFloat tagTextWidth = [self tl_widthForTagText:pestNameLabel.text];
  [tagContainerView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(pestTitleLabel.mas_bottom).offset(14.0);
    make.left.equalTo(contentView).offset(24.0);
    make.width.mas_equalTo(tagTextWidth);
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
    make.left.equalTo(contentView).offset(18.0);
  }];

  [solutionLabel mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(solutionTitleLabel.mas_bottom).offset(12.0);
    make.left.equalTo(contentView).offset(18.0);
    make.right.equalTo(contentView).offset(-22.0);
  }];

  [contentView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.bottom.equalTo(solutionLabel.mas_bottom).offset(40.0);
  }];
  [self.pageContentViews addObject:contentView];

  if (index == 0) {
    self.firstPageContentView = contentView;
    self.firstPagePestTitleLabel = pestTitleLabel;
    self.pestNameLabel = pestNameLabel;
    self.firstPageConfidenceBadgeView = confidenceBadgeView;
    self.confidenceLabel = confidenceLabel;
    self.firstPageSolutionTitleLabel = solutionTitleLabel;
    self.solutionLabel = solutionLabel;
  }

  return verticalScrollView;
}

#pragma mark - Public

- (void)configureWithImage:(nullable UIImage *)image results:(NSArray<NSDictionary *> *)results {
  if (image) {
    self.photoView.image = image;
  }

  [self.pagePestTitleLabels enumerateObjectsUsingBlock:^(UILabel * _Nonnull label, NSUInteger idx, BOOL * _Nonnull stop) {
    label.hidden = NO;
  }];
  [self.pageTagLabels enumerateObjectsUsingBlock:^(UILabel * _Nonnull label, NSUInteger idx, BOOL * _Nonnull stop) {
    label.text = @"无结果";
    label.hidden = NO;
  }];
  [self.pageTagContainerViews enumerateObjectsUsingBlock:^(UIView * _Nonnull containerView, NSUInteger idx, BOOL * _Nonnull stop) {
    containerView.hidden = NO;
  }];
  [self.pageConfidenceBadgeViews enumerateObjectsUsingBlock:^(UIView * _Nonnull badgeView, NSUInteger idx, BOOL * _Nonnull stop) {
    badgeView.hidden = YES;
  }];
  [self.pageConfidenceLabels enumerateObjectsUsingBlock:^(UILabel * _Nonnull label, NSUInteger idx, BOOL * _Nonnull stop) {
    label.text = @"";
  }];
  [self.pageSolutionTitleLabels enumerateObjectsUsingBlock:^(UILabel * _Nonnull label, NSUInteger idx, BOOL * _Nonnull stop) {
    label.hidden = NO;
  }];
  [self.pageSolutionLabels enumerateObjectsUsingBlock:^(UILabel * _Nonnull label, NSUInteger idx, BOOL * _Nonnull stop) {
    label.text = @"当前未返回该候选结果";
    label.attributedText = nil;
    label.hidden = NO;
    [self tl_applySolutionStyleToLabel:label];
  }];

  [results enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull result, NSUInteger idx, BOOL * _Nonnull stop) {
    if (idx >= kResultPageCount) {
      *stop = YES;
      return;
    }

    NSString *title = [result[@"title"] isKindOfClass:[NSString class]] ? result[@"title"] : nil;
    if (title.length > 0 && idx < self.tabButtons.count) {
      [self.tabButtons[idx] setTitle:title forState:UIControlStateNormal];
    }

    NSString *name = nil;
    id namesObject = result[@"names"];
    if ([result[@"name"] isKindOfClass:[NSString class]] && [result[@"name"] length] > 0) {
      name = result[@"name"];
    } else if ([namesObject isKindOfClass:[NSArray class]]) {
      for (id item in (NSArray *)namesObject) {
        if ([item isKindOfClass:[NSString class]] && [((NSString *)item) length] > 0) {
          name = item;
          break;
        }
      }
    }
    if (name.length > 0 && idx < self.pageTagLabels.count) {
      self.pagePestTitleLabels[idx].hidden = NO;
      UILabel *tagLabel = self.pageTagLabels[idx];
      tagLabel.text = name;
      tagLabel.hidden = NO;
      UIView *tagContainerView = self.pageTagContainerViews[idx];
      tagContainerView.hidden = NO;
      [tagContainerView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo([self tl_widthForTagText:name]);
      }];
    }

    NSString *confidence = [result[@"confidence"] isKindOfClass:[NSString class]] ? result[@"confidence"] : @"";
    if (idx < self.pageConfidenceLabels.count) {
      self.pageConfidenceLabels[idx].text = confidence.length > 0 ? confidence : @"--";
      self.pageConfidenceBadgeViews[idx].hidden = (confidence.length == 0);
    }

    NSString *advice = [result[@"advice"] isKindOfClass:[NSString class]] ? result[@"advice"] : nil;
    if (advice.length == 0 && [result[@"solution"] isKindOfClass:[NSString class]]) {
      advice = result[@"solution"];
    }
    if (idx < self.pageSolutionLabels.count && advice.length > 0) {
      self.pageSolutionTitleLabels[idx].hidden = NO;
      self.pageSolutionLabels[idx].text = advice;
      self.pageSolutionLabels[idx].hidden = NO;
      [self tl_applySolutionStyleToLabel:self.pageSolutionLabels[idx]];
    }
  }];

  [self setNeedsLayout];
  [self layoutIfNeeded];
}

- (void)applyLayoutStyleFlag:(NSInteger)styleFlag {
  if (styleFlag == 0) {
    [self applyRecordStyleLayout];
    return;
  }

  self.usesRecordStyleLayout = NO;
  self.backgroundGradientLayer.hidden = YES;
  self.headerTitleContainer.hidden = YES;
  self.effectiveView.hidden = YES;
  self.backgroundColor = [UIColor blackColor];
  self.photoView.layer.cornerRadius = 0.0;
  self.photoView.layer.masksToBounds = YES;
  self.cardView.effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemMaterialLight];
  self.cardView.backgroundColor = [UIColor clearColor];
  self.cardOverlayView.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.58];
  self.tabContainer.backgroundColor = [[UIColor colorWithRed:0.74 green:0.86 blue:0.86 alpha:1.0] colorWithAlphaComponent:0.42];
  self.tabContainer.layer.cornerRadius = 13.0;
  self.tabContainer.layer.borderWidth = 1.0;
  self.tabContainer.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.26].CGColor;
  self.aiHintImageView.hidden = NO;
  self.aiHintLabel.hidden = NO;
  self.aiHintLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightBold];
  self.aiHintLabel.textColor = [UIColor colorWithRed:0.98 green:0.68 blue:0.13 alpha:1.0];
  self.aiTextLabel.textColor = [UIColor colorWithRed:1.0 green:0.69 blue:0.18 alpha:1.0];
  self.aiTextLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
  self.headerTitleLabel.font = [UIFont systemFontOfSize:20 weight:UIFontWeightBold];
  self.headerTitleIconView.image = [UIImage systemImageNamed:@"clock.fill"
                                           withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:16.0
                                                                                                             weight:UIImageSymbolWeightSemibold]];
  [self.tabButtons enumerateObjectsUsingBlock:^(UIButton * _Nonnull button, NSUInteger idx, BOOL * _Nonnull stop) {
    button.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
  }];
  [self.pageConfidenceLabels enumerateObjectsUsingBlock:^(UILabel * _Nonnull label, NSUInteger idx, BOOL * _Nonnull stop) {
    label.font = [UIFont systemFontOfSize:11 weight:UIFontWeightSemibold];
  }];

  [self.photoView mas_remakeConstraints:^(MASConstraintMaker *make) {
    make.top.left.right.equalTo(self);
    make.height.mas_equalTo(kTopPhotoHeight);
  }];

  [self.effectiveView mas_remakeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(self.photoView.mas_bottom).offset(-22.0);
    make.left.right.bottom.equalTo(self);
  }];

  [self.cardView mas_remakeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(self.photoView.mas_bottom).offset(-30.0);
    make.left.right.bottom.equalTo(self);
  }];

  [self.tabContainer mas_remakeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(self.cardView.contentView).offset(16.0);
    make.left.equalTo(self.cardView.contentView).offset(18.0);
    make.right.equalTo(self.cardView.contentView).offset(-18.0);
    make.height.mas_equalTo(48.0);
  }];

  [self.resultScrollView mas_remakeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(self.tabContainer.mas_bottom).offset(12.0);
    make.left.equalTo(self.cardView.contentView).offset(18.0);
    make.right.equalTo(self.cardView.contentView).offset(-18.0);
    make.bottom.equalTo(self.mas_safeAreaLayoutGuideBottom).offset(-132.0);
  }];

  [self.retakeButton mas_remakeConstraints:^(MASConstraintMaker *make) {
    make.right.equalTo(self).offset(-24.0);
    make.bottom.equalTo(self.mas_safeAreaLayoutGuideBottom).offset(18.0);
    make.width.mas_equalTo(200.0);
    make.height.mas_equalTo(80.0);
  }];

  [self.aiActionContainer mas_remakeConstraints:^(MASConstraintMaker *make) {
    make.left.equalTo(self).offset(20.0);
    make.bottom.equalTo(self.mas_safeAreaLayoutGuideBottom).offset(18.0);
    make.width.mas_equalTo(132.0);
    make.height.mas_equalTo(150.0);
  }];

  [self.aiButton mas_remakeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(self.aiHintImageView.mas_bottom).offset(4.0);
    make.left.equalTo(self.aiActionContainer);
    make.width.height.mas_equalTo(55.0);
  }];

  [self.aiTextLabel mas_updateConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(self.aiButton.mas_bottom).offset(-9.0);
  }];

  [self.pageContentViews enumerateObjectsUsingBlock:^(UIView * _Nonnull contentView, NSUInteger idx, BOOL * _Nonnull stop) {
    if (idx >= self.pagePestTitleLabels.count ||
        idx >= self.verticalPageScrollViews.count ||
        idx >= self.pageTagLabels.count ||
        idx >= self.pageTagContainerViews.count ||
        idx >= self.pageConfidenceBadgeViews.count ||
        idx >= self.pageSolutionTitleLabels.count ||
        idx >= self.pageSolutionLabels.count) {
      return;
    }

    UIScrollView *verticalScrollView = self.verticalPageScrollViews[idx];
    UILabel *pestTitleLabel = self.pagePestTitleLabels[idx];
    UIView *tagContainerView = self.pageTagContainerViews[idx];
    UILabel *tagLabel = self.pageTagLabels[idx];
    UIView *confidenceBadgeView = self.pageConfidenceBadgeViews[idx];
    UILabel *solutionTitleLabel = self.pageSolutionTitleLabels[idx];
    UILabel *solutionLabel = self.pageSolutionLabels[idx];

    pestTitleLabel.font = [UIFont systemFontOfSize:22 weight:UIFontWeightSemibold];
    pestTitleLabel.textColor = [UIColor colorWithWhite:0.22 alpha:1.0];
    solutionTitleLabel.font = [UIFont systemFontOfSize:22 weight:UIFontWeightSemibold];
    solutionTitleLabel.textColor = [UIColor colorWithWhite:0.22 alpha:1.0];
    tagContainerView.layer.cornerRadius = 15.0;
    tagLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
    tagLabel.textColor = [UIColor whiteColor];
    confidenceBadgeView.layer.cornerRadius = 11.0;
    confidenceBadgeView.backgroundColor = [UIColor colorWithRed:1.0 green:0.70 blue:0.26 alpha:1.0];
    self.pageConfidenceLabels[idx].font = [UIFont systemFontOfSize:11 weight:UIFontWeightSemibold];
    solutionLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    solutionLabel.textColor = [UIColor colorWithWhite:0.32 alpha:1.0];
    [self tl_applySolutionStyleToLabel:solutionLabel];

    [pestTitleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
      make.top.equalTo(contentView).offset(10.0);
      make.left.equalTo(contentView).offset(2.0);
    }];

    [tagContainerView mas_remakeConstraints:^(MASConstraintMaker *make) {
      make.top.equalTo(pestTitleLabel.mas_bottom).offset(14.0);
      make.left.equalTo(contentView).offset(8.0);
      make.width.mas_equalTo([self tl_widthForTagText:tagLabel.text]);
      make.height.mas_equalTo(54.0);
    }];

    [confidenceBadgeView mas_remakeConstraints:^(MASConstraintMaker *make) {
      make.top.equalTo(tagContainerView).offset(-8.0);
      make.right.equalTo(tagContainerView).offset(8.0);
      make.width.mas_equalTo(36.0);
      make.height.mas_equalTo(22.0);
    }];

    [solutionTitleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
      make.top.equalTo(tagContainerView.mas_bottom).offset(24.0);
      make.left.equalTo(contentView).offset(2.0);
    }];

    [solutionLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
      make.top.equalTo(solutionTitleLabel.mas_bottom).offset(12.0);
      make.left.equalTo(contentView).offset(2.0);
      make.right.equalTo(contentView).offset(-6.0);
    }];

    [contentView mas_remakeConstraints:^(MASConstraintMaker *make) {
      make.top.left.right.equalTo(verticalScrollView);
      make.width.equalTo(verticalScrollView);
      make.bottom.equalTo(solutionLabel.mas_bottom).offset(72.0);
    }];
  }];

  [self.pageSolutionLabels enumerateObjectsUsingBlock:^(UILabel * _Nonnull label, NSUInteger idx, BOOL * _Nonnull stop) {
    [self tl_applySolutionStyleToLabel:label];
  }];
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

- (NSString *)currentPestName {
  if (self.selectedTabIndex < 0 || self.selectedTabIndex >= self.pageTagLabels.count) {
    return @"";
  }
  return self.pageTagLabels[self.selectedTabIndex].text ?: @"";
}

- (NSString *)currentConfidenceText {
  if (self.selectedTabIndex < 0 || self.selectedTabIndex >= self.pageConfidenceLabels.count) {
    return @"";
  }
  return self.pageConfidenceLabels[self.selectedTabIndex].text ?: @"";
}

- (NSString *)currentAdviceText {
  if (self.selectedTabIndex < 0 || self.selectedTabIndex >= self.pageSolutionLabels.count) {
    return @"";
  }
  UILabel *label = self.pageSolutionLabels[self.selectedTabIndex];
  if (label.attributedText.string.length > 0) {
    return label.attributedText.string;
  }
  return label.text ?: @"";
}

- (void)applyRecordStyleLayout {
  self.usesRecordStyleLayout = YES;
  if (!self.backgroundGradientLayer) {
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
  self.backgroundGradientLayer.hidden = NO;

  self.backgroundColor = [UIColor colorWithRed:0.95 green:0.98 blue:0.97 alpha:1.0];
  self.headerTitleContainer.hidden = NO;
  self.effectiveView.hidden = NO;
  self.headerTitleLabel.text = @"识别记录";
  self.headerTitleLabel.font = [UIFont systemFontOfSize:22 weight:UIFontWeightBold];
  self.headerTitleIconView.image = [UIImage systemImageNamed:@"clock.fill"
                                           withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:20.0
                                                                                                             weight:UIImageSymbolWeightBold]];
  self.photoView.layer.cornerRadius = 18.0;
  self.photoView.layer.masksToBounds = YES;
  self.cardView.effect = nil;
  self.cardView.backgroundColor = [UIColor clearColor];
  self.cardOverlayView.backgroundColor = [UIColor clearColor];
  self.tabContainer.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.22];
  self.tabContainer.layer.cornerRadius = 11.0;
  self.tabContainer.layer.borderWidth = 0.0;
  self.pillView.backgroundColor = [UIColor whiteColor];
  self.pillView.layer.shadowColor = [UIColor colorWithRed:0.35 green:0.59 blue:0.57 alpha:0.18].CGColor;
  self.pillView.layer.shadowOpacity = 1.0;
  self.pillView.layer.shadowOffset = CGSizeMake(0, 2);
  self.pillView.layer.shadowRadius = 7.0;
  self.aiHintImageView.hidden = YES;
  self.aiHintLabel.hidden = YES;
  self.aiTextLabel.textColor = [UIColor colorWithRed:0.95 green:0.65 blue:0.15 alpha:1.0];
  self.aiTextLabel.font = [UIFont systemFontOfSize:22 weight:UIFontWeightSemibold];
  [self.tabButtons enumerateObjectsUsingBlock:^(UIButton * _Nonnull button, NSUInteger idx, BOOL * _Nonnull stop) {
    button.titleLabel.font = [UIFont systemFontOfSize:20 weight:UIFontWeightSemibold];
  }];
  [self.pageSolutionLabels enumerateObjectsUsingBlock:^(UILabel * _Nonnull label, NSUInteger idx, BOOL * _Nonnull stop) {
    [self tl_applySolutionStyleToLabel:label];
  }];

  [self.backButton mas_remakeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(self.mas_safeAreaLayoutGuideTop).offset(8.0);
    make.left.equalTo(self).offset(16.0);
    make.width.height.mas_equalTo(44.0);
  }];

  [self.headerTitleContainer mas_remakeConstraints:^(MASConstraintMaker *make) {
    make.centerY.equalTo(self.backButton).offset(-1);
    make.centerX.equalTo(self);
  }];

  [self.photoView mas_remakeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(self.mas_safeAreaLayoutGuideTop).offset(52.0);
    make.left.equalTo(self).offset(18.0);
    make.right.equalTo(self).offset(-18.0);
    make.height.mas_equalTo(198.0);
  }];

  [self.effectiveView mas_remakeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(self.photoView.mas_bottom).offset(10.0);
    make.left.equalTo(self).offset(10.0);
    make.right.equalTo(self).offset(-10.0);
    make.bottom.equalTo(self).offset(-10.0);
  }];

  [self.cardView mas_remakeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(self.photoView.mas_bottom).offset(10.0);
    make.left.right.equalTo(self);
    make.bottom.equalTo(self);
  }];

  [self.tabContainer mas_remakeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(self.cardView.contentView).offset(12.0);
    make.left.equalTo(self.cardView.contentView).offset(18.0);
    make.right.equalTo(self.cardView.contentView).offset(-18.0);
    make.height.mas_equalTo(40.0);
  }];

  [self.resultScrollView mas_remakeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(self.tabContainer.mas_bottom).offset(16.0);
    make.left.equalTo(self.cardView.contentView).offset(18.0);
    make.right.equalTo(self.cardView.contentView).offset(-18.0);
    make.bottom.equalTo(self.mas_safeAreaLayoutGuideBottom).offset(-108.0);
  }];

  [self.pagesContainer mas_remakeConstraints:^(MASConstraintMaker *make) {
    make.edges.equalTo(self.resultScrollView);
    make.height.equalTo(self.resultScrollView);
  }];

  [self.pageContentViews enumerateObjectsUsingBlock:^(UIView * _Nonnull contentView, NSUInteger idx, BOOL * _Nonnull stop) {
    if (idx >= self.pagePestTitleLabels.count ||
        idx >= self.verticalPageScrollViews.count ||
        idx >= self.pageTagLabels.count ||
        idx >= self.pageConfidenceBadgeViews.count ||
        idx >= self.pageSolutionTitleLabels.count ||
        idx >= self.pageSolutionLabels.count) {
      return;
    }

    UIScrollView *verticalScrollView = self.verticalPageScrollViews[idx];
    UILabel *pestTitleLabel = self.pagePestTitleLabels[idx];
    UILabel *tagLabel = self.pageTagLabels[idx];
    UIView *confidenceBadgeView = self.pageConfidenceBadgeViews[idx];
    UILabel *solutionTitleLabel = self.pageSolutionTitleLabels[idx];
    UILabel *solutionLabel = self.pageSolutionLabels[idx];

    pestTitleLabel.font = [UIFont systemFontOfSize:28 weight:UIFontWeightBold];
    pestTitleLabel.textColor = [UIColor colorWithWhite:0.24 alpha:1.0];
    solutionTitleLabel.font = [UIFont systemFontOfSize:28 weight:UIFontWeightBold];
    solutionTitleLabel.textColor = [UIColor colorWithWhite:0.24 alpha:1.0];
    UIView *tagContainerView = self.pageTagContainerViews[idx];
    tagContainerView.layer.cornerRadius = 12.0;
    tagLabel.font = [UIFont systemFontOfSize:22 weight:UIFontWeightSemibold];
    tagLabel.backgroundColor = [UIColor clearColor];
    confidenceBadgeView.layer.cornerRadius = 13.0;
    confidenceBadgeView.backgroundColor = [UIColor colorWithRed:1.0 green:0.63 blue:0.20 alpha:1.0];
    self.pageConfidenceLabels[idx].font = [UIFont systemFontOfSize:15 weight:UIFontWeightBold];
    solutionLabel.font = [UIFont systemFontOfSize:21 weight:UIFontWeightMedium];
    solutionLabel.textColor = [UIColor colorWithWhite:0.39 alpha:1.0];
    [self tl_applySolutionStyleToLabel:solutionLabel];

    [pestTitleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
      make.top.equalTo(contentView).offset(2.0);
      make.left.equalTo(contentView);
    }];

    [tagContainerView mas_remakeConstraints:^(MASConstraintMaker *make) {
      make.top.equalTo(pestTitleLabel.mas_bottom).offset(12.0);
      make.left.equalTo(contentView).offset(10.0);
      make.width.mas_equalTo(MAX(112.0, [self tl_widthForTagText:tagLabel.text] + 6.0));
      make.height.mas_equalTo(50.0);
    }];

    [confidenceBadgeView mas_remakeConstraints:^(MASConstraintMaker *make) {
      make.top.equalTo(tagContainerView).offset(-8.0);
      make.right.equalTo(tagContainerView).offset(10.0);
      make.width.mas_equalTo(46.0);
      make.height.mas_equalTo(26.0);
    }];

    [solutionTitleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
      make.top.equalTo(tagContainerView.mas_bottom).offset(26.0);
      make.left.equalTo(contentView);
    }];

    [solutionLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
      make.top.equalTo(solutionTitleLabel.mas_bottom).offset(12.0);
      make.left.equalTo(contentView);
      make.right.equalTo(contentView).offset(-6.0);
    }];

    [contentView mas_remakeConstraints:^(MASConstraintMaker *make) {
      make.top.left.right.equalTo(verticalScrollView);
      make.width.equalTo(verticalScrollView);
      make.bottom.equalTo(solutionLabel.mas_bottom).offset(72.0);
    }];
  }];

  [self.retakeButton mas_remakeConstraints:^(MASConstraintMaker *make) {
    make.right.equalTo(self).offset(-20.0);
    make.top.equalTo(self).offset(755.0);
    make.width.mas_equalTo(172.0);
    make.height.mas_equalTo(72.0);
  }];

  [self.aiActionContainer mas_remakeConstraints:^(MASConstraintMaker *make) {
    make.left.equalTo(self).offset(15.0);
    make.top.equalTo(self).offset(740.0);
    make.width.mas_equalTo(84.0);
    make.height.mas_equalTo(96.0);
  }];

  [self.aiButton mas_remakeConstraints:^(MASConstraintMaker *make) {
    make.top.left.equalTo(self.aiActionContainer);
    make.width.height.mas_equalTo(64.0);
  }];

  [self.aiTextLabel mas_updateConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(self.aiButton.mas_bottom).offset(-9.0);
  }];

  [self setNeedsLayout];
  [self layoutIfNeeded];
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

- (void)tl_setupBottomCardLayout {
  [self.cardView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(self.photoView.mas_bottom).offset(-22.0);
    make.left.right.bottom.equalTo(self);
  }];

  [self.tabContainer mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(self.cardView.contentView).offset(16.0);
    make.left.equalTo(self.cardView.contentView).offset(18.0);
    make.right.equalTo(self.cardView.contentView).offset(-18.0);
    make.height.mas_equalTo(48.0);
  }];

  [self.resultScrollView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(self.tabContainer.mas_bottom).offset(12.0);
    make.left.right.bottom.equalTo(self.cardView.contentView);
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
}

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

  [self tl_updateTabIndicatorAnimated:animated];
}

- (void)tl_updateTabIndicatorAnimated:(BOOL)animated {
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
  UIFont *font = self.usesRecordStyleLayout
    ? [UIFont systemFontOfSize:22 weight:UIFontWeightSemibold]
    : [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
  CGFloat horizontalPadding = self.usesRecordStyleLayout ? 40.0 : 38.0;
  CGFloat minWidth = self.usesRecordStyleLayout ? 104.0 : 96.0;
  CGSize textSize = [safeText sizeWithAttributes:@{NSFontAttributeName: font}];
  return MAX(minWidth, ceil(textSize.width) + horizontalPadding);
}

- (void)tl_applySolutionStyleToLabel:(UILabel *)label {
  if (![label.text isKindOfClass:[NSString class]] || label.text.length == 0) {
    return;
  }

  NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
  paragraphStyle.lineSpacing = self.usesRecordStyleLayout ? 10.0 : 7.0;
  paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;

  NSDictionary *attributes = @{
    NSParagraphStyleAttributeName: paragraphStyle,
    NSForegroundColorAttributeName: label.textColor ?: [UIColor colorWithWhite:0.32 alpha:1.0],
    NSFontAttributeName: label.font ?: [UIFont systemFontOfSize:16 weight:UIFontWeightMedium]
  };
  label.attributedText = [[NSAttributedString alloc] initWithString:label.text attributes:attributes];
}

@end
