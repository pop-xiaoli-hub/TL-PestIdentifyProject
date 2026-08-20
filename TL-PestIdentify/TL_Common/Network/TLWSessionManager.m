//
//  TLWSessionManager.m
//  TL-PestIdentify
//

#import "TLWSessionManager.h"
#import "TLWDBManager.h"
#import "TLWToast.h"
#import <AgriPestClient/AGApiClient.h>
#import <AgriPestClient/AGServiceCode.h>
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
@property (nonatomic, strong) NSMutableArray<dispatch_block_t> *pendingRefreshFailureBlocks;
@property (nonatomic, assign) BOOL isRefreshing;
@property (nonatomic, assign) BOOL isHandlingSessionInvalidation;
@property (nonatomic, assign) NSTimeInterval lastAuthToastTimestamp;
@property (nonatomic, copy, nullable) NSString *lastAuthToastMessage;

//  这是一个会话版本号，用于避免旧回调污染新会话
@property (nonatomic, assign) NSUInteger authStateVersion;

- (void)tl_fetchProfileWithCompletion:(nullable void(^)(AGUserProfileDto * _Nullable profile))completion
                         didRetryAuth:(BOOL)didRetryAuth;
- (void)tl_showAuthToastIfNeeded:(NSString *)message;
- (void)tl_forceLogoutAndNotifyWithMessage:(nullable NSString *)message;
- (nullable NSNumber *)tl_serviceCodeFromError:(nullable NSError *)error;
- (nullable NSString *)tl_serverMessageFromError:(nullable NSError *)error;
- (NSInteger)tl_httpStatusCodeFromError:(nullable NSError *)error;

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
//从keychain中，按照account读取一条通用秘码记录，并将取出的二进制数据按照UTF-8解码为NSString字符串
+ (nullable NSString *)_keychainLoadForAccount:(NSString *)account {
  //构造传给SecItemCopyMathcing的查询条件
    NSDictionary *query = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService: kKeychainService,
        (__bridge id)kSecAttrAccount: account,
        (__bridge id)kSecReturnData: @YES,//返回原原始的二进制数据
        (__bridge id)kSecMatchLimit: (__bridge id)kSecMatchLimitOne,//限制只返回一条数据
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
        _pendingRefreshFailureBlocks = [NSMutableArray array];
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
                                            error:error
                                       retryBlock:^{
                    NSLog(@"[Profile] retry fetch after refresh");
                    [self tl_fetchProfileWithCompletion:completion didRetryAuth:YES];
                }]) {
                return;
            }

            if (didRetryAuth && [self shouldAttemptTokenRefreshForCode:output.code error:error]) {
                [self invalidateSessionWithMessage:@"登录状态恢复失败，可能该账号已在其他设备登录，请重新登录"];
                if (completion) completion(nil);
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
        self.isRefreshing = NO;
        [self.pendingRetryBlocks removeAllObjects];
        [self.pendingRefreshFailureBlocks removeAllObjects];
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
    return [self shouldAttemptTokenRefreshForCode:code error:nil];
}

- (BOOL)shouldAttemptTokenRefreshForCode:(NSNumber *)code error:(NSError *)error {
    NSInteger responseCode = code.integerValue;
    if (responseCode == 401 || responseCode == AGServiceCodeInvalidTokenOrTokenExpired) {
        return YES;
    }

    NSInteger errorServiceCode = [self tl_serviceCodeFromError:error].integerValue;
    if (errorServiceCode == 401 || errorServiceCode == AGServiceCodeInvalidTokenOrTokenExpired) {
        return YES;
    }

    return [self tl_httpStatusCodeFromError:error] == 401;
}

- (BOOL)handleAuthFailureForCode:(NSNumber *)code
                         message:(NSString *)message
                      retryBlock:(nullable void(^)(void))retryBlock {
    return [self handleAuthFailureForCode:code
                                  message:message
                                    error:nil
                               retryBlock:retryBlock];
}

- (BOOL)handleAuthFailureForCode:(NSNumber *)code
                         message:(NSString *)message
                           error:(NSError *)error
                      retryBlock:(nullable void(^)(void))retryBlock {
    if (![self shouldAttemptTokenRefreshForCode:code error:error]) {
        return NO;
    }

    NSNumber *errorServiceCode = [self tl_serviceCodeFromError:error];
    NSInteger httpStatus = [self tl_httpStatusCodeFromError:error];
    NSString *effectiveMessage = message.length > 0 ? message : [self tl_serverMessageFromError:error];
    NSLog(@"[Auth] response considered expired: code=%@ errorCode=%@ http=%ld userId=%ld message=%@",
          code ?: @"<nil>",
          errorServiceCode ?: @"<nil>",
          (long)httpStatus,
          (long)self.userId,
          effectiveMessage ?: @"<empty>");
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
    NSNumber *errorServiceCode = [self tl_serviceCodeFromError:error];
    NSInteger effectiveCode = code.integerValue;
    if (effectiveCode == 0) effectiveCode = errorServiceCode.integerValue;
    NSInteger httpStatus = [self tl_httpStatusCodeFromError:error];
    NSString *effectiveMessage = serverMessage.length > 0 ? serverMessage : [self tl_serverMessageFromError:error];
    if (effectiveCode == 401
        || effectiveCode == AGServiceCodeInvalidTokenOrTokenExpired
        || httpStatus == 401) {
        return @"登录状态异常，请重新登录";
    }
    if (effectiveCode == 403
        || effectiveCode == AGServiceCodeAccessDenied
        || httpStatus == 403) {
        return effectiveMessage.length > 0 ? effectiveMessage : @"当前账号没有权限访问该内容";
    }
    if (effectiveMessage.length > 0) {
        return effectiveMessage;
    }
    if (error.localizedDescription.length > 0) {
        return error.localizedDescription;
    }
    return defaultMessage;
}

- (void)handleUnauthorizedWithRetry:(nullable void(^)(void))retryBlock {
    [self handleUnauthorizedWithRetry:retryBlock failure:nil];
}

- (void)handleUnauthorizedWithRetry:(nullable void(^)(void))retryBlock
                            failure:(nullable void(^)(void))failureBlock {
    NSString *refreshToken = nil;
    NSUInteger requestVersion = 0;
    BOOL shouldStartRefresh = NO;
    BOOL shouldForceLogout = NO;
    NSString *logoutMessage = nil;
    NSArray<dispatch_block_t> *failureBlocks = nil;

    @synchronized (self) {
        if (retryBlock) {
            [self.pendingRetryBlocks addObject:[retryBlock copy]];
        }
        if (failureBlock) {
            [self.pendingRefreshFailureBlocks addObject:[failureBlock copy]];
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
            failureBlocks = [self.pendingRefreshFailureBlocks copy];
            [self.pendingRetryBlocks removeAllObjects];
            [self.pendingRefreshFailureBlocks removeAllObjects];
        } else {
            self.isRefreshing = YES;
            requestVersion = self.authStateVersion;
            shouldStartRefresh = YES;
        }
    }

    if (shouldForceLogout) {
        for (dispatch_block_t block in failureBlocks) {
            block();
        }
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
                    [self.pendingRefreshFailureBlocks removeAllObjects];
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
                        [self.pendingRefreshFailureBlocks removeAllObjects];
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
                NSArray<dispatch_block_t> *refreshFailureBlocks = nil;
                @synchronized (self) {
                    refreshFailureBlocks = [self.pendingRefreshFailureBlocks copy];
                    [self.pendingRetryBlocks removeAllObjects];
                    [self.pendingRefreshFailureBlocks removeAllObjects];
                }
                for (dispatch_block_t block in refreshFailureBlocks) {
                    block();
                }
                [self tl_forceLogoutAndNotifyWithMessage:@"登录状态恢复失败，可能该账号已在其他设备登录，请重新登录"];
                return;
            }

            NSLog(@"[Token] refresh failed, force logout: code=%@ message=%@ error=%@",
                  output.code ?: @"<nil>",
                  output.message ?: @"<empty>",
                  error.localizedDescription ?: @"<nil>");
            NSArray<dispatch_block_t> *refreshFailureBlocks = nil;
            @synchronized (self) {
                refreshFailureBlocks = [self.pendingRefreshFailureBlocks copy];
                [self.pendingRetryBlocks removeAllObjects];
                [self.pendingRefreshFailureBlocks removeAllObjects];
            }
            for (dispatch_block_t block in refreshFailureBlocks) {
                block();
            }
            [self tl_forceLogoutAndNotifyWithMessage:@"登录状态恢复失败，可能该账号已在其他设备登录，请重新登录"];
        });
    }];
}

#pragma mark - Private

- (nullable id)tl_responsePayloadFromError:(nullable NSError *)error {
    NSError *currentError = error;
    for (NSInteger depth = 0; currentError && depth < 8; depth += 1) {
        id payload = currentError.userInfo[AGResponseObjectErrorKey];
        if (!payload) {
            payload = currentError.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey];
        }
        if (payload) return payload;

        NSError *underlying = currentError.userInfo[NSUnderlyingErrorKey];
        if (![underlying isKindOfClass:[NSError class]] || underlying == currentError) break;
        currentError = underlying;
    }
    return nil;
}

- (nullable NSDictionary *)tl_responseDictionaryFromError:(nullable NSError *)error {
    id payload = [self tl_responsePayloadFromError:error];
    if ([payload isKindOfClass:[NSDictionary class]]) {
        return payload;
    }
    if (![payload isKindOfClass:[NSData class]]) {
        return nil;
    }

    id json = [NSJSONSerialization JSONObjectWithData:payload options:0 error:nil];
    return [json isKindOfClass:[NSDictionary class]] ? json : nil;
}

- (nullable NSNumber *)tl_serviceCodeFromError:(nullable NSError *)error {
    id value = [self tl_responseDictionaryFromError:error][@"code"];
    if ([value isKindOfClass:[NSNumber class]]) return value;
    if ([value isKindOfClass:[NSString class]] && [value length] > 0) {
        return @([value integerValue]);
    }
    return nil;
}

- (nullable NSString *)tl_serverMessageFromError:(nullable NSError *)error {
    NSDictionary *payload = [self tl_responseDictionaryFromError:error];
    for (NSString *key in @[@"message", @"msg", @"error"]) {
        id value = payload[key];
        if ([value isKindOfClass:[NSString class]] && [value length] > 0) return value;
    }
    return nil;
}

- (NSInteger)tl_httpStatusCodeFromError:(nullable NSError *)error {
    NSError *currentError = error;
    for (NSInteger depth = 0; currentError && depth < 8; depth += 1) {
        id response = currentError.userInfo[AFNetworkingOperationFailingURLResponseErrorKey];
        if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
            return ((NSHTTPURLResponse *)response).statusCode;
        }

        NSError *underlying = currentError.userInfo[NSUnderlyingErrorKey];
        if (![underlying isKindOfClass:[NSError class]] || underlying == currentError) break;
        currentError = underlying;
    }
    return 0;
}

- (void)tl_restoreSessionFromPersistence {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSString *token = [TLWSessionManager _keychainLoadForAccount:kKeychainAccessToken];//获取当前账号的accessToken
    NSString *refreshToken = [TLWSessionManager _keychainLoadForAccount:kKeychainRefreshToken];//获取刷新token
    NSInteger persistedUserId = [ud integerForKey:kUserIdKey];

    BOOL hasCompleteSession = token.length > 0 && refreshToken.length > 0 && persistedUserId > 0;//判断会话是否完整
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
