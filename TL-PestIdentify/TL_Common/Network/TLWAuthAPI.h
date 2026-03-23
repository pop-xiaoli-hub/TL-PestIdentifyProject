//
//  TLWAuthAPI.h
//  TL-PestIdentify
//

#import <Foundation/Foundation.h>
#import "TLWNetworkManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface TLWAuthAPI : NSObject

/// 发送短信验证码
+ (void)sendCodeWithPhone:(NSString *)phone
                  success:(nullable TLWNetworkSuccess)success
                  failure:(nullable TLWNetworkFailure)failure;

/// 短信验证码登录（未注册自动注册），成功后自动保存 Token
+ (void)loginBySmsWithPhone:(NSString *)phone
                       code:(NSString *)code
                    success:(nullable TLWNetworkSuccess)success
                    failure:(nullable TLWNetworkFailure)failure;

/// 账号密码登录，成功后自动保存 Token
+ (void)loginWithUsernameOrPhone:(NSString *)account
                        password:(NSString *)password
                         success:(nullable TLWNetworkSuccess)success
                         failure:(nullable TLWNetworkFailure)failure;

/// 账号密码注册，成功后自动保存 Token
+ (void)registerWithUsername:(NSString *)username
                       phone:(NSString *)phone
                    password:(NSString *)password
                     success:(nullable TLWNetworkSuccess)success
                     failure:(nullable TLWNetworkFailure)failure;

/// 刷新 Token，成功后自动更新本地 Token
+ (void)refreshTokenWithSuccess:(nullable TLWNetworkSuccess)success
                        failure:(nullable TLWNetworkFailure)failure;

/// 登出，清除本地 Token
+ (void)logout;

@end

NS_ASSUME_NONNULL_END
