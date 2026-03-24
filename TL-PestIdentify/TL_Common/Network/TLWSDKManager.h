//
//  TLWSDKManager.h
//  TL-PestIdentify
//

#import <Foundation/Foundation.h>

@class AGApiService;
@class AGAuthResponse;

NS_ASSUME_NONNULL_BEGIN

@interface TLWSDKManager : NSObject

+ (instancetype)shared;

/// SDK API 服务
@property (nonatomic, strong, readonly) AGApiService *api;

/// 当前用户 ID
@property (nonatomic, assign) NSInteger userId;
/// 当前用户名
@property (nonatomic, copy, nullable) NSString *username;

/// 是否已登录
- (BOOL)isLoggedIn;

/// 保存登录成功后的认证信息（Token + 用户信息持久化到 NSUserDefaults）
- (void)saveAuthResponse:(AGAuthResponse *)auth;

/// 退出登录，清除所有本地凭证
- (void)logout;

/// 获取本地保存的 refreshToken
- (nullable NSString *)refreshToken;

@end

NS_ASSUME_NONNULL_END
