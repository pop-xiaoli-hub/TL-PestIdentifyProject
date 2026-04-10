//
//
//  TLWSDKManager.m
//  TL-PestIdentify
//

#import "TLWSDKManager.h"
#import <UIKit/UIKit.h>

@interface TLWSDKManager ()
@property (nonatomic, strong, readwrite) AGApiService *api;
@property (nonatomic, strong, readwrite) TLWSessionManager *sessionManager;
@property (nonatomic, strong, readwrite) NSArray<AGPostResponseDto *> *cachedFavoritedPosts;
@end

@implementation TLWSDKManager

#pragma mark - Window

//  这段代码用于拿到当前应用里"正在使用的窗口"，也就是通常想暂时弹窗、找根控制器时会用到的 UIWindow
/*
 为什么非得要这样呢，。因为在 iOS 13 之前，很多代码直接这么拿窗口：[UIApplication sharedApplication].keyWindow。但是13之后的多场景机制开始，这种全局取窗口就不再准确

 */
+ (UIWindow *)tl_activeWindow {
    UIWindow *window = nil;
    //  因为iOS13引入了scene机制，一个app可能会不止一个窗口场景，所以不能再简单的只取UIApplication.windows
    // 因此，我们需要遍历connectedScenes，找出处于ForegroundActive的场景，判断是不是UIWinowScene，再便利这个场景的windows
    if (@available(iOS 13.0, *)) {
        for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive &&
                [scene isKindOfClass:[UIWindowScene class]]) {
                UIWindowScene *windowScene = (UIWindowScene *)scene;
                //  遍历当前app链接的所有场景需满足 再前台活跃 && 这个场景确实是窗口场景 UIWindow Scene
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
        AGDefaultConfiguration *config = [AGDefaultConfiguration sharedConfig];
        config.host = @"http://115.191.67.35:8080";
        self.cachedFavoritedPosts = @[];
        self.api = [[AGApiService alloc] init];
        self.sessionManager = [[TLWSessionManager alloc] initWithAPIService:self.api];
        __weak typeof(self) weakSelf = self;
        self.sessionManager.sessionInvalidationHandler = ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) return;
            [strongSelf _navigateToLogin];
        };
    }
    return self;
}

#pragma mark - Public

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
  if (![self.sessionManager isLoggedIn]) {
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

- (void)setApi:(AGApiService *)api {
    _api = api;
    [self.sessionManager updateAPIService:api];
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

- (NSURLSessionTask *)createCropWithRequest:(AGMyCropCreateRequest *)request
                          completionHandler:(void (^)(AGResultMyCropResponseDto * output, NSError * error))handler {
  return [self.api createCropWithMyCropCreateRequest:request completionHandler:handler];
}

- (NSURLSessionTask *)getMyCropsWithCompletionHandler:(void (^)(AGResultListMyCropResponseDto * output, NSError * error))handler {
  return [self.api getMyCropsWithCompletionHandler:handler];
}

- (NSURLSessionTask *)getCropDetailWithId:(NSNumber *)cropId
                        completionHandler:(void (^)(AGResultMyCropResponseDto * output, NSError * error))handler {
  return [self.api getCropDetailWithId:cropId completionHandler:handler];
}

- (NSURLSessionTask *)addTagWithCropId:(NSNumber *)cropId
                   tagOperationRequest:(AGTagOperationRequest *)request
                     completionHandler:(void (^)(AGResultVoid * output, NSError * error))handler {
  return [self.api addTagWithId:cropId tagOperationRequest:request completionHandler:handler];
}
@end
