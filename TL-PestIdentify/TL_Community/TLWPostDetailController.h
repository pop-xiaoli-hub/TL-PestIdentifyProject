//
//  TLWPostDetailController.h
//  TL-PestIdentify
//

#import <UIKit/UIKit.h>

@class TLWCommunityPost;

NS_ASSUME_NONNULL_BEGIN

@interface TLWPostDetailController : UIViewController

/// 外部传入帖子数据
@property (nonatomic, strong) NSNumber* _id;
@property (nonatomic, strong) TLWCommunityPost *post;
@property (nonatomic, strong) NSMutableArray* hasCollectedPosts;
@end

NS_ASSUME_NONNULL_END
