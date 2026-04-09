//
//  TLWPlantDetailInfoCardView.m
//  TL-PestIdentify
//

#import "TLWPlantDetailInfoCardView.h"
#import <Masonry/Masonry.h>

@interface TLWPlantDetailInfoCardView ()

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *valueLabel;

@end

@implementation TLWPlantDetailInfoCardView

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    self.backgroundColor = [UIColor colorWithRed:0.96 green:0.99 blue:0.99 alpha:1.0];
    self.layer.cornerRadius = 14.0;
    self.layer.shadowColor = [UIColor colorWithRed:0.05 green:0.23 blue:0.19 alpha:0.06].CGColor;
    self.layer.shadowOpacity = 1.0;
    self.layer.shadowOffset = CGSizeMake(0, 8);
    self.layer.shadowRadius = 16.0;

    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.font = [UIFont systemFontOfSize:12.0 weight:UIFontWeightMedium];
    titleLabel.textColor = [UIColor colorWithWhite:0.68 alpha:1.0];
    [self addSubview:titleLabel];
    self.titleLabel = titleLabel;

    UILabel *valueLabel = [[UILabel alloc] init];
    valueLabel.font = [UIFont systemFontOfSize:22.0 weight:UIFontWeightSemibold];
    valueLabel.textColor = [UIColor colorWithRed:0.20 green:0.68 blue:0.56 alpha:1.0];
    [self addSubview:valueLabel];
    self.valueLabel = valueLabel;

    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
      make.top.equalTo(self).offset(12.0);
      make.left.equalTo(self).offset(12.0);
      make.right.equalTo(self).offset(-12.0);
    }];

    [valueLabel mas_makeConstraints:^(MASConstraintMaker *make) {
      make.left.equalTo(titleLabel);
      make.right.equalTo(self).offset(-12.0);
      make.bottom.equalTo(self).offset(-12.0);
    }];
  }
  return self;
}

- (void)configureWithTitle:(NSString *)title value:(NSString *)value emphasizeValue:(BOOL)emphasizeValue {
  self.titleLabel.text = title;
  self.valueLabel.text = value;
  self.valueLabel.font = emphasizeValue ? [UIFont systemFontOfSize:22.0 weight:UIFontWeightSemibold] : [UIFont systemFontOfSize:18.0 weight:UIFontWeightSemibold];
  self.valueLabel.textColor = emphasizeValue ? [UIColor colorWithRed:0.18 green:0.74 blue:0.58 alpha:1.0] : [UIColor colorWithWhite:0.25 alpha:1.0];
}

@end
