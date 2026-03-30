//
//  TLWMyView.h
//  TL-PestIdentify
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TLWMyView : UIView

@property (nonatomic, strong, readonly) UIImageView *avatarImageView;
@property (nonatomic, strong, readonly) UILabel     *userNameLabel;
@property (nonatomic, strong, readonly) UILabel     *favCountLabel;
@property (nonatomic, strong, readonly) UIView      *favStatView;
@property (nonatomic, strong, readonly) UILabel     *recordCountLabel;
@property (nonatomic, strong, readonly) UIButton    *editProfileButton;
@property (nonatomic, strong, readonly) UIButton    *settingButton;
@property (nonatomic, strong, readonly) UIButton    *shareButton;
@property (nonatomic, strong, readonly) UIImageView *postAvatarImageView;
@property (nonatomic, strong, readonly) UILabel     *postNameLabel;

@end

NS_ASSUME_NONNULL_END
