//
//  TLWAISSEParserTests.m
//  TL-PestIdentifyTests
//
//  覆盖：分块边界、UTF-8 多字节截断、CRLF/CR 空行、多行 data、注释、
//        无事件名帧、EOF 残帧丢弃、reset 复位。
//

#import <XCTest/XCTest.h>
#import "TLWAISSEParser.h"

@interface TLWAISSEParserTests : XCTestCase
@property (nonatomic, strong) TLWAISSEParser *parser;
@property (nonatomic, strong) NSMutableArray<NSArray<NSString *> *> *events; // [name, data]
@property (nonatomic, strong) NSMutableArray<NSString *> *comments;
@end

@implementation TLWAISSEParserTests

- (void)setUp {
    [super setUp];
    self.parser = [[TLWAISSEParser alloc] init];
    self.events = [NSMutableArray array];
    self.comments = [NSMutableArray array];
    __weak typeof(self) weakSelf = self;
    self.parser.onEvent = ^(NSString *eventName, NSString *data) {
        [weakSelf.events addObject:@[(eventName ?: @""), (data ?: @"")]];
    };
    self.parser.onComment = ^(NSString *comment) {
        [weakSelf.comments addObject:comment ?: @""];
    };
}

- (void)appendString:(NSString *)string {
    [self.parser appendData:[string dataUsingEncoding:NSUTF8StringEncoding]];
}

#pragma mark - 基本解析

- (void)testSingleEventWithSingleDataLine {
    [self appendString:@"event: done\ndata: {}\n\n"];
    XCTAssertEqual(self.events.count, 1);
    XCTAssertEqualObjects(self.events[0][0], @"done");
    XCTAssertEqualObjects(self.events[0][1], @"{}");
}

- (void)testMultiLineDataJoinedWithNewline {
    [self appendString:@"event: plan\ndata: 第一行\ndata: 第二行\n\n"];
    XCTAssertEqual(self.events.count, 1);
    XCTAssertEqualObjects(self.events[0][0], @"plan");
    XCTAssertEqualObjects(self.events[0][1], @"第一行\n第二行");
}

- (void)testDataColonWithoutSpace {
    [self appendString:@"event: plan_delta\ndata:文本不带空格\n\n"];
    XCTAssertEqual(self.events.count, 1);
    XCTAssertEqualObjects(self.events[0][1], @"文本不带空格");
}

#pragma mark - 分块边界

- (void)testEventSplitAcrossChunks {
    [self appendString:@"event: plan_delta\n"];
    XCTAssertEqual(self.events.count, 0);
    [self appendString:@"data: 一段增量\n"];
    XCTAssertEqual(self.events.count, 0);
    [self appendString:@"\n"];
    XCTAssertEqual(self.events.count, 1);
    XCTAssertEqualObjects(self.events[0][0], @"plan_delta");
    XCTAssertEqualObjects(self.events[0][1], @"一段增量");
}

- (void)testEmptyDataLinesPreserveSeparatingNewline {
    [self appendString:@"event: plan_delta\ndata:\ndata: 下一行\n\n"];
    XCTAssertEqual(self.events.count, 1);
    XCTAssertEqualObjects(self.events[0][1], @"\n下一行");
}

- (void)testBlankLineSplitAcrossChunks {
    [self appendString:@"event: done\ndata: x"];
    XCTAssertEqual(self.events.count, 0);
    [self appendString:@"\n"];
    XCTAssertEqual(self.events.count, 0);
    [self appendString:@"\n"];
    XCTAssertEqual(self.events.count, 1);
}

- (void)testMultipleEventsInOneChunk {
    [self appendString:@"event: disease\ndata: [{\"name\":\"a\"}]\n\nevent: done\ndata: {}\n\n"];
    XCTAssertEqual(self.events.count, 2);
    XCTAssertEqualObjects(self.events[0][0], @"disease");
    XCTAssertEqualObjects(self.events[1][0], @"done");
}

#pragma mark - UTF-8 多字节截断

- (void)testUTF8MultibyteCharacterSplitAcrossChunks {
    // "病" 的 UTF-8 为 3 字节；分块在字节中间切断不应丢字。
    [self appendString:@"event: plan_delta\ndata: "];
    NSData *raw = [@"病" dataUsingEncoding:NSUTF8StringEncoding];
    XCTAssertEqual(raw.length, 3);
    [self.parser appendData:[raw subdataWithRange:NSMakeRange(0, 1)]];
    [self.parser appendData:[raw subdataWithRange:NSMakeRange(1, 1)]];
    [self.parser appendData:[raw subdataWithRange:NSMakeRange(2, 1)]];
    [self appendString:@"\n\n"];

    XCTAssertEqual(self.events.count, 1);
    XCTAssertEqualObjects(self.events[0][1], @"病");
}

- (void)testEmojiInDeltaSurvivesChunking {
    NSString *expected = @"✅⚠️👍";
    [self appendString:@"event: plan_delta\ndata: "];
    NSData *raw = [expected dataUsingEncoding:NSUTF8StringEncoding];
    for (NSUInteger i = 0; i < raw.length; i++) {
        [self.parser appendData:[raw subdataWithRange:NSMakeRange(i, 1)]];
    }
    [self appendString:@"\n\n"];

    XCTAssertEqual(self.events.count, 1);
    XCTAssertEqualObjects(self.events[0][1], expected);
}

- (void)testChineseDeltaSplitInsideCharacter {
    NSString *expected = @"番茄早疫病防治";
    [self appendString:@"event: plan_delta\ndata: "];
    NSData *raw = [expected dataUsingEncoding:NSUTF8StringEncoding];
    NSUInteger half = raw.length / 2;
    [self.parser appendData:[raw subdataWithRange:NSMakeRange(0, half)]];
    [self.parser appendData:[raw subdataWithRange:NSMakeRange(half, raw.length - half)]];
    [self appendString:@"\n\n"];

    XCTAssertEqual(self.events.count, 1);
    XCTAssertEqualObjects(self.events[0][1], expected);
}

#pragma mark - CRLF / CR 空行

- (void)testCRLFBlankLineSeparatesEvents {
    [self appendString:@"event: plan_delta\r\ndata: a\r\n\r\nevent: done\r\ndata: {}\r\n\r\n"];
    XCTAssertEqual(self.events.count, 2);
    XCTAssertEqualObjects(self.events[0][1], @"a");
    XCTAssertEqualObjects(self.events[1][0], @"done");
}

- (void)testCRBlankLineSeparatesEvents {
    [self appendString:@"event: done\rdata: {}\r\r"];
    XCTAssertEqual(self.events.count, 1);
    XCTAssertEqualObjects(self.events[0][0], @"done");
}

#pragma mark - 注释与无事件名帧

- (void)testCommentLinesAreIgnored {
    [self appendString:@": keepalive\n\nevent: done\ndata: {}\n\n"];
    XCTAssertEqual(self.events.count, 1);
    XCTAssertEqualObjects(self.events[0][0], @"done");
}

- (void)testPureCommentFrameInvokesHeartbeatCallback {
    [self appendString:@": keepalive\n\n"];

    XCTAssertEqual(self.events.count, 0);
    XCTAssertEqual(self.comments.count, 1);
    XCTAssertEqualObjects(self.comments.firstObject, @"keepalive");
}

- (void)testCommentHeartbeatWaitsForCompleteFrameAndJoinsLines {
    [self appendString:@": keepalive\n: tick\n"];
    XCTAssertEqual(self.comments.count, 0);

    [self appendString:@"\n"];

    XCTAssertEqual(self.comments.count, 1);
    XCTAssertEqualObjects(self.comments.firstObject, @"keepalive\ntick");
    XCTAssertEqual(self.events.count, 0);
}

- (void)testEmptyCommentFrameDoesNotInvokeHeartbeatCallback {
    [self appendString:@":\n\n"];
    XCTAssertEqual(self.comments.count, 1);
    XCTAssertEqualObjects(self.comments.firstObject, @"");
}

- (void)testCommentFrameWithBusinessDataDoesNotInvokeHeartbeatCallback {
    [self appendString:@": keepalive\nevent: plan_delta\ndata: text\n\n"];

    XCTAssertEqual(self.events.count, 1);
    XCTAssertEqual(self.comments.count, 0);
}

- (void)testFrameWithoutEventNameIsSkipped {
    [self appendString:@"data: 独白\n\n"];
    XCTAssertEqual(self.events.count, 0);
}

- (void)testMetadataBOMAndColonlessFieldsSurviveBytewiseCRLF {
    __block NSUInteger metadataUpdates = 0;
    self.parser.onMetadata = ^(NSString *eventID, NSNumber *retry) { metadataUpdates++; };
    NSData *bytes = [@"\uFEFFid: 42\r\nretry: 3000\r\nevent: meta\r\ndata: {}\r\n\r\nid\r\nretry: -2\r\nevent: done\r\ndata: {}\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding];
    for (NSUInteger index = 0; index < bytes.length; index++) [self.parser appendData:[bytes subdataWithRange:NSMakeRange(index, 1)]];
    XCTAssertEqualObjects(self.parser.lastEventID, @"");
    XCTAssertEqualObjects(self.parser.retryMilliseconds, @3000);
    XCTAssertEqual(metadataUpdates, 3u);
    XCTAssertEqualObjects(self.events, (@[@[@"meta", @"{}"], @[@"done", @"{}"]]));
}

- (void)testUnframedBufferOverflowFailsOnceAndResetRestoresParsing {
    __block NSUInteger overflows = 0;
    self.parser.onBufferOverflow = ^{ overflows++; };
    [self.parser appendData:[NSData dataWithBytesNoCopy:calloc(1024 * 1024 + 1, 1) length:1024 * 1024 + 1 freeWhenDone:YES]];
    [self appendString:@"event: done\ndata: {}\n\n"];
    XCTAssertEqual(overflows, 1u);
    XCTAssertEqual(self.events.count, 0u);
    XCTAssertEqual(self.parser.bufferedByteCount, 0u);
    [self.parser reset];
    [self appendString:@"event: done\ndata: {}\n\n"];
    XCTAssertEqualObjects(self.events, (@[@[@"done", @"{}"]]));
}

#pragma mark - EOF 残帧

- (void)testUnfinishedFrameDroppedOnFinish {
    [self appendString:@"event: plan_delta\ndata: 完整事件\n\nevent: done\ndata: {"];
    XCTAssertEqual(self.events.count, 1);

    NSUInteger leftover = [self.parser finish];
    XCTAssertGreaterThan(leftover, 0);
    XCTAssertEqual(self.events.count, 1);   // 残帧不应派发 done
}

- (void)testFinishWithEmptyBufferReturnsZero {
    [self appendString:@"event: done\ndata: {}\n\n"];
    XCTAssertEqual([self.parser finish], 0);
}

#pragma mark - reset

- (void)testResetClearsBuffer {
    [self appendString:@"event: plan_delta\ndata: 半截"];
    [self.parser reset];
    XCTAssertEqual(self.parser.bufferedByteCount, 0);
    [self appendString:@"\n\n"];
    XCTAssertEqual(self.events.count, 0);
}

@end
