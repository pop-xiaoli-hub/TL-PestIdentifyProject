//
//  TLWEditProfileView.h
//  TL-PestIdentify
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TLWEditProfileView : UIView

@property (nonatomic, strong, readonly) UIButton    *backButton;
@property (nonatomic, strong, readonly) UIButton    *avatarRowButton;
@property (nonatomic, strong, readonly) UIButton    *nicknameRowButton;
@property (nonatomic, strong, readonly) UIButton    *backgroundRowButton;
@property (nonatomic, strong, readonly) UIImageView *avatarImageView;
@property (nonatomic, strong, readonly) UILabel     *nicknameValueLabel;
@property (nonatomic, strong, readonly) UILabel     *phoneValueLabel;
@property (nonatomic, strong, readonly) UILabel     *cropValueLabel;

@end

NS_ASSUME_NONNULL_END
