#import <XCTest/XCTest.h>
#import "TLWAIKeyboardGeometry.h"
@interface TLWAIKeyboardGeometryTests : XCTestCase @end
@implementation TLWAIKeyboardGeometryTests
- (void)testOnlyDockedKeyboardOccludesComposer {
    CGRect bounds = CGRectMake(0, 0, 400, 800);
    XCTAssertEqual(TLWAIKeyboardOverlap(CGRectMake(0, 500, 400, 300), bounds), 300);
    XCTAssertEqual(TLWAIKeyboardOverlap(CGRectMake(100, 400, 200, 200), bounds), 0);
    XCTAssertEqual(TLWAIKeyboardOverlap(CGRectMake(0, 800, 400, 300), bounds), 0);
    XCTAssertEqual(TLWAIKeyboardOverlap(CGRectMake(0, 250, 800, 150), CGRectMake(0, 0, 800, 400)), 150);
}
@end
