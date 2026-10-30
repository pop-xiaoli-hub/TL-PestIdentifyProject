#import <XCTest/XCTest.h>
#import "TLWAIMarkdownRenderPatch.h"

@interface TLWAIMarkdownRenderPatchTests : XCTestCase @end
@implementation TLWAIMarkdownRenderPatchTests
- (void)assertPatchFrom:(NSAttributedString *)old to:(NSAttributedString *)next range:(NSRange)range replacement:(NSString *)replacement {
    TLWAIMarkdownRenderPatch *patch = [TLWAIMarkdownRenderPatch patchFrom:old to:next];
    XCTAssertNotNil(patch);
    XCTAssertTrue(NSEqualRanges(patch.oldRenderedRange, range), @"%@ != %@", NSStringFromRange(patch.oldRenderedRange), NSStringFromRange(range));
    XCTAssertEqualObjects(patch.replacement.string, replacement);
    NSMutableAttributedString *applied = [old mutableCopy];
    [applied replaceCharactersInRange:patch.oldRenderedRange withAttributedString:patch.replacement];
    XCTAssertEqualObjects(applied, next);
}
- (void)testAppendPreservesExistingAttributedPrefix {
    NSAttributedString *old = [[NSAttributedString alloc] initWithString:@"原文👩‍🌾" attributes:@{@"style": @1}];
    NSMutableAttributedString *next = [old mutableCopy];
    [next appendAttributedString:[[NSAttributedString alloc] initWithString:@"新增" attributes:@{@"style": @2}]];
    [self assertPatchFrom:old to:next range:NSMakeRange(7, 0) replacement:@"新增"];
}
- (void)testMiddleReplacementPreservesBothUnchangedEnds {
    [self assertPatchFrom:[[NSAttributedString alloc] initWithString:@"前旧后"] to:[[NSAttributedString alloc] initWithString:@"前新的后"] range:NSMakeRange(1, 1) replacement:@"新的"];
}
- (void)testSameVisibleTextStillUpdatesAndRemovesAttributes {
    NSMutableAttributedString *old = [[NSMutableAttributedString alloc] initWithString:@"前重点后"];
    [old addAttributes:@{@"weight": @2, @"link": @"https://example.org"} range:NSMakeRange(1, 2)];
    NSMutableAttributedString *next = [[NSMutableAttributedString alloc] initWithString:@"前重点后"];
    [next addAttribute:@"weight" value:@1 range:NSMakeRange(1, 2)];
    [self assertPatchFrom:old to:next range:NSMakeRange(1, 2) replacement:@"重点"];
}
- (void)testChangedEmojiAndCombiningMarksAreReplacedAsWholeClusters {
    [self assertPatchFrom:[[NSAttributedString alloc] initWithString:@"A👩‍🌾Z"] to:[[NSAttributedString alloc] initWithString:@"A👩‍🔬Z"] range:NSMakeRange(1, 5) replacement:@"👩‍🔬"];
    [self assertPatchFrom:[[NSAttributedString alloc] initWithString:@"Ae\u0301Z"] to:[[NSAttributedString alloc] initWithString:@"Ae\u0300Z"] range:NSMakeRange(1, 2) replacement:@"e\u0300"];
}
- (void)testNewCombiningMarkReplacesPreviouslyRenderedBaseCharacter {
    [self assertPatchFrom:[[NSAttributedString alloc] initWithString:@"Ae"] to:[[NSAttributedString alloc] initWithString:@"Ae\u0301"] range:NSMakeRange(1, 1) replacement:@"e\u0301"];
}
- (void)testInsertionDeletionAndEmptyDocument {
    [self assertPatchFrom:[[NSAttributedString alloc] initWithString:@""] to:[[NSAttributedString alloc] initWithString:@"新"] range:NSMakeRange(0, 0) replacement:@"新"];
    [self assertPatchFrom:[[NSAttributedString alloc] initWithString:@"前删除后"] to:[[NSAttributedString alloc] initWithString:@"前后"] range:NSMakeRange(1, 2) replacement:@""];
    [self assertPatchFrom:[[NSAttributedString alloc] initWithString:@"清空"] to:[[NSAttributedString alloc] initWithString:@""] range:NSMakeRange(0, 2) replacement:@""];
}
- (void)testEqualTextAndAttributesProduceNoPatch {
    NSAttributedString *text = [[NSAttributedString alloc] initWithString:@"保持👩‍🌾" attributes:@{@"style": @1}];
    XCTAssertNil([TLWAIMarkdownRenderPatch patchFrom:text to:[[NSMutableAttributedString alloc] initWithAttributedString:text]]);
}
@end
