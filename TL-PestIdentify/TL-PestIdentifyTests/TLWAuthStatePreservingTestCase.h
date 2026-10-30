#import <XCTest/XCTest.h>

/// 仅测试目标：鉴权用例清理存储前在内存保留现场，tearDown 后恢复；不记录凭据。
@interface TLWAuthStatePreservingTestCase : XCTestCase
@end
