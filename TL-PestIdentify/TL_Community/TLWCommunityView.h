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
@property (nonatomic, strong, readonly) UIButton *uploadButton;
@property (nonatomic, strong) UIButton *publishButton;
- (void)tl_showSearchOverlay;
- (void)tl_hideSearchOverlay;
@end

NS_ASSUME_NONNULL_END
