//
//  TLWSDKManager.h
//  TL-PestIdentify
//

#import <Foundation/Foundation.h>
#import <UIKit/UIImage.h>

// SDK 头文件统一引入
#import <AgriPestClient/AGApiService.h>
#import <AgriPestClient/AGDefaultConfiguration.h>
#import <AgriPestClient/AGAuthResponse.h>
#import <AgriPestClient/AGLoginRequest.h>
#import <AgriPestClient/AGSmsLoginRequest.h>
#import <AgriPestClient/AGSendSmsRequest.h>
#import <AgriPestClient/AGRegisterRequest.h>
#import <AgriPestClient/AGRefreshTokenRequest.h>
#import <AgriPestClient/AGProfileUpdateRequest.h>
#import <AgriPestClient/AGChangePhoneRequest.h>
#import <AgriPestClient/AGUserProfileDto.h>
#import <AgriPestClient/AGResultAuthResponse.h>
#import <AgriPestClient/AGResultUserProfileDto.h>
#import <AgriPestClient/AGResultVoid.h>
#import <AgriPestClient/AGResultString.h>
#import <AgriPestClient/AGResultListString.h>

/// 用户资料变更通知（改昵称、改头像、改偏好等更新缓存后发出）
extern NSString * const TLWProfileDidUpdateNotification;

NS_ASSUME_NONNULL_BEGIN

@interface TLWSDKManager : NSObject

+ (instancetype)shared;
/// SDK API 服务
@property (nonatomic, strong, readonly) AGApiService *api;

/// 当前用户 ID
@property (nonatomic, assign) NSInteger userId;
/// 当前用户名
@property (nonatomic, copy, nullable) NSString *username;

/// 缓存的用户资料（登录后拉取一次，修改后刷新）
@property (nonatomic, strong, nullable, readonly) AGUserProfileDto *cachedProfile;

/// 是否已登录
- (BOOL)isLoggedIn;

/// 保存登录成功后的认证信息（Token + 用户信息持久化到 NSUserDefaults）
- (void)saveAuthResponse:(AGAuthResponse *)auth;

/// 拉取用户资料并缓存，完成后发送 TLWProfileDidUpdateNotification
- (void)fetchProfileWithCompletion:(nullable void(^)(AGUserProfileDto * _Nullable profile))completion;

/// 退出登录，清除所有本地凭证
- (void)logout;

/// 获取本地保存的 refreshToken
- (nullable NSString *)refreshToken;

/// 上传多张图片，返回服务器 URL 数组
- (nullable NSURLSessionTask *)uploadImages:(NSArray<UIImage *> *)images
                                     prefix:(NSString *)prefix
                                 completion:(void(^)(NSArray<NSString *> * _Nullable urls, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
