#import <XCTest/XCTest.h>

#import "../TL_AIAssistant/Models/TLWAIAssistantMessage.h"
#import "../TL_AIAssistant/Models/TLWAIConversationTurn.h"
#import "../TL_AIAssistant/Views/TLWAIAssistantMessageListView.h"

@interface TLWAIConversationFlowTests : XCTestCase
@end

@implementation TLWAIConversationFlowTests

- (TLWAIConversationTurn *)turn {
    return [[TLWAIConversationTurn alloc] initWithUserMessage:
        [TLWAIAssistantMessage messageWithRole:TLWAIAssistantMessageRoleUser text:@"问题"]
        assistantMessage:[TLWAIAssistantMessage messageWithRole:TLWAIAssistantMessageRoleAssistant text:@""]];
}

- (void)testStopDrainsParsedTailAndRejectsLateGeneration {
    TLWAIConversationTurn *turn = [self turn];
    XCTAssertTrue([turn beginConnection]);
    NSUInteger generation = turn.generation;
    [turn appendDelta:@"头👨‍👩‍👧‍👦尾" generation:generation];
    XCTAssertEqualObjects([turn consumePendingWithBudget:2], @"头👨‍👩‍👧‍👦");
    XCTAssertTrue([turn finishWithState:TLWAIConversationTurnStateCancelled]);
    [turn appendDelta:@"迟到" generation:generation];
    XCTAssertEqualObjects(turn.planAccumulated, @"头👨‍👩‍👧‍👦尾");
    XCTAssertEqualObjects(turn.pendingDelta, @"");
    XCTAssertEqual(turn.state, TLWAIConversationTurnStateCancelled);
    XCTAssertFalse([turn beginConnection]);
    XCTAssertFalse([turn finishWithState:TLWAIConversationTurnStateCompleted]);
}

- (void)testAuthRebuildClearsOldBodyAndRejectsOldConnectionWithoutSecondRetry {
    TLWAIConversationTurn *turn = [self turn];
    [turn beginConnection];
    NSUInteger oldGeneration = turn.generation;
    [turn appendDelta:@"旧正文" generation:oldGeneration];
    [turn consumePendingWithBudget:1];
    XCTAssertTrue([turn prepareAuthRefresh]);
    XCTAssertFalse([turn acceptsIdentifier:turn.identifier generation:oldGeneration]);
    XCTAssertTrue([turn beginConnection]);
    [turn appendDelta:@"旧连接迟到" generation:oldGeneration];
    [turn appendDelta:@"新正文" generation:turn.generation];
    XCTAssertFalse([turn prepareAuthRefresh]);
    XCTAssertTrue([turn finishWithState:TLWAIConversationTurnStateFailed]);
    XCTAssertEqualObjects(turn.planAccumulated, @"新正文");
    XCTAssertEqual(turn.retryCount, 1u);
    XCTAssertEqual(turn.assistantMessage.status, TLWAIAssistantMessageStatusFailed);
}

- (void)testUploadMustConnectBeforeApplyingBusinessFrame {
    TLWAIConversationTurn *turn = [self turn];
    XCTAssertTrue([turn beginUpload]);
    [turn appendDelta:@"非法输出" generation:turn.generation];
    XCTAssertEqualObjects(turn.pendingDelta, @"");
    XCTAssertFalse([turn beginUpload]);
    XCTAssertTrue([turn beginConnection]);
    [turn appendDelta:@"增量" generation:turn.generation];
    [turn replacePlan:@"最终快照" generation:turn.generation];
    [turn finishWithState:TLWAIConversationTurnStateIncomplete];
    XCTAssertEqualObjects(turn.planAccumulated, @"最终快照");
    XCTAssertEqual(turn.lastAppliedSeq, 2u);
}


- (void)testMessageListKeepsHistoryOffsetUntilUserReturnsToBottom {
    TLWAIAssistantMessageListView *listView = [[TLWAIAssistantMessageListView alloc] initWithFrame:CGRectMake(0, 0, 320, 240)];
    NSMutableArray<TLWAIAssistantMessage *> *messages = [NSMutableArray array];
    for (NSUInteger index = 0; index < 12; index++) {
        NSString *text = [NSString stringWithFormat:@"消息 %lu：这是一段足够长的文本，用于让外层消息列表产生可滚动内容。", (unsigned long)index];
        [messages addObject:[TLWAIAssistantMessage messageWithRole:TLWAIAssistantMessageRoleAssistant text:text]];
    }

    [listView displayMessages:messages];
    [listView layoutIfNeeded];
    [listView scrollToBottomAnimated:NO];
    [listView layoutIfNeeded];

    UITableView *tableView = [listView valueForKey:@"tableView"];
    [tableView.delegate scrollViewWillBeginDragging:tableView];
    [tableView setContentOffset:CGPointMake(0, 0) animated:NO];
    [tableView.delegate scrollViewDidScroll:tableView];
    [tableView.delegate scrollViewDidEndDragging:tableView willDecelerate:NO];

    CGFloat historyOffset = tableView.contentOffset.y;
    TLWAIAssistantMessage *lastMessage = messages.lastObject;
    lastMessage.text = [lastMessage.text stringByAppendingString:@" 新增正文"];
    [listView reloadMessage:lastMessage];
    [listView layoutIfNeeded];

    XCTAssertEqualWithAccuracy(tableView.contentOffset.y, historyOffset, 0.5);

    [listView scrollToBottomAnimated:NO];
}


- (void)testReaderReturningToVisibleReplyBottomFollowsParagraphGrowth {
    TLWAIAssistantMessageListView *list = [[TLWAIAssistantMessageListView alloc] initWithFrame:CGRectMake(0, 0, 320, 240)];
    NSMutableArray<TLWAIAssistantMessage *> *messages = [NSMutableArray new];
    for (NSUInteger index = 0; index < 3; index++) {
        [messages addObject:[TLWAIAssistantMessage messageWithRole:TLWAIAssistantMessageRoleAssistant
            text:@"第一行\n第二行\n第三行\n第四行\n第五行\n第六行\n第七行\n第八行"]];
    }
    [list displayMessages:messages];
    [list layoutIfNeeded];
    UITableView *table = [list valueForKey:@"tableView"];
    NSIndexPath *last = [NSIndexPath indexPathForRow:2 inSection:0];
    [table scrollToRowAtIndexPath:last atScrollPosition:UITableViewScrollPositionBottom animated:NO];
    [list layoutIfNeeded];
    [table.delegate scrollViewWillBeginDragging:table];
    [table scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
        atScrollPosition:UITableViewScrollPositionTop animated:NO];
    [table.delegate scrollViewDidEndDragging:table willDecelerate:NO];
    [table.delegate scrollViewWillBeginDragging:table];
    [table scrollToRowAtIndexPath:last atScrollPosition:UITableViewScrollPositionBottom animated:NO];
    [list layoutIfNeeded];
    CGPoint target = table.contentOffset;
    [table.delegate scrollViewWillEndDragging:table withVelocity:CGPointMake(0, 1) targetContentOffset:&target];
    [table.delegate scrollViewDidEndDragging:table willDecelerate:NO];
    TLWAIAssistantMessage *reply = messages.lastObject;
    reply.text = [reply.text stringByAppendingString:@"\n新增正文\n继续生成"];
    [list reloadMessage:reply];
    [list layoutIfNeeded];
    UITableViewCell *cell = [table cellForRowAtIndexPath:last];
    XCTAssertNotNil(cell);
    CGFloat visibleBottom = CGRectGetMaxY(table.bounds) - table.adjustedContentInset.bottom;
    XCTAssertLessThanOrEqual(CGRectGetMaxY([cell convertRect:cell.bounds toView:table]) - visibleBottom, 24.0);
}

- (void)testStreamingRefreshDoesNotCancelAnInProgressUpwardDrag {
    TLWAIAssistantMessageListView *listView = [[TLWAIAssistantMessageListView alloc] initWithFrame:CGRectMake(0, 0, 320, 240)];
    NSMutableArray<TLWAIAssistantMessage *> *messages = [NSMutableArray array];
    for (NSUInteger index = 0; index < 12; index++) {
        NSString *text = [NSString stringWithFormat:@"消息 %lu：用于验证拖动中更新。", (unsigned long)index];
        [messages addObject:[TLWAIAssistantMessage messageWithRole:TLWAIAssistantMessageRoleAssistant text:text]];
    }
    [listView displayMessages:messages];
    [listView layoutIfNeeded];
    [listView scrollToBottomAnimated:NO];

    UITableView *tableView = [listView valueForKey:@"tableView"];
    UIEdgeInsets inset = tableView.adjustedContentInset;
    CGFloat bottomOffset = MAX(-inset.top,
                               tableView.contentSize.height - CGRectGetHeight(tableView.bounds) + inset.bottom);
    [tableView.delegate scrollViewWillBeginDragging:tableView];
    [tableView setContentOffset:CGPointMake(0, bottomOffset - 10.0) animated:NO];
    [tableView.delegate scrollViewDidScroll:tableView];

    TLWAIAssistantMessage *lastMessage = messages.lastObject;
    lastMessage.text = [lastMessage.text stringByAppendingString:@" 刷新期间的小段增量"];
    [listView reloadMessage:lastMessage];

    inset = tableView.adjustedContentInset;
    bottomOffset = MAX(-inset.top,
                       tableView.contentSize.height - CGRectGetHeight(tableView.bounds) + inset.bottom);
    [tableView setContentOffset:CGPointMake(0, bottomOffset - 40.0) animated:NO];
    [tableView.delegate scrollViewDidScroll:tableView];
    XCTAssertFalse([[listView valueForKey:@"followsBottom"] boolValue]);

    CGFloat historyOffset = tableView.contentOffset.y;
    lastMessage.text = [lastMessage.text stringByAppendingString:@" 上滑后新文本"];
    [listView reloadMessage:lastMessage];
    XCTAssertEqualWithAccuracy(tableView.contentOffset.y, historyOffset, 0.5);
}
@end
