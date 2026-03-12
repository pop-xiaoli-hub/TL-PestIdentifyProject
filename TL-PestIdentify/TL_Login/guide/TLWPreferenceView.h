//
//  TLWPreferenceView.h
//  TL-PestIdentify
//
//  Created by 吴桐 on 2026/3/12.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TLWPreferenceView : UIView

@property (nonatomic, strong, readonly) UICollectionView *collectionView;
@property (nonatomic, strong, readonly) UIButton        *confirmButton;

@end

NS_ASSUME_NONNULL_END
