//
//  TLWFavoriteCell.h
//  TL-PestIdentify
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class AGPostResponseDto;

@interface TLWFavoriteCell : UICollectionViewCell

- (void)configureWithPostDto:(AGPostResponseDto *)post;

@end

NS_ASSUME_NONNULL_END
