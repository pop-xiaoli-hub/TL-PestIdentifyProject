//
//  TLWSessionManager.h
//  TL-PestIdentify
//

#import <Foundation/Foundation.h>
#import <AgriPestClient/AGApiService.h>
#import <AgriPestClient/AGAuthResponse.h>
#import <AgriPestClient/AGDefaultConfiguration.h>
#import <AgriPestClient/AGRefreshTokenRequest.h>
#import <AgriPestClient/AGResultAuthResponse.h>
#import <AgriPestClient/AGResultUserProfileDto.h>
#import <AgriPestClient/AGUserProfileDto.h>

NS_ASSUME_NONNULL_BEGIN

/// 用户资料变更通知（改昵称、改头像、改偏好等更新缓存后发出）
extern NSString * const TLWProfileDidUpdateNotification;

@interface TLWSessionManager : NSObject

- (instancetype)initWithAPIService:(AGApiService *)api NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

/// 当前绑定的 API 服务。默认由 TLWSDKManager 注入。
@property (nonatomic, strong, readonly) AGApiService *api;

/// 当前用户 ID
@property (nonatomic, assign) NSInteger userId;

/// 当前用户名
@property (nonatomic, copy, nullable) NSString *username;

/// 缓存的用户资料（登录后拉取一次，修改后刷新）
@property (nonatomic, strong, nullable, readonly) AGUserProfileDto *cachedProfile;

/// 自动注册时生成的密码（仅短信验证码登录自动注册时有值）
@property (nonatomic, copy, nullable, readonly) NSString *generatedPassword;

/// 会话失效且需要回到登录页时触发，由上层决定具体跳转方式。
@property (nonatomic, copy, nullable) dispatch_block_t sessionInvalidationHandler;

/// 替换底层 API 服务，便于测试注入 mock。
- (void)updateAPIService:(AGApiService *)api;

/// 是否已登录
- (BOOL)isLoggedIn;

/// 保存登录成功后的认证信息（双 token + 用户信息）
/// @return YES 表示保存成功，NO 表示认证数据无效或关键凭证持久化失败
- (BOOL)saveAuthResponse:(AGAuthResponse *)auth;

/// 拉取用户资料并缓存，完成后发送 TLWProfileDidUpdateNotification
- (void)fetchProfileWithCompletion:(nullable void(^)(AGUserProfileDto * _Nullable profile))completion;

/// 退出登录，清除所有本地凭证
- (void)logout;

/// 获取本地保存的 refreshToken
- (nullable NSString *)refreshToken;

/// Token 续期入口：检测到 401 时调用，自动用 refreshToken 换新 accessToken 后执行 retryBlock。
/// 若 refreshToken 也已过期则强制跳回登录页。多个并发 401 只发一次刷新请求，其余排队等结果。
- (void)handleUnauthorizedWithRetry:(nullable void(^)(void))retryBlock;

@end

NS_ASSUME_NONNULL_END
