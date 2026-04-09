//
//  TLWAuthSessionIntegrationTests.m
//  TL-PestIdentifyTests
//

#import <XCTest/XCTest.h>
#import <Security/Security.h>

@interface TLWSDKManager : NSObject
+ (instancetype)shared;
- (BOOL)isLoggedIn;
- (void)logout;
- (void)handleUnauthorizedWithRetry:(void(^)(void))retryBlock;
- (nullable NSString *)refreshToken;
@property (nonatomic, assign) NSInteger userId;
@property (nonatomic, copy, nullable) NSString *username;
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

@end
