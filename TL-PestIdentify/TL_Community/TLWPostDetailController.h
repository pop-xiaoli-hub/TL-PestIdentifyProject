//
//  TLWPostDetailController.h
//  TL-PestIdentify
//

#import "TLWBaseViewController.h"

@class TLWCommunityPost;

NS_ASSUME_NONNULL_BEGIN

@interface TLWPostDetailController : TLWBaseViewController
@property (nonatomic, copy)void(^reloadPosts)(NSNumber*);

/// 外部传入帖子数据
@property (nonatomic, strong) NSNumber* _id;
@property (nonatomic, strong) TLWCommunityPost *post;
@property (nonatomic, strong) NSMutableArray* hasCollectedPosts;
@end

NS_ASSUME_NONNULL_END
