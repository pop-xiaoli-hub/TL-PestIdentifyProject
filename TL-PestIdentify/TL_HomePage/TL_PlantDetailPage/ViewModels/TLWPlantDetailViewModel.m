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
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableDictionary<NSString *, NSNumber *> *> *markedStatusMapsByTagType;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *noteContentMap;

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
  //初始化默认为浇水模型
  self = [super init];
  if (self) {
    _plantModel = plantModel;
    _selectedTabType = TLWPlantDetailTabTypeWater;

    NSCalendar *calendar = [self tl_calendar];
    NSDateComponents *components = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth fromDate:[NSDate date]];
    components.day = 1;
    _displayMonthDate = [calendar dateFromComponents:components] ?: [NSDate date];
    _selectedDate = [self tl_normalizedDate:[NSDate date]];
    _markedStatusMapsByTagType = [NSMutableDictionary dictionary];
    _noteContentMap = [NSMutableDictionary dictionary];
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
  return self.plantModel.plantStatus.length > 0 ? self.plantModel.plantStatus : @"未知";
}

- (NSString *)plantingDateText {
  NSDate *referenceDate = self.plantModel.plantingDate;
  if (!referenceDate) {
    return @"--";
  }
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
  return [self calendarItemsForTabType:self.selectedTabType];
}

- (NSArray<TLWPlantCalendarDayItem *> *)calendarItemsForTabType:(TLWPlantDetailTabType)tabType {
  NSCalendar *calendar = [self tl_calendar];
  NSDateComponents *monthComponents = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth fromDate:self.displayMonthDate];
  monthComponents.day = 1;
  NSDate *firstDayOfMonth = [calendar dateFromComponents:monthComponents] ?: self.displayMonthDate;
  NSDictionary<NSString *, NSNumber *> *statusMap = [self tl_statusMapForTabType:tabType];

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

    NSNumber *storedStatus = statusMap[[self tl_keyForDate:date]];
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
    case TLWPlantDetailTabTypeMedicine:
      return 650.0;
    case TLWPlantDetailTabTypeNote:
      return 670.0;
  }
}

- (NSDate *)currentSelectedDate {
  return self.selectedDate ?: [NSDate date];
}

- (NSString *)noteContentForSelectedDate {
  NSString *dateKey = [self tl_keyForDate:self.selectedDate];
  NSString *noteContent = self.noteContentMap[dateKey];
  return [noteContent isKindOfClass:[NSString class]] ? noteContent : @"";
}

- (void)applyCropDetailResponse:(AGMyCropResponseDto *)cropDetail {
  if (![cropDetail isKindOfClass:[AGMyCropResponseDto class]]) {
    return;
  }

  if ([cropDetail.plantName isKindOfClass:[NSString class]] && cropDetail.plantName.length > 0) {
    self.plantModel.plantName = cropDetail.plantName;
  }
  if ([cropDetail.imageUrl isKindOfClass:[NSString class]] && cropDetail.imageUrl.length > 0) {
    self.plantModel.imageUrl = cropDetail.imageUrl;
  }
  self.plantModel.plantStatus = [cropDetail.status isKindOfClass:[NSString class]] ? cropDetail.status : @"";
  self.plantModel.plantingDate = cropDetail.plantingDate;

  id recordsObj = cropDetail.records;
  if (![recordsObj isKindOfClass:[NSDictionary class]]) {
    return;
  }

  NSDictionary *records = (NSDictionary *)recordsObj;
  [self tl_updateStatusMapForTagType:@"WATERING" withRecordsObject:records[@"WATERING"]];
  [self tl_updateStatusMapForTagType:@"FERTILIZING" withRecordsObject:records[@"FERTILIZING"]];
  [self tl_updateStatusMapForTagType:@"MEDICATION" withRecordsObject:records[@"MEDICATION"]];
  [self tl_updateStatusMapForTagType:@"NOTE" withRecordsObject:records[@"NOTE"]];
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
  NSMutableDictionary<NSString *, NSNumber *> *statusMap = [self tl_mutableStatusMapForTabType:self.selectedTabType];
  statusMap[[self tl_keyForDate:date]] = @(status);
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

- (NSString *)tl_tagTypeKeyForTabType:(TLWPlantDetailTabType)tabType {
  switch (tabType) {
    case TLWPlantDetailTabTypeWater:
      return @"WATERING";
    case TLWPlantDetailTabTypeFertilizer:
      return @"FERTILIZING";
    case TLWPlantDetailTabTypeMedicine:
      return @"MEDICATION";
    case TLWPlantDetailTabTypeNote:
      return @"NOTE";
  }
}

- (NSDictionary<NSString *, NSNumber *> *)tl_statusMapForTabType:(TLWPlantDetailTabType)tabType {
  NSString *tagTypeKey = [self tl_tagTypeKeyForTabType:tabType];
  NSDictionary<NSString *, NSNumber *> *statusMap = self.markedStatusMapsByTagType[tagTypeKey];
  return [statusMap isKindOfClass:[NSDictionary class]] ? statusMap : @{};
}

- (NSMutableDictionary<NSString *, NSNumber *> *)tl_mutableStatusMapForTabType:(TLWPlantDetailTabType)tabType {
  NSString *tagTypeKey = [self tl_tagTypeKeyForTabType:tabType];
  NSMutableDictionary<NSString *, NSNumber *> *statusMap = self.markedStatusMapsByTagType[tagTypeKey];
  if (![statusMap isKindOfClass:[NSMutableDictionary class]]) {
    statusMap = [NSMutableDictionary dictionary];
    self.markedStatusMapsByTagType[tagTypeKey] = statusMap;
  }
  return statusMap;
}

- (void)tl_updateStatusMapForTagType:(NSString *)tagTypeKey withRecordsObject:(id)recordsObject {
  NSMutableDictionary<NSString *, NSNumber *> *serverStatusMap = [NSMutableDictionary dictionary];
  NSDateFormatter *formatter = [self tl_dayFormatter];
  NSArray *records = [recordsObject isKindOfClass:[NSArray class]] ? (NSArray *)recordsObject : nil;
  BOOL isNoteTagType = [tagTypeKey isEqualToString:@"NOTE"];

  if (isNoteTagType) {
    [self.noteContentMap removeAllObjects];
  }

  for (id recordObj in records) {
    NSDate *recordDate = nil;
    NSNumber *statusNumber = nil;
    NSString *content = nil;
    NSString *tagType = nil;

    if ([recordObj isKindOfClass:[NSDictionary class]]) {
      NSDictionary *recordDict = (NSDictionary *)recordObj;
      NSString *recordDateString = [recordDict[@"recordDate"] isKindOfClass:[NSString class]] ? recordDict[@"recordDate"] : nil;
      statusNumber = [recordDict[@"status"] isKindOfClass:[NSNumber class]] ? recordDict[@"status"] : nil;
      content = [recordDict[@"content"] isKindOfClass:[NSString class]] ? recordDict[@"content"] : nil;
      tagType = [recordDict[@"tagType"] isKindOfClass:[NSString class]] ? recordDict[@"tagType"] : nil;
      if (recordDateString.length > 0) {
        recordDate = [self tl_normalizedDate:[formatter dateFromString:recordDateString]];
      }
    } else if ([recordObj isKindOfClass:[AGCultivationRecordDto class]]) {
      AGCultivationRecordDto *recordDto = (AGCultivationRecordDto *)recordObj;
      recordDate = [self tl_normalizedDate:recordDto.recordDate];
      statusNumber = recordDto.status;
      content = recordDto.content;
      tagType = recordDto.tagType;
    } else {
      continue;
    }

    if (recordDate == nil) {
      continue;
    }

    NSLog(@"[PlantDetail] %@ record, date=%@ status=%@ content=%@ tagType=%@",
          tagTypeKey,
          [formatter stringFromDate:recordDate],
          statusNumber,
          content,
          tagType);

    NSString *dateKey = [self tl_keyForDate:recordDate];
    TLWPlantCalendarDayStatus status = [self tl_calendarStatusForServerStatus:statusNumber tagTypeKey:tagTypeKey];
    serverStatusMap[dateKey] = @(status);
    if (isNoteTagType && status == TLWPlantCalendarDayStatusWatered && content.length > 0) {
      self.noteContentMap[dateKey] = content;
    }
  }

  self.markedStatusMapsByTagType[tagTypeKey] = serverStatusMap;
}

- (TLWPlantCalendarDayStatus)tl_calendarStatusForServerStatus:(NSNumber *)statusNumber tagTypeKey:(NSString *)tagTypeKey {
  BOOL isDone = statusNumber.integerValue == 1;
  if ([tagTypeKey isEqualToString:@"NOTE"]) {
    return isDone ? TLWPlantCalendarDayStatusWatered : TLWPlantCalendarDayStatusNone;
  }
  return isDone ? TLWPlantCalendarDayStatusWatered : TLWPlantCalendarDayStatusPending;
}

@end
