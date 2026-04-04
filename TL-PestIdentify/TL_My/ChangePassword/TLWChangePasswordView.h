//
//  TLWChangePasswordView.h
//  TL-PestIdentify
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TLWChangePasswordView : UIView

@property (nonatomic, strong, readonly) UITextField *passwordField;
@property (nonatomic, strong, readonly) UITextField *confirmPasswordField;
@property (nonatomic, strong, readonly) UIButton    *confirmButton;

/// 设置后在顶部显示"当前密码：xxx"
@property (nonatomic, copy, nullable) NSString *currentPassword;

@end

NS_ASSUME_NONNULL_END
