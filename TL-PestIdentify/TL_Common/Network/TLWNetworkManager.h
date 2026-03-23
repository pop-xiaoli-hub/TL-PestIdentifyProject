//
//  TLWNetworkManager.h
//  TL-PestIdentify
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^TLWNetworkSuccess)(id _Nullable data);
typedef void(^TLWNetworkFailure)(NSString *message);

@interface TLWNetworkManager : NSObject

+ (instancetype)shared;

/// 当前登录用户的 Access Token
@property (nonatomic, copy, nullable) NSString *token;
/// 刷新令牌
@property (nonatomic, copy, nullable) NSString *refreshToken;
/// 用户ID
@property (nonatomic, assign) NSInteger userId;
/// 用户名
@property (nonatomic, copy, nullable) NSString *username;

/// 是否已登录
- (BOOL)isLoggedIn;

/// 退出登录，清除本地 Token
- (void)logout;

/// 通用请求方法
- (void)GET:(NSString *)path
 parameters:(nullable NSDictionary *)parameters
    success:(nullable TLWNetworkSuccess)success
    failure:(nullable TLWNetworkFailure)failure;

- (void)POST:(NSString *)path
  parameters:(nullable NSDictionary *)parameters
     success:(nullable TLWNetworkSuccess)success
     failure:(nullable TLWNetworkFailure)failure;

- (void)PUT:(NSString *)path
 parameters:(nullable NSDictionary *)parameters
    success:(nullable TLWNetworkSuccess)success
    failure:(nullable TLWNetworkFailure)failure;

- (void)DELETE:(NSString *)path
    parameters:(nullable NSDictionary *)parameters
       success:(nullable TLWNetworkSuccess)success
       failure:(nullable TLWNetworkFailure)failure;

@end

NS_ASSUME_NONNULL_END
