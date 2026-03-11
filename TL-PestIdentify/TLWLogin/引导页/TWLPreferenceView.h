//
//  TWLPreferenceView.h
//  TL-PestIdentify
//
//  偏好设置页 View — 选择关注的农作物
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TWLPreferenceView : UIView

@property (nonatomic, strong, readonly) UICollectionView *collectionView;
@property (nonatomic, strong, readonly) UIButton        *confirmButton;

@end

NS_ASSUME_NONNULL_END
