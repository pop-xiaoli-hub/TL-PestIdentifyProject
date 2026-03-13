//
//  TLWCommunityCell.h
//  TL-PestIdentify
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class TLWCommunityPost;

@interface TLWCommunityCell : UICollectionViewCell

- (void)configureWithPost:(TLWCommunityPost *)post;

@end

NS_ASSUME_NONNULL_END

