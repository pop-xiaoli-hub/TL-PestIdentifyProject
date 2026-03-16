//
//  TLWCommunityView.h
//  TL-PestIdentify
//
//  Created by xiaoli pop on 2026/3/13.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TLWCommunityView : UIView

@property (nonatomic, strong, readonly) UICollectionView *collectionView;
@property (nonatomic, strong, readonly) UITextField *searchTextField;
@property (nonatomic, strong, readonly) UIButton *voiceButton;
@property (nonatomic, strong, readonly) UIButton *uploadButton;
@property (nonatomic, strong) UIButton *publishButton;
@property (nonatomic, strong) UIView *searchOverlay;
/// 显示/隐藏搜索浮层
- (void)tl_showSearchOverlay;
- (void)tl_hideSearchOverlay;

/// 设置搜索历史标签（先横向填满再换行）；传 nil 或空数组即清空
- (void)tl_setSearchHistoryItems:(nullable NSArray<NSString *> *)items;

/// 设置「猜你想搜」标签（先横向填满再换行）；传 nil 或空数组即清空
- (void)tl_setGuessYouWantToSearchItems:(nullable NSArray<NSString *> *)items;

@end

NS_ASSUME_NONNULL_END
