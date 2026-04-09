//
//  TLWPlantDetailViewModel.m
//  TL-PestIdentify
//

#import "TLWPlantDetailViewModel.h"
#import "../../Models/TLWPlantModel.h"

@implementation TLWPlantCalendarDayItem
@end

@interface TLWPlantDetailViewModel ()

@property (nonatomic, strong, readwrite) TLWPlantModel *plantModel;
@property (nonatomic, strong, readwrite) NSDate *displayMonthDate;

@end

@implementation TLWPlantDetailViewModel

- (instancetype)initWithPlantModel:(TLWPlantModel *)plantModel {
  self = [super init];
  if (self) {
    _plantModel = plantModel;
    _selectedTabType = TLWPlantDetailTabTypeWater;

    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth fromDate:[NSDate date]];
    components.day = 1;
    _displayMonthDate = [calendar dateFromComponents:components] ?: [NSDate date];
  }
  return self;
}

- (NSString *)plantTitleText {
  return self.plantModel.plantName.length > 0 ? self.plantModel.plantName : @"未命名植物";
}

- (NSString *)healthStatusText {
  if (self.plantModel.isUploading) {
    return @"上传中";
  }
  return @"良好";
}

- (NSString *)plantingDateText {
  NSDate *referenceDate = [NSDate dateWithTimeIntervalSinceNow:-(24 * 60 * 60 * 120)];
  NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
  formatter.dateFormat = @"MM/dd/yyyy";
  return [formatter stringFromDate:referenceDate];
}

- (nullable NSString *)imageURLString {
  return self.plantModel.imageUrl.length > 0 ? self.plantModel.imageUrl : nil;
}

- (NSArray<NSString *> *)tabTitles {
  return @[@"浇水", @"施肥", @"用药", @"笔记"];
}

- (NSString *)currentMonthTitle {
  NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
  formatter.dateFormat = @"yyyy年M月";
  return [formatter stringFromDate:self.displayMonthDate];
}

- (NSArray<TLWPlantCalendarDayItem *> *)calendarItems {
  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSDateComponents *monthComponents = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth fromDate:self.displayMonthDate];
  monthComponents.day = 1;
  NSDate *firstDayOfMonth = [calendar dateFromComponents:monthComponents] ?: self.displayMonthDate;

  NSRange dayRange = [calendar rangeOfUnit:NSCalendarUnitDay inUnit:NSCalendarUnitMonth forDate:firstDayOfMonth];
  NSInteger numberOfDays = dayRange.length;

  NSInteger weekday = [calendar component:NSCalendarUnitWeekday fromDate:firstDayOfMonth];
  NSInteger leadingEmptyCount = (weekday + 5) % 7;

  NSDateComponents *offsetComponents = [[NSDateComponents alloc] init];
  offsetComponents.day = -leadingEmptyCount;
  NSDate *gridStartDate = [calendar dateByAddingComponents:offsetComponents toDate:firstDayOfMonth options:0] ?: firstDayOfMonth;

  NSMutableArray<TLWPlantCalendarDayItem *> *items = [NSMutableArray array];
  NSSet<NSNumber *> *wateredDays = [NSSet setWithArray:@[@2, @6, @11, @16]];
  NSSet<NSNumber *> *pendingDays = [NSSet setWithArray:@[@20, @23, @26]];
  NSInteger selectedDay = 18;

  for (NSInteger index = 0; index < 42; index++) {
    NSDateComponents *dayOffset = [[NSDateComponents alloc] init];
    dayOffset.day = index;
    NSDate *date = [calendar dateByAddingComponents:dayOffset toDate:gridStartDate options:0] ?: gridStartDate;
    NSDateComponents *dateComponents = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:date];

    TLWPlantCalendarDayItem *item = [[TLWPlantCalendarDayItem alloc] init];
    item.dayText = [NSString stringWithFormat:@"%02ld", (long)dateComponents.day];
    item.inCurrentMonth = (dateComponents.month == monthComponents.month && dateComponents.year == monthComponents.year);
    item.isToday = [calendar isDateInToday:date];
    item.status = TLWPlantCalendarDayStatusNone;

    if (item.inCurrentMonth && dateComponents.day == selectedDay) {
      item.status = TLWPlantCalendarDayStatusSelected;
    } else if (item.inCurrentMonth && [wateredDays containsObject:@(dateComponents.day)]) {
      item.status = TLWPlantCalendarDayStatusWatered;
    } else if (item.inCurrentMonth && [pendingDays containsObject:@(dateComponents.day)]) {
      item.status = TLWPlantCalendarDayStatusPending;
    }

    [items addObject:item];
  }

  if (items.count > numberOfDays + leadingEmptyCount && items.count < 42) {
    return [items copy];
  }
  return [items copy];
}

- (CGFloat)preferredContentHeightForSelectedTab {
  switch (self.selectedTabType) {
    case TLWPlantDetailTabTypeWater:
      return 620.0;
    case TLWPlantDetailTabTypeFertilizer:
    case TLWPlantDetailTabTypeMedicine:
    case TLWPlantDetailTabTypeNote:
      return 176.0;
  }
}

- (void)moveToPreviousMonth {
  NSDateComponents *components = [[NSDateComponents alloc] init];
  components.month = -1;
  self.displayMonthDate = [[NSCalendar currentCalendar] dateByAddingComponents:components toDate:self.displayMonthDate options:0] ?: self.displayMonthDate;
}

- (void)moveToNextMonth {
  NSDateComponents *components = [[NSDateComponents alloc] init];
  components.month = 1;
  self.displayMonthDate = [[NSCalendar currentCalendar] dateByAddingComponents:components toDate:self.displayMonthDate options:0] ?: self.displayMonthDate;
}

@end
