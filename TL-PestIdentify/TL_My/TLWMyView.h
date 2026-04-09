//
//  TLWMyView.h
//  TL-PestIdentify
//

#import <UIKit/UIKit.h>
#import <AgriPestClient/AGPostResponseDto.h>

NS_ASSUME_NONNULL_BEGIN

@interface TLWMyView : UIView

@property (nonatomic, strong, readonly) UIImageView *avatarImageView;
@property (nonatomic, strong, readonly) UILabel     *userNameLabel;
@property (nonatomic, strong, readonly) UILabel     *favCountLabel;
@property (nonatomic, strong, readonly) UIView      *favStatView;
@property (nonatomic, strong, readonly) UILabel     *recordCountLabel;
@property (nonatomic, strong, readonly) UIView      *recordStatView;
@property (nonatomic, strong, readonly) UIButton    *editProfileButton;
@property (nonatomic, strong, readonly) UIButton    *settingButton;
@property (nonatomic, strong, readonly) UIButton    *shareButton;
@property (nonatomic, strong, readonly) UIImageView *postAvatarImageView;
@property (nonatomic, strong, readonly) UILabel     *postNameLabel;

/// 点击某条帖子时触发，参数为帖子 ID
@property (nonatomic, copy, nullable) void (^onPostTapped)(NSNumber *postId);

/// 用真实帖子数据刷新"我的帖子"区域
- (void)reloadPosts:(NSArray<AGPostResponseDto *> *)posts;

@end

NS_ASSUME_NONNULL_END
