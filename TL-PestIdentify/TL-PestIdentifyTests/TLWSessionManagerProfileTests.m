#import <XCTest/XCTest.h>
#import <Security/Security.h>

extern NSString * const TLWProfileDidUpdateNotification;

@interface TLWSessionManager : NSObject
- (instancetype)initWithAPIService:(id)api;
- (BOOL)saveAuthResponse:(id)auth;
- (void)fetchProfileWithCompletion:(void(^)(id profile))completion;
- (void)logout;
@property (nonatomic, assign) NSInteger userId;
@property (nonatomic, copy) NSString *username;
@property (nonatomic, strong, readonly) id cachedProfile;
@end

static NSString * const kProfileAuthService = @"com.tl.pestidentify.auth";
static NSString * const kProfileAccessTokenAccount = @"access_token";
static NSString * const kProfileRefreshTokenAccount = @"refresh_token";
static NSString * const kProfileUserIdKey = @"TLW_user_id";
static NSString * const kProfileUsernameKey = @"TLW_username";
static NSString * const kProfileGeneratedPasswordKey = @"TLW_generated_password";
static NSString * const kProfileLegacyTokenKey = @"TLW_access_token";
static NSString * const kProfileLegacyRefreshKey = @"TLW_refresh_token";

@interface TLWFakeProfileAuthResponse : NSObject
@property (nonatomic, copy) NSString *token;
@property (nonatomic, copy) NSString *refreshToken;
@property (nonatomic, strong) NSNumber *userId;
@property (nonatomic, copy) NSString *username;
@property (nonatomic, copy) NSString *generatedPassword;
@end

@implementation TLWFakeProfileAuthResponse
@end

@interface TLWFakeProfileResult : NSObject
@property (nonatomic, strong) NSNumber *code;
@property (nonatomic, strong) id data;
@property (nonatomic, copy) NSString *message;
@end

@implementation TLWFakeProfileResult
@end

typedef void (^TLWProfileCompletion)(id output, NSError *error);

@interface TLWFakeProfileApiService : NSObject
@property (nonatomic, copy) void (^onGetProfile)(TLWProfileCompletion completion);
@end

@implementation TLWFakeProfileApiService

- (id)getCurrentUserProfileWithCompletionHandler:(TLWProfileCompletion)handler {
    if (self.onGetProfile) {
        self.onGetProfile([handler copy]);
    }
    return nil;
}

@end

@interface TLWSessionManagerProfileTests : XCTestCase
@property (nonatomic, strong) TLWSessionManager *manager;
@property (nonatomic, strong) TLWFakeProfileApiService *mockApi;
@end

@implementation TLWSessionManagerProfileTests

- (void)setUp {
    [super setUp];
    self.continueAfterFailure = NO;
    [self tl_clearPersistedAuthState];
    self.mockApi = [[TLWFakeProfileApiService alloc] init];
    self.manager = [[TLWSessionManager alloc] initWithAPIService:self.mockApi];
    [self.manager logout];
}

- (void)tearDown {
    [self.manager logout];
    [self tl_clearPersistedAuthState];
    [super tearDown];
}

- (void)testFetchProfileIgnoresStaleSuccessCallbackAfterSessionChange {
    XCTAssertTrue([self.manager saveAuthResponse:[self tl_authResponseWithToken:@"user_a_access"
                                                                   refreshToken:@"user_a_refresh"
                                                                         userId:1001
                                                                       username:@"user_a"]]);

    __block TLWProfileCompletion capturedCompletion = nil;
    self.mockApi.onGetProfile = ^(TLWProfileCompletion completion) {
        capturedCompletion = [completion copy];
    };

    __block BOOL completionCalled = NO;
    __block NSUInteger notificationCount = 0;
    id observer = [[NSNotificationCenter defaultCenter] addObserverForName:TLWProfileDidUpdateNotification
                                                                    object:nil
                                                                     queue:nil
                                                                usingBlock:^(__unused NSNotification * _Nonnull note) {
        notificationCount += 1;
    }];

    [self.manager fetchProfileWithCompletion:^(__unused id profile) {
        completionCalled = YES;
    }];

    XCTAssertNotNil(capturedCompletion);
    XCTAssertTrue([self.manager saveAuthResponse:[self tl_authResponseWithToken:@"user_b_access"
                                                                   refreshToken:@"user_b_refresh"
                                                                         userId:2002
                                                                       username:@"user_b"]]);

    TLWFakeProfileResult *result = [[TLWFakeProfileResult alloc] init];
    result.code = @200;
    result.data = [NSObject new];
    capturedCompletion(result, nil);

    XCTestExpectation *drainMainQueue = [self expectationWithDescription:@"drain main queue"];
    dispatch_async(dispatch_get_main_queue(), ^{
        [drainMainQueue fulfill];
    });
    [self waitForExpectations:@[drainMainQueue] timeout:1.0];

    [[NSNotificationCenter defaultCenter] removeObserver:observer];

    XCTAssertFalse(completionCalled);
    XCTAssertEqual(notificationCount, 0U);
    XCTAssertNil(self.manager.cachedProfile);
    XCTAssertEqual(self.manager.userId, 2002);
    XCTAssertEqualObjects(self.manager.username, @"user_b");
}

#pragma mark - Helpers

- (TLWFakeProfileAuthResponse *)tl_authResponseWithToken:(NSString *)token
                                            refreshToken:(NSString *)refreshToken
                                                  userId:(NSInteger)userId
                                                username:(NSString *)username {
    TLWFakeProfileAuthResponse *auth = [[TLWFakeProfileAuthResponse alloc] init];
    auth.token = token;
    auth.refreshToken = refreshToken;
    auth.userId = @(userId);
    auth.username = username;
    auth.generatedPassword = nil;
    return auth;
}

- (void)tl_clearPersistedAuthState {
    [self tl_deleteKeychainValueForAccount:kProfileAccessTokenAccount];
    [self tl_deleteKeychainValueForAccount:kProfileRefreshTokenAccount];

    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud removeObjectForKey:kProfileLegacyTokenKey];
    [ud removeObjectForKey:kProfileLegacyRefreshKey];
    [ud removeObjectForKey:kProfileUserIdKey];
    [ud removeObjectForKey:kProfileUsernameKey];
    [ud removeObjectForKey:kProfileGeneratedPasswordKey];
}

- (void)tl_deleteKeychainValueForAccount:(NSString *)account {
    NSDictionary *query = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService: kProfileAuthService,
        (__bridge id)kSecAttrAccount: account,
    };
    SecItemDelete((__bridge CFDictionaryRef)query);
}

@end
