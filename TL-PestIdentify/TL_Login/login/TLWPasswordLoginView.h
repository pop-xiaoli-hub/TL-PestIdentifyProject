//
//  TLWPasswordLoginView.h
//  TL-PestIdentify
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TLWPasswordLoginView : UIView

@property (nonatomic, strong, readonly) UITextField *accountField;
@property (nonatomic, strong, readonly) UITextField *passwordField;
@property (nonatomic, strong, readonly) UIButton *togglePasswordButton;
@property (nonatomic, strong, readonly) UIButton *loginTapButton;
@property (nonatomic, strong, readonly) UIButton *qqLoginButton;
@property (nonatomic, strong, readonly) UIButton *phoneLoginButton;
@property (nonatomic, strong, readonly) UIButton *backButton;

@end

NS_ASSUME_NONNULL_END
