//
//  TLWSDKManager.m
//  TL-PestIdentify
//

#import "TLWSDKManager.h"
#import <UIKit/UIKit.h>

NSString * const TLWProfileDidUpdateNotification = @"TLWProfileDidUpdateNotification";

static NSString * const kTokenKey    = @"TLW_access_token";
static NSString * const kRefreshKey  = @"TLW_refresh_token";
static NSString * const kUserIdKey   = @"TLW_user_id";
static NSString * const kUsernameKey = @"TLW_username";
static NSString * const kGenPwdKey  = @"TLW_generated_password";

@interface TLWSDKManager ()
@property (nonatomic, strong, readwrite) AGUserProfileDto *cachedProfile;
@property (nonatomic, strong, readwrite) NSArray<AGPostResponseDto *> *cachedFavoritedPosts;
/// 是否正在刷新 token（防止并发多次刷新请求）
@property (nonatomic, assign) BOOL isRefreshing;
/// 等待 token 刷新完成后重试的 block 队列
@property (nonatomic, strong) NSMutableArray<dispatch_block_t> *pendingRetryBlocks;
@end

@implementation TLWSDKManager

+ (instancetype)shared {
  static TLWSDKManager *instance;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[TLWSDKManager alloc] init];
  });
  return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // 配置 SDK
        AGDefaultConfiguration *config = [AGDefaultConfiguration sharedConfig];
        config.host = @"http://115.191.67.35:8080";
        // 从本地恢复登录态
        NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
        NSString *token = [ud stringForKey:kTokenKey];
        if (token.length > 0) {
            config.accessToken = token;
        }
        _userId   = [ud integerForKey:kUserIdKey];
        _username = [ud stringForKey:kUsernameKey];
        _cachedFavoritedPosts = @[];
        //  api服务入口，所有接口都从这里走
        _api = [[AGApiService alloc] init];
        _pendingRetryBlocks = [NSMutableArray array];
    }
    return self;
}

#pragma mark - Public

- (BOOL)isLoggedIn {
  return [AGDefaultConfiguration sharedConfig].accessToken.length > 0;
}

- (void)saveAuthResponse:(AGAuthResponse *)auth {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  // 设置SDK的token
  [AGDefaultConfiguration sharedConfig].accessToken = auth.token;
  [ud setObject:auth.token        forKey:kTokenKey];
  [ud setObject:auth.refreshToken forKey:kRefreshKey];
  [ud setInteger:auth.userId.integerValue forKey:kUserIdKey];
  [ud setObject:auth.username     forKey:kUsernameKey];
  if (auth.generatedPassword.length > 0) {
    [ud setObject:auth.generatedPassword forKey:kGenPwdKey];
  }

  _userId   = auth.userId.integerValue;
  _username = auth.username;
}

- (nullable NSString *)refreshToken {
  return [[NSUserDefaults standardUserDefaults] stringForKey:kRefreshKey];
}

- (nullable NSString *)generatedPassword {
  return [[NSUserDefaults standardUserDefaults] stringForKey:kGenPwdKey];
}

- (void)fetchProfileWithCompletion:(nullable void(^)(AGUserProfileDto * _Nullable profile))completion {
    [_api getCurrentUserProfileWithCompletionHandler:^(AGResultUserProfileDto *output, NSError *error) {
        if (!error && output.code.integerValue == 200) {
            self.cachedProfile = output.data;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:TLWProfileDidUpdateNotification object:nil];
            if (completion) completion(self.cachedProfile);
        });
    }];
}

- (void)logout {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  [AGDefaultConfiguration sharedConfig].accessToken = nil;

  [ud removeObjectForKey:kTokenKey];
  [ud removeObjectForKey:kRefreshKey];
  [ud removeObjectForKey:kUserIdKey];
  [ud removeObjectForKey:kUsernameKey];
  [ud removeObjectForKey:kGenPwdKey];

  _userId   = 0;
  _username = nil;
}

- (NSURLSessionTask* )uploadImages:(NSArray<UIImage* >* )images prefix:(NSString* )prefix completion:(void(^)(NSArray<NSString* > *urls, NSError* error))completion {
  //图片数组为空，返回空的urls数组
  if (!images.count) {
    if (completion) {
      completion(@[], nil);
      return nil;
    }
  }
  NSMutableArray<NSURL* >* fileURLS = [NSMutableArray array];
  NSMutableArray<NSString* >* tempPaths = [NSMutableArray array];
  //遍历处理图片数组
  for (NSInteger i = 0; i < images.count; i++) {
    UIImage* image = images[i];
    if (![image isKindOfClass:[UIImage class]]) {
      continue;
    }
    NSData* data = UIImageJPEGRepresentation(image, 1.0);//将UIimage转换成JPEG格式的二进制输出
    if (!data) {
      continue;
    }
    NSString* uuid = [[NSUUID UUID] UUIDString];
    NSString* fileName = [NSString stringWithFormat:@"%@_%ld.jpg", uuid, (long)i];//拼接一个独立的标识符
    NSString* path = [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];//临时文件存储路径
    BOOL ok = [data writeToFile:path atomically:YES];
    if (!ok) {
      continue;
    }
    [tempPaths addObject:path];//临时路径记录
    [fileURLS addObject:[NSURL fileURLWithPath:path]];//用于上传
  }
  if (fileURLS.count == 0) {
    if (completion) {
      completion(nil, [NSError errorWithDomain:@"upload" code:-1 userInfo:@{NSLocalizedDescriptionKey:@"no valid images"}]);
      return nil;
    }
  }
  //调用 SDK 接口上传图片，拿到远端 url
  return [[TLWSDKManager shared].api uploadFilesWithFiles:fileURLS prefix:prefix completionHandler:^(AGResultListString *output, NSError *error) {
    dispatch_async(dispatch_get_main_queue(), ^{
      //删除临时文件
      for (NSString* temp in tempPaths) {
        [[NSFileManager defaultManager] removeItemAtPath:temp error:nil];
      }
      if (error) {
        NSLog(@"[Upload] 上传失败: %@", error.localizedDescription);
        if (completion) {
          completion(nil, error);
          return;
        }
      }
      //服务器返回200，成功
      if (output.code && output.code.integerValue == 200) {
        NSArray<NSString *> *urls = output.data ?: @[];
        if (completion) {
          completion(urls, nil);
        }
      } else {
        NSString *msg = output.message ?: @"upload failed";
        NSError *e = [NSError errorWithDomain:@"upload" code:output.code.integerValue userInfo:@{NSLocalizedDescriptionKey: msg}];
        if (completion) {
          completion(nil, e);
        }
      }
    });
  }];
}

- (NSURLSessionTask *)getAllPostsWithTag:(nullable NSString *)tag
                                       q:(nullable NSString *)q
                                     page:(NSNumber *)page
                                     size:(NSNumber *)size
                        completionHandler:(void (^)(AGResultPageResultPostResponseDto * output, NSError * error))handler {
  return [self.api getPostsWithTag:(NSString *)tag
                                 q:(NSString *)q
                             page:page
                             size:size
               completionHandler:handler];
}

- (NSURLSessionTask *)getPostDetailWithId:(NSNumber *)_id
                        completionHandler:(void (^)(AGResultPostResponseDto * output, NSError * error))handler {
  return [self.api getPostDetailWithId:_id completionHandler:handler];
}

- (NSURLSessionTask *)getCommentsWithId:(NSNumber *)_id
                                    page:(NSNumber *)page
                                    size:(NSNumber *)size
                        completionHandler:(void (^)(AGResultPageResultCommentResponseDto * output, NSError * error))handler {
  return [self.api getCommentsWithId:_id page:page size:size completionHandler:handler];
}

- (NSURLSessionTask *)addCommentWithId:(NSNumber *)_id
                               content:(NSString *)content
                     completionHandler:(void (^)(AGResultCommentResponseDto * output, NSError * error))handler {
  AGCommentRequest *req = [[AGCommentRequest alloc] init];
  req.content = content;
  return [self.api addCommentWithId:_id commentRequest:req completionHandler:handler];
}

- (NSURLSessionTask *)getFavoritedPostsWithPage:(NSNumber *)page size:(NSNumber *)size completionHandler:(void (^)(AGResultPageResultPostResponseDto * output, NSError * error))handler {
  return [self.api getFavoritedPostsWithPage:page size:size completionHandler:handler];
}

- (void)fetchAllFavoritedPostsWithCompletion:(void (^)(NSArray<AGPostResponseDto *> * _Nullable posts, NSError * _Nullable error))completion {
  NSLog(@"开始拉取用户收藏的贴子");
  if (![self isLoggedIn]) {
    self.cachedFavoritedPosts = @[];
    if (completion) {
      dispatch_async(dispatch_get_main_queue(), ^{
        completion(@[], nil);
      });
    }
    return;
  }

  NSInteger pageSize = 20;
  NSInteger maxPages = 50;
  NSMutableArray<AGPostResponseDto *> *accumulator = [NSMutableArray array];
  __weak typeof(self) weakSelf = self;

  __block void (^fetchPageBlock)(NSInteger pageIndex);
  fetchPageBlock = ^(NSInteger pageIndex) {
    __strong typeof(weakSelf) strongSelf = weakSelf;
    if (!strongSelf) return;

    [strongSelf getFavoritedPostsWithPage:@(pageIndex) size:@(pageSize) completionHandler:^(AGResultPageResultPostResponseDto *output, NSError *error) {
      __strong typeof(weakSelf) s = weakSelf;
      if (!s) return;

      if (error || !output || output.code.integerValue != 200) {
        NSError *finalError = error;
        if (!finalError) {
          NSString *msg = output.message ?: @"拉取收藏帖子失败";
          NSLog(@"拉取帖子失败");
          finalError = [NSError errorWithDomain:@"TLWSDKManager.favorite" code:output.code.integerValue userInfo:@{NSLocalizedDescriptionKey : msg}];
        }
        fetchPageBlock = nil;
        dispatch_async(dispatch_get_main_queue(), ^{
          if (completion) completion(nil, finalError);
        });
        return;
      }

      NSLog(@"拉取帖子成功");
      NSArray<AGPostResponseDto *> *list = output.data.list ?: @[];
      [accumulator addObjectsFromArray:list];

      BOOL hasNext = output.data.hasNext.boolValue;
      if (hasNext && pageIndex + 1 < maxPages) {
        fetchPageBlock(pageIndex + 1);
      } else {
        fetchPageBlock = nil;
        s.cachedFavoritedPosts = [accumulator copy];
        dispatch_async(dispatch_get_main_queue(), ^{
          if (completion) completion(s.cachedFavoritedPosts, nil);
        });
      }
    }];
  };

  fetchPageBlock(0);
}

//获取收藏的帖子
- (NSURLSessionTask *)favoritePostWithId:(NSNumber *)_id completionHandler:(void (^)(AGResultVoid * output, NSError * error))handler {
  return [self.api favoritePostWithId:_id completionHandler:handler];
}

- (NSURLSessionTask *)unfavoritePostWithId:(NSNumber *)_id completionHandler:(void (^)(AGResultVoid * output, NSError * error))handler {
  return [self.api unfavoritePostWithId:_id completionHandler:handler];
}

- (void)handleUnauthorizedWithRetry:(nullable void(^)(void))retryBlock {
    // 把重试 block 入队（nil 也可以，只需要触发刷新）
    if (retryBlock) {
        [self.pendingRetryBlocks addObject:[retryBlock copy]];
    }
    // 已在刷新中，等结果就行，不重复发请求
    if (self.isRefreshing) return;
    NSString *rt = [self refreshToken];
    if (!rt.length) {
        // 没有 refresh token，直接跳登录
        [self logout];
        [self _navigateToLogin];
        return;
    }

    self.isRefreshing = YES;
    AGRefreshTokenRequest *req = [[AGRefreshTokenRequest alloc] init];
    req.refreshToken = rt;

    __weak typeof(self) weakSelf = self;
    [_api refreshWithRefreshTokenRequest:req completionHandler:^(AGResultAuthResponse *output, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) self = weakSelf;
            if (!self) return;
            self.isRefreshing = NO;

            if (!error && output.code.integerValue == 200) {
                // 刷新成功：更新双 token，执行所有排队重试
                [self saveAuthResponse:output.data];
                NSArray<dispatch_block_t> *blocks = [self.pendingRetryBlocks copy];
                [self.pendingRetryBlocks removeAllObjects];
                for (dispatch_block_t block in blocks) { block(); }
            } else {
                // 刷新失败：清除凭证，跳回登录页
                NSLog(@"[Token] refresh 失败，强制登出: %@", error ?: output.message);
                [self.pendingRetryBlocks removeAllObjects];
                [self logout];
                [self _navigateToLogin];
            }
        });
    }];
}


- (void)_navigateToLogin {
    // 动态 import 避免循环依赖，运行时查找登录 VC 类
    Class loginClass = NSClassFromString(@"TLWPasswordLoginController");
    if (!loginClass) return;
    UIViewController *loginVC = [[loginClass alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:loginVC];
    UIWindow *window = [UIApplication sharedApplication].windows.firstObject;
    [UIView transitionWithView:window
                      duration:0.35
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{ window.rootViewController = nav; }
                    completion:nil];
}

@end
