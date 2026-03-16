//
//  TLWPublishView.h
//  TL-PestIdentify
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TLWPublishView : UIView

@property (nonatomic, strong, readonly) UIButton *backButton;
@property (nonatomic, strong, readonly) UIButton *cropSelectButton;
@property (nonatomic, strong, readonly) UITextView *contentTextView;
@property (nonatomic, strong, readonly) UIButton *addImageButton;
@property (nonatomic, strong, readonly) UIButton *confirmPublishButton;
@property (nonatomic, strong) UIView *middleCardView;
@property (nonatomic, strong, readonly) UICollectionView *imagesCollectionView;

@end

NS_ASSUME_NONNULL_END

