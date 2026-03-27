//
//  TLWPostDetailController.h
//  TL-PestIdentify
//

#import <UIKit/UIKit.h>

@class TLWCommunityPost;

NS_ASSUME_NONNULL_BEGIN

@interface TLWPostDetailController : UIViewController

/// 外部传入帖子数据
@property (nonatomic, strong) TLWCommunityPost *post;

@end

NS_ASSUME_NONNULL_END
