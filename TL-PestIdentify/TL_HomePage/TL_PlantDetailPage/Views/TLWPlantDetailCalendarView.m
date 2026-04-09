//
//  TLWPlantDetailCalendarView.m
//  TL-PestIdentify
//

#import "TLWPlantDetailCalendarView.h"
#import "TLWPlantDetailViewModel.h"
#import <Masonry/Masonry.h>

@interface TLWPlantDetailCalendarDayCellView : UIView

- (void)configureWithItem:(TLWPlantCalendarDayItem *)item;

@end

@interface TLWPlantDetailCalendarDayCellView ()

@property (nonatomic, strong) UIView *circleView;
@property (nonatomic, strong) UILabel *dayLabel;

@end

@implementation TLWPlantDetailCalendarDayCellView

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    UIView *circleView = [[UIView alloc] init];
    circleView.layer.cornerRadius = 16.0;
    [self addSubview:circleView];
    self.circleView = circleView;

    UILabel *dayLabel = [[UILabel alloc] init];
    dayLabel.textAlignment = NSTextAlignmentCenter;
    dayLabel.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightSemibold];
    [self addSubview:dayLabel];
    self.dayLabel = dayLabel;

    [circleView mas_makeConstraints:^(MASConstraintMaker *make) {
      make.center.equalTo(self);
      make.width.height.mas_equalTo(32.0);
    }];

    [dayLabel mas_makeConstraints:^(MASConstraintMaker *make) {
      make.edges.equalTo(self);
    }];
  }
  return self;
}

- (void)configureWithItem:(TLWPlantCalendarDayItem *)item {
  self.dayLabel.text = item.dayText;
  self.dayLabel.textColor = item.inCurrentMonth ? [UIColor colorWithWhite:0.32 alpha:1.0] : [UIColor colorWithWhite:0.78 alpha:1.0];
  self.circleView.backgroundColor = [UIColor clearColor];
  self.circleView.layer.borderWidth = 0.0;
  self.circleView.layer.borderColor = UIColor.clearColor.CGColor;

  switch (item.status) {
    case TLWPlantCalendarDayStatusWatered:
      self.circleView.backgroundColor = [UIColor colorWithRed:0.47 green:0.86 blue:0.79 alpha:1.0];
      self.dayLabel.textColor = [UIColor whiteColor];
      break;
    case TLWPlantCalendarDayStatusPending:
      self.circleView.backgroundColor = [UIColor colorWithRed:0.98 green:0.70 blue:0.34 alpha:1.0];
      self.dayLabel.textColor = [UIColor whiteColor];
      break;
    case TLWPlantCalendarDayStatusSelected:
      self.circleView.backgroundColor = [UIColor whiteColor];
      self.circleView.layer.borderWidth = 2.0;
      self.circleView.layer.borderColor = [UIColor colorWithRed:0.48 green:0.78 blue:0.74 alpha:1.0].CGColor;
      self.dayLabel.textColor = [UIColor colorWithWhite:0.32 alpha:1.0];
      break;
    case TLWPlantCalendarDayStatusNone:
      break;
  }
}

@end

@interface TLWPlantDetailCalendarView ()

@property (nonatomic, strong) UILabel *monthTitleLabel;
@property (nonatomic, strong) NSMutableArray<UILabel *> *weekdayLabels;
@property (nonatomic, strong) NSMutableArray<TLWPlantDetailCalendarDayCellView *> *dayCellViews;

@end

@implementation TLWPlantDetailCalendarView

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    self.backgroundColor = [UIColor whiteColor];
    self.layer.cornerRadius = 18.0;

    UIButton *previousButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [previousButton setTitle:@"‹" forState:UIControlStateNormal];
    [previousButton setTitleColor:[UIColor colorWithWhite:0.30 alpha:1.0] forState:UIControlStateNormal];
    previousButton.titleLabel.font = [UIFont systemFontOfSize:24.0 weight:UIFontWeightMedium];
    [previousButton addTarget:self action:@selector(tl_previousTapped) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:previousButton];

    UIButton *nextButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [nextButton setTitle:@"›" forState:UIControlStateNormal];
    [nextButton setTitleColor:[UIColor colorWithWhite:0.30 alpha:1.0] forState:UIControlStateNormal];
    nextButton.titleLabel.font = [UIFont systemFontOfSize:24.0 weight:UIFontWeightMedium];
    [nextButton addTarget:self action:@selector(tl_nextTapped) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:nextButton];

    UILabel *monthTitleLabel = [[UILabel alloc] init];
    monthTitleLabel.font = [UIFont systemFontOfSize:18.0 weight:UIFontWeightSemibold];
    monthTitleLabel.textColor = [UIColor colorWithWhite:0.28 alpha:1.0];
    monthTitleLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:monthTitleLabel];
    self.monthTitleLabel = monthTitleLabel;

    [previousButton mas_makeConstraints:^(MASConstraintMaker *make) {
      make.left.equalTo(self).offset(14.0);
      make.top.equalTo(self).offset(10.0);
      make.width.height.mas_equalTo(30.0);
    }];

    [nextButton mas_makeConstraints:^(MASConstraintMaker *make) {
      make.right.equalTo(self).offset(-14.0);
      make.centerY.equalTo(previousButton);
      make.width.height.mas_equalTo(30.0);
    }];

    [monthTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
      make.left.equalTo(previousButton.mas_right).offset(8.0);
      make.right.equalTo(nextButton.mas_left).offset(-8.0);
      make.centerY.equalTo(previousButton);
    }];

    self.weekdayLabels = [NSMutableArray array];
    NSArray<NSString *> *weekdays = @[@"一", @"二", @"三", @"四", @"五", @"六", @"日"];
    UILabel *previousWeekLabel = nil;
    for (NSInteger index = 0; index < weekdays.count; index++) {
      UILabel *label = [[UILabel alloc] init];
      label.text = weekdays[index];
      label.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightSemibold];
      label.textColor = [UIColor colorWithWhite:0.65 alpha:1.0];
      label.textAlignment = NSTextAlignmentCenter;
      [self addSubview:label];
      [self.weekdayLabels addObject:label];

      [label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(monthTitleLabel.mas_bottom).offset(14.0);
        make.height.mas_equalTo(20.0);
        if (previousWeekLabel) {
          make.left.equalTo(previousWeekLabel.mas_right);
          make.width.equalTo(previousWeekLabel);
        } else {
          make.left.equalTo(self).offset(8.0);
        }
        if (index == weekdays.count - 1) {
          make.right.equalTo(self).offset(-8.0);
        }
      }];
      previousWeekLabel = label;
    }

    self.dayCellViews = [NSMutableArray array];
    for (NSInteger index = 0; index < 42; index++) {
      TLWPlantDetailCalendarDayCellView *cellView = [[TLWPlantDetailCalendarDayCellView alloc] init];
      [self addSubview:cellView];
      [self.dayCellViews addObject:cellView];

      NSInteger row = index / 7;
      NSInteger column = index % 7;
      UILabel *anchorLabel = self.weekdayLabels[column];
      UIView *topAnchor = row == 0 ? self.weekdayLabels.firstObject : self.dayCellViews[index - 7];
      CGFloat topOffset = row == 0 ? 10.0 : 8.0;

      [cellView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(anchorLabel);
        make.top.equalTo(topAnchor.mas_bottom).offset(topOffset);
        make.width.height.mas_equalTo(38.0);
      }];
    }
  }
  return self;
}

- (void)configureWithMonthTitle:(NSString *)monthTitle dayItems:(NSArray<TLWPlantCalendarDayItem *> *)dayItems {
  self.monthTitleLabel.text = monthTitle;
  NSInteger maxCount = MIN(dayItems.count, self.dayCellViews.count);
  for (NSInteger index = 0; index < maxCount; index++) {
    [self.dayCellViews[index] configureWithItem:dayItems[index]];
  }
}

- (void)tl_previousTapped {
  if (self.previousMonthBlock) {
    self.previousMonthBlock();
  }
}

- (void)tl_nextTapped {
  if (self.nextMonthBlock) {
    self.nextMonthBlock();
  }
}

@end
