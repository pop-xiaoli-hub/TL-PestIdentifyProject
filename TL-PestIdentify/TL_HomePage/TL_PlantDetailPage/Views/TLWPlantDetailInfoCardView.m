//
//  TLWPlantDetailInfoCardView.m
//  TL-PestIdentify
//

#import "TLWPlantDetailInfoCardView.h"
#import <Masonry/Masonry.h>

@interface TLWPlantDetailInfoCardView ()

@property (nonatomic, strong) UIView *surfaceView;
@property (nonatomic, strong) UIView *glowView;
@property (nonatomic, strong) UIView *highlightView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *valueLabel;

@end

@implementation TLWPlantDetailInfoCardView

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    self.backgroundColor = [UIColor clearColor];
    self.layer.cornerRadius = 18.0;
    self.layer.shadowColor = [UIColor colorWithRed:0.16 green:0.35 blue:0.32 alpha:0.18].CGColor;
    self.layer.shadowOpacity = 1.0;
    self.layer.shadowOffset = CGSizeMake(0, 14);
    self.layer.shadowRadius = 24.0;

    UIView *surfaceView = [[UIView alloc] init];
    surfaceView.backgroundColor = [UIColor colorWithRed:0.95 green:0.99 blue:0.98 alpha:1.0];
    surfaceView.layer.cornerRadius = 18.0;
    surfaceView.layer.borderWidth = 1.0;
    surfaceView.layer.borderColor = [UIColor colorWithRed:0.85 green:0.95 blue:0.92 alpha:0.9].CGColor;
    surfaceView.layer.masksToBounds = YES;
    [self addSubview:surfaceView];
    self.surfaceView = surfaceView;

    UIView *glowView = [[UIView alloc] init];
    glowView.backgroundColor = [UIColor colorWithRed:0.80 green:0.96 blue:0.91 alpha:0.35];
    glowView.layer.cornerRadius = 28.0;
    glowView.userInteractionEnabled = NO;
    [surfaceView addSubview:glowView];
    self.glowView = glowView;

    UIView *highlightView = [[UIView alloc] init];
    highlightView.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.55];
    highlightView.layer.cornerRadius = 14.0;
    highlightView.userInteractionEnabled = NO;
    [surfaceView addSubview:highlightView];
    self.highlightView = highlightView;

    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.font = [UIFont systemFontOfSize:12.0 weight:UIFontWeightMedium];
    titleLabel.textColor = [UIColor colorWithRed:0.57 green:0.64 blue:0.63 alpha:1.0];
    [surfaceView addSubview:titleLabel];
    self.titleLabel = titleLabel;

    UILabel *valueLabel = [[UILabel alloc] init];
    valueLabel.font = [UIFont systemFontOfSize:22.0 weight:UIFontWeightSemibold];
    valueLabel.textColor = [UIColor colorWithRed:0.20 green:0.68 blue:0.56 alpha:1.0];
    [surfaceView addSubview:valueLabel];
    self.valueLabel = valueLabel;

    [surfaceView mas_makeConstraints:^(MASConstraintMaker *make) {
      make.edges.equalTo(self);
    }];

    [glowView mas_makeConstraints:^(MASConstraintMaker *make) {
      make.width.mas_equalTo(94.0);
      make.height.mas_equalTo(72.0);
      make.right.equalTo(surfaceView).offset(18.0);
      make.bottom.equalTo(surfaceView).offset(20.0);
    }];

    [highlightView mas_makeConstraints:^(MASConstraintMaker *make) {
      make.top.equalTo(surfaceView).offset(8.0);
      make.left.equalTo(surfaceView).offset(10.0);
      make.right.equalTo(surfaceView).offset(-10.0);
      make.height.mas_equalTo(24.0);
    }];

    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
      make.top.equalTo(surfaceView).offset(14.0);
      make.left.equalTo(surfaceView).offset(16.0);
      make.right.equalTo(surfaceView).offset(-16.0);
    }];

    [valueLabel mas_makeConstraints:^(MASConstraintMaker *make) {
      make.left.equalTo(titleLabel);
      make.right.equalTo(surfaceView).offset(-16.0);
      make.bottom.equalTo(surfaceView).offset(-13.0);
    }];
  }
  return self;
}

- (void)layoutSubviews {
  [super layoutSubviews];
  self.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:18.0].CGPath;
}

- (void)configureWithTitle:(NSString *)title value:(NSString *)value emphasizeValue:(BOOL)emphasizeValue {
  self.titleLabel.text = title;
  self.valueLabel.text = value;
  self.valueLabel.font = emphasizeValue ? [UIFont systemFontOfSize:22.0 weight:UIFontWeightSemibold] : [UIFont systemFontOfSize:18.0 weight:UIFontWeightSemibold];
  self.valueLabel.textColor = emphasizeValue ? [UIColor colorWithRed:0.18 green:0.74 blue:0.58 alpha:1.0] : [UIColor colorWithWhite:0.25 alpha:1.0];
}

@end
