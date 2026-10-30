#import <XCTest/XCTest.h>
#import "TLWAITextPresentation.h"

@interface TLWAITextPresentationTests : XCTestCase @end
@implementation TLWAITextPresentationTests
- (void)testUnclosedTailExpiresWithoutReceivingAnotherDelta {
    TLWAITextPresentation *presentation = [TLWAITextPresentation new];
    [presentation appendText:@"已显示\n\n`未闭" atTime:1];
    XCTAssertEqualObjects(presentation.visibleText, @"已显示\n\n");
    XCTAssertFalse([presentation releaseExpiredAtTime:1.20]);
    XCTAssertTrue([presentation releaseExpiredAtTime:1.25]);
    XCTAssertEqualObjects(presentation.visibleText, @"已显示\n\n`未闭");
}
- (void)testLinkDestinationAcrossChunksIsHeldUntilClosed {
    TLWAITextPresentation *presentation = [TLWAITextPresentation new];
    [presentation appendText:@"前[标签" atTime:0];
    [presentation appendText:@"](https://example.org" atTime:0.1];
    XCTAssertEqualObjects(presentation.visibleText, @"前");
    [presentation appendText:@")后" atTime:0.15];
    XCTAssertEqualObjects(presentation.visibleText, @"前[标签](https://example.org)后");
}
- (void)testHoldbackBoundCountsComposedClustersAndNewlineReleases {
    TLWAITextPresentation *presentation = [TLWAITextPresentation new];
    NSMutableString *tail = [NSMutableString stringWithString:@"**"];
    for (NSUInteger index = 0; index < 62; index++) [tail appendString:@"👨‍👩‍👧‍👦"];
    [presentation appendText:tail atTime:0];
    XCTAssertTrue(presentation.hasHeldTail);
    XCTAssertEqualObjects(presentation.visibleText, @"");
    [presentation appendText:@"👨‍👩‍👧‍👦" atTime:0.1];
    XCTAssertFalse(presentation.hasHeldTail);
    XCTAssertEqualObjects(presentation.visibleText, presentation.source);
    [presentation reset];
    [presentation appendText:@"x**未闭\n" atTime:0];
    XCTAssertEqualObjects(presentation.visibleText, @"x**未闭\n");
}
- (void)testFenceContentsAreReleasedLiterallyBeforeFenceCloses {
    TLWAITextPresentation *presentation = [TLWAITextPresentation new];
    [presentation appendText:@"```objc" atTime:0];
    XCTAssertEqualObjects(presentation.visibleText, @"```objc");
    [presentation appendText:@"\n# literal\n\n**x**\n" atTime:0.1];
    XCTAssertFalse(presentation.hasHeldTail);
    XCTAssertEqualObjects(presentation.visibleText, @"```objc\n# literal\n\n**x**\n");
}
- (void)testLongerFenceIgnoresShorterClosingRunAndTerminalKeepsTail {
    TLWAITextPresentation *presentation = [TLWAITextPresentation new];
    [presentation appendText:@"````\ncode\n```\n**literal**\n" atTime:0];
    XCTAssertEqualObjects(presentation.visibleText, @"````\ncode\n```\n**literal**\n");
    [presentation appendText:@"````\n后[未闭" atTime:0.1];
    XCTAssertEqualObjects(presentation.visibleText, @"````\ncode\n```\n**literal**\n````\n后");
    [presentation finish];
    XCTAssertEqualObjects(presentation.visibleText, @"````\ncode\n```\n**literal**\n````\n后[未闭");
}
- (void)testExpiredBoldCanFinishLaterWithoutDuplicatingOrDroppingSource {
    TLWAITextPresentation *presentation = [TLWAITextPresentation new];
    [presentation appendText:@"建议 **减少浇水" atTime:0];
    XCTAssertTrue([presentation releaseExpiredAtTime:0.25]);
    XCTAssertEqualObjects(presentation.visibleText, @"建议 **减少浇水");
    [presentation appendText:@"**，保持通风。" atTime:0.3];
    [presentation finish];
    XCTAssertEqualObjects(presentation.source, @"建议 **减少浇水**，保持通风。");
    XCTAssertEqualObjects(presentation.visibleText, @"建议 **减少浇水**，保持通风。");
}
@end
