#import <XCTest/XCTest.h>
#import "TLWAIFramePacer.h"
@interface TLWAIFramePacerTests : XCTestCase @end
@implementation TLWAIFramePacerTests
- (void)testPacerCatchesUpWithoutConsumingPastBacklog {
    XCTAssertEqual(TLWAIFrameBudget(0), 0u);
    XCTAssertEqual(TLWAIFrameBudget(7), 1u);
    XCTAssertEqual(TLWAIFrameBudget(8), 2u);
    XCTAssertEqual(TLWAIFrameBudget(64), 16u);
    XCTAssertEqual(TLWAIFrameBudget(65), 49u);
    XCTAssertEqual(TLWAIFrameBudget(1024), 1008u);
}
@end
