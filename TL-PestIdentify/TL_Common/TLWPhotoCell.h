//
//  TLWPhotoCell.h
//  TL-PestIdentify
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

static NSString * const kTLWPhotoCellID = @"TLWPhotoCell";

@interface TLWPhotoCell : UICollectionViewCell

@property (nonatomic, strong, readonly) UIImageView      *imageView;
@property (nonatomic, assign)          PHImageRequestID   requestID;

@end

NS_ASSUME_NONNULL_END
