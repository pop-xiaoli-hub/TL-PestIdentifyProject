//
//  TLWMyFavoriteView.h
//  TL-PestIdentify
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TLWMyFavoriteView : UIView

@property (nonatomic, strong, readonly) UIButton         *backButton;
@property (nonatomic, strong, readonly) UIButton         *filterButton;
@property (nonatomic, strong, readonly) UICollectionView *collectionView;

/// 切换空态/列表态
- (void)showEmpty:(BOOL)empty;

@end

NS_ASSUME_NONNULL_END
