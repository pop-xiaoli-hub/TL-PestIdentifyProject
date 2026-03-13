//
//  TLWCommunityView.h
//  TL-PestIdentify
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TLWCommunityView : UIView

@property (nonatomic, strong, readonly) UICollectionView *collectionView;
@property (nonatomic, strong, readonly) UITextField *searchTextField;
@property (nonatomic, strong, readonly) UIButton *uploadButton;

@end

NS_ASSUME_NONNULL_END

