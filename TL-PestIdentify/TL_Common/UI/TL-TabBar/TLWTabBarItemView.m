//
//  TLWTabBarItemView.m
//  TL-PestIdentify
//
//  Created by TommyWu on 2026/4/4.
//  职责：实现底部导航栏单项视图。
//
#import "TLWTabBarItemView.h"

static CGFloat const kCircleSize = 64.0;
static CGFloat const kIconSize = 20.0;
static CGFloat const kLabelHeight = 13.0;
static CGFloat const kIconLabelGap = 2.0;

@implementation TLWTabBarItemView

- (instancetype)initWithTitle:(NSString *)title icon:(UIImage *)icon {
  self = [super initWithFrame:CGRectZero];
  if (self) {
	    self.backgroundColor = UIColor.clearColor;
	    self.userInteractionEnabled = YES;
      self.isAccessibilityElement = YES;
      self.accessibilityLabel = title;
      self.accessibilityTraits = UIAccessibilityTraitButton;

    self.circleView = [UIView new];
    self.circleView.backgroundColor = UIColor.whiteColor;
    self.circleView.layer.cornerRadius = 32;
    self.circleView.layer.masksToBounds = NO;
    self.circleView.layer.shadowColor = [UIColor colorWithWhite:0 alpha:1].CGColor;
    self.circleView.layer.shadowOpacity = 0.10;
    self.circleView.layer.shadowRadius = 10;
    self.circleView.userInteractionEnabled = NO;
    self.circleView.layer.shadowOffset = CGSizeMake(0, 6);
    [self addSubview:self.circleView];

    self.selectedGradient = [CAGradientLayer layer];
    self.selectedGradient.startPoint = CGPointMake(0, 0);
    self.selectedGradient.endPoint = CGPointMake(1, 1);
    self.selectedGradient.colors = @[
      (__bridge id)[UIColor colorWithRed:0.10 green:0.93 blue:0.70 alpha:1.0].CGColor,
      (__bridge id)[UIColor colorWithRed:0.12 green:0.80 blue:0.98 alpha:1.0].CGColor
    ];
    self.selectedGradient.locations = @[@0, @1];
    self.selectedGradient.cornerRadius = 32;

    self.iconView = [[UIImageView alloc] initWithImage:icon];
    self.iconView.contentMode = UIViewContentModeScaleAspectFit;
    [self.circleView addSubview:self.iconView];

    // 文字放在圆圈内部，图标正下方
    self.titleLabel = [UILabel new];
    self.titleLabel.text = title;
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.font = [UIFont systemFontOfSize:10 weight:UIFontWeightMedium];
    self.titleLabel.textColor = [UIColor colorWithRed:0.00 green:0.62 blue:0.52 alpha:1.0];
    [self.circleView addSubview:self.titleLabel];

    [self tl_applySelected:NO];
  }
  return self;
}


- (void)layoutSubviews {
  [super layoutSubviews];

  CGFloat circleSize = kCircleSize;
  CGFloat circleX = (self.bounds.size.width - circleSize) / 2.0;
  self.circleView.frame = CGRectMake(circleX, 0, circleSize, circleSize);
  self.circleView.layer.cornerRadius = circleSize / 2.0;

  self.selectedGradient.frame = self.circleView.bounds;
  self.selectedGradient.cornerRadius = self.circleView.layer.cornerRadius;

  // 图标 + 文字整体在圆圈内垂直居中
  CGFloat iconSize = kIconSize;
  CGFloat labelHeight = kLabelHeight;
  CGFloat gap = kIconLabelGap;
  CGFloat totalH = iconSize + gap + labelHeight;
  CGFloat topY = (circleSize - totalH) / 2.0;

  // 图标在上
  self.iconView.frame = CGRectMake((circleSize - iconSize) / 2.0, topY, iconSize, iconSize);

  // 文字紧接图标下方，宽度撑满圆圈
  self.titleLabel.frame = CGRectMake(0, topY + iconSize + gap, circleSize, labelHeight);
}

- (void)tl_applySelected:(BOOL)selected {
  self.tl_selected = selected;

  UIColor *green = [UIColor colorWithRed:0.00 green:0.62 blue:0.52 alpha:1.0];
  if (selected) {
    if (self.selectedGradient.superlayer != self.circleView.layer) {
      [self.circleView.layer insertSublayer:self.selectedGradient atIndex:0];
    }
    self.circleView.backgroundColor = UIColor.clearColor;
    self.circleView.layer.shadowColor = green.CGColor;
    self.circleView.layer.shadowOpacity = 0.35;
    self.circleView.layer.shadowRadius = 18;
    self.circleView.layer.shadowOffset = CGSizeMake(0, 10);
    self.iconView.tintColor = UIColor.whiteColor;
    self.titleLabel.textColor = UIColor.whiteColor;
  } else {
    [self.selectedGradient removeFromSuperlayer];
    self.circleView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.90];
    self.circleView.layer.shadowColor = [UIColor colorWithWhite:0 alpha:1].CGColor;
    self.circleView.layer.shadowOpacity = 0.10;
    self.circleView.layer.shadowRadius = 10;
    self.circleView.layer.shadowOffset = CGSizeMake(0, 6);
    self.iconView.tintColor = green;
    self.titleLabel.textColor = green;
  }

  self.accessibilityTraits = UIAccessibilityTraitButton | (selected ? UIAccessibilityTraitSelected : 0);
}


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
