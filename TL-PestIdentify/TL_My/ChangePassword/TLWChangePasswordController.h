//
//  TLWChangePasswordController.h
//  TL-PestIdentify
//

#import "TLWBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface TLWChangePasswordController : TLWBaseViewController

/// 传入当前密码用于展示（如自动注册生成的密码）
- (instancetype)initWithCurrentPassword:(nullable NSString *)password;

@end

NS_ASSUME_NONNULL_END
