//
//  TLWPlantDetailViewModel.m
//  TL-PestIdentify
//

#import "TLWPlantDetailViewModel.h"
#import "../../Models/TLWPlantModel.h"
#import <AgriPestClient/AGCultivationRecordDto.h>
#import <AgriPestClient/AGMyCropResponseDto.h>

@implementation TLWPlantCalendarDayItem
@end

@interface TLWPlantDetailViewModel ()

@property (nonatomic, strong, readwrite) TLWPlantModel *plantModel;
@property (nonatomic, strong, readwrite) NSDate *displayMonthDate;
@property (nonatomic, strong) NSDate *selectedDate;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *markedStatusMap;

@end

@implementation TLWPlantDetailViewModel

- (NSCalendar *)tl_calendar {
  NSCalendar *calendar = [NSCalendar currentCalendar];
  calendar.timeZone = [NSTimeZone localTimeZone];
  return calendar;
}

- (NSDateFormatter *)tl_dayFormatter {
  NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
  formatter.dateFormat = @"yyyy-MM-dd";
  formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
  formatter.timeZone = [NSTimeZone localTimeZone];
  return formatter;
}

- (NSDate *)tl_normalizedDate:(NSDate *)date {
  if (!date) {
    return nil;
  }
  return [[self tl_calendar] startOfDayForDate:date];
}

- (instancetype)initWithPlantModel:(TLWPlantModel *)plantModel {
  self = [super init];
  if (self) {
    _plantModel = plantModel;
    _selectedTabType = TLWPlantDetailTabTypeWater;

    NSCalendar *calendar = [self tl_calendar];
    NSDateComponents *components = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth fromDate:[NSDate date]];
    components.day = 1;
    _displayMonthDate = [calendar dateFromComponents:components] ?: [NSDate date];
    _selectedDate = [self tl_normalizedDate:[NSDate date]];
    _markedStatusMap = [NSMutableDictionary dictionary];
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
  NSCalendar *calendar = [self tl_calendar];
  NSDateComponents *monthComponents = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth fromDate:self.displayMonthDate];
  monthComponents.day = 1;
  NSDate *firstDayOfMonth = [calendar dateFromComponents:monthComponents] ?: self.displayMonthDate;

  NSInteger weekday = [calendar component:NSCalendarUnitWeekday fromDate:firstDayOfMonth];
  NSInteger leadingEmptyCount = (weekday + 5) % 7;

  NSDateComponents *offsetComponents = [[NSDateComponents alloc] init];
  offsetComponents.day = -leadingEmptyCount;
  NSDate *gridStartDate = [calendar dateByAddingComponents:offsetComponents toDate:firstDayOfMonth options:0] ?: firstDayOfMonth;

  NSMutableArray<TLWPlantCalendarDayItem *> *items = [NSMutableArray array];
  for (NSInteger index = 0; index < 42; index++) {
    NSDateComponents *dayOffset = [[NSDateComponents alloc] init];
    dayOffset.day = index;
    NSDate *date = [calendar dateByAddingComponents:dayOffset toDate:gridStartDate options:0] ?: gridStartDate;
    NSDateComponents *dateComponents = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:date];

    TLWPlantCalendarDayItem *item = [[TLWPlantCalendarDayItem alloc] init];
    item.dayText = [NSString stringWithFormat:@"%02ld", (long)dateComponents.day];
    item.inCurrentMonth = (dateComponents.month == monthComponents.month && dateComponents.year == monthComponents.year);
    item.isToday = [calendar isDateInToday:date];
    item.date = [self tl_normalizedDate:date];
    item.status = TLWPlantCalendarDayStatusNone;
    item.isSelected = item.inCurrentMonth && [calendar isDate:date equalToDate:self.selectedDate toUnitGranularity:NSCalendarUnitDay];

    NSNumber *storedStatus = self.markedStatusMap[[self tl_keyForDate:date]];
    if (storedStatus != nil) {
      item.status = storedStatus.integerValue;
    }

    [items addObject:item];
  }

  return [items copy];
}

- (CGFloat)preferredContentHeightForSelectedTab {
  switch (self.selectedTabType) {
    case TLWPlantDetailTabTypeWater:
    case TLWPlantDetailTabTypeFertilizer:
      return 620.0;
    case TLWPlantDetailTabTypeMedicine:
    case TLWPlantDetailTabTypeNote:
      return 176.0;
  }
}

- (NSDate *)currentSelectedDate {
  return self.selectedDate ?: [NSDate date];
}

- (void)applyCropDetailResponse:(AGMyCropResponseDto *)cropDetail {
  if (![cropDetail isKindOfClass:[AGMyCropResponseDto class]]) {
    return;
  }

  id recordsObj = cropDetail.records;
  if (![recordsObj isKindOfClass:[NSDictionary class]]) {
    return;
  }

  NSDictionary *records = (NSDictionary *)recordsObj;
  id wateringRecordsObj = records[@"WATERING"];
  if (![wateringRecordsObj isKindOfClass:[NSArray class]]) {
    return;
  }

  NSArray *wateringRecords = (NSArray *)wateringRecordsObj;
  NSMutableDictionary<NSString *, NSNumber *> *serverStatusMap = [NSMutableDictionary dictionary];
  NSDateFormatter *formatter = [self tl_dayFormatter];

  for (id recordObj in wateringRecords) {
    if (![recordObj isKindOfClass:[NSDictionary class]]) {
      continue;
    }

    NSDictionary *recordDict = (NSDictionary *)recordObj;
    NSString *recordDateString = [recordDict[@"recordDate"] isKindOfClass:[NSString class]] ? recordDict[@"recordDate"] : nil;
    NSNumber *statusNumber = [recordDict[@"status"] isKindOfClass:[NSNumber class]] ? recordDict[@"status"] : nil;
    NSString *content = [recordDict[@"content"] isKindOfClass:[NSString class]] ? recordDict[@"content"] : nil;
    NSString *tagType = [recordDict[@"tagType"] isKindOfClass:[NSString class]] ? recordDict[@"tagType"] : nil;

    if (recordDateString.length == 0) {
      continue;
    }

    NSLog(@"[PlantDetail] watering record, date=%@ status=%@ content=%@ tagType=%@",
          recordDateString,
          statusNumber,
          content,
          tagType);

    NSDate *recordDate = [self tl_normalizedDate:[formatter dateFromString:recordDateString]];
    if (recordDate == nil) {
      continue;
    }

    NSString *dateKey = [self tl_keyForDate:recordDate];
    TLWPlantCalendarDayStatus status = statusNumber.integerValue == 1 ? TLWPlantCalendarDayStatusWatered : TLWPlantCalendarDayStatusPending;
    serverStatusMap[dateKey] = @(status);
  }

  [self.markedStatusMap removeAllObjects];
  [self.markedStatusMap addEntriesFromDictionary:serverStatusMap];
}

- (void)selectDate:(NSDate *)date {
  if (!date) {
    return;
  }
  self.selectedDate = [self tl_normalizedDate:date];
}

- (void)markSelectedDateAsWatered {
  [self tl_storeStatus:TLWPlantCalendarDayStatusWatered forDate:self.selectedDate];
}

- (void)markSelectedDateAsPending {
  [self tl_storeStatus:TLWPlantCalendarDayStatusPending forDate:self.selectedDate];
}

- (void)moveToPreviousMonth {
  NSDateComponents *components = [[NSDateComponents alloc] init];
  components.month = -1;
  self.displayMonthDate = [[self tl_calendar] dateByAddingComponents:components toDate:self.displayMonthDate options:0] ?: self.displayMonthDate;
  [self tl_resetSelectedDateIntoDisplayMonthIfNeeded];
}

- (void)moveToNextMonth {
  NSDateComponents *components = [[NSDateComponents alloc] init];
  components.month = 1;
  self.displayMonthDate = [[self tl_calendar] dateByAddingComponents:components toDate:self.displayMonthDate options:0] ?: self.displayMonthDate;
  [self tl_resetSelectedDateIntoDisplayMonthIfNeeded];
}

- (NSString *)tl_keyForDate:(NSDate *)date {
  NSDate *normalizedDate = [self tl_normalizedDate:date];
  if (!normalizedDate) {
    return nil;
  }
  return [[self tl_dayFormatter] stringFromDate:normalizedDate];
}

- (void)tl_storeStatus:(TLWPlantCalendarDayStatus)status forDate:(NSDate *)date {
  if (!date) {
    return;
  }
  self.markedStatusMap[[self tl_keyForDate:date]] = @(status);
}

- (void)tl_resetSelectedDateIntoDisplayMonthIfNeeded {
  NSCalendar *calendar = [self tl_calendar];
  if ([calendar isDate:self.selectedDate equalToDate:self.displayMonthDate toUnitGranularity:NSCalendarUnitMonth]) {
    return;
  }

  NSDateComponents *components = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth fromDate:self.displayMonthDate];
  components.day = 1;
  self.selectedDate = [self tl_normalizedDate:[calendar dateFromComponents:components] ?: self.displayMonthDate];
}

@end
