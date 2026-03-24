//
//  TLWSmsLoginView.h
//  TL-PestIdentify
//
//  Created by 吴桐 on 2026/3/12.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TLWSmsLoginView : UIView

@property (nonatomic, strong, readonly) UITextField *phoneField;
@property (nonatomic, strong, readonly) UIButton *sendCodeButton;
@property (nonatomic, strong, readonly) UITextField *codeField;
@property (nonatomic, strong, readonly) UIButton *loginTapButton;
@property (nonatomic, strong, readonly) UIButton *wechatLoginButton;
@property (nonatomic, strong, readonly) UIButton *qqLoginButton;
@property (nonatomic, strong, readonly) UIButton *localPhoneLoginButton;
@property (nonatomic, strong, readonly) UIButton *skipButton;

@end

NS_ASSUME_NONNULL_END

