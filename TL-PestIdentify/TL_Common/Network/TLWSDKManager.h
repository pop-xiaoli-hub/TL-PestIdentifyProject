//
//  TLWSDKManager.h
//  TL-PestIdentify
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
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
#import <AgriPestClient/AGResultPageResultPostResponseDto.h>
#import <AgriPestClient/AGResultPostResponseDto.h>
#import <AgriPestClient/AGResultSearchResultResponse.h>
#import <AgriPestClient/AGPostResponseDto.h>
#import <AgriPestClient/AGSearchResultResponse.h>
#import <AgriPestClient/AGResultPageResultCommentResponseDto.h>
#import <AgriPestClient/AGCommentRequest.h>
#import <AgriPestClient/AGResultCommentResponseDto.h>

/// 用户资料变更通知（改昵称、改头像、改偏好等更新缓存后发出）
extern NSString * const TLWProfileDidUpdateNotification;

NS_ASSUME_NONNULL_BEGIN

@interface TLWSDKManager : NSObject

+ (instancetype)shared;

/// 获取当前活跃窗口（优先从前台 Scene 取 keyWindow，兜底 windows.firstObject）
+ (UIWindow *)tl_activeWindow;

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

/// 保存登录成功后的认证信息（双 token + 用户信息）
/// @return YES 表示保存成功，NO 表示认证数据无效或关键凭证持久化失败
- (BOOL)saveAuthResponse:(AGAuthResponse *)auth;

/// 拉取用户资料并缓存，完成后发送 TLWProfileDidUpdateNotification
- (void)fetchProfileWithCompletion:(nullable void(^)(AGUserProfileDto * _Nullable profile))completion;

/// 退出登录，清除所有本地凭证
- (void)logout;

/// 获取本地保存的 refreshToken
- (nullable NSString *)refreshToken;

/// 自动注册时生成的密码（仅短信验证码登录自动注册时有值）
@property (nonatomic, copy, nullable, readonly) NSString *generatedPassword;

/// 上传多张图片，返回服务器 URL 数组
- (nullable NSURLSessionTask *)uploadImages:(NSArray<UIImage *> *)images
                                     prefix:(NSString *)prefix
                                 completion:(void(^)(NSArray<NSString *> * _Nullable urls, NSError * _Nullable error))completion;

/// 获取所有帖子列表（分页）
- (NSURLSessionTask *)getAllPostsWithTag:(nullable NSString *)tag
                                       q:(nullable NSString *)q
                                     page:(NSNumber *)page
                                     size:(NSNumber *)size
                        completionHandler:(void (^)(AGResultPageResultPostResponseDto * output, NSError * error)) handler;

/// 获取搜索联想词
- (NSURLSessionTask *)getSuggestionsWithQ:(NSString *)q
                        completionHandler:(void (^)(AGResultListString * output, NSError * error))handler;

/// 高级模糊搜索帖子，返回匹配结果、推荐内容及关键词建议
- (NSURLSessionTask *)searchPostsWithQ:(NSString *)q
                                  page:(NSNumber *)page
                                  size:(NSNumber *)size
                     completionHandler:(void (^)(AGResultSearchResultResponse * output, NSError * error))handler;

/// 获取帖子详情
- (NSURLSessionTask *)getPostDetailWithId:(NSNumber *)_id
                        completionHandler:(void (^)(AGResultPostResponseDto * output, NSError * error))handler;

/// 获取帖子评论列表（分页）
/// - 与你提供的方法签名保持一致
- (NSURLSessionTask *)getCommentsWithId:(NSNumber *) _id
                                    page:(NSNumber *)page
                                    size:(NSNumber *)size
                        completionHandler:(void (^)(AGResultPageResultCommentResponseDto * output, NSError * error)) handler;

/// 发表评论
- (NSURLSessionTask *)addCommentWithId:(NSNumber *)_id
                               content:(NSString *)content
                     completionHandler:(void (^)(AGResultCommentResponseDto * output, NSError * error))handler;

/// 获取当前用户自己发布的帖子列表（分页）
- (NSURLSessionTask *)getMyPostsWithPage:(NSNumber *)page size:(NSNumber *)size completionHandler:(void (^)(AGResultPageResultPostResponseDto * output, NSError * error))handler;

/// 收藏列表缓存（应用启动预拉取）
@property (nonatomic, strong, readonly) NSArray<AGPostResponseDto *> *cachedFavoritedPosts;

/// 获取当前用户收藏帖子列表（单页）
- (NSURLSessionTask *)getFavoritedPostsWithPage:(NSNumber *)page size:(NSNumber *)size completionHandler:(void (^)(AGResultPageResultPostResponseDto * output, NSError * error))handler;

/// 拉取当前用户全部收藏帖子（分页聚合）
- (void)fetchAllFavoritedPostsWithCompletion:(void (^)(NSArray<AGPostResponseDto *> * _Nullable posts, NSError * _Nullable error))completion;

/// 收藏指定帖子
- (NSURLSessionTask *)favoritePostWithId:(NSNumber *)_id completionHandler:(void (^)(AGResultVoid * output, NSError * error))handler;

/// 取消收藏指定帖子
- (NSURLSessionTask *)unfavoritePostWithId:(NSNumber *)_id completionHandler:(void (^)(AGResultVoid * output, NSError * error))handler;

/// 点赞指定帖子
- (NSURLSessionTask *)likePostWithId:(NSNumber *)_id completionHandler:(void (^)(AGResultVoid * output, NSError * error))handler;

/// 取消点赞指定帖子
- (NSURLSessionTask *)unlikePostWithId:(NSNumber *)_id completionHandler:(void (^)(AGResultVoid * output, NSError * error))handler;

/// Token 续期入口：检测到 401 时调用，自动用 refreshToken 换新 accessToken 后执行 retryBlock。
/// 若 refreshToken 也已过期则强制跳回登录页。多个并发 401 只发一次刷新请求，其余排队等结果。
- (void)handleUnauthorizedWithRetry:(nullable void(^)(void))retryBlock;


/// 上传单张图片/文件，返回服务器 URL
- (NSURLSessionTask *)uploadFileWithFile:(NSURL *)file
                                  prefix:(NSString *)prefix
                       completionHandler:(void (^)(AGResultString * output, NSError * error))handler;
@end

NS_ASSUME_NONNULL_END
