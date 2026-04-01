//
//  TLWSearchResultView.h
//  TL-PestIdentify
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TLWSearchResultView : UIView

@property (nonatomic, strong, readonly) UIButton *closeButton;
@property (nonatomic, strong, readonly) UILabel *titleLabel;
@property (nonatomic, strong, readonly) UILabel *subtitleLabel;
@property (nonatomic, strong, readonly) UICollectionView *collectionView;
@property (nonatomic, strong, readonly) UILabel *emptyLabel;

- (void)tl_updateQueryText:(NSString *)query;
- (void)tl_setEmptyHidden:(BOOL)hidden;

@end

NS_ASSUME_NONNULL_END
