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
static NSTimeInterval const kTLWAuthToastThrottleInterval = 2.0;

NSString * const TLWProfileDidUpdateNotification = @"TLWProfileDidUpdateNotification";

@interface TLWSessionManager ()

@property (nonatomic, strong, readwrite) AGApiService *api;
@property (nonatomic, strong, readwrite) AGUserProfileDto *cachedProfile;
@property (nonatomic, strong) NSMutableArray<dispatch_block_t> *pendingRetryBlocks;
@property (nonatomic, assign) BOOL isRefreshing;
@property (nonatomic, assign) BOOL isHandlingSessionInvalidation;
@property (nonatomic, assign) NSTimeInterval lastAuthToastTimestamp;
@property (nonatomic, copy, nullable) NSString *lastAuthToastMessage;

//  这是一个会话版本号，用于避免旧回调污染新会话
@property (nonatomic, assign) NSUInteger authStateVersion;
// 记录最近一次 refresh 成功后对应的会话版本，避免新 token 仍返回 403 时重复 refresh
@property (nonatomic, assign) NSUInteger lastRefreshSucceededAuthStateVersion;

- (void)tl_fetchProfileWithCompletion:(nullable void(^)(AGUserProfileDto * _Nullable profile))completion
                         didRetryAuth:(BOOL)didRetryAuth;
- (void)tl_showAuthToastIfNeeded:(NSString *)message;
- (void)tl_forceLogoutAndNotifyWithMessage:(nullable NSString *)message;

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
        _lastRefreshSucceededAuthStateVersion = NSNotFound;
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
    [ud removeObjectForKey:kGeneratedPasswordKey];

    @synchronized (self) {
        self.authStateVersion += 1;
        self.userId = auth.userId.integerValue;
        self.username = auth.username.length > 0 ? auth.username : nil;
        self.isHandlingSessionInvalidation = NO;
    }

    //  重新打开数据库
    [[TLWDBManager shared] reopenForCurrentUser];
    return YES;
}

- (void)fetchProfileWithCompletion:(nullable void(^)(AGUserProfileDto * _Nullable profile))completion {
    [self tl_fetchProfileWithCompletion:completion didRetryAuth:NO];
}

- (void)tl_fetchProfileWithCompletion:(nullable void(^)(AGUserProfileDto * _Nullable profile))completion
                         didRetryAuth:(BOOL)didRetryAuth {
    __block NSUInteger requestVersion = 0;
    __block NSInteger requestUserId = 0;
    @synchronized (self) {
        requestVersion = self.authStateVersion;
        requestUserId = self.userId;
    }

    __weak typeof(self) weakSelf = self;
    [self.api getCurrentUserProfileWithCompletionHandler:^(AGResultUserProfileDto *output, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) self = weakSelf;
            if (!self) return;

            BOOL shouldIgnore = NO;
            @synchronized (self) {
                shouldIgnore = (requestVersion != self.authStateVersion || requestUserId != self.userId || requestUserId <= 0);
            }
            if (shouldIgnore) {
                NSLog(@"[Profile] ignore stale callback: requestVersion=%lu currentVersion=%lu requestUserId=%ld currentUserId=%ld",
                      (unsigned long)requestVersion,
                      (unsigned long)self.authStateVersion,
                      (long)requestUserId,
                      (long)self.userId);
                return;
            }

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

            if (!didRetryAuth
                && [self handleAuthFailureForCode:output.code
                                          message:output.message
                                       retryBlock:^{
                    NSLog(@"[Profile] retry fetch after refresh");
                    [self tl_fetchProfileWithCompletion:completion didRetryAuth:YES];
                }]) {
                return;
            }

            NSLog(@"[Profile] fetch failed: code=%@ message=%@ error=%@ data=%@",
                  output.code ?: @"<nil>",
                  output.message ?: @"<empty>",
                  error.localizedDescription ?: @"<nil>",
                  output.data ? @"present" : @"nil");
            [TLWToast show:[self userFacingMessageForError:error
                                                     code:output.code
                                            serverMessage:output.message
                                           defaultMessage:@"资料拉取失败，请稍后重试"]];
            if (completion) completion(nil);
        });
    }];
}

- (void)logout {
    @synchronized (self) {
        self.authStateVersion += 1;
        self.lastRefreshSucceededAuthStateVersion = NSNotFound;
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
    return nil;
}

- (BOOL)shouldAttemptTokenRefreshForCode:(NSNumber *)code {
    NSInteger statusCode = code.integerValue;
    if (statusCode == 401) {
        return YES;
    }
    if (statusCode != 403) {
        return NO;
    }

    @synchronized (self) {
        return self.lastRefreshSucceededAuthStateVersion != self.authStateVersion;
    }
}

- (BOOL)handleAuthFailureForCode:(NSNumber *)code
                         message:(NSString *)message
                      retryBlock:(nullable void(^)(void))retryBlock {
    if (![self shouldAttemptTokenRefreshForCode:code]) {
        return NO;
    }

    NSLog(@"[Auth] response considered expired: code=%@ userId=%ld message=%@",
          code ?: @"<nil>",
          (long)self.userId,
          message ?: @"<empty>");
    [self tl_showAuthToastIfNeeded:@"登录状态已失效，正在尝试恢复"];
    [self handleUnauthorizedWithRetry:retryBlock];
    return YES;
}

- (void)invalidateSessionWithMessage:(nullable NSString *)message {
    [self tl_forceLogoutAndNotifyWithMessage:message];
}

- (NSString *)userFacingMessageForError:(NSError *)error
                                   code:(NSNumber *)code
                          serverMessage:(NSString *)serverMessage
                         defaultMessage:(NSString *)defaultMessage {
    if (error.localizedDescription.length > 0) {
        return error.localizedDescription;
    }
    if (code.integerValue == 401) {
        return @"登录状态异常，请重新登录";
    }
    if (code.integerValue == 403 || code.integerValue == 4003) {
        return serverMessage.length > 0 ? serverMessage : @"当前账号没有权限访问该内容";
    }
    if (serverMessage.length > 0) {
        return serverMessage;
    }
    return defaultMessage;
}

- (void)handleUnauthorizedWithRetry:(nullable void(^)(void))retryBlock {
    NSString *refreshToken = nil;
    NSUInteger requestVersion = 0;
    BOOL shouldStartRefresh = NO;
    BOOL shouldForceLogout = NO;
    NSString *logoutMessage = nil;

    @synchronized (self) {
        if (retryBlock) {
            [self.pendingRetryBlocks addObject:[retryBlock copy]];
        }
        if (self.isRefreshing) {
            NSLog(@"[Token] refresh already in progress, queued retry block count=%lu",
                  (unsigned long)self.pendingRetryBlocks.count);
            return;
        }

        refreshToken = [self refreshToken];
        if (!refreshToken.length) {
            NSLog(@"[Token] no refreshToken available, force logout");
            shouldForceLogout = YES;
            logoutMessage = @"登录信息已失效，请重新登录";
            [self.pendingRetryBlocks removeAllObjects];
        } else {
            self.isRefreshing = YES;
            requestVersion = self.authStateVersion;
            shouldStartRefresh = YES;
        }
    }

    if (shouldForceLogout) {
        [self tl_forceLogoutAndNotifyWithMessage:logoutMessage];
        return;
    }
    if (!shouldStartRefresh) return;

    NSLog(@"[Token] start refresh: userId=%ld queuedRetryCount=%lu",
          (long)self.userId,
          (unsigned long)self.pendingRetryBlocks.count);

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
                        self.lastRefreshSucceededAuthStateVersion = self.authStateVersion;
                        blocks = [self.pendingRetryBlocks copy];
                        [self.pendingRetryBlocks removeAllObjects];
                    }
                    NSLog(@"[Token] refresh success: code=%@ newUserId=%@ retryCount=%lu",
                          output.code,
                          output.data.userId ?: @"<nil>",
                          (unsigned long)blocks.count);
                    for (dispatch_block_t block in blocks) {
                        block();
                    }
                    return;
                }

                NSLog(@"[Token] refresh returned 200 but auth data invalid: token=%@ refreshToken=%@ userId=%@",
                      output.data.token.length > 0 ? @"present" : @"nil",
                      output.data.refreshToken.length > 0 ? @"present" : @"nil",
                      output.data.userId ?: @"<nil>");
                @synchronized (self) {
                    [self.pendingRetryBlocks removeAllObjects];
                }
                [self tl_forceLogoutAndNotifyWithMessage:@"登录状态恢复失败，可能该账号已在其他设备登录，请重新登录"];
                return;
            }

            NSLog(@"[Token] refresh failed, force logout: code=%@ message=%@ error=%@",
                  output.code ?: @"<nil>",
                  output.message ?: @"<empty>",
                  error.localizedDescription ?: @"<nil>");
            @synchronized (self) {
                [self.pendingRetryBlocks removeAllObjects];
            }
            [self tl_forceLogoutAndNotifyWithMessage:@"登录状态恢复失败，可能该账号已在其他设备登录，请重新登录"];
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

- (void)tl_showAuthToastIfNeeded:(NSString *)message {
    if (message.length == 0) return;

    dispatch_async(dispatch_get_main_queue(), ^{
        NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
        BOOL sameMessage = [self.lastAuthToastMessage isEqualToString:message];
        if (sameMessage && (now - self.lastAuthToastTimestamp) < kTLWAuthToastThrottleInterval) {
            return;
        }

        self.lastAuthToastMessage = [message copy];
        self.lastAuthToastTimestamp = now;
        [TLWToast show:message];
    });
}

- (void)tl_forceLogoutAndNotifyWithMessage:(nullable NSString *)message {
    BOOL shouldNotify = NO;
    @synchronized (self) {
        if (!self.isHandlingSessionInvalidation) {
            self.isHandlingSessionInvalidation = YES;
            shouldNotify = YES;
        }
    }

    [self logout];
    [self tl_showAuthToastIfNeeded:(message.length > 0 ? message : @"登录状态已失效，请重新登录")];

    if (!shouldNotify) {
        return;
    }

    dispatch_block_t handler = self.sessionInvalidationHandler;
    if (handler) {
        dispatch_async(dispatch_get_main_queue(), handler);
    }
}

@end
