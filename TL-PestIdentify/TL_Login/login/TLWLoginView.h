//
//  TLWLoginView.h
//  TL-PestIdentify
//
//  登录页 View：负责展示「病虫害App」PNG 切图和交互控件
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TLWLoginView : UIView

@property (nonatomic, strong, readonly) UITextField *phoneField;
@property (nonatomic, strong, readonly) UIButton *sendCodeButton;
@property (nonatomic, strong, readonly) UITextField *codeField;
@property (nonatomic, strong, readonly) UIButton *loginTapButton;
@property (nonatomic, strong, readonly) UIButton *wechatLoginButton;
@property (nonatomic, strong, readonly) UIButton *qqLoginButton;
@property (nonatomic, strong, readonly) UIButton *localPhoneLoginButton;

@end

NS_ASSUME_NONNULL_END

