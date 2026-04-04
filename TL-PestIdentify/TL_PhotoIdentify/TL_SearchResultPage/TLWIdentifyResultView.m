//
//  TLWIdentifyResultView.m
//  TL-PestIdentify
//
//  Created by xiaoli pop on 2026/4/3.
//

#import "TLWIdentifyResultView.h"
#import <Masonry/Masonry.h>

static CGFloat const kTopPhotoHeight = 300.0;
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

@property (nonatomic, strong) UIView *tabContainer;
@property (nonatomic, strong) UIView *pillView;
@property (nonatomic, strong) UIView *pagesContainer;
@property (nonatomic, strong) NSMutableArray<UIScrollView *> *verticalPageScrollViews;
@property (nonatomic, strong) NSMutableArray<UILabel *> *pageTagLabels;
@property (nonatomic, strong) NSMutableArray<UILabel *> *pageConfidenceLabels;
@property (nonatomic, strong) NSMutableArray<UILabel *> *pageSolutionLabels;
@property (nonatomic, strong) CAGradientLayer *retakeGradientLayer;
@property (nonatomic, assign) NSInteger selectedTabIndex;

@end

@implementation TLWIdentifyResultView

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    self.verticalPageScrollViews = [NSMutableArray array];
    self.pageTagLabels = [NSMutableArray array];
    self.pageConfidenceLabels = [NSMutableArray array];
    self.pageSolutionLabels = [NSMutableArray array];
    [self tl_setupBackground];
    [self tl_setupPhotoArea];
    [self tl_setupBackButton];
    [self tl_setupBottomCard];
  }
  return self;
}

- (void)layoutSubviews {
  [super layoutSubviews];

  self.retakeGradientLayer.frame = self.retakeButton.bounds;
  self.retakeGradientLayer.cornerRadius = self.retakeButton.bounds.size.height * 0.5;

  CGFloat pageWidth = CGRectGetWidth(self.resultScrollView.bounds);
  if (pageWidth > 0) {
    CGPoint targetOffset = CGPointMake(pageWidth * self.selectedTabIndex, 0);
    if (fabs(self.resultScrollView.contentOffset.x - targetOffset.x) > 0.5) {
      [self.resultScrollView setContentOffset:targetOffset animated:NO];
    }
  }

  [self tl_applyTabVisualStateAnimated:NO];
  [self tl_updateTabIndicatorAnimated:NO];
}

#pragma mark - Setup

- (void)tl_setupBackground {
  self.backgroundColor = [UIColor blackColor];
}

- (void)tl_setupPhotoArea {
  UIImageView *photoView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"hp_eg1.jpg"]];
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
  backButton.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.24];
  backButton.layer.cornerRadius = 21.0;
  backButton.layer.borderWidth = 1.0;
  backButton.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.25].CGColor;
  [self addSubview:backButton];
  self.backButton = backButton;

  [backButton mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(self.mas_safeAreaLayoutGuideTop).offset(10.0);
    make.left.equalTo(self).offset(16.0);
    make.width.height.mas_equalTo(42.0);
  }];
}

- (void)tl_setupBottomCard {
  UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemMaterialLight];
  UIVisualEffectView *cardView = [[UIVisualEffectView alloc] initWithEffect:blur];
  cardView.layer.cornerRadius = kCardCornerRadius;
  cardView.layer.masksToBounds = YES;
  [self addSubview:cardView];

  UIView *overlay = [[UIView alloc] init];
  overlay.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.58];
  [cardView.contentView addSubview:overlay];
  [overlay mas_makeConstraints:^(MASConstraintMaker *make) {
    make.edges.equalTo(cardView.contentView);
  }];

  [cardView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(self.photoView.mas_bottom).offset(-22.0);
    make.left.right.bottom.equalTo(self);
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

  [tabContainer mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(cardView.contentView).offset(16.0);
    make.left.equalTo(cardView.contentView).offset(18.0);
    make.right.equalTo(cardView.contentView).offset(-18.0);
    make.height.mas_equalTo(48.0);
  }];

  [pagingScrollView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(tabContainer.mas_bottom).offset(12.0);
    make.left.right.bottom.equalTo(cardView.contentView);
  }];

  [pagesContainer mas_makeConstraints:^(MASConstraintMaker *make) {
    make.edges.equalTo(pagingScrollView);
    make.height.equalTo(pagingScrollView);
  }];

  UIView *previousPage = nil;
  for (NSInteger idx = 0; idx < kResultPageCount; idx++) {
    UIScrollView *verticalScrollView = [self tl_buildVerticalPageAtIndex:idx];
    [pagingScrollView addSubview:verticalScrollView];
    [self.verticalPageScrollViews addObject:verticalScrollView];

    [verticalScrollView mas_makeConstraints:^(MASConstraintMaker *make) {
      make.top.bottom.equalTo(pagingScrollView);
      make.width.equalTo(pagingScrollView);
      if (previousPage) {
        make.left.equalTo(previousPage.mas_right);
      } else {
        make.left.equalTo(pagingScrollView);
      }
    }];
    previousPage = verticalScrollView;
  }

  [previousPage mas_makeConstraints:^(MASConstraintMaker *make) {
    make.right.equalTo(pagingScrollView);
  }];

  self.selectedTabIndex = 0;
  [self selectTabAtIndex:0 animated:NO];
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

  NSArray<NSString *> *pestNames = @[@"炭疽病", @"叶斑病", @"锈病"];
  UILabel *pestNameLabel = [[UILabel alloc] init];
  pestNameLabel.text = pestNames[index];
  pestNameLabel.textColor = [UIColor whiteColor];
  pestNameLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
  pestNameLabel.textAlignment = NSTextAlignmentCenter;
  pestNameLabel.backgroundColor = [UIColor colorWithRed:0.34 green:0.74 blue:0.98 alpha:1.0];
  pestNameLabel.layer.cornerRadius = 18.0;
  pestNameLabel.layer.masksToBounds = YES;
  [contentView addSubview:pestNameLabel];
  [self.pageTagLabels addObject:pestNameLabel];

  UIView *confidenceBadgeView = [[UIView alloc] init];
  confidenceBadgeView.backgroundColor = [UIColor colorWithRed:1.0 green:0.70 blue:0.26 alpha:1.0];
  confidenceBadgeView.layer.cornerRadius = 11.0;
  [contentView addSubview:confidenceBadgeView];

  UILabel *confidenceLabel = [[UILabel alloc] init];
  NSArray<NSString *> *confidences = @[@"80%", @"76%", @"68%"];
  confidenceLabel.text = confidences[index];
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

  UILabel *solutionLabel = [[UILabel alloc] init];
  solutionLabel.numberOfLines = 0;
  solutionLabel.textColor = [UIColor colorWithWhite:0.32 alpha:1.0];
  solutionLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
  NSArray<NSString *> *solutions = @[
    @"1. 清：清病株深埋，轮作豆/花生2-3年。\n2. 管：合理密植，少氮多磷钾，雨后排水。\n3. 药：播前用苯醚甲环唑拌种；发病初期喷咪鲜胺/丙环唑，7-10天一次，连喷2-3次，轮换用药。",
    @"1. 清：及时摘除重病叶，集中处理。\n2. 管：加强通风透光，控制田间湿度。\n3. 药：发病初期喷施代森锰锌或嘧菌酯，间隔7天连续2-3次。",
    @"1. 清：发现病叶立即剪除，减少传播源。\n2. 管：增施磷钾肥，降低叶面长时间积水。\n3. 药：选择三唑酮、戊唑醇等药剂轮换喷施。"
  ];
  solutionLabel.text = solutions[index];
  [contentView addSubview:solutionLabel];
  [self.pageSolutionLabels addObject:solutionLabel];

  UIImageView *aiHintBackgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Ip_message.png"]];
  aiHintBackgroundView.contentMode = UIViewContentModeScaleToFill;
  aiHintBackgroundView.userInteractionEnabled = YES;
  [contentView addSubview:aiHintBackgroundView];

  UIImageView *warnIconView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Ip_warn.png"]];
  warnIconView.contentMode = UIViewContentModeScaleAspectFit;
  [aiHintBackgroundView addSubview:warnIconView];

  UIButton *aiButton = [UIButton buttonWithType:UIButtonTypeCustom];
  [aiButton setImage:[UIImage imageNamed:@"Ip_AI.png"] forState:UIControlStateNormal];
  aiButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
  [contentView addSubview:aiButton];

  UILabel *aiTextLabel = [[UILabel alloc] init];
  aiTextLabel.text = @"AI助手";
  aiTextLabel.textColor = [UIColor colorWithRed:1.0 green:0.69 blue:0.18 alpha:1.0];
  aiTextLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
  aiTextLabel.textAlignment = NSTextAlignmentCenter;
  [contentView addSubview:aiTextLabel];

  UIButton *retakeButton = [UIButton buttonWithType:UIButtonTypeCustom];
  [retakeButton setImage:[UIImage imageNamed:@"Ip_newCap.png"] forState:UIControlStateNormal];
  retakeButton.imageView.contentMode = UIViewContentModeScaleToFill;
  [contentView addSubview:retakeButton];

  [pestTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(contentView).offset(10.0);
    make.left.equalTo(contentView).offset(18.0);
  }];

  CGFloat tagTextWidth = [self tl_widthForTagText:pestNameLabel.text];
  [pestNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(pestTitleLabel.mas_bottom).offset(14.0);
    make.left.equalTo(contentView).offset(24.0);
    make.width.mas_equalTo(tagTextWidth);
    make.height.mas_equalTo(36.0);
  }];

  [confidenceBadgeView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(pestNameLabel).offset(-8.0);
    make.right.equalTo(pestNameLabel).offset(6.0);
    make.width.mas_equalTo(36.0);
    make.height.mas_equalTo(22.0);
  }];

  [confidenceLabel mas_makeConstraints:^(MASConstraintMaker *make) {
    make.edges.equalTo(confidenceBadgeView);
  }];

  [solutionTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(pestNameLabel.mas_bottom).offset(24.0);
    make.left.equalTo(contentView).offset(18.0);
  }];

  [solutionLabel mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(solutionTitleLabel.mas_bottom).offset(12.0);
    make.left.equalTo(contentView).offset(18.0);
    make.right.equalTo(contentView).offset(-22.0);
  }];

  [aiHintBackgroundView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(solutionLabel.mas_bottom).offset(34.0);
    make.left.equalTo(contentView).offset(20.0);
    make.width.mas_equalTo(118.0);
    make.height.mas_equalTo(78.0);
  }];

  [warnIconView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.edges.equalTo(aiHintBackgroundView).insets(UIEdgeInsetsMake(10.0, 10.0, 12.0, 10.0));
  }];

  [aiButton mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(aiHintBackgroundView.mas_bottom).offset(8.0);
   // make.bottom.equalTo(self.mas_bottom).offset(-80);
    make.left.equalTo(contentView).offset(18.0);
    make.width.height.mas_equalTo(55.0);
  }];

  [aiTextLabel mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(aiButton.mas_bottom).offset(4.0);
    make.centerX.equalTo(aiButton);
  }];

  [retakeButton mas_makeConstraints:^(MASConstraintMaker *make) {
    make.centerY.equalTo(aiButton).offset(2.0);
    make.right.equalTo(contentView).offset(-20.0);
    make.width.mas_equalTo(204.0);
    make.height.mas_equalTo(72.0);
  }];

  [contentView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.bottom.equalTo(aiTextLabel.mas_bottom).offset(34.0);
  }];

  if (index == 0) {
    self.pestNameLabel = pestNameLabel;
    self.confidenceLabel = confidenceLabel;
    self.solutionLabel = solutionLabel;
    self.aiButton = aiButton;
    self.retakeButton = retakeButton;
  }

  return verticalScrollView;
}

#pragma mark - Public

- (void)configureWithImage:(nullable UIImage *)image results:(NSArray<NSDictionary *> *)results {
  if (image) {
    self.photoView.image = image;
  }

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
      UILabel *tagLabel = self.pageTagLabels[idx];
      tagLabel.text = name;
      [tagLabel mas_updateConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo([self tl_widthForTagText:name]);
      }];
    }

    NSString *confidence = [result[@"confidence"] isKindOfClass:[NSString class]] ? result[@"confidence"] : @"";
    if (idx < self.pageConfidenceLabels.count) {
      self.pageConfidenceLabels[idx].text = confidence.length > 0 ? confidence : @"--";
    }

    NSString *advice = [result[@"advice"] isKindOfClass:[NSString class]] ? result[@"advice"] : nil;
    if (advice.length == 0 && [result[@"solution"] isKindOfClass:[NSString class]]) {
      advice = result[@"solution"];
    }
    if (idx < self.pageSolutionLabels.count && advice.length > 0) {
      self.pageSolutionLabels[idx].text = advice;
    }
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
  NSString *safeText = text.length > 0 ? text : @"未知病害";
  CGSize textSize = [safeText sizeWithAttributes:@{NSFontAttributeName: [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold]}];
  return MAX(88.0, ceil(textSize.width) + 32.0);
}

@end
