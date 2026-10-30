#import <XCTest/XCTest.h>
#import "TLWAIAssistantMessageListView.h"
#import "TLWAIAssistantMessage.h"
#import "TLWAIAssistantMessageCell.h"
#import "TLWAIMarkdownBodyView.h"
@interface TLWAIAssistantMessageListView (ScrollFixture)
- (UITableView *)tl_makeTableView;
@end
@interface TLWAISpyTable : UITableView
@property (nonatomic) BOOL trackingFixture;
@property (nonatomic) BOOL deceleratingFixture;
@property (nonatomic) NSUInteger offsetWrites;
@end
@implementation TLWAISpyTable
- (BOOL)isTracking { return self.trackingFixture || super.isTracking; }
- (BOOL)isDecelerating { return self.deceleratingFixture || super.isDecelerating; }
- (void)setContentOffset:(CGPoint)offset animated:(BOOL)animated { self.offsetWrites++; [super setContentOffset:offset animated:animated]; }
@end
@interface TLWAIInnerDecelerationFixture : UIScrollView
@property (nonatomic) BOOL deceleratingFixture;
@end
@implementation TLWAIInnerDecelerationFixture
- (BOOL)isDecelerating { return self.deceleratingFixture; }
@end
@interface TLWAISpyList : TLWAIAssistantMessageListView @end
@implementation TLWAISpyList
- (UITableView *)tl_makeTableView { return [[TLWAISpyTable alloc] initWithFrame:CGRectZero style:UITableViewStylePlain]; }
@end
@interface TLWAIScrollFollowingTests : XCTestCase @end
@implementation TLWAIScrollFollowingTests
- (void)testStreamingNeverWritesOffsetDuringDragDecelerationOrBounce {
    TLWAISpyList *list = [[TLWAISpyList alloc] initWithFrame:CGRectMake(0, 0, 320, 240)];
    NSMutableArray *messages = [NSMutableArray array];
    for (NSUInteger i = 0; i < 12; i++) [messages addObject:[TLWAIAssistantMessage messageWithRole:TLWAIAssistantMessageRoleAssistant text:@"可滚动历史内容"]];
    TLWAIAssistantMessage *reply = messages.lastObject;
    reply.status = TLWAIAssistantMessageStatusSending;
    [list displayMessages:messages]; [list layoutIfNeeded]; [list scrollToBottomAnimated:NO];
    TLWAISpyTable *table = [list valueForKey:@"tableView"];
    table.trackingFixture = YES;
    [table.delegate scrollViewWillBeginDragging:table];
    table.offsetWrites = 0;
    for (NSUInteger i = 0; i < 30; i++) {
        reply.text = [reply.text stringByAppendingString:@"增量"];
        [list reloadMessage:reply]; [list followBottomIfNeededAnimated:NO];
    }
    XCTAssertEqual(table.offsetWrites, 0u);
    XCTAssertFalse([[list valueForKey:@"followsBottom"] boolValue]);
    table.trackingFixture = NO; table.deceleratingFixture = YES;
    [table.delegate scrollViewDidEndDragging:table willDecelerate:YES];
    table.offsetWrites = 0;
    [list reloadMessage:reply]; [list followBottomIfNeededAnimated:NO];
    XCTAssertEqual(table.offsetWrites, 0u);
    XCTAssertFalse([[list valueForKey:@"followsBottom"] boolValue]);
    table.deceleratingFixture = NO;
    CGFloat bottom = MAX(-table.adjustedContentInset.top, table.contentSize.height - table.bounds.size.height + table.adjustedContentInset.bottom);
    [table setContentOffset:CGPointMake(0, bottom + 12) animated:NO];
    [table.delegate scrollViewDidEndDecelerating:table];
    table.offsetWrites = 0;
    [list followBottomIfNeededAnimated:NO];
    XCTAssertEqual(table.offsetWrites, 0u);
    XCTAssertFalse([[list valueForKey:@"followsBottom"] boolValue]);
}

- (void)testStreamingGrowthUpdatesActualTableRowWithoutReattachingHistoryReader {
    TLWAIAssistantMessageListView *list = [[TLWAIAssistantMessageListView alloc] initWithFrame:CGRectMake(0, 0, 350, 500)];
    [list layoutIfNeeded];
    TLWAIAssistantMessage *reply = [TLWAIAssistantMessage messageWithRole:TLWAIAssistantMessageRoleAssistant text:@"开始"];
    reply.status = TLWAIAssistantMessageStatusSending;
    [list displayMessages:@[reply]];
    [list layoutIfNeeded];
    UITableView *table = [list valueForKey:@"tableView"];
    [table layoutIfNeeded];
    [list setValue:@NO forKey:@"followsBottom"];
    CGPoint readingOffset = table.contentOffset;
    reply.text = [@"普通正文一行\n" stringByPaddingToLength:2000 withString:@"普通正文一行\n" startingAtIndex:0];
    [list reloadMessage:reply];
    XCTNSPredicateExpectation *grown = [[XCTNSPredicateExpectation alloc] initWithPredicate:[NSPredicate predicateWithBlock:^BOOL(id object, NSDictionary *bindings) {
        return [table rectForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]].size.height > 500;
    }] object:nil];
    [self waitForExpectations:@[grown] timeout:3];
    XCTAssertFalse([[list valueForKey:@"followsBottom"] boolValue]);
    XCTAssertEqualWithAccuracy(table.contentOffset.y, readingOffset.y, 0.5);
}

- (void)testVisibleReplyContinuesRenderingAndGrowingDuringDragWithoutFollowing {
    TLWAISpyList *list = [[TLWAISpyList alloc] initWithFrame:CGRectMake(0, 0, 350, 400)];
    [list layoutIfNeeded];
    TLWAIAssistantMessage *reply = [TLWAIAssistantMessage messageWithRole:TLWAIAssistantMessageRoleAssistant text:@"开始"];
    reply.status = TLWAIAssistantMessageStatusSending;
    [list displayMessages:@[reply]];
    TLWAISpyTable *table = [list valueForKey:@"tableView"];
    [table layoutIfNeeded];
    TLWAIAssistantMessageCell *cell = (id)[table cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    TLWAIMarkdownBodyView *body = [cell valueForKey:@"messageBody"];
    XCTAssertNotNil(body);
    CGFloat oldHeight = [table rectForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]].size.height;
    table.trackingFixture = YES;
    [table.delegate scrollViewWillBeginDragging:table];
    table.offsetWrites = 0;
    reply.text = [@"拖动期间仍持续更新\n" stringByPaddingToLength:1000 withString:@"新正文一行\n" startingAtIndex:0];
    [list reloadMessage:reply];
    [list followBottomIfNeededAnimated:NO];
    XCTAssertTrue([body.text containsString:@"拖动期间仍持续更新"]);
    XCTNSPredicateExpectation *grown = [[XCTNSPredicateExpectation alloc] initWithPredicate:[NSPredicate predicateWithBlock:^BOOL(id object, NSDictionary *bindings) {
        return [table rectForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]].size.height > oldHeight + 100;
    }] object:nil];
    [self waitForExpectations:@[grown] timeout:3];
    XCTAssertEqual(table.offsetWrites, 0u);
    XCTAssertFalse([[list valueForKey:@"followsBottom"] boolValue]);
    table.trackingFixture = NO;
    [table.delegate scrollViewDidEndDragging:table willDecelerate:NO];
}

- (void)testJumpButtonAppearsWhileReadingHistoryAndRestoresLatestFollowing {
    TLWAISpyList *list = [[TLWAISpyList alloc] initWithFrame:CGRectMake(0, 0, 350, 300)];
    [list layoutIfNeeded];
    NSMutableArray *messages = [NSMutableArray array];
    for (NSUInteger i = 0; i < 12; i++) {
        [messages addObject:[TLWAIAssistantMessage messageWithRole:TLWAIAssistantMessageRoleAssistant text:@"可滚动历史\n第二行\n第三行"]];
    }
    [list displayMessages:messages];
    [list layoutIfNeeded];
    [list scrollToBottomAnimated:NO];
    UIButton *jump = nil;
    for (UIView *view in list.subviews) {
        if ([view isKindOfClass:UIButton.class] && [view.accessibilityIdentifier isEqualToString:@"ai.scrollToBottom"]) jump = (id)view;
    }
    XCTAssertNotNil(jump);
    if (!jump) return;
    XCTAssertTrue(jump.hidden);
    XCTAssertEqualWithAccuracy(jump.center.x, CGRectGetMidX(list.bounds), 0.5);
    TLWAISpyTable *table = [list valueForKey:@"tableView"];
    table.trackingFixture = YES;
    [table.delegate scrollViewWillBeginDragging:table];
    [table setContentOffset:CGPointMake(0, -table.adjustedContentInset.top) animated:NO];
    [table.delegate scrollViewDidScroll:table];
    XCTAssertFalse(jump.hidden);
    table.trackingFixture = NO;
    [table.delegate scrollViewDidEndDragging:table willDecelerate:NO];
    [jump sendActionsForControlEvents:UIControlEventTouchUpInside];
    XCTNSPredicateExpectation *atBottom = [[XCTNSPredicateExpectation alloc] initWithPredicate:[NSPredicate predicateWithBlock:^BOOL(id object, NSDictionary *bindings) {
        CGFloat bottom = MAX(-table.adjustedContentInset.top, table.contentSize.height - table.bounds.size.height + table.adjustedContentInset.bottom);
        return fabs(table.contentOffset.y - bottom) < 1;
    }] object:nil];
    [self waitForExpectations:@[atBottom] timeout:3];
    XCTAssertTrue(jump.hidden);
    XCTAssertTrue([[list valueForKey:@"followsBottom"] boolValue]);
}

- (void)testJumpRequestedDuringInnerDecelerationRunsWhenThatInteractionEnds {
    TLWAISpyList *list = [[TLWAISpyList alloc] initWithFrame:CGRectMake(0, 0, 350, 300)];
    [list layoutIfNeeded];
    NSMutableArray *messages = [NSMutableArray array];
    for (NSUInteger i = 0; i < 12; i++) {
        [messages addObject:[TLWAIAssistantMessage messageWithRole:TLWAIAssistantMessageRoleAssistant text:@"历史正文\n第二行\n第三行"]];
    }
    [list displayMessages:messages];
    [list layoutIfNeeded];
    [list scrollToBottomAnimated:NO];
    TLWAISpyTable *table = [list valueForKey:@"tableView"];
    CGFloat bottom = table.contentSize.height - table.bounds.size.height + table.adjustedContentInset.bottom;
    [table.delegate scrollViewWillBeginDragging:table];
    [table setContentOffset:CGPointMake(0, bottom - 60) animated:NO];
    [table.delegate scrollViewDidEndDragging:table willDecelerate:NO];
    [table layoutIfNeeded];
    TLWAIAssistantMessageCell *cell = (id)[table cellForRowAtIndexPath:[NSIndexPath indexPathForRow:messages.count - 1 inSection:0]];
    XCTAssertNotNil(cell);
    if (!cell) return;
    TLWAIInnerDecelerationFixture *inner = [TLWAIInnerDecelerationFixture new];
    inner.deceleratingFixture = YES;
    [cell setValue:inner forKey:@"imageScrollView"];
    UIButton *jump = [list valueForKey:@"jumpToBottomButton"];
    [jump sendActionsForControlEvents:UIControlEventTouchUpInside];
    inner.deceleratingFixture = NO;
    [(id<UIScrollViewDelegate>)cell scrollViewDidEndDecelerating:inner];
    XCTNSPredicateExpectation *atBottom = [[XCTNSPredicateExpectation alloc] initWithPredicate:[NSPredicate predicateWithBlock:^BOOL(id object, NSDictionary *bindings) {
        CGFloat latestBottom = MAX(-table.adjustedContentInset.top, table.contentSize.height - table.bounds.size.height + table.adjustedContentInset.bottom);
        return fabs(table.contentOffset.y - latestBottom) < 1;
    }] object:nil];
    [self waitForExpectations:@[atBottom] timeout:3];
    XCTAssertTrue(jump.hidden);
}
- (void)testExplicitJumpMeasuresOffscreenTallRowBeforeHidingButton {
    TLWAIAssistantMessageListView *list = [[TLWAIAssistantMessageListView alloc] initWithFrame:CGRectMake(0, 0, 350, 320)];
    [list layoutIfNeeded];
    NSMutableArray *history = [NSMutableArray array];
    for (NSUInteger i = 0; i < 12; i++) [history addObject:[TLWAIAssistantMessage messageWithRole:TLWAIAssistantMessageRoleAssistant text:@"短历史\n第二行\n第三行"]];
    [list displayMessages:history];
    [list layoutIfNeeded];
    UITableView *table = [list valueForKey:@"tableView"];
    [table.delegate scrollViewWillBeginDragging:table];
    [table setContentOffset:CGPointMake(0, -table.adjustedContentInset.top) animated:NO];
    [table.delegate scrollViewDidEndDragging:table willDecelerate:NO];
    NSString *tall = [@"已完成富文本样本\n" stringByPaddingToLength:1800 withString:@"这是需要真实测量后才能露出的最后一行。\n" startingAtIndex:0];
    [list appendMessage:[TLWAIAssistantMessage messageWithRole:TLWAIAssistantMessageRoleAssistant text:tall]];
    UIButton *jump = [list valueForKey:@"jumpToBottomButton"];
    XCTAssertFalse(jump.hidden);
    [jump sendActionsForControlEvents:UIControlEventTouchUpInside];
    NSIndexPath *last = [NSIndexPath indexPathForRow:history.count inSection:0];
    XCTNSPredicateExpectation *landed = [[XCTNSPredicateExpectation alloc] initWithPredicate:[NSPredicate predicateWithBlock:^BOOL(id object, NSDictionary *bindings) {
        [list layoutIfNeeded];
        CGRect row = [table rectForRowAtIndexPath:last];
        CGFloat target = CGRectGetMaxY(row) - table.bounds.size.height + table.adjustedContentInset.bottom;
        return row.size.height > 400 && fabs(table.contentOffset.y - target) < 1 && jump.hidden;
    }] object:nil];
    [self waitForExpectations:@[landed] timeout:3];
}
- (void)testExplicitJumpProceedsWhileOuterDecelerationFlagRemainsSet {
    TLWAISpyList *list = [[TLWAISpyList alloc] initWithFrame:CGRectMake(0, 0, 350, 280)];
    [list layoutIfNeeded];
    NSMutableArray *messages = [NSMutableArray array];
    for (NSUInteger i = 0; i < 10; i++) [messages addObject:[TLWAIAssistantMessage messageWithRole:TLWAIAssistantMessageRoleAssistant text:@"可滚动历史\n第二行"]];
    [list displayMessages:messages];
    [list layoutIfNeeded];
    TLWAISpyTable *table = [list valueForKey:@"tableView"];
    [table.delegate scrollViewWillBeginDragging:table];
    [table setContentOffset:CGPointMake(0, -table.adjustedContentInset.top) animated:NO];
    table.deceleratingFixture = YES;
    [table.delegate scrollViewDidEndDragging:table willDecelerate:YES];
    [list scrollToBottomAnimated:NO];
    [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.2]];
    NSIndexPath *last = [NSIndexPath indexPathForRow:messages.count - 1 inSection:0];
    CGRect row = [table rectForRowAtIndexPath:last];
    CGFloat target = MAX(-table.adjustedContentInset.top, CGRectGetMaxY(row) - table.bounds.size.height + table.adjustedContentInset.bottom);
    XCTAssertFalse([[list valueForKey:@"pendingExplicitBottom"] boolValue]);
    XCTAssertGreaterThanOrEqual(table.contentOffset.y, target - 1);
    XCTAssertGreaterThan(table.contentOffset.y, -table.adjustedContentInset.top + 24);
    XCTAssertTrue(table.deceleratingFixture);
}
- (void)testOffscreenAppendAppearsWithLatestHeightWhenReaderReturns {
    TLWAISpyList *list = [[TLWAISpyList alloc] initWithFrame:CGRectMake(0, 0, 350, 320)];
    NSMutableArray *messages = [NSMutableArray array];
    for (NSUInteger i = 0; i < 12; i++) {
        [messages addObject:[TLWAIAssistantMessage messageWithRole:TLWAIAssistantMessageRoleAssistant text:@"历史第一行\n历史第二行\n历史第三行"]];
    }
    TLWAIAssistantMessage *reply = messages.lastObject;
    reply.status = TLWAIAssistantMessageStatusSending;
    [list displayMessages:messages];
    [list layoutIfNeeded];
    TLWAISpyTable *table = [list valueForKey:@"tableView"];
    table.trackingFixture = YES;
    [table.delegate scrollViewWillBeginDragging:table];
    [table scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
    [table layoutIfNeeded];
    table.trackingFixture = NO;
    [table.delegate scrollViewDidEndDragging:table willDecelerate:NO];
    NSIndexPath *last = [NSIndexPath indexPathForRow:messages.count - 1 inSection:0];
    XCTAssertFalse([table.indexPathsForVisibleRows containsObject:last]);
    CGPoint readingOffset = table.contentOffset;
    reply.text = [@"离屏生成正文\n" stringByPaddingToLength:600 withString:@"后续完整正文\n" startingAtIndex:0];
    [list reloadMessage:reply];
    [list layoutIfNeeded];
    XCTAssertEqualWithAccuracy(table.contentOffset.y, readingOffset.y, 0.5);
    [table scrollToRowAtIndexPath:last atScrollPosition:UITableViewScrollPositionBottom animated:NO];
    [table layoutIfNeeded];
    XCTNSPredicateExpectation *visible = [[XCTNSPredicateExpectation alloc] initWithPredicate:[NSPredicate predicateWithBlock:^BOOL(id object, NSDictionary *bindings) {
        TLWAIAssistantMessageCell *cell = (id)[table cellForRowAtIndexPath:last];
        TLWAIMarkdownBodyView *body = [cell valueForKey:@"messageBody"];
        return [body.text containsString:@"离屏生成正文"] && [table rectForRowAtIndexPath:last].size.height > 500;
    }] object:nil];
    [self waitForExpectations:@[visible] timeout:3];
}

- (void)testCompletionUpdatesRowHeightWhenOnlyStatusAreaDisappears {
    TLWAIAssistantMessageListView *list = [[TLWAIAssistantMessageListView alloc] initWithFrame:CGRectMake(0, 0, 350, 500)];
    TLWAIAssistantMessage *reply = [TLWAIAssistantMessage messageWithRole:TLWAIAssistantMessageRoleAssistant text:@"正文"];
    reply.status = TLWAIAssistantMessageStatusSending;
    [list displayMessages:@[reply]];
    [list layoutIfNeeded];
    UITableView *table = [list valueForKey:@"tableView"];
    [table layoutIfNeeded];
    NSIndexPath *row = [NSIndexPath indexPathForRow:0 inSection:0];
    CGFloat sendingHeight = [table rectForRowAtIndexPath:row].size.height;
    reply.status = TLWAIAssistantMessageStatusIdle;
    reply.completed = YES;
    [list reloadMessage:reply];
    XCTNSPredicateExpectation *completed = [[XCTNSPredicateExpectation alloc] initWithPredicate:[NSPredicate predicateWithBlock:^BOOL(id object, NSDictionary *bindings) {
        return [table rectForRowAtIndexPath:row].size.height < sendingHeight - 1;
    }] object:nil];
    [self waitForExpectations:@[completed] timeout:3];
    TLWAIAssistantMessageCell *cell = (id)[table cellForRowAtIndexPath:row];
    XCTAssertEqualObjects(((TLWAIMarkdownBodyView *)[cell valueForKey:@"messageBody"]).text, @"正文");
}
@end
