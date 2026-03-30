//
//  TLWPostDetailHeaderView.h
//  TL-PestIdentify
//

#import <UIKit/UIKit.h>

@class TLWCommunityPost;

NS_ASSUME_NONNULL_BEGIN

@interface TLWPostDetailHeaderView : UIView
@property (nonatomic, strong) UIButton *collectButton;
@property (nonatomic, strong) UIButton *likeButton;
@property (nonatomic, assign) BOOL isCollected;
@property (nonatomic, assign) BOOL isLiked;
@property (nonatomic, strong) UILabel* collectedCountLabel;
@property (nonatomic, strong) UILabel* likedCountLabel;
- (void)configureWithPost:(TLWCommunityPost *)post;

/// 计算并返回 header 的合适高度（根据图片数量+内容）
+ (CGFloat)heightForPost:(TLWCommunityPost *)post;

@end

NS_ASSUME_NONNULL_END
