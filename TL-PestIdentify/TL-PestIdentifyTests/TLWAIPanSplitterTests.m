#import <XCTest/XCTest.h>
#import "TLWAIPanSplitter.h"
@interface TLWAIPanSplitterTests : XCTestCase @end
@implementation TLWAIPanSplitterTests
- (void)testTopBottomAndMidpointConserveFingerDisplacement {
    TLWAIPanSplit top = TLWAISplitPan(0, 50, 12, 0, 100, 0, 1000);
    XCTAssertEqual(top.innerOffset, 0); XCTAssertEqual(top.outerTranslation, 12); XCTAssertEqual(top.outerOffset, 38);
    TLWAIPanSplit bottom = TLWAISplitPan(100, 50, -8, 0, 100, 0, 1000);
    XCTAssertEqual(bottom.innerOffset, 100); XCTAssertEqual(bottom.outerOffset, 58); XCTAssertEqual(bottom.outerTranslation, -8);
    TLWAIPanSplit middle = TLWAISplitPan(50, 50, 12, 0, 100, 0, 1000);
    XCTAssertEqual(middle.innerOffset, 38); XCTAssertEqual(middle.outerOffset, 50); XCTAssertEqual(middle.outerTranslation, 0);
    TLWAIPanSplit edge = TLWAISplitPan(0, 0, 12, 0, 100, 0, 1000);
    XCTAssertEqual(edge.innerOffset, 0); XCTAssertEqual(edge.outerOffset, 0); XCTAssertEqual(edge.unconsumedTranslation, 12);
}
@end
