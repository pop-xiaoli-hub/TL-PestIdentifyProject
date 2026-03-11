//
//  TLWTabBarItemView.m
//  TL-PestIdentify
//
//  Created by xiaoli pop on 2026/3/11.
//

#import "TLWTabBarItemView.h"

@implementation TLWTabBarItemView

- (instancetype)initWithTitle:(NSString *)title icon:(UIImage *)icon {
  self = [super initWithFrame:CGRectZero];
  if (self) {
    self.backgroundColor = UIColor.clearColor;
    self.userInteractionEnabled = YES;

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


    [self tl_applySelected:NO];
  }
  return self;
}


- (void)layoutSubviews {
  [super layoutSubviews];

  CGFloat circleSize = 64.0;
  CGFloat circleX = (self.bounds.size.width - circleSize) / 2.0;
  self.circleView.frame = CGRectMake(circleX, 0, circleSize, circleSize);
  self.circleView.layer.cornerRadius = circleSize / 2.0;

  self.selectedGradient.frame = self.circleView.bounds;
  self.selectedGradient.cornerRadius = self.circleView.layer.cornerRadius;

  CGFloat iconSize = 26.0;
  self.iconView.frame = CGRectMake((circleSize - iconSize) / 2.0, (circleSize - iconSize) / 2.0 - 4.0, iconSize, iconSize);
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
  } else {
    [self.selectedGradient removeFromSuperlayer];
    self.circleView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.90];
    self.circleView.layer.shadowColor = [UIColor colorWithWhite:0 alpha:1].CGColor;
    self.circleView.layer.shadowOpacity = 0.10;
    self.circleView.layer.shadowRadius = 10;
    self.circleView.layer.shadowOffset = CGSizeMake(0, 6);
    self.iconView.tintColor = green;
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
