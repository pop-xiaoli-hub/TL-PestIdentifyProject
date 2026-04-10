//
//  TLWAuthSessionIntegrationTests.m
//  TL-PestIdentifyTests
//

#import <XCTest/XCTest.h>
#import <Security/Security.h>
#import <objc/message.h>
#import "TLWDBManager.h"

@interface TLWSDKManager : NSObject
+ (instancetype)shared;
- (BOOL)isLoggedIn;
- (void)logout;
- (void)handleUnauthorizedWithRetry:(void(^)(void))retryBlock;
- (BOOL)saveAuthResponse:(id)auth;
- (nullable NSString *)refreshToken;
@property (nonatomic, assign) NSInteger userId;
@property (nonatomic, copy, nullable) NSString *username;
@property (nonatomic, copy, nullable, readonly) NSString *generatedPassword;
@end

static NSString * const kAuthService = @"com.tl.pestidentify.auth";
static NSString * const kAccessTokenAccount = @"access_token";
static NSString * const kRefreshTokenAccount = @"refresh_token";

static NSString * const kUserIdKey = @"TLW_user_id";
static NSString * const kUsernameKey = @"TLW_username";
static NSString * const kGeneratedPasswordKey = @"TLW_generated_password";
static NSString * const kLegacyTokenKey = @"TLW_access_token";
static NSString * const kLegacyRefreshKey = @"TLW_refresh_token";

@interface TLWFakeAuthResponse : NSObject
@property (nonatomic, copy) NSString *token;
@property (nonatomic, copy) NSString *refreshToken;
@property (nonatomic, strong) NSNumber *userId;
@property (nonatomic, copy) NSString *username;
@property (nonatomic, copy) NSString *generatedPassword;
@end

@implementation TLWFakeAuthResponse
@end

@interface TLWFakeResultAuthResponse : NSObject
@property (nonatomic, strong) NSNumber *code;
@property (nonatomic, strong) id data;
@end

@implementation TLWFakeResultAuthResponse
@end

typedef void (^TLWRefreshCompletion)(id output, NSError *error);

@interface TLWMockApiService : NSObject
@property (nonatomic, assign) NSInteger refreshCallCount;
@property (nonatomic, copy) void (^onRefreshCalled)(TLWRefreshCompletion completion);
@end

@implementation TLWMockApiService

- (id)refreshWithRefreshTokenRequest:(id)refreshTokenRequest
                   completionHandler:(TLWRefreshCompletion)handler {
    (void)refreshTokenRequest;
    @synchronized (self) {
        self.refreshCallCount += 1;
    }
    if (self.onRefreshCalled) {
        self.onRefreshCalled([handler copy]);
    }
    return nil;
}

@end

@interface TLWAuthSessionIntegrationTests : XCTestCase
@property (nonatomic, strong) TLWSDKManager *manager;
@end

@implementation TLWAuthSessionIntegrationTests

- (void)setUp {
    [super setUp];
    self.continueAfterFailure = NO;
    self.manager = [TLWSDKManager shared];
    [self tl_clearPersistedAuthState];
    [self.manager logout];
    [self.manager setValue:[NSObject new] forKey:@"api"];
    [self.manager setValue:[NSMutableArray array] forKey:@"pendingRetryBlocks"];
    [self.manager setValue:@(NO) forKey:@"isRefreshing"];
}

- (void)tearDown {
    [self.manager setValue:[NSObject new] forKey:@"api"];
    [self.manager logout];
    [self tl_clearPersistedAuthState];
    [super tearDown];
}

- (void)testColdStartRestoresLoginStateFromPersistence {
    [self tl_saveKeychainValue:@"persisted_access_token" account:kAccessTokenAccount];
    [self tl_saveKeychainValue:@"persisted_refresh_token" account:kRefreshTokenAccount];

    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud setInteger:9527 forKey:kUserIdKey];
    [ud setObject:@"tester_restart" forKey:kUsernameKey];

    TLWSDKManager *coldStartManager = [[TLWSDKManager alloc] init];

    XCTAssertTrue([coldStartManager isLoggedIn]);
    XCTAssertEqual(coldStartManager.userId, 9527);
    XCTAssertEqualObjects(coldStartManager.username, @"tester_restart");
    XCTAssertEqualObjects([coldStartManager refreshToken], @"persisted_refresh_token");
}

- (void)testColdStartWithoutAccessTokenDoesNotHydrateStaleIdentity {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud setInteger:4242 forKey:kUserIdKey];
    [ud setObject:@"ghost_user" forKey:kUsernameKey];

    TLWSDKManager *coldStartManager = [[TLWSDKManager alloc] init];

    XCTAssertFalse([coldStartManager isLoggedIn]);
    XCTAssertEqual(coldStartManager.userId, 0);
    XCTAssertNil(coldStartManager.username);
    XCTAssertNil([ud objectForKey:kUserIdKey]);
    XCTAssertNil([ud stringForKey:kUsernameKey]);
    [self tl_assertRuntimeAccessTokenCleared];
}

- (void)testColdStartWithoutRefreshTokenClearsStaleSessionArtifacts {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [self tl_saveKeychainValue:@"orphan_access_token" account:kAccessTokenAccount];
    [ud setInteger:5252 forKey:kUserIdKey];
    [ud setObject:@"ghost_user" forKey:kUsernameKey];

    TLWSDKManager *coldStartManager = [[TLWSDKManager alloc] init];

    XCTAssertFalse([coldStartManager isLoggedIn]);
    XCTAssertEqual(coldStartManager.userId, 0);
    XCTAssertNil(coldStartManager.username);
    XCTAssertNil([self tl_keychainValueForAccount:kAccessTokenAccount]);
    XCTAssertNil([self tl_keychainValueForAccount:kRefreshTokenAccount]);
    XCTAssertNil([ud objectForKey:kUserIdKey]);
    XCTAssertNil([ud stringForKey:kUsernameKey]);
    [self tl_assertRuntimeAccessTokenCleared];
}

- (void)testColdStartWithoutUserIdClearsStaleSessionArtifacts {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [self tl_saveKeychainValue:@"persisted_access_token" account:kAccessTokenAccount];
    [self tl_saveKeychainValue:@"persisted_refresh_token" account:kRefreshTokenAccount];
    [ud setObject:@"ghost_user" forKey:kUsernameKey];

    TLWSDKManager *coldStartManager = [[TLWSDKManager alloc] init];

    XCTAssertFalse([coldStartManager isLoggedIn]);
    XCTAssertEqual(coldStartManager.userId, 0);
    XCTAssertNil(coldStartManager.username);
    XCTAssertNil([self tl_keychainValueForAccount:kAccessTokenAccount]);
    XCTAssertNil([self tl_keychainValueForAccount:kRefreshTokenAccount]);
    XCTAssertNil([ud objectForKey:kUserIdKey]);
    XCTAssertNil([ud stringForKey:kUsernameKey]);
    [self tl_assertRuntimeAccessTokenCleared];
}

- (void)testColdStartWithLegacyPersistedTokensClearsStaleSessionArtifacts {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud setObject:@"legacy_access_token" forKey:kLegacyTokenKey];
    [ud setObject:@"legacy_refresh_token" forKey:kLegacyRefreshKey];
    [ud setInteger:8080 forKey:kUserIdKey];
    [ud setObject:@"legacy_user" forKey:kUsernameKey];

    TLWSDKManager *coldStartManager = [[TLWSDKManager alloc] init];

    XCTAssertFalse([coldStartManager isLoggedIn]);
    XCTAssertEqual(coldStartManager.userId, 0);
    XCTAssertNil(coldStartManager.username);
    XCTAssertNil([coldStartManager refreshToken]);
    XCTAssertNil([self tl_keychainValueForAccount:kAccessTokenAccount]);
    XCTAssertNil([self tl_keychainValueForAccount:kRefreshTokenAccount]);
    XCTAssertNil([ud stringForKey:kLegacyTokenKey]);
    XCTAssertNil([ud stringForKey:kLegacyRefreshKey]);
    XCTAssertNil([ud objectForKey:kUserIdKey]);
    XCTAssertNil([ud stringForKey:kUsernameKey]);
    [self tl_assertRuntimeAccessTokenCleared];
}

- (void)testSaveAuthResponseClearsStaleOptionalIdentityFields {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud setObject:@"stale_name" forKey:kUsernameKey];
    [ud setObject:@"stale_generated_password" forKey:kGeneratedPasswordKey];

    TLWFakeAuthResponse *auth = [self tl_authResponseWithToken:@"fresh_access"
                                                  refreshToken:@"fresh_refresh"
                                                        userId:7001
                                                      username:nil
                                             generatedPassword:nil];
    BOOL saved = [self.manager saveAuthResponse:auth];

    XCTAssertTrue(saved);
    XCTAssertTrue([self.manager isLoggedIn]);
    XCTAssertEqual(self.manager.userId, 7001);
    XCTAssertNil(self.manager.username);
    XCTAssertNil(self.manager.generatedPassword);
    XCTAssertEqualObjects([self.manager refreshToken], @"fresh_refresh");
    XCTAssertNil([ud stringForKey:kUsernameKey]);
    XCTAssertNil([ud stringForKey:kGeneratedPasswordKey]);
}

- (void)testSaveAuthResponseRejectsIncompletePayload {
    // 无 refreshToken
    TLWFakeAuthResponse *noRefresh = [self tl_authResponseWithToken:@"access"
                                                        refreshToken:nil
                                                              userId:7002
                                                            username:@"user"
                                                   generatedPassword:nil];
    XCTAssertFalse([self.manager saveAuthResponse:noRefresh]);
    XCTAssertFalse([self.manager isLoggedIn]);
    XCTAssertEqual(self.manager.userId, 0);
    XCTAssertNil(self.manager.username);
    XCTAssertNil([self tl_keychainValueForAccount:kAccessTokenAccount]);
    XCTAssertNil([self tl_keychainValueForAccount:kRefreshTokenAccount]);
    [self tl_assertRuntimeAccessTokenCleared];

    // 无 userId
    TLWFakeAuthResponse *noUserId = [self tl_authResponseWithToken:@"access"
                                                       refreshToken:@"refresh"
                                                             userId:0
                                                           username:@"user"
                                                  generatedPassword:nil];
    XCTAssertFalse([self.manager saveAuthResponse:noUserId]);
    XCTAssertFalse([self.manager isLoggedIn]);
    XCTAssertEqual(self.manager.userId, 0);
    XCTAssertNil(self.manager.username);
    XCTAssertNil([self tl_keychainValueForAccount:kAccessTokenAccount]);
    XCTAssertNil([self tl_keychainValueForAccount:kRefreshTokenAccount]);
    [self tl_assertRuntimeAccessTokenCleared];

    // 无 token
    TLWFakeAuthResponse *noToken = [self tl_authResponseWithToken:nil
                                                      refreshToken:@"refresh"
                                                            userId:7003
                                                          username:@"user"
                                                 generatedPassword:nil];
    XCTAssertFalse([self.manager saveAuthResponse:noToken]);
    XCTAssertFalse([self.manager isLoggedIn]);
    XCTAssertEqual(self.manager.userId, 0);
    XCTAssertNil(self.manager.username);
    XCTAssertNil([self tl_keychainValueForAccount:kAccessTokenAccount]);
    XCTAssertNil([self tl_keychainValueForAccount:kRefreshTokenAccount]);
    [self tl_assertRuntimeAccessTokenCleared];
}

- (void)testLogoutClearsPersistedIdentityAndTokens {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    TLWFakeAuthResponse *auth = [self tl_authResponseWithToken:@"logout_access"
                                                  refreshToken:@"logout_refresh"
                                                        userId:9009
                                                      username:@"logout_user"
                                             generatedPassword:@"logout_password"];
    [self.manager saveAuthResponse:auth];

    XCTAssertTrue([self.manager isLoggedIn]);
    XCTAssertEqualObjects([self.manager refreshToken], @"logout_refresh");
    XCTAssertEqualObjects(self.manager.generatedPassword, @"logout_password");

    [self.manager logout];

    XCTAssertFalse([self.manager isLoggedIn]);
    XCTAssertEqual(self.manager.userId, 0);
    XCTAssertNil(self.manager.username);
    XCTAssertNil(self.manager.generatedPassword);
    XCTAssertNil([self.manager refreshToken]);
    XCTAssertNil([ud objectForKey:kUserIdKey]);
    XCTAssertNil([ud stringForKey:kUsernameKey]);
    XCTAssertNil([ud stringForKey:kGeneratedPasswordKey]);
}

- (void)testUnauthorizedWithoutRefreshTokenLogsOutAndDropsRetry {
    // 模拟 refreshToken 意外丢失：手动写 accessToken + userId，但不写 refreshToken
    [self tl_saveKeychainValue:@"orphan_access" account:kAccessTokenAccount];
    [[NSUserDefaults standardUserDefaults] setInteger:1337 forKey:kUserIdKey];

    // 重新初始化让 init 读到这些值
    TLWSDKManager *mgr = [[TLWSDKManager alloc] init];
    [mgr setValue:[NSObject new] forKey:@"api"];
    [mgr setValue:[NSMutableArray array] forKey:@"pendingRetryBlocks"];
    [mgr setValue:@(NO) forKey:@"isRefreshing"];

    __block BOOL retryExecuted = NO;
    [mgr handleUnauthorizedWithRetry:^{
        retryExecuted = YES;
    }];

    XCTAssertFalse([mgr isLoggedIn]);
    XCTAssertNil([mgr refreshToken]);
    XCTAssertFalse(retryExecuted);
}

- (void)testConcurrentUnauthorizedRequestsOnlyTriggerSingleRefresh {
    [self tl_saveKeychainValue:@"refresh_for_concurrency" account:kRefreshTokenAccount];

    TLWMockApiService *mockApi = [[TLWMockApiService alloc] init];
    [self.manager setValue:mockApi forKey:@"api"];

    XCTestExpectation *refreshStarted = [self expectationWithDescription:@"refresh started"];
    XCTestExpectation *allRetriesExecuted = [self expectationWithDescription:@"all retries executed"];

    __block TLWRefreshCompletion refreshCompletion = nil;
    __block NSInteger retriedCount = 0;
    NSInteger totalRetryBlocks = 20;

    mockApi.onRefreshCalled = ^(TLWRefreshCompletion completion) {
        @synchronized (self) {
            if (!refreshCompletion) {
                refreshCompletion = [completion copy];
                [refreshStarted fulfill];
            }
        }
    };

    dispatch_queue_t queue = dispatch_queue_create("com.tlw.tests.refresh.concurrent", DISPATCH_QUEUE_CONCURRENT);
    dispatch_apply((size_t)totalRetryBlocks, queue, ^(size_t idx) {
        (void)idx;
        [self.manager handleUnauthorizedWithRetry:^{
            @synchronized (self) {
                retriedCount += 1;
                if (retriedCount == totalRetryBlocks) {
                    [allRetriesExecuted fulfill];
                }
            }
        }];
    });

    [self waitForExpectations:@[refreshStarted] timeout:2.0];
    XCTAssertNotNil(refreshCompletion);
    XCTAssertEqual(mockApi.refreshCallCount, 1);

    TLWFakeAuthResponse *auth = [[TLWFakeAuthResponse alloc] init];
    auth.token = @"new_access_after_refresh";
    auth.refreshToken = @"new_refresh_after_refresh";
    auth.userId = @1001;
    auth.username = @"retry_user";

    TLWFakeResultAuthResponse *result = [[TLWFakeResultAuthResponse alloc] init];
    result.code = @200;
    result.data = auth;

    refreshCompletion(result, nil);

    [self waitForExpectations:@[allRetriesExecuted] timeout:2.0];
    XCTAssertEqual(mockApi.refreshCallCount, 1);
    XCTAssertEqual(retriedCount, totalRetryBlocks);
    XCTAssertTrue([self.manager isLoggedIn]);
    XCTAssertEqualObjects([self.manager refreshToken], @"new_refresh_after_refresh");
}

- (void)testRefreshSuccessClearsMissingOptionalIdentityFields {
    TLWFakeAuthResponse *initialAuth = [self tl_authResponseWithToken:@"initial_access"
                                                         refreshToken:@"initial_refresh"
                                                               userId:5150
                                                             username:@"stale_after_refresh"
                                                    generatedPassword:@"stale_generated_password"];
    XCTAssertTrue([self.manager saveAuthResponse:initialAuth]);

    TLWMockApiService *mockApi = [[TLWMockApiService alloc] init];
    [self.manager setValue:mockApi forKey:@"api"];

    XCTestExpectation *refreshStarted = [self expectationWithDescription:@"refresh started"];
    XCTestExpectation *retryExecuted = [self expectationWithDescription:@"retry executed"];

    __block TLWRefreshCompletion refreshCompletion = nil;
    __block BOOL didRetry = NO;

    mockApi.onRefreshCalled = ^(TLWRefreshCompletion completion) {
        refreshCompletion = [completion copy];
        [refreshStarted fulfill];
    };

    [self.manager handleUnauthorizedWithRetry:^{
        didRetry = YES;
        [retryExecuted fulfill];
    }];

    [self waitForExpectations:@[refreshStarted] timeout:2.0];
    XCTAssertNotNil(refreshCompletion);

    TLWFakeAuthResponse *refreshedAuth = [self tl_authResponseWithToken:@"refreshed_access"
                                                           refreshToken:@"refreshed_refresh"
                                                                 userId:5150
                                                               username:nil
                                                      generatedPassword:nil];
    TLWFakeResultAuthResponse *result = [[TLWFakeResultAuthResponse alloc] init];
    result.code = @200;
    result.data = refreshedAuth;

    refreshCompletion(result, nil);

    [self waitForExpectations:@[retryExecuted] timeout:2.0];
    XCTAssertTrue(didRetry);
    XCTAssertEqualObjects([self.manager refreshToken], @"refreshed_refresh");
    XCTAssertNil(self.manager.username);
    XCTAssertNil(self.manager.generatedPassword);
    XCTAssertNil([[NSUserDefaults standardUserDefaults] stringForKey:kUsernameKey]);
    XCTAssertNil([[NSUserDefaults standardUserDefaults] stringForKey:kGeneratedPasswordKey]);
}

- (void)testRefreshRejectsIncompleteAuthPayloadAndLogsOut {
    TLWFakeAuthResponse *initialAuth = [self tl_authResponseWithToken:@"initial_access"
                                                         refreshToken:@"initial_refresh"
                                                               userId:5151
                                                             username:@"refresh_user"
                                                    generatedPassword:nil];
    XCTAssertTrue([self.manager saveAuthResponse:initialAuth]);

    TLWMockApiService *mockApi = [[TLWMockApiService alloc] init];
    [self.manager setValue:mockApi forKey:@"api"];

    XCTestExpectation *refreshStarted = [self expectationWithDescription:@"refresh started"];
    XCTestExpectation *callbackHandled = [self expectationWithDescription:@"callback handled"];

    __block TLWRefreshCompletion refreshCompletion = nil;
    __block BOOL didRetry = NO;

    mockApi.onRefreshCalled = ^(TLWRefreshCompletion completion) {
        refreshCompletion = [completion copy];
        [refreshStarted fulfill];
    };

    [self.manager handleUnauthorizedWithRetry:^{
        didRetry = YES;
    }];

    [self waitForExpectations:@[refreshStarted] timeout:2.0];
    XCTAssertNotNil(refreshCompletion);

    TLWFakeAuthResponse *invalidRefreshAuth = [self tl_authResponseWithToken:@"refreshed_access_without_refresh"
                                                                refreshToken:nil
                                                                      userId:5151
                                                                    username:@"refresh_user"
                                                           generatedPassword:nil];
    TLWFakeResultAuthResponse *result = [[TLWFakeResultAuthResponse alloc] init];
    result.code = @200;
    result.data = invalidRefreshAuth;

    refreshCompletion(result, nil);

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [callbackHandled fulfill];
    });
    [self waitForExpectations:@[callbackHandled] timeout:2.0];

    XCTAssertFalse(didRetry);
    XCTAssertFalse([self.manager isLoggedIn]);
    XCTAssertEqual(self.manager.userId, 0);
    XCTAssertNil(self.manager.username);
    XCTAssertNil([self.manager refreshToken]);
    XCTAssertNil([self tl_keychainValueForAccount:kAccessTokenAccount]);
    XCTAssertNil([self tl_keychainValueForAccount:kRefreshTokenAccount]);
    [self tl_assertRuntimeAccessTokenCleared];
}

- (void)testLogoutDuringInFlightRefreshDoesNotRestoreSession {
    [self tl_saveKeychainValue:@"refresh_for_logout_race" account:kRefreshTokenAccount];

    TLWMockApiService *mockApi = [[TLWMockApiService alloc] init];
    [self.manager setValue:mockApi forKey:@"api"];

    XCTestExpectation *refreshStarted = [self expectationWithDescription:@"refresh started"];
    XCTestExpectation *callbackHandled = [self expectationWithDescription:@"stale refresh callback handled"];

    __block TLWRefreshCompletion refreshCompletion = nil;
    __block BOOL retryBlockExecuted = NO;

    mockApi.onRefreshCalled = ^(TLWRefreshCompletion completion) {
        @synchronized (self) {
            if (!refreshCompletion) {
                refreshCompletion = [completion copy];
                [refreshStarted fulfill];
            }
        }
    };

    [self.manager handleUnauthorizedWithRetry:^{
        retryBlockExecuted = YES;
    }];

    [self waitForExpectations:@[refreshStarted] timeout:2.0];
    XCTAssertEqual(mockApi.refreshCallCount, 1);
    XCTAssertNotNil(refreshCompletion);

    [self.manager logout];

    TLWFakeAuthResponse *auth = [[TLWFakeAuthResponse alloc] init];
    auth.token = @"should_not_restore_access";
    auth.refreshToken = @"should_not_restore_refresh";
    auth.userId = @2002;
    auth.username = @"should_not_restore_user";

    TLWFakeResultAuthResponse *result = [[TLWFakeResultAuthResponse alloc] init];
    result.code = @200;
    result.data = auth;

    refreshCompletion(result, nil);

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [callbackHandled fulfill];
    });
    [self waitForExpectations:@[callbackHandled] timeout:2.0];

    XCTAssertFalse([self.manager isLoggedIn]);
    XCTAssertNil([self.manager refreshToken]);
    XCTAssertFalse(retryBlockExecuted);
}

- (void)testCollectedDatabaseReopensForEachAuthenticatedUser {
    NSInteger userA = 61001;
    NSInteger userB = 61002;
    [self tl_clearCollectedPostsForUserId:userA];
    [self tl_clearCollectedPostsForUserId:userB];

    TLWDBManager *dbManager = [TLWDBManager shared];

    [self.manager saveAuthResponse:[self tl_authResponseWithToken:@"db_access_a"
                                                     refreshToken:@"db_refresh_a"
                                                           userId:userA
                                                         username:@"db_user_a"
                                                generatedPassword:nil]];
    XCTAssertTrue([dbManager upsertCollectedPostFromDto:[self tl_postWithId:@91001 title:@"User A Post"]]);
    XCTAssertEqual(dbManager.fetchAllCollectedPosts.count, 1);

    [self.manager saveAuthResponse:[self tl_authResponseWithToken:@"db_access_b"
                                                     refreshToken:@"db_refresh_b"
                                                           userId:userB
                                                         username:@"db_user_b"
                                                generatedPassword:nil]];
    XCTAssertEqual(dbManager.fetchAllCollectedPosts.count, 0);
    XCTAssertTrue([dbManager upsertCollectedPostFromDto:[self tl_postWithId:@91002 title:@"User B Post"]]);
    XCTAssertEqual(dbManager.fetchAllCollectedPosts.count, 1);

    [self.manager saveAuthResponse:[self tl_authResponseWithToken:@"db_access_a_again"
                                                     refreshToken:@"db_refresh_a_again"
                                                           userId:userA
                                                         username:@"db_user_a"
                                                generatedPassword:nil]];
    XCTAssertEqual(dbManager.fetchAllCollectedPosts.count, 1);

    [dbManager deleteAllCollectedPosts];
    [self.manager saveAuthResponse:[self tl_authResponseWithToken:@"db_access_b_cleanup"
                                                     refreshToken:@"db_refresh_b_cleanup"
                                                           userId:userB
                                                         username:@"db_user_b"
                                                generatedPassword:nil]];
    [dbManager deleteAllCollectedPosts];
}

#pragma mark - Helpers

- (void)tl_clearPersistedAuthState {
    [self tl_deleteKeychainValueForAccount:kAccessTokenAccount];
    [self tl_deleteKeychainValueForAccount:kRefreshTokenAccount];

    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud removeObjectForKey:kLegacyTokenKey];
    [ud removeObjectForKey:kLegacyRefreshKey];
    [ud removeObjectForKey:kUserIdKey];
    [ud removeObjectForKey:kUsernameKey];
    [ud removeObjectForKey:kGeneratedPasswordKey];
}

- (void)tl_saveKeychainValue:(NSString *)value account:(NSString *)account {
    [self tl_deleteKeychainValueForAccount:account];
    NSData *data = [value dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *query = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService: kAuthService,
        (__bridge id)kSecAttrAccount: account,
        (__bridge id)kSecValueData: data,
        (__bridge id)kSecAttrAccessible: (__bridge id)kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
    };
    OSStatus status = SecItemAdd((__bridge CFDictionaryRef)query, NULL);
    XCTAssertEqual(status, errSecSuccess);
}

- (void)tl_deleteKeychainValueForAccount:(NSString *)account {
    NSDictionary *query = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService: kAuthService,
        (__bridge id)kSecAttrAccount: account,
    };
    SecItemDelete((__bridge CFDictionaryRef)query);
}

- (nullable NSString *)tl_keychainValueForAccount:(NSString *)account {
    NSDictionary *query = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService: kAuthService,
        (__bridge id)kSecAttrAccount: account,
        (__bridge id)kSecReturnData: @YES,
        (__bridge id)kSecMatchLimit: (__bridge id)kSecMatchLimitOne,
    };
    CFTypeRef result = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &result);
    if (status != errSecSuccess || !result) {
        return nil;
    }
    NSData *data = (__bridge_transfer NSData *)result;
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

- (nullable NSString *)tl_runtimeAccessToken {
    Class configClass = NSClassFromString(@"AGDefaultConfiguration");
    if (!configClass) {
        return nil;
    }
    SEL sharedConfigSelector = NSSelectorFromString(@"sharedConfig");
    id (*msgSendTyped)(Class, SEL) = (void *)objc_msgSend;
    id config = msgSendTyped(configClass, sharedConfigSelector);
    return [config valueForKey:@"accessToken"];
}

- (void)tl_assertRuntimeAccessTokenCleared {
    XCTAssertEqual([self tl_runtimeAccessToken].length, 0U);
}

- (TLWFakeAuthResponse *)tl_authResponseWithToken:(NSString *)token
                                     refreshToken:(NSString *)refreshToken
                                           userId:(NSInteger)userId
                                         username:(NSString *)username
                                generatedPassword:(NSString *)generatedPassword {
    TLWFakeAuthResponse *auth = [[TLWFakeAuthResponse alloc] init];
    auth.token = token;
    auth.refreshToken = refreshToken;
    auth.userId = @(userId);
    auth.username = username;
    auth.generatedPassword = generatedPassword;
    return auth;
}

- (void)tl_clearCollectedPostsForUserId:(NSInteger)userId {
    self.manager.userId = userId;
    [[TLWDBManager shared] reopenForCurrentUser];
    [[TLWDBManager shared] deleteAllCollectedPosts];
}

- (id)tl_postWithId:(NSNumber *)postId title:(NSString *)title {
    id post = [[NSClassFromString(@"AGPostResponseDto") alloc] init];
    [post setValue:postId forKey:@"_id"];
    [post setValue:title forKey:@"title"];
    [post setValue:@[] forKey:@"images"];
    [post setValue:@"author" forKey:@"authorName"];
    [post setValue:@"avatar" forKey:@"authorAvatar"];
    [post setValue:@1 forKey:@"favoriteCount"];
    return post;
}

@end
