//
//  TLWPlantDetailSegmentTabView.h
//  TL-PestIdentify
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TLWPlantDetailSegmentTabView : UIView

@property (nonatomic, copy, nullable) void(^selectionChangedBlock)(NSInteger index);

- (void)configureWithTitles:(NSArray<NSString *> *)titles;
- (void)selectIndex:(NSInteger)index;

@end

NS_ASSUME_NONNULL_END
