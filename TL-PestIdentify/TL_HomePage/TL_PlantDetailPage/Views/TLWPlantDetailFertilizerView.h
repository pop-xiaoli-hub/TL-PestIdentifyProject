#import <UIKit/UIKit.h>

@class TLWPlantDetailViewModel;

NS_ASSUME_NONNULL_BEGIN

@interface TLWPlantDetailFertilizerView : UIView

@property (nonatomic, copy, nullable) void(^previousMonthBlock)(void);
@property (nonatomic, copy, nullable) void(^nextMonthBlock)(void);
@property (nonatomic, copy, nullable) void(^dateSelectionBlock)(NSDate *date);

- (void)configureWithViewModel:(TLWPlantDetailViewModel *)viewModel;

@end

NS_ASSUME_NONNULL_END
