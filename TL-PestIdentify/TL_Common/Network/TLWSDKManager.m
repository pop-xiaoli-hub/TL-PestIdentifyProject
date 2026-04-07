//
//
//  TLWSDKManager.m
//  TL-PestIdentify
//

#import "TLWSDKManager.h"
#import <UIKit/UIKit.h>
#import <Security/Security.h>

static NSString * const kKeychainService = @"com.tl.pestidentify.auth";
static NSString * const kKeychainAccessToken  = @"access_token";
static NSString * const kKeychainRefreshToken = @"refresh_token";

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
/// 认证会话版本号。登出时递增，用于丢弃过期 refresh 回调。
@property (nonatomic, assign) NSUInteger authStateVersion;
@end

@implementation TLWSDKManager

#pragma mark - Window

+ (UIWindow *)tl_activeWindow {
    UIWindow *window = nil;
    if (@available(iOS 13.0, *)) {
        for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive &&
                [scene isKindOfClass:[UIWindowScene class]]) {
                UIWindowScene *windowScene = (UIWindowScene *)scene;
                for (UIWindow *w in windowScene.windows) {
                    if (w.isKeyWindow) {
                        window = w;
                        break;
                    }
                }
                if (window) break;
            }
        }
    }
    if (!window) {
        window = [UIApplication sharedApplication].windows.firstObject;
    }
    return window;
}

#pragma mark - Keychain Helpers

+ (BOOL)_keychainSave:(NSString *)value forAccount:(NSString *)account {
    if (!value) return NO;
    NSData *data = [value dataUsingEncoding:NSUTF8StringEncoding];
    // 先删除旧值
    NSDictionary *delQuery = @{
        (__bridge id)kSecClass:       (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService: kKeychainService,
        (__bridge id)kSecAttrAccount: account,
    };
    SecItemDelete((__bridge CFDictionaryRef)delQuery);
    // 写入新值
    NSDictionary *addQuery = @{
        (__bridge id)kSecClass:       (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService: kKeychainService,
        (__bridge id)kSecAttrAccount: account,
        (__bridge id)kSecValueData:   data,
        (__bridge id)kSecAttrAccessible: (__bridge id)kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
    };
    OSStatus status = SecItemAdd((__bridge CFDictionaryRef)addQuery, NULL);
    return status == errSecSuccess;
}

+ (nullable NSString *)_keychainLoadForAccount:(NSString *)account {
    NSDictionary *query = @{
        (__bridge id)kSecClass:       (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService: kKeychainService,
        (__bridge id)kSecAttrAccount: account,
        (__bridge id)kSecReturnData:  @YES,
        (__bridge id)kSecMatchLimit:  (__bridge id)kSecMatchLimitOne,
    };
    CFTypeRef result = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &result);
    if (status == errSecSuccess && result) {
        NSString *value = [[NSString alloc] initWithData:(__bridge_transfer NSData *)result encoding:NSUTF8StringEncoding];
        return value;
    }
    return nil;
}

+ (void)_keychainDeleteForAccount:(NSString *)account {
    NSDictionary *query = @{
        (__bridge id)kSecClass:       (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService: kKeychainService,
        (__bridge id)kSecAttrAccount: account,
    };
    SecItemDelete((__bridge CFDictionaryRef)query);
}

#pragma mark - Singleton

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
        // 从 Keychain 恢复登录态（迁移：若 Keychain 无值但 NSUserDefaults 有，则迁移后删除旧值）
        NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
        NSString *token = [TLWSDKManager _keychainLoadForAccount:kKeychainAccessToken];
        if (!token.length) {
            // 尝试从旧的 NSUserDefaults 迁移
            NSString *legacyToken = [ud stringForKey:kTokenKey];
            if (legacyToken.length) {
                [TLWSDKManager _keychainSave:legacyToken forAccount:kKeychainAccessToken];
                NSString *legacyRefresh = [ud stringForKey:kRefreshKey];
                if (legacyRefresh.length) {
                    [TLWSDKManager _keychainSave:legacyRefresh forAccount:kKeychainRefreshToken];
                }
                // 迁移完成后清除 NSUserDefaults 中的敏感信息
                [ud removeObjectForKey:kTokenKey];
                [ud removeObjectForKey:kRefreshKey];
                token = legacyToken;
            }
        }
        if (token.length > 0) {
            config.accessToken = token;
        }
        _userId   = [ud integerForKey:kUserIdKey];
        _username = [ud stringForKey:kUsernameKey];
        _cachedFavoritedPosts = @[];
        //  api服务入口，所有接口都从这里走
        _api = [[AGApiService alloc] init];
        _pendingRetryBlocks = [NSMutableArray array];
        _authStateVersion = 0;
    }
    return self;
}

#pragma mark - Public

- (BOOL)isLoggedIn {
  return [AGDefaultConfiguration sharedConfig].accessToken.length > 0;
}

- (void)saveAuthResponse:(AGAuthResponse *)auth {
  // 关键字段 nil 防护：token 必须存在，否则不写入
  if (!auth.token.length) {
      NSLog(@"[Token] saveAuthResponse: token 为空，跳过保存");
      return;
  }

  // Token 存入 Keychain
  [AGDefaultConfiguration sharedConfig].accessToken = auth.token;
  BOOL tokenSaved = [TLWSDKManager _keychainSave:auth.token forAccount:kKeychainAccessToken];
  if (!tokenSaved) {
      NSLog(@"[Token] ⚠️ accessToken 写入 Keychain 失败，重启后可能丢失登录态");
  }
  if (auth.refreshToken.length) {
      BOOL rtSaved = [TLWSDKManager _keychainSave:auth.refreshToken forAccount:kKeychainRefreshToken];
      if (!rtSaved) {
          NSLog(@"[Token] ⚠️ refreshToken 写入 Keychain 失败");
      }
  } else {
      // 服务端未返回 refreshToken 时，删除旧值防止残留历史账号 token
      [TLWSDKManager _keychainDeleteForAccount:kKeychainRefreshToken];
  }

  // 非敏感信息存 NSUserDefaults
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  [ud setInteger:auth.userId.integerValue forKey:kUserIdKey];
  if (auth.username) {
      [ud setObject:auth.username forKey:kUsernameKey];
  }
  if (auth.generatedPassword.length > 0) {
      [ud setObject:auth.generatedPassword forKey:kGenPwdKey];
  }

  _userId   = auth.userId.integerValue;
  _username = auth.username;
}

- (nullable NSString *)refreshToken {
  return [TLWSDKManager _keychainLoadForAccount:kKeychainRefreshToken];
}

- (nullable NSString *)generatedPassword {
  return [[NSUserDefaults standardUserDefaults] stringForKey:kGenPwdKey];
}

- (void)fetchProfileWithCompletion:(nullable void(^)(AGUserProfileDto * _Nullable profile))completion {
    __weak typeof(self) weakSelf = self;
    [_api getCurrentUserProfileWithCompletionHandler:^(AGResultUserProfileDto *output, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) self = weakSelf;
            if (!self) return;

            if (!error && output.code.integerValue == 200) {
                self.cachedProfile = output.data;
                [[NSNotificationCenter defaultCenter] postNotificationName:TLWProfileDidUpdateNotification object:nil];
                if (completion) completion(self.cachedProfile);
                return;
            }

            // 401 时自动走 refresh 兜底，刷新成功后重试拉取资料
            if (!error && output.code.integerValue == 401) {
                [self handleUnauthorizedWithRetry:^{
                    [self fetchProfileWithCompletion:completion];
                }];
                return;
            }

            if (completion) completion(nil);
        });
    }];
}

- (void)logout {
  @synchronized (self) {
      self.authStateVersion += 1;
      self.isRefreshing = NO;
      [self.pendingRetryBlocks removeAllObjects];
  }

  [AGDefaultConfiguration sharedConfig].accessToken = nil;

  // 清除 Keychain 中的敏感凭证
  [TLWSDKManager _keychainDeleteForAccount:kKeychainAccessToken];
  [TLWSDKManager _keychainDeleteForAccount:kKeychainRefreshToken];

  // 清除 NSUserDefaults 中的非敏感信息
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  [ud removeObjectForKey:kTokenKey];     // 兼容清理旧数据
  [ud removeObjectForKey:kRefreshKey];   // 兼容清理旧数据
  [ud removeObjectForKey:kUserIdKey];
  [ud removeObjectForKey:kUsernameKey];
  [ud removeObjectForKey:kGenPwdKey];

  _userId   = 0;
  _username = nil;
  self.cachedProfile = nil;
  self.cachedFavoritedPosts = @[];
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

- (NSURLSessionTask *)getSuggestionsWithQ:(NSString *)q
                        completionHandler:(void (^)(AGResultListString * output, NSError * error))handler {
  return [self.api getSuggestionsWithQ:q completionHandler:handler];
}

- (NSURLSessionTask *)searchPostsWithQ:(NSString *)q
                                  page:(NSNumber *)page
                                  size:(NSNumber *)size
                     completionHandler:(void (^)(AGResultSearchResultResponse * output, NSError * error))handler {
  return [self.api searchPostsWithQ:q page:page size:size completionHandler:handler];
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

- (NSURLSessionTask *)getMyPostsWithPage:(NSNumber *)page size:(NSNumber *)size completionHandler:(void (^)(AGResultPageResultPostResponseDto * output, NSError * error))handler {
  return [self.api getMyPostsWithPage:page size:size completionHandler:handler];
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

- (NSURLSessionTask *)likePostWithId:(NSNumber *)_id completionHandler:(void (^)(AGResultVoid * output, NSError * error))handler {
  return [self.api likePostWithId:_id completionHandler:handler];
}

- (NSURLSessionTask *)unlikePostWithId:(NSNumber *)_id completionHandler:(void (^)(AGResultVoid * output, NSError * error))handler {
  return [self.api unlikePostWithId:_id completionHandler:handler];
}

- (void)handleUnauthorizedWithRetry:(nullable void(^)(void))retryBlock {
    NSString *rt = nil;
    NSUInteger requestVersion = 0;
    BOOL shouldStartRefresh = NO;
    BOOL shouldForceLogout = NO;

    @synchronized (self) {
        // 把重试 block 入队（nil 也可以，只需要触发刷新）
        if (retryBlock) {
            [self.pendingRetryBlocks addObject:[retryBlock copy]];
        }
        // 已在刷新中，等结果就行，不重复发请求
        if (self.isRefreshing) {
            return;
        }

        rt = [self refreshToken];
        if (!rt.length) {
            shouldForceLogout = YES;
            [self.pendingRetryBlocks removeAllObjects];
        } else {
            self.isRefreshing = YES;
            requestVersion = self.authStateVersion;
            shouldStartRefresh = YES;
        }
    }

    if (shouldForceLogout) {
        // 没有 refresh token，直接跳登录
        [self logout];
        [self _navigateToLogin];
        return;
    }
    if (!shouldStartRefresh) return;

    AGRefreshTokenRequest *req = [[AGRefreshTokenRequest alloc] init];
    req.refreshToken = rt;

    __weak typeof(self) weakSelf = self;
    [_api refreshWithRefreshTokenRequest:req completionHandler:^(AGResultAuthResponse *output, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) self = weakSelf;
            if (!self) return;

            BOOL shouldIgnore = NO;
            @synchronized (self) {
                self.isRefreshing = NO;
                if (requestVersion != self.authStateVersion) {
                    // 用户已登出/切换会话，丢弃过期 refresh 回调
                    [self.pendingRetryBlocks removeAllObjects];
                    shouldIgnore = YES;
                }
            }
            if (shouldIgnore) return;

            if (!error && output.code.integerValue == 200) {
                // 刷新成功：更新双 token，执行所有排队重试
                [self saveAuthResponse:output.data];
                NSArray<dispatch_block_t> *blocks = nil;
                @synchronized (self) {
                    blocks = [self.pendingRetryBlocks copy];
                    [self.pendingRetryBlocks removeAllObjects];
                }
                for (dispatch_block_t block in blocks) { block(); }
            } else {
                // 刷新失败：清除凭证，跳回登录页
                NSLog(@"[Token] refresh 失败，强制登出: %@", error ?: output.message);
                @synchronized (self) {
                    [self.pendingRetryBlocks removeAllObjects];
                }
                [self logout];
                [self _navigateToLogin];
            }
        });
    }];
}


- (void)_navigateToLogin {
    Class loginClass = NSClassFromString(@"TLWPasswordLoginController");
    if (!loginClass) return;
    UIViewController *loginVC = [[loginClass alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:loginVC];
    nav.navigationBarHidden = YES;

    UIWindow *window = [TLWSDKManager tl_activeWindow];
    if (!window) return;

    [UIView transitionWithView:window
                      duration:0.35
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{ window.rootViewController = nav; }
                    completion:nil];
}

- (NSURLSessionTask *)uploadFileWithFile:(NSURL *)file
                                  prefix:(NSString *)prefix
                       completionHandler:(void (^)(AGResultString * output, NSError * error))handler {
  NSString *uploadPrefix = prefix.length > 0 ? prefix : @"uploads/";
  return [self.api uploadFileWithFile:file prefix:uploadPrefix completionHandler:handler];
}

@end
