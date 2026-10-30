#import <XCTest/XCTest.h>
#import "TLWAIConversationTurn.h"
#import "TLWAIAssistantMessage.h"
#import "TLWAITextPresentation.h"
#import "TLWAIStreamClient.h"

@interface TLWAIRecoveryTurnTransport : TLWAIStreamClient
@end
@implementation TLWAIRecoveryTurnTransport
- (BOOL)supportsJobRecovery { return YES; }
@end

@interface TLWAIRecoveryTurnTests : XCTestCase
@end
@implementation TLWAIRecoveryTurnTests
- (TLWAIConversationTurn *)turn {
    return [[TLWAIConversationTurn alloc] initWithUserMessage:[TLWAIAssistantMessage messageWithRole:TLWAIAssistantMessageRoleUser text:@"question"]
        assistantMessage:[TLWAIAssistantMessage messageWithRole:TLWAIAssistantMessageRoleAssistant text:@""]];
}
- (void)testResumedTurnRetainsDurablePrefixBeforeNewMetadata {
    TLWAIAssistantMessage *assistant = [TLWAIAssistantMessage messageWithRole:TLWAIAssistantMessageRoleAssistant text:@"已保存👩🏽‍🌾"];
    assistant.recoveryCheckpoint = @{@"clientRequestId":@"stable-client", @"text":@"已保存👩🏽‍🌾"};
    TLWAIConversationTurn *turn = [[TLWAIConversationTurn alloc] initWithUserMessage:[TLWAIAssistantMessage messageWithRole:TLWAIAssistantMessageRoleUser text:@"question"] assistantMessage:assistant];
    [turn beginConnection];
    [turn appendDelta:@"新尾部" generation:turn.generation];
    [turn finishWithState:TLWAIConversationTurnStateIncomplete];
    XCTAssertEqualObjects(turn.planAccumulated, @"已保存👩🏽‍🌾新尾部");
    XCTAssertEqualObjects(turn.clientRequestId, @"stable-client");
}
- (void)testRunningSnapshotDoesNotPrematurelyCloseMarkdownFence {
    TLWAIConversationTurn *turn = [self turn];
    [turn beginConnection];
    [turn restoreReceivedPlan:@"```objc\nlet" generation:turn.generation];
    [turn appendDelta:@" x\n**literal**" generation:turn.generation];
    [turn flushAllPendingDelta];
    XCTAssertEqualObjects(turn.textPresentation.visibleText, @"```objc\nlet x\n**literal**");
    XCTAssertFalse(turn.textPresentation.hasHeldTail);
    [turn appendDelta:@"\n```\n" generation:turn.generation];
    [turn finishWithState:TLWAIConversationTurnStateCompleted];
    XCTAssertEqualObjects(turn.planAccumulated, @"```objc\nlet x\n**literal**\n```\n");
    XCTAssertEqualObjects(turn.textPresentation.visibleText, @"```objc\nlet x\n**literal**\n```\n");
}
- (void)testJobAuthRefreshKeepsVisibleAndUnpaintedReceivedText {
    TLWAIConversationTurn *turn = [self turn];
    [turn beginConnection];
    NSUInteger previous = turn.generation;
    turn.streamClient = [TLWAIRecoveryTurnTransport new];
    [turn appendDelta:@"A👩🏽‍🌾B" generation:previous];
    [turn consumePendingWithBudget:1];
    XCTAssertTrue([turn prepareAuthRefresh]);
    XCTAssertEqualObjects(turn.planAccumulated, @"A");
    XCTAssertEqualObjects(turn.pendingDelta, @"👩🏽‍🌾B");
    [turn beginConnection];
    [turn appendDelta:@"旧连接" generation:previous];
    [turn appendDelta:@"C" generation:turn.generation];
    [turn finishWithState:TLWAIConversationTurnStateIncomplete];
    XCTAssertEqualObjects(turn.planAccumulated, @"A👩🏽‍🌾BC");
    XCTAssertEqual(turn.retryCount, 1u);
}
- (void)testRecoveryCallbackCannotReviveTerminalTurn {
    TLWAIConversationTurn *turn = [self turn];
    [turn beginConnection];
    NSUInteger generation = turn.generation;
    [turn setRecovering:YES generation:generation];
    XCTAssertEqual(turn.state, TLWAIConversationTurnStateRecovering);
    [turn appendDelta:@"retained" generation:generation];
    [turn finishWithState:TLWAIConversationTurnStateCancelled];
    [turn setRecovering:YES generation:generation];
    XCTAssertEqual(turn.state, TLWAIConversationTurnStateCancelled);
    XCTAssertEqualObjects(turn.planAccumulated, @"retained");
}
@end
