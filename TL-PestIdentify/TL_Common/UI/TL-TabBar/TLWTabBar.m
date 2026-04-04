//
//  TLWTabBar.m
//  TL-PestIdentify
//
//  Created by TommyWu on 2026/4/4.
//  职责：实现组件化底部导航栏视图。
//

#import "TLWTabBar.h"

static CGFloat const kTabBarTotalHeight = 96.0;
static CGFloat const kPillHorizontalInset = 28.0;
static CGFloat const kPillMaxWidth = 520.0;
static CGFloat const kPillHeight = 76.0;
static CGFloat const kPillBottomOffset = 10.0;
static CGFloat const kPillItemTopInset = 6.0;
static CGFloat const kSymbolPointSize = 22.0;

@implementation TLWTabBar

- (instancetype)initWithFrame:(CGRect)frame {
  if (self = [super initWithFrame:frame]) {
    self.translucent = YES;//半透明
    self.backgroundImage = [UIImage new];//移除系统默认背景
    self.shadowImage = [UIImage new];

    // 添加渐变层
    self.pillView = [UIView new];
    self.pillView.backgroundColor = UIColor.clearColor;
    self.pillView.userInteractionEnabled = YES;
	    self.pillView.layer.cornerRadius = kPillHeight / 2.0;
    self.pillView.layer.masksToBounds = NO;
    self.pillView.layer.shadowColor = [UIColor colorWithWhite:0 alpha:1].CGColor;
    self.pillView.layer.shadowOpacity = 0.18;
    self.pillView.layer.shadowRadius = 24;
    self.pillView.layer.shadowOffset = CGSizeMake(0, 10);
    [self addSubview:self.pillView];

    self.pillGradient = [CAGradientLayer layer];//渐变层
    self.pillGradient.startPoint = CGPointMake(0, 0.5);//渐变方向
    self.pillGradient.endPoint = CGPointMake(1, 0.5);
    self.pillGradient.colors = @[
      (__bridge id)[UIColor colorWithRed:0.92 green:0.96 blue:0.90 alpha:0.75].CGColor,
      (__bridge id)[UIColor colorWithRed:0.90 green:0.96 blue:0.92 alpha:0.75].CGColor
    ];
    self.pillGradient.locations = @[@0, @1];
	    self.pillGradient.cornerRadius = kPillHeight / 2.0;
    [self.pillView.layer insertSublayer:self.pillGradient atIndex:0];
      

    // 4 个按钮：使用系统 SF Symbols（可根据设计替换）
    UIImage *homeIcon = nil;
    UIImage *communityIcon = nil;
    UIImage *msgIcon = nil;
    UIImage *meIcon = nil;
    if (@available(iOS 13.0, *)) {
	      UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:kSymbolPointSize weight:UIImageSymbolWeightSemibold];
      homeIcon = [[[UIImage systemImageNamed:@"house.fill"] imageWithConfiguration:config] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
      communityIcon = [[[UIImage systemImageNamed:@"leaf.fill"] imageWithConfiguration:config] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
      msgIcon = [[[UIImage systemImageNamed:@"ellipsis.bubble.fill"] imageWithConfiguration:config] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
      meIcon = [[[UIImage systemImageNamed:@"person.fill"] imageWithConfiguration:config] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    TLWTabBarItemView *v0 = [[TLWTabBarItemView alloc] initWithTitle:@"首页" icon:homeIcon ?: [UIImage new]];
    TLWTabBarItemView *v1 = [[TLWTabBarItemView alloc] initWithTitle:@"社区" icon:communityIcon ?: [UIImage new]];
    TLWTabBarItemView *v2 = [[TLWTabBarItemView alloc] initWithTitle:@"消息" icon:msgIcon ?: [UIImage new]];
    TLWTabBarItemView *v3 = [[TLWTabBarItemView alloc] initWithTitle:@"我的" icon:meIcon ?: [UIImage new]];
    self.itemViews = @[v0, v1, v2, v3];

	    for (NSInteger i = 0; i < (NSInteger)self.itemViews.count; i++) {
	      TLWTabBarItemView *item = self.itemViews[i];
	      item.tag = i;
	      item.accessibilityIdentifier = [NSString stringWithFormat:@"tl_tab_item_%ld", (long)i];
	      item.userInteractionEnabled = YES;
	      [item addTarget:self action:@selector(tl_itemTapped:) forControlEvents:UIControlEventTouchUpInside];
	      [self.pillView addSubview:item];
    }
    self.currentIndex = 0;
    [self tl_setSelectedIndex:0];
  }
  return self;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
  // 解决“几乎点不动”：系统 UITabBar 子视图可能拦截触摸（即使 hidden）
  // 若触点落在自定义胶囊区域内，强制把触摸交给 pillView/itemViews。
  if (self.hidden || self.alpha <= 0.01 || !self.userInteractionEnabled) {
    return [super hitTest:point withEvent:event];
  }

  CGPoint p = [self convertPoint:point toView:self.pillView];
  if (CGRectContainsPoint(self.pillView.bounds, p)) {
    UIView *v = [self.pillView hitTest:p withEvent:event];
    return v ?: self.pillView;
  }

  return [super hitTest:point withEvent:event];
}

- (void)tl_itemTapped:(UIControl *)sender {
  NSInteger idx = sender.tag;
  [self tl_setSelectedIndex:idx];
  if (self.selectionHandler) {
    self.selectionHandler(idx);
  }
}

- (void)tl_setSelectedIndex:(NSInteger)idx {
  self.currentIndex = idx;
  for (NSInteger i = 0; i < (NSInteger)self.itemViews.count; i++) {
    [self.itemViews[i] tl_applySelected:(i == idx)];
  }
}

- (CGSize)sizeThatFits:(CGSize)size {
  CGSize s = [super sizeThatFits:size];
  CGFloat safeBottom = 0;
  if (@available(iOS 11.0, *)) {
    safeBottom = self.safeAreaInsets.bottom;
  }
  s.height = kTabBarTotalHeight + safeBottom; // 胶囊 + 圆按钮更需要高度
  return s;
}

- (void)layoutSubviews {
  [super layoutSubviews];

  // 隐藏系统注入的交互控件，避免与自定义按钮竞争触摸
  for (UIView *v in self.subviews) {
    if (v != self.pillView && [v isKindOfClass:UIControl.class]) {
      v.hidden = YES;
      v.userInteractionEnabled = NO;
    }
  }
  // 确保自定义胶囊在最上层，可接收点击
  [self bringSubviewToFront:self.pillView];

  CGFloat safeBottom = 0;
  if (@available(iOS 11.0, *)) {
    safeBottom = self.safeAreaInsets.bottom;
  }

  CGFloat pillH = kPillHeight;
  CGFloat pillW = MIN(self.bounds.size.width - kPillHorizontalInset, kPillMaxWidth);
  CGFloat pillX = (self.bounds.size.width - pillW) / 2.0;
  CGFloat pillY = self.bounds.size.height - safeBottom - pillH - kPillBottomOffset;
  self.pillView.frame = CGRectMake(pillX, pillY, pillW, pillH);
  self.pillView.layer.cornerRadius = pillH / 2.0;
  self.pillGradient.frame = self.pillView.bounds;
  self.pillGradient.cornerRadius = self.pillView.layer.cornerRadius;
  self.pillView.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.pillView.bounds cornerRadius:self.pillView.layer.cornerRadius].CGPath;


  CGFloat itemW = pillW / self.itemViews.count;
  for (NSInteger i = 0; i < (NSInteger)self.itemViews.count; i++) {
    TLWTabBarItemView *item = self.itemViews[i];
    item.frame = CGRectMake(i * itemW, kPillItemTopInset, itemW, pillH - kPillItemTopInset);
  }
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
