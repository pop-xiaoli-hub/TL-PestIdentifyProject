//
//  TLWPlantDetailWateringView.m
//  TL-PestIdentify
//

#import "TLWPlantDetailWateringView.h"
#import "TLWPlantDetailCalendarView.h"
#import "TLWPlantDetailViewModel.h"
#import <Masonry/Masonry.h>

@interface TLWPlantLegendItemView : UIView

- (void)configureWithColor:(UIColor *)color title:(NSString *)title;

@end

@interface TLWPlantLegendItemView ()

@property (nonatomic, strong) UIView *dotView;
@property (nonatomic, strong) UILabel *titleLabel;

@end

@implementation TLWPlantLegendItemView

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    self.backgroundColor = [UIColor colorWithWhite:0.94 alpha:1.0];
    self.layer.cornerRadius = 10.0;

    UIView *dotView = [[UIView alloc] init];
    dotView.layer.cornerRadius = 9.0;
    [self addSubview:dotView];
    self.dotView = dotView;

    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightSemibold];
    titleLabel.textColor = [UIColor colorWithWhite:0.43 alpha:1.0];
    [self addSubview:titleLabel];
    self.titleLabel = titleLabel;

    [dotView mas_makeConstraints:^(MASConstraintMaker *make) {
      make.left.equalTo(self).offset(18.0);
      make.centerY.equalTo(self);
      make.width.height.mas_equalTo(18.0);
    }];

    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
      make.left.equalTo(dotView.mas_right).offset(10.0);
      make.centerY.equalTo(self);
      make.right.equalTo(self).offset(-12.0);
    }];
  }
  return self;
}

- (void)configureWithColor:(UIColor *)color title:(NSString *)title {
  self.dotView.backgroundColor = color;
  self.titleLabel.text = title;
}

@end

@interface TLWPlantDetailWateringView ()

@property (nonatomic, strong) TLWPlantDetailCalendarView *calendarView;

@end

@implementation TLWPlantDetailWateringView

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    TLWPlantDetailCalendarView *calendarView = [[TLWPlantDetailCalendarView alloc] init];
    [self addSubview:calendarView];
    self.calendarView = calendarView;

    UILabel *legendTitleLabel = [[UILabel alloc] init];
    legendTitleLabel.text = @"标签";
    legendTitleLabel.font = [UIFont systemFontOfSize:16.0 weight:UIFontWeightSemibold];
    legendTitleLabel.textColor = [UIColor colorWithWhite:0.18 alpha:1.0];
    [self addSubview:legendTitleLabel];

    TLWPlantLegendItemView *wateredLegendView = [[TLWPlantLegendItemView alloc] init];
    [wateredLegendView configureWithColor:[UIColor colorWithRed:0.47 green:0.86 blue:0.79 alpha:1.0] title:@"已浇水"];
    [self addSubview:wateredLegendView];

    TLWPlantLegendItemView *pendingLegendView = [[TLWPlantLegendItemView alloc] init];
    [pendingLegendView configureWithColor:[UIColor colorWithRed:0.98 green:0.70 blue:0.34 alpha:1.0] title:@"待浇水"];
    [self addSubview:pendingLegendView];

    UIButton *tagButton = [self tl_actionButtonWithTitle:@"打上标签"];
    [tagButton addTarget:self action:@selector(tl_tagButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:tagButton];

    UIButton *cancelTagButton = [self tl_actionButtonWithTitle:@"取消标签"];
    [cancelTagButton addTarget:self action:@selector(tl_cancelTagButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:cancelTagButton];

    [calendarView mas_makeConstraints:^(MASConstraintMaker *make) {
      make.top.left.right.equalTo(self);
      make.height.mas_equalTo(350.0);
    }];

    [legendTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
      make.top.equalTo(calendarView.mas_bottom).offset(18.0);
      make.left.equalTo(self).offset(2.0);
    }];

    [wateredLegendView mas_makeConstraints:^(MASConstraintMaker *make) {
      make.top.equalTo(legendTitleLabel.mas_bottom).offset(12.0);
      make.left.right.equalTo(self);
      make.height.mas_equalTo(42.0);
    }];

    [pendingLegendView mas_makeConstraints:^(MASConstraintMaker *make) {
      make.top.equalTo(wateredLegendView.mas_bottom).offset(10.0);
      make.left.right.height.equalTo(wateredLegendView);
    }];

    [tagButton mas_makeConstraints:^(MASConstraintMaker *make) {
      make.top.equalTo(pendingLegendView.mas_bottom).offset(18.0);
      make.left.right.equalTo(self);
      make.height.mas_equalTo(44.0);
    }];

    [cancelTagButton mas_makeConstraints:^(MASConstraintMaker *make) {
      make.top.equalTo(tagButton.mas_bottom).offset(10.0);
      make.left.right.height.equalTo(tagButton);
      make.bottom.equalTo(self);
    }];

    __weak typeof(self) weakSelf = self;
    calendarView.previousMonthBlock = ^{
      __strong typeof(weakSelf) strongSelf = weakSelf;
      if (strongSelf.previousMonthBlock) {
        strongSelf.previousMonthBlock();
      }
    };
    calendarView.nextMonthBlock = ^{
      __strong typeof(weakSelf) strongSelf = weakSelf;
      if (strongSelf.nextMonthBlock) {
        strongSelf.nextMonthBlock();
      }
    };
  }
  return self;
}

- (UIButton *)tl_actionButtonWithTitle:(NSString *)title {
  UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
  [button setTitle:title forState:UIControlStateNormal];
  [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
  button.titleLabel.font = [UIFont systemFontOfSize:17.0 weight:UIFontWeightSemibold];
  button.layer.cornerRadius = 12.0;
  button.layer.masksToBounds = YES;
  CAGradientLayer *gradientLayer = [CAGradientLayer layer];
  gradientLayer.colors = @[
    (__bridge id)[UIColor colorWithRed:1.00 green:0.82 blue:0.31 alpha:1.0].CGColor,
    (__bridge id)[UIColor colorWithRed:0.99 green:0.63 blue:0.23 alpha:1.0].CGColor
  ];
  gradientLayer.startPoint = CGPointMake(0.0, 0.5);
  gradientLayer.endPoint = CGPointMake(1.0, 0.5);
  gradientLayer.frame = CGRectMake(0, 0, 300, 44);
  [button.layer insertSublayer:gradientLayer atIndex:0];
  return button;
}

- (void)layoutSubviews {
  [super layoutSubviews];
  for (CALayer *layer in self.layer.sublayers) {
    (void)layer;
  }
  for (UIView *subview in self.subviews) {
    if ([subview isKindOfClass:[UIButton class]]) {
      UIButton *button = (UIButton *)subview;
      CALayer *gradientLayer = button.layer.sublayers.firstObject;
      gradientLayer.frame = button.bounds;
      gradientLayer.cornerRadius = button.bounds.size.height * 0.5;
      button.layer.cornerRadius = button.bounds.size.height * 0.5;
    }
  }
}

- (void)configureWithViewModel:(TLWPlantDetailViewModel *)viewModel {
  [self.calendarView configureWithMonthTitle:[viewModel currentMonthTitle] dayItems:[viewModel calendarItems]];
}

- (void)tl_tagButtonTapped {
  if (self.tagActionBlock) {
    self.tagActionBlock();
  }
}

- (void)tl_cancelTagButtonTapped {
  if (self.cancelTagActionBlock) {
    self.cancelTagActionBlock();
  }
}

@end
