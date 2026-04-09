//
//  TLWPlantDetailViewModel.h
//  TL-PestIdentify
//

#import <Foundation/Foundation.h>

@class TLWPlantModel;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, TLWPlantDetailTabType) {
  TLWPlantDetailTabTypeWater = 0,
  TLWPlantDetailTabTypeFertilizer,
  TLWPlantDetailTabTypeMedicine,
  TLWPlantDetailTabTypeNote,
};

typedef NS_ENUM(NSInteger, TLWPlantCalendarDayStatus) {
  TLWPlantCalendarDayStatusNone = 0,
  TLWPlantCalendarDayStatusWatered,
  TLWPlantCalendarDayStatusPending,
  TLWPlantCalendarDayStatusSelected,
};

@interface TLWPlantCalendarDayItem : NSObject

@property (nonatomic, copy) NSString *dayText;
@property (nonatomic, assign) BOOL inCurrentMonth;
@property (nonatomic, assign) BOOL isToday;
@property (nonatomic, assign) TLWPlantCalendarDayStatus status;

@end

@interface TLWPlantDetailViewModel : NSObject

@property (nonatomic, strong, readonly) TLWPlantModel *plantModel;
@property (nonatomic, assign) TLWPlantDetailTabType selectedTabType;
@property (nonatomic, strong, readonly) NSDate *displayMonthDate;

- (instancetype)initWithPlantModel:(TLWPlantModel *)plantModel;

- (NSString *)plantTitleText;
- (NSString *)healthStatusText;
- (NSString *)plantingDateText;
- (nullable NSString *)imageURLString;
- (NSArray<NSString *> *)tabTitles;
- (NSString *)currentMonthTitle;
- (NSArray<TLWPlantCalendarDayItem *> *)calendarItems;
- (CGFloat)preferredContentHeightForSelectedTab;

- (void)moveToPreviousMonth;
- (void)moveToNextMonth;

@end

NS_ASSUME_NONNULL_END
