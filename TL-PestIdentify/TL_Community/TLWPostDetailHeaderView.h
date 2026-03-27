//
//  TLWPostDetailHeaderView.h
//  TL-PestIdentify
//

#import <UIKit/UIKit.h>

@class TLWCommunityPost;

NS_ASSUME_NONNULL_BEGIN

@interface TLWPostDetailHeaderView : UIView

- (void)configureWithPost:(TLWCommunityPost *)post;

/// 计算并返回 header 的合适高度（根据图片数量+内容）
+ (CGFloat)heightForPost:(TLWCommunityPost *)post;

@end

NS_ASSUME_NONNULL_END
