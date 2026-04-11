//
//  TLWPlantDetailViewModel.h
//  TL-PestIdentify
//

#import <Foundation/Foundation.h>

@class TLWPlantModel;
@class AGMyCropResponseDto;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, TLWPlantDetailTabType) {//枚举表示当前选中的功能标签
  TLWPlantDetailTabTypeWater = 0,
  TLWPlantDetailTabTypeFertilizer,
  TLWPlantDetailTabTypeMedicine,
  TLWPlantDetailTabTypeNote,
};

typedef NS_ENUM(NSInteger, TLWPlantCalendarDayStatus) {//日历单元格的数据模型
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
@property (nonatomic, assign) BOOL isSelected;
@property (nonatomic, strong) NSDate *date;

@end

@interface TLWPlantDetailViewModel : NSObject

@property (nonatomic, strong, readonly) TLWPlantModel *plantModel;//存储当前植物
@property (nonatomic, assign) TLWPlantDetailTabType selectedTabType;//选中的模块
@property (nonatomic, strong, readonly) NSDate *displayMonthDate;//当前正在显示的月份

- (instancetype)initWithPlantModel:(TLWPlantModel *)plantModel;

- (NSString *)plantTitleText;
- (NSString *)healthStatusText;
- (NSString *)plantingDateText;
- (nullable NSString *)imageURLString;
- (NSArray<NSString *> *)tabTitles;
- (NSString *)currentMonthTitle;
- (NSArray<TLWPlantCalendarDayItem *> *)calendarItems;
- (NSArray<TLWPlantCalendarDayItem *> *)calendarItemsForTabType:(TLWPlantDetailTabType)tabType;
- (NSString *)noteContentForSelectedDate;
- (CGFloat)preferredContentHeightForSelectedTab;
- (NSDate *)currentSelectedDate;
- (void)applyCropDetailResponse:(AGMyCropResponseDto *)cropDetail;
- (void)selectDate:(NSDate *)date;
- (void)markSelectedDateAsWatered;
- (void)markSelectedDateAsPending;

- (void)moveToPreviousMonth;
- (void)moveToNextMonth;

@end

NS_ASSUME_NONNULL_END
