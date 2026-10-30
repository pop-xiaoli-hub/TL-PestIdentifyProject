#import "TLWAuthStatePreservingTestCase.h"
#import <Security/Security.h>

@interface TLWAuthStatePreservationTests : TLWAuthStatePreservingTestCase
@end
@implementation TLWAuthStatePreservationTests
- (void)testDestructiveAuthFixtureRestoresPriorIdentityAndSecret {
    self.continueAfterFailure = NO;
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    [defaults setInteger:47001 forKey:@"TLW_user_id"];
    [defaults setObject:@"state-preservation-fixture" forKey:@"TLW_username"];
    NSMutableDictionary *query = [@{(__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService: @"com.tl.pestidentify.auth",
        (__bridge id)kSecAttrAccount: @"access_token"} mutableCopy];
    SecItemDelete((__bridge CFDictionaryRef)query);
    NSData *fixture = [@"state-preservation-fixture-only" dataUsingEncoding:NSUTF8StringEncoding];
    query[(__bridge id)kSecValueData] = fixture;
    XCTAssertEqual(SecItemAdd((__bridge CFDictionaryRef)query, NULL), errSecSuccess);
    [query removeObjectForKey:(__bridge id)kSecValueData];
    TLWAuthStatePreservingTestCase *scope = [TLWAuthStatePreservingTestCase new];
    [scope setUp];
    @try {
        [defaults removeObjectForKey:@"TLW_user_id"];
        [defaults setObject:@"temporary-test-user" forKey:@"TLW_username"];
        SecItemDelete((__bridge CFDictionaryRef)query);
    } @finally {
        [scope tearDown];
    }
    XCTAssertEqual([defaults integerForKey:@"TLW_user_id"], 47001);
    XCTAssertTrue([[defaults stringForKey:@"TLW_username"] isEqualToString:@"state-preservation-fixture"]);
    query[(__bridge id)kSecReturnData] = @YES;
    CFTypeRef value = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &value);
    NSData *restored = CFBridgingRelease(value);
    XCTAssertEqual(status, errSecSuccess);
    XCTAssertTrue([restored isEqualToData:fixture], @"Pre-test secret must survive fixture cleanup; values are never logged");
}
@end
