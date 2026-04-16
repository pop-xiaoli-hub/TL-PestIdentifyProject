//
//  TLWSDKManager.h
//  TL-PestIdentify
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "TLWSessionManager.h"
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
#import <AgriPestClient/AGMyCropCreateRequest.h>
#import <AgriPestClient/AGTagOperationRequest.h>
#import <AgriPestClient/AGResultMyCropResponseDto.h>
#import <AgriPestClient/AGResultListMyCropResponseDto.h>
#import <AgriPestClient/AGResultPageResultMessageResponseDto.h>
#import <AgriPestClient/AGPageResultMessageResponseDto.h>
#import <AgriPestClient/AGMessageResponseDto.h>
#import <AgriPestClient/AGChatRequest.h>
#import <AgriPestClient/AGResultListDiagnosisItem.h>

NS_ASSUME_NONNULL_BEGIN

@interface TLWSDKManager : NSObject

+ (instancetype)shared;

/// 获取当前活跃窗口（优先从前台 Scene 取 keyWindow，兜底 windows.firstObject）
+ (UIWindow *)tl_activeWindow;

/// SDK API 服务
@property (nonatomic, strong, readonly) AGApiService *api;

/// 登录会话与鉴权状态
@property (nonatomic, strong, readonly) TLWSessionManager *sessionManager;

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

/// 上传单张图片/文件，返回服务器 URL
- (NSURLSessionTask *)uploadFileWithFile:(NSURL *)file
                                  prefix:(NSString *)prefix
                       completionHandler:(void (^)(AGResultString * output, NSError * error))handler;

/// 新建我的作物
- (NSURLSessionTask *)createCropWithRequest:(AGMyCropCreateRequest *)request
                          completionHandler:(void (^)(AGResultMyCropResponseDto * output, NSError * error))handler;

/// 获取我的作物列表
- (NSURLSessionTask *)getMyCropsWithCompletionHandler:(void (^)(AGResultListMyCropResponseDto * output, NSError * error))handler;

/// 获取作物详情
- (NSURLSessionTask *)getCropDetailWithId:(NSNumber *)cropId
                        completionHandler:(void (^)(AGResultMyCropResponseDto * output, NSError * error))handler;

/// 删除作物
- (NSURLSessionTask *)deleteCropWithId:(NSNumber *)cropId
                     completionHandler:(void (^)(AGResultVoid * output, NSError * error))handler;

/// 添加种植标签（浇水、施肥、用药、笔记）
- (NSURLSessionTask *)addTagWithCropId:(NSNumber *)cropId
                   tagOperationRequest:(AGTagOperationRequest *)request
                     completionHandler:(void (^)(AGResultVoid * output, NSError * error))handler;

/// 获取首页预警消息列表（仅未读 ALERT 类型）
- (NSURLSessionTask *)getAlertMessagesWithPage:(NSNumber *)page
                                          size:(NSNumber *)size
                             completionHandler:(void (^)(AGResultPageResultMessageResponseDto * output, NSError * error))handler;

/// 发起多模态诊断请求
- (NSURLSessionTask *)chatWithChatRequest:(AGChatRequest *)chatRequest
                        completionHandler:(void (^)(AGResultListDiagnosisItem * output, NSError * error))handler;
/// 获取首页实时天气（和风天气）
- (nullable NSURLSessionTask *)getCurrentWeatherWithLatitude:(double)latitude
                                           longitude:(double)longitude
                                          completion:(void (^)(NSDictionary * _Nullable weatherInfo, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
