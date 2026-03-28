//
//  TLWChangePasswordView.h
//  TL-PestIdentify
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TLWChangePasswordView : UIView

@property (nonatomic, strong, readonly) UIButton    *backButton;
@property (nonatomic, strong, readonly) UITextField *passwordField;
@property (nonatomic, strong, readonly) UITextField *confirmPasswordField;
@property (nonatomic, strong, readonly) UIButton    *confirmButton;

@end

NS_ASSUME_NONNULL_END
