//
//  TLWPublishView.h
//  TL-PestIdentify
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TLWPublishView : UIView

@property (nonatomic, strong, readonly) UIButton *backButton;
@property (nonatomic, strong, readonly) UIButton *cropSelectButton;
@property (nonatomic, strong, readonly) UICollectionView *cropsCollectionView;
@property (nonatomic, strong, readonly) UITextField *titleTextField;
@property (nonatomic, strong, readonly) UITextView *contentTextView;
@property (nonatomic, strong, readonly) UIButton *addImageButton;
@property (nonatomic, strong, readonly) UIButton *confirmPublishButton;
@property (nonatomic, strong) UIView *middleCardView;
@property (nonatomic, strong, readonly) UICollectionView *imagesCollectionView;
@property (nonatomic, strong, readonly) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *loadingView;
/// 根据是否有选中的作物，切换顶部卡片的占位文案 / 标签列表展示
- (void)tl_updateCropSelectionVisible:(BOOL)hasSelection;
- (void)tl_createBlurLoadingView;
- (void)tl_dismissBlurLoadingView;
@end

NS_ASSUME_NONNULL_END
