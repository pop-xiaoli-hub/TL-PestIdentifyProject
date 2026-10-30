#import "TLWAuthStatePreservingTestCase.h"
#import <Security/Security.h>
#import <objc/message.h>
#import "TLWDBManager.h"

static id TLWAuthTestSend(id object, NSString *selector) {
    return ((id (*)(id, SEL))objc_msgSend)(object, NSSelectorFromString(selector));
}

@interface TLWAuthStatePreservingTestCase ()
@property (nonatomic, copy) NSDictionary *savedDefaults;
@property (nonatomic, copy) NSArray<NSDictionary *> *savedSecrets;
@property (nonatomic, copy) NSArray<NSDictionary *> *savedRuntimeTokens;
@property (nonatomic, strong) id savedSessionManager;
@property (nonatomic, strong) NSNumber *savedUserIdentifier;
@end

@implementation TLWAuthStatePreservingTestCase
- (void)setUp {
    [super setUp];
    NSMutableDictionary *defaults = [NSMutableDictionary dictionary];
    for (NSString *key in @[@"TLW_access_token", @"TLW_refresh_token", @"TLW_user_id", @"TLW_username", @"TLW_generated_password"]) {
        defaults[key] = [NSUserDefaults.standardUserDefaults objectForKey:key] ?: NSNull.null;
    }
    self.savedDefaults = defaults;
    NSMutableArray *secrets = [NSMutableArray array];
    for (NSString *account in @[@"access_token", @"refresh_token", @"auth_session"]) {
        NSDictionary *query = @{(__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
            (__bridge id)kSecAttrService: @"com.tl.pestidentify.auth", (__bridge id)kSecAttrAccount: account,
            (__bridge id)kSecReturnData: @YES, (__bridge id)kSecReturnAttributes: @YES};
        CFTypeRef result = NULL;
        OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &result);
        NSDictionary *item = CFBridgingRelease(result);
        if (status != errSecSuccess && status != errSecItemNotFound) {
            [NSException raise:@"TLWAuthTestSnapshotFailed" format:@"Cannot preserve login state; status=%d. Auth tests will not clear storage.", (int)status];
        }
        [secrets addObject:@{@"account": account, @"data": item[(__bridge id)kSecValueData] ?: NSNull.null,
            @"accessible": item[(__bridge id)kSecAttrAccessible] ?: (__bridge id)kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly}];
    }
    self.savedSecrets = secrets;
    NSMutableArray *runtime = [NSMutableArray array];
    id defaultConfig = TLWAuthTestSend(NSClassFromString(@"AGDefaultConfiguration"), @"sharedConfig");
    id apiConfig = TLWAuthTestSend(TLWAuthTestSend(NSClassFromString(@"AGApiClient"), @"sharedClient"), @"configuration");
    for (id config in @[defaultConfig ?: NSNull.null, apiConfig ?: NSNull.null]) {
        if (config != NSNull.null) {
            // 显式调用 accessToken，不能用 KVC 读到 SDK 的 getAccessToken（它会添加 Bearer）。
            [runtime addObject:@{@"config": config, @"token": TLWAuthTestSend(config, @"accessToken") ?: NSNull.null}];
        }
    }
    self.savedRuntimeTokens = runtime;
    self.savedSessionManager = TLWAuthTestSend(TLWAuthTestSend(NSClassFromString(@"TLWSDKManager"), @"shared"), @"sessionManager");
    self.savedUserIdentifier = [self.savedSessionManager valueForKey:@"userId"];
}

- (void)tearDown {
    for (NSString *key in self.savedDefaults) {
        id value = self.savedDefaults[key];
        if (value == NSNull.null) [NSUserDefaults.standardUserDefaults removeObjectForKey:key];
        else [NSUserDefaults.standardUserDefaults setObject:value forKey:key];
    }
    for (NSDictionary *secret in self.savedSecrets) {
        NSMutableDictionary *query = [@{(__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
            (__bridge id)kSecAttrService: @"com.tl.pestidentify.auth", (__bridge id)kSecAttrAccount: secret[@"account"]} mutableCopy];
        SecItemDelete((__bridge CFDictionaryRef)query);
        if (secret[@"data"] != NSNull.null) {
            query[(__bridge id)kSecValueData] = secret[@"data"];
            query[(__bridge id)kSecAttrAccessible] = secret[@"accessible"];
            XCTAssertEqual(SecItemAdd((__bridge CFDictionaryRef)query, NULL), errSecSuccess, @"Failed to restore pre-test login storage");
        }
    }
    for (NSDictionary *entry in self.savedRuntimeTokens) {
        [entry[@"config"] setValue:entry[@"token"] == NSNull.null ? nil : entry[@"token"] forKey:@"accessToken"];
    }
    if (self.savedUserIdentifier && ![[self.savedSessionManager valueForKey:@"userId"] isEqual:self.savedUserIdentifier]) {
        [self.savedSessionManager setValue:self.savedUserIdentifier forKey:@"userId"];
        [[TLWDBManager shared] reopenForCurrentUser];
    }
    self.savedDefaults = nil;
    self.savedSecrets = nil;
    self.savedRuntimeTokens = nil;
    self.savedSessionManager = nil;
    [super tearDown];
}
@end
