#import <XCTest/XCTest.h>
#import "TLWAIIncrementalMarkdown.h"
@interface TLWAIIncrementalMarkdownTests : XCTestCase @end
@implementation TLWAIIncrementalMarkdownTests
- (void)testClosedParagraphRemainsSeparateWhileTailGrows {
    TLWAIIncrementalMarkdown *parser = [TLWAIIncrementalMarkdown new];
    [parser appendText:@"已闭合\n\n"];
    [parser appendText:@"后续段落"];
    XCTAssertEqual(parser.closedBlocks.count, 1u);
    XCTAssertEqualObjects(parser.closedBlocks.firstObject.source, @"已闭合\n\n");
    [parser finish];
    XCTAssertEqualObjects(parser.closedBlocks.lastObject.source, @"后续段落");
}
- (void)testFenceIsCodeBeforeClosingAndKeepsLiteralSyntax {
    TLWAIIncrementalMarkdown *parser = [TLWAIIncrementalMarkdown new];
    [parser appendText:@"```objc"];
    XCTAssertEqual(parser.openBlockKind, TLWAITextBlockKindCode);
    [parser appendText:@"\n# literal\n\n**x**\n```\n"];
    XCTAssertEqual(parser.closedBlocks.lastObject.kind, TLWAITextBlockKindCode);
    XCTAssertEqualObjects(parser.closedBlocks.lastObject.source, @"```objc\n# literal\n\n**x**\n```\n");
}
- (void)testTableOnlyPromotesAfterDelimiterRow {
    TLWAIIncrementalMarkdown *parser = [TLWAIIncrementalMarkdown new];
    [parser appendText:@"|a|b|\n"];
    XCTAssertEqual(parser.openBlockKind, TLWAITextBlockKindParagraph);
    [parser appendText:@"|---|:---:|\n"];
    XCTAssertEqual(parser.openBlockKind, TLWAITextBlockKindTable);
    [parser appendText:@"|1|2|\n\n"];
    XCTAssertEqual(parser.closedBlocks.lastObject.kind, TLWAITextBlockKindTable);
}
- (void)testTableDoesNotConsumeAdjacentParagraphsWithoutBlankLines {
    TLWAIIncrementalMarkdown *parser = [TLWAIIncrementalMarkdown new];
    [parser appendText:@"说明段落\n|A|B|\n"];
    [parser appendText:@"|---|---|\n|1|2|\n结束段落\n"];
    [parser finish];
    NSArray<TLWAITextBlock *> *blocks = parser.closedBlocks;
    XCTAssertEqual(blocks.count, 3u);
    XCTAssertEqualObjects(blocks[0].source, @"说明段落\n");
    XCTAssertEqual(blocks[1].kind, TLWAITextBlockKindTable);
    XCTAssertEqualObjects(blocks[1].source, @"|A|B|\n|---|---|\n|1|2|\n");
    XCTAssertEqual(blocks[2].kind, TLWAITextBlockKindParagraph);
    XCTAssertEqualObjects(blocks[2].source, @"结束段落\n");
}
- (void)testFenceLengthAndTerminalFlush {
    TLWAIIncrementalMarkdown *parser = [TLWAIIncrementalMarkdown new];
    [parser appendText:@"````\ncode\n```\n"];
    XCTAssertEqual(parser.openBlockKind, TLWAITextBlockKindCode);
    XCTAssertEqual(parser.closedBlocks.count, 0u);
    [parser appendText:@"````\n后[未闭"]; [parser finish];
    XCTAssertEqual(parser.closedBlocks.firstObject.kind, TLWAITextBlockKindCode);
    XCTAssertEqualObjects(parser.closedBlocks.lastObject.source, @"后[未闭");
}
- (void)testHeadingLineEndsPreviousParagraphWithoutBlankLine {
    TLWAIIncrementalMarkdown *parser = [TLWAIIncrementalMarkdown new];
    [parser appendText:@"前面正文\n## 处理"];
    [parser appendText:@"建议\n后面正文"];
    NSArray<TLWAITextBlock *> *blocks = parser.closedBlocks;
    XCTAssertEqual(blocks.count, 2u);
    if (blocks.count != 2) return;
    XCTAssertEqualObjects(blocks[0].source, @"前面正文\n");
    XCTAssertEqualObjects(blocks[1].source, @"## 处理建议\n");
    XCTAssertEqualObjects(parser.source, @"前面正文\n## 处理建议\n后面正文");
    [parser finish];
    XCTAssertEqualObjects(parser.closedBlocks.lastObject.source, @"后面正文");
}
- (void)testWhitespaceOnlyLineClosesParagraphButHashInsideTextDoesNot {
    TLWAIIncrementalMarkdown *parser = [TLWAIIncrementalMarkdown new];
    [parser appendText:@"正文 # 不是标题\n下一行\n \t\n尾部"];
    XCTAssertEqual(parser.closedBlocks.count, 1u);
    XCTAssertEqualObjects(parser.closedBlocks.firstObject.source, @"正文 # 不是标题\n下一行\n \t\n");
    [parser finish];
    XCTAssertEqualObjects(parser.closedBlocks.lastObject.source, @"尾部");
}
@end
