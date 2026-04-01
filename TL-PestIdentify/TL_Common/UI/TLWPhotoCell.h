//
//  TLWPhotoCell.h
//  TL-PestIdentify
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString * const kTLWPhotoCellID;

@interface TLWPhotoCell : UICollectionViewCell

@property (nonatomic, strong, readonly) UIImageView      *imageView;
@property (nonatomic, assign)          PHImageRequestID   requestID;

- (void)setShowsSelectionIndicator:(BOOL)showsSelectionIndicator;
- (void)configureWithSelectionIndex:(NSInteger)index;

@end

NS_ASSUME_NONNULL_END
