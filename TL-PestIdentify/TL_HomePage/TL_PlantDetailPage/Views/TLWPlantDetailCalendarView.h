//
//  TLWPlantDetailCalendarView.h
//  TL-PestIdentify
//

#import <UIKit/UIKit.h>

@class TLWPlantCalendarDayItem;

NS_ASSUME_NONNULL_BEGIN

@interface TLWPlantDetailCalendarView : UIView

@property (nonatomic, copy, nullable) void(^previousMonthBlock)(void);
@property (nonatomic, copy, nullable) void(^nextMonthBlock)(void);
@property (nonatomic, copy, nullable) void(^dateSelectionBlock)(NSDate *date);

- (void)configureWithMonthTitle:(NSString *)monthTitle dayItems:(NSArray<TLWPlantCalendarDayItem *> *)dayItems;

@end

NS_ASSUME_NONNULL_END
