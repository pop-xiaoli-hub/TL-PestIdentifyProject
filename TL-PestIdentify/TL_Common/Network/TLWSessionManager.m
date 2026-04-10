//
//  TLWSessionManager.m
//  TL-PestIdentify
//

#import "TLWSessionManager.h"
#import "TLWDBManager.h"
#import "TLWToast.h"
#import <Security/Security.h>

static NSString * const kKeychainService = @"com.tl.pestidentify.auth";
static NSString * const kKeychainAccessToken  = @"access_token";
static NSString * const kKeychainRefreshToken = @"refresh_token";

static NSString * const kLegacyTokenKey = @"TLW_access_token";
static NSString * const kLegacyRefreshKey = @"TLW_refresh_token";
static NSString * const kUserIdKey = @"TLW_user_id";
static NSString * const kUsernameKey = @"TLW_username";
static NSString * const kGeneratedPasswordKey = @"TLW_generated_password";

NSString * const TLWProfileDidUpdateNotification = @"TLWProfileDidUpdateNotification";

static inline void TLWAuthDebugToast(NSString *message) {
#if DEBUG
    [TLWToast show:message];
#else
    (void)message;
#endif
}

@interface TLWSessionManager ()

@property (nonatomic, strong, readwrite) AGApiService *api;
@property (nonatomic, strong, readwrite) AGUserProfileDto *cachedProfile;
@property (nonatomic, strong) NSMutableArray<dispatch_block_t> *pendingRetryBlocks;
@property (nonatomic, assign) BOOL isRefreshing;

//  这是一个会话版本号，用于避免旧回调污染新会话
@property (nonatomic, assign) NSUInteger authStateVersion;

@end

@implementation TLWSessionManager

#pragma mark - Keychain Helpers

+ (BOOL)_keychainSave:(NSString *)value forAccount:(NSString *)account {
    if (!value) return NO;
    NSData *data = [value dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *delQuery = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService: kKeychainService,
        (__bridge id)kSecAttrAccount: account,
    };
    SecItemDelete((__bridge CFDictionaryRef)delQuery);

    NSDictionary *addQuery = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService: kKeychainService,
        (__bridge id)kSecAttrAccount: account,
        (__bridge id)kSecValueData: data,
        (__bridge id)kSecAttrAccessible: (__bridge id)kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
    };
    OSStatus status = SecItemAdd((__bridge CFDictionaryRef)addQuery, NULL);
    return status == errSecSuccess;
}

+ (nullable NSString *)_keychainLoadForAccount:(NSString *)account {
    NSDictionary *query = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService: kKeychainService,
        (__bridge id)kSecAttrAccount: account,
        (__bridge id)kSecReturnData: @YES,
        (__bridge id)kSecMatchLimit: (__bridge id)kSecMatchLimitOne,
    };
    CFTypeRef result = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &result);
    if (status == errSecSuccess && result) {
        return [[NSString alloc] initWithData:(__bridge_transfer NSData *)result encoding:NSUTF8StringEncoding];
    }
    return nil;
}

+ (void)_keychainDeleteForAccount:(NSString *)account {
    NSDictionary *query = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService: kKeychainService,
        (__bridge id)kSecAttrAccount: account,
    };
    SecItemDelete((__bridge CFDictionaryRef)query);
}

#pragma mark - Lifecycle

- (instancetype)initWithAPIService:(AGApiService *)api {
    self = [super init];
    if (self) {
        _api = api;
        _pendingRetryBlocks = [NSMutableArray array];
        _authStateVersion = 0;
        [self tl_restoreSessionFromPersistence];
    }
    return self;
}

- (void)updateAPIService:(AGApiService *)api {
    _api = api;
}

#pragma mark - Public

- (BOOL)isLoggedIn {
    return [AGDefaultConfiguration sharedConfig].accessToken.length > 0
        && [self refreshToken].length > 0
        && self.userId > 0;
}

- (BOOL)saveAuthResponse:(AGAuthResponse *)auth {
    if (!auth.token.length) {
        NSLog(@"[Token] saveAuthResponse: token 为空，跳过保存");
        return NO;
    }
    if (auth.userId.integerValue <= 0) {
        NSLog(@"[Token] saveAuthResponse: userId 无效（%@），跳过保存", auth.userId);
        return NO;
    }
    if (!auth.refreshToken.length) {
        NSLog(@"[Token] saveAuthResponse: refreshToken 为空，跳过保存");
        return NO;
    }

    BOOL tokenSaved = [TLWSessionManager _keychainSave:auth.token forAccount:kKeychainAccessToken];
    if (!tokenSaved) {
        NSLog(@"[Token] accessToken 写入 Keychain 失败");
        return NO;
    }

    BOOL refreshSaved = [TLWSessionManager _keychainSave:auth.refreshToken forAccount:kKeychainRefreshToken];
    if (!refreshSaved) {
        NSLog(@"[Token] refreshToken 写入 Keychain 失败，回滚 accessToken");
        [TLWSessionManager _keychainDeleteForAccount:kKeychainAccessToken];
        [TLWSessionManager _keychainDeleteForAccount:kKeychainRefreshToken];
        return NO;
    }

    //  把accessToken写入全局配置
    [AGDefaultConfiguration sharedConfig].accessToken = auth.token;
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud setInteger:auth.userId.integerValue forKey:kUserIdKey];
    if (auth.username.length > 0) {
        [ud setObject:auth.username forKey:kUsernameKey];
    } else {
        [ud removeObjectForKey:kUsernameKey];
    }
    if (auth.generatedPassword.length > 0) {
        [ud setObject:auth.generatedPassword forKey:kGeneratedPasswordKey];
    } else {
        [ud removeObjectForKey:kGeneratedPasswordKey];
    }

    self.userId = auth.userId.integerValue;
    self.username = auth.username.length > 0 ? auth.username : nil;

    //  重新打开数据库
    [[TLWDBManager shared] reopenForCurrentUser];
    return YES;
}

- (void)fetchProfileWithCompletion:(nullable void(^)(AGUserProfileDto * _Nullable profile))completion {
    __weak typeof(self) weakSelf = self;
    [self.api getCurrentUserProfileWithCompletionHandler:^(AGResultUserProfileDto *output, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) self = weakSelf;
            if (!self) return;

            if (!error && output.code.integerValue == 200) {
                NSLog(@"[Profile] fetch success: code=%@ userId=%ld data=%@",
                      output.code,
                      (long)self.userId,
                      output.data ? @"present" : @"nil");
                self.cachedProfile = output.data;
                [[NSNotificationCenter defaultCenter] postNotificationName:TLWProfileDidUpdateNotification object:nil];
                if (completion) completion(self.cachedProfile);
                return;
            }

            if (!error && output.code.integerValue == 401) {
                NSLog(@"[Profile] fetch got 401, attempting refresh: userId=%ld message=%@",
                      (long)self.userId,
                      output.message ?: @"<empty>");
                TLWAuthDebugToast(@"登录状态失效，正在刷新登录");
                [self handleUnauthorizedWithRetry:^{
                    NSLog(@"[Profile] retry fetch after refresh");
                    TLWAuthDebugToast(@"登录状态已刷新，正在重试拉取资料");
                    [self fetchProfileWithCompletion:completion];
                }];
                return;
            }

            NSLog(@"[Profile] fetch failed: code=%@ message=%@ error=%@ data=%@",
                  output.code ?: @"<nil>",
                  output.message ?: @"<empty>",
                  error.localizedDescription ?: @"<nil>",
                  output.data ? @"present" : @"nil");
            TLWAuthDebugToast(@"资料拉取失败，请稍后重试");
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

    [self tl_clearPersistedSessionArtifacts];
    [self tl_resetInMemorySession];
    [[TLWDBManager shared] reopenForCurrentUser];
}

- (nullable NSString *)refreshToken {
    return [TLWSessionManager _keychainLoadForAccount:kKeychainRefreshToken];
}

- (nullable NSString *)generatedPassword {
    return [[NSUserDefaults standardUserDefaults] stringForKey:kGeneratedPasswordKey];
}

- (void)handleUnauthorizedWithRetry:(nullable void(^)(void))retryBlock {
    NSString *refreshToken = nil;
    NSUInteger requestVersion = 0;
    BOOL shouldStartRefresh = NO;
    BOOL shouldForceLogout = NO;

    @synchronized (self) {
        if (retryBlock) {
            [self.pendingRetryBlocks addObject:[retryBlock copy]];
        }
        if (self.isRefreshing) {
            NSLog(@"[Token] refresh already in progress, queued retry block count=%lu",
                  (unsigned long)self.pendingRetryBlocks.count);
            TLWAuthDebugToast(@"登录刷新进行中，请稍候");
            return;
        }

        refreshToken = [self refreshToken];
        if (!refreshToken.length) {
            NSLog(@"[Token] no refreshToken available, force logout");
            TLWAuthDebugToast(@"登录信息缺失，请重新登录");
            shouldForceLogout = YES;
            [self.pendingRetryBlocks removeAllObjects];
        } else {
            self.isRefreshing = YES;
            requestVersion = self.authStateVersion;
            shouldStartRefresh = YES;
        }
    }

    if (shouldForceLogout) {
        [self tl_forceLogoutAndNotify];
        return;
    }
    if (!shouldStartRefresh) return;

    NSLog(@"[Token] start refresh: userId=%ld queuedRetryCount=%lu",
          (long)self.userId,
          (unsigned long)self.pendingRetryBlocks.count);
    TLWAuthDebugToast(@"检测到登录已过期，正在自动续期");

    AGRefreshTokenRequest *req = [[AGRefreshTokenRequest alloc] init];
    req.refreshToken = refreshToken;

    __weak typeof(self) weakSelf = self;
    [self.api refreshWithRefreshTokenRequest:req completionHandler:^(AGResultAuthResponse *output, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) self = weakSelf;
            if (!self) return;

            BOOL shouldIgnore = NO;
            @synchronized (self) {
                self.isRefreshing = NO;
                if (requestVersion != self.authStateVersion) {
                    NSLog(@"[Token] ignore refresh result because auth state changed");
                    [self.pendingRetryBlocks removeAllObjects];
                    shouldIgnore = YES;
                }
            }
            if (shouldIgnore) return;

            if (!error && output.code.integerValue == 200) {
                BOOL saved = [self saveAuthResponse:output.data];
                if (saved) {
                    NSArray<dispatch_block_t> *blocks = nil;
                    @synchronized (self) {
                        blocks = [self.pendingRetryBlocks copy];
                        [self.pendingRetryBlocks removeAllObjects];
                    }
                    NSLog(@"[Token] refresh success: code=%@ newUserId=%@ retryCount=%lu",
                          output.code,
                          output.data.userId ?: @"<nil>",
                          (unsigned long)blocks.count);
                    TLWAuthDebugToast(@"登录已续期成功");
                    for (dispatch_block_t block in blocks) {
                        block();
                    }
                    return;
                }

                NSLog(@"[Token] refresh returned 200 but auth data invalid: token=%@ refreshToken=%@ userId=%@",
                      output.data.token.length > 0 ? @"present" : @"nil",
                      output.data.refreshToken.length > 0 ? @"present" : @"nil",
                      output.data.userId ?: @"<nil>");
                TLWAuthDebugToast(@"登录续期异常，请重新登录");
                @synchronized (self) {
                    [self.pendingRetryBlocks removeAllObjects];
                }
                [self tl_forceLogoutAndNotify];
                return;
            }

            NSLog(@"[Token] refresh failed, force logout: code=%@ message=%@ error=%@",
                  output.code ?: @"<nil>",
                  output.message ?: @"<empty>",
                  error.localizedDescription ?: @"<nil>");
            TLWAuthDebugToast(@"登录已失效，请重新登录");
            @synchronized (self) {
                [self.pendingRetryBlocks removeAllObjects];
            }
            [self tl_forceLogoutAndNotify];
        });
    }];
}

#pragma mark - Private

- (void)tl_restoreSessionFromPersistence {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSString *token = [TLWSessionManager _keychainLoadForAccount:kKeychainAccessToken];
    NSString *refreshToken = [TLWSessionManager _keychainLoadForAccount:kKeychainRefreshToken];
    NSInteger persistedUserId = [ud integerForKey:kUserIdKey];

    BOOL hasCompleteSession = token.length > 0 && refreshToken.length > 0 && persistedUserId > 0;
    if (hasCompleteSession) {
        [AGDefaultConfiguration sharedConfig].accessToken = token;
        self.userId = persistedUserId;
        self.username = [ud stringForKey:kUsernameKey];
        return;
    }

    BOOL hasStalePersistedAuth = token.length > 0
        || refreshToken.length > 0
        || persistedUserId > 0
        || [ud stringForKey:kLegacyTokenKey].length > 0
        || [ud stringForKey:kLegacyRefreshKey].length > 0
        || [ud stringForKey:kUsernameKey].length > 0
        || [ud stringForKey:kGeneratedPasswordKey].length > 0;
    if (hasStalePersistedAuth) {
        NSLog(@"[Token] cold start detected stale auth, clearing local credentials");
        [self tl_clearPersistedSessionArtifacts];
    }
    [self tl_resetInMemorySession];
}

- (void)tl_resetInMemorySession {
    [AGDefaultConfiguration sharedConfig].accessToken = @"";
    self.userId = 0;
    self.username = nil;
    self.cachedProfile = nil;
}

- (void)tl_clearPersistedSessionArtifacts {
    [TLWSessionManager _keychainDeleteForAccount:kKeychainAccessToken];
    [TLWSessionManager _keychainDeleteForAccount:kKeychainRefreshToken];

    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud removeObjectForKey:kLegacyTokenKey];
    [ud removeObjectForKey:kLegacyRefreshKey];
    [ud removeObjectForKey:kUserIdKey];
    [ud removeObjectForKey:kUsernameKey];
    [ud removeObjectForKey:kGeneratedPasswordKey];
}

- (void)tl_forceLogoutAndNotify {
    [self logout];
    dispatch_block_t handler = self.sessionInvalidationHandler;
    if (handler) {
        dispatch_async(dispatch_get_main_queue(), handler);
    }
}

@end
