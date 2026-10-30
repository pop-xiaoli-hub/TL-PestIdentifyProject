#import <XCTest/XCTest.h>
#import "../Pods/Headers/Public/AgriPestClient/AGDefaultConfiguration.h"
#import "../TL_AIAssistant/TLWAIAssistantController.h"
#import "../TL_AIAssistant/TLWAIStreamClient.h"
#import "../TL_AIAssistant/Views/TLWAIAssistantView.h"
#import "../TL_AIAssistant/Models/TLWAIAssistantMessage.h"
#import "../TL_AIAssistant/Models/TLWAIConversationTurn.h"
#import "TLWAITurnStore.h"
#import "TLWAIAssistantSession.h"

@interface TLWAIAssistantController (Testing)
- (void)tl_send;
- (void)tl_stopAI;
- (TLWAIStreamClient *)tl_makeStreamClient;
- (void)tl_continueFromMessage:(TLWAIAssistantMessage *)message;
- (void)tl_flushPendingDeltasIfNeeded;
@end

@interface TLWAIFixtureClient : TLWAIStreamClient
@property (nonatomic) BOOL cancelled;
@end
@implementation TLWAIFixtureClient
- (NSURLSessionDataTask *)streamChatWithRequest:(AGChatRequest *)request accessToken:(NSString *)token { return nil; }
- (void)cancel { self.cancelled = YES; }
@end

@interface TLWAIFixtureController : TLWAIAssistantController
@property (nonatomic, strong) NSMutableArray<TLWAIFixtureClient *> *clients;
@end
@implementation TLWAIFixtureController
- (void)tl_openStore {
    // Controller 回归不读取或写入用户的正式问诊数据库。
    TLWAITurnStore *store = [[TLWAITurnStore alloc] initWithUserIdentifier:0];
    [self setValue:store forKey:@"turnStore"];
    [self setValue:store.currentSession forKey:@"session"];
}
- (void)tl_startProfileComparisonDebugWithRequest:(AGChatRequest *)request tag:(NSString *)tag {}
- (void)tl_refreshAuthWithRetry:(dispatch_block_t)retry failure:(dispatch_block_t)failure { if (retry) retry(); }
- (TLWAIStreamClient *)tl_makeStreamClient {
    TLWAIFixtureClient *client = [TLWAIFixtureClient new];
    if (!self.clients) self.clients = [NSMutableArray array];
    [self.clients addObject:client];
    return client;
}
@end

@interface TLWMessageTapTouch : UITouch
@property (nonatomic, strong) UIView *hitView;
@end
@implementation TLWMessageTapTouch
- (UIView *)view { return self.hitView; }
@end

@interface TLWAIAssistantControllerTests : XCTestCase
@end
@implementation TLWAIAssistantControllerTests
- (void)testKeyboardDismissTapAcceptsReadonlyMessageButNotComposerOrButtons {
    TLWAIFixtureController *controller = [TLWAIFixtureController new];
    [controller loadViewIfNeeded];
    TLWAIAssistantView *view = [controller valueForKey:@"myView"];
    UITextView *message = [UITextView new];
    message.editable = NO;
    [view addSubview:message];
    TLWMessageTapTouch *touch = [TLWMessageTapTouch new];
    touch.hitView = message;
    UITapGestureRecognizer *tap = [UITapGestureRecognizer new];
    id<UIGestureRecognizerDelegate> delegate = (id)controller;
    XCTAssertTrue([delegate gestureRecognizer:tap shouldReceiveTouch:touch]);
    touch.hitView = view.inputTextField;
    XCTAssertFalse([delegate gestureRecognizer:tap shouldReceiveTouch:touch]);
    touch.hitView = view.sendButton;
    XCTAssertFalse([delegate gestureRecognizer:tap shouldReceiveTouch:touch]);
    message.text = @"已选中的内容";
    message.selectedRange = NSMakeRange(0, 2);
    touch.hitView = message;
    XCTAssertFalse([delegate gestureRecognizer:tap shouldReceiveTouch:touch]);
    [message removeFromSuperview];
}
- (void)testPreemptionCancelsOldTaskDrainsTextAndIgnoresLateDelta {
    AGDefaultConfiguration *configuration = AGDefaultConfiguration.sharedConfig;
    NSString *previous = configuration.accessToken;
    configuration.accessToken = @"local-fixture";
    TLWAIFixtureController *controller = [TLWAIFixtureController new];
    [controller loadViewIfNeeded];
    TLWAIAssistantView *view = [controller valueForKey:@"myView"];
    [view setInputText:@"第一问"];
    [controller tl_send];
    TLWAIAssistantMessage *first = [controller valueForKeyPath:@"activeTurn.assistantMessage"];
    TLWAIFixtureClient *old = controller.clients.firstObject;
    XCTAssertNotNil(old);
    if (!old) { [controller tl_stopAI]; configuration.accessToken = previous; return; }
    old.onPlanDelta(@"保留尾部👨‍👩‍👧‍👦");
    [view setInputText:@"第二问"];
    [controller tl_send];
    TLWAIAssistantMessage *second = [controller valueForKeyPath:@"activeTurn.assistantMessage"];
    XCTAssertTrue(old.cancelled);
    XCTAssertNotEqual(first.status, TLWAIAssistantMessageStatusSending);
    XCTAssertEqualObjects(first.text, @"保留尾部👨‍👩‍👧‍👦");
    old.onPlanDelta(@"旧任务迟到");
    [controller tl_stopAI];
    XCTAssertFalse([second.text containsString:@"旧任务迟到"]);
    XCTAssertNotEqual(second.status, TLWAIAssistantMessageStatusSending);
    configuration.accessToken = previous;
}

- (void)testDraggingHistoryDoesNotBlockConsumptionOfReceivedReply {
    AGDefaultConfiguration *configuration = AGDefaultConfiguration.sharedConfig;
    NSString *previous = configuration.accessToken;
    TLWAIFixtureController *controller = [TLWAIFixtureController new];
    @try {
        configuration.accessToken = @"local-fixture";
        [controller loadViewIfNeeded];
        TLWAIAssistantView *view = [controller valueForKey:@"myView"];
        [view setInputText:@"边读边生成"];
        [controller tl_send];
        TLWAIConversationTurn *turn = [controller valueForKey:@"activeTurn"];
        UITableView *table = [view valueForKeyPath:@"messageListView.tableView"];
        [table.delegate scrollViewWillBeginDragging:table];
        NSString *received = @"拖动期间继续推进正文👨‍👩‍👧‍👦";
        controller.clients.firstObject.onPlanDelta(received);
        for (NSUInteger i = 0; i < 32; i++) [controller tl_flushPendingDeltasIfNeeded];
        XCTAssertEqualObjects(turn.assistantMessage.text, received);
        XCTAssertEqualObjects(turn.pendingDelta, @"");
        XCTAssertEqual([controller valueForKey:@"activeTurn"], turn);
        [table.delegate scrollViewDidEndDragging:table willDecelerate:NO];
    } @finally {
        [controller tl_stopAI];
        configuration.accessToken = previous;
    }
}

- (void)testLeavingAssistantCancelsTextGeneration {
    AGDefaultConfiguration *configuration = AGDefaultConfiguration.sharedConfig;
    NSString *previous = configuration.accessToken;
    configuration.accessToken = @"local-fixture";
    TLWAIFixtureController *controller = [TLWAIFixtureController new];
    [controller loadViewIfNeeded];
    TLWAIAssistantView *view = [controller valueForKey:@"myView"];
    [view setInputText:@"离开页面"];
    [controller tl_send];
    TLWAIAssistantMessage *message = [controller valueForKeyPath:@"activeTurn.assistantMessage"];
    [controller viewWillDisappear:NO];
    [controller viewDidDisappear:NO];
    XCTAssertNil([controller valueForKey:@"activeTurn"]);
    XCTAssertTrue(controller.clients.firstObject.cancelled);
    XCTAssertNotEqual(message.status, TLWAIAssistantMessageStatusSending);
    configuration.accessToken = previous;
}

- (void)testCancelledNavigationKeepsGenerationAndItsPendingText {
    AGDefaultConfiguration *configuration = AGDefaultConfiguration.sharedConfig;
    NSString *previous = configuration.accessToken;
    TLWAIFixtureController *controller = [TLWAIFixtureController new];
    @try {
        configuration.accessToken = @"local-fixture";
        [controller loadViewIfNeeded];
        [(TLWAIAssistantView *)[controller valueForKey:@"myView"] setInputText:@"取消返回"];
        [controller tl_send];
        TLWAIConversationTurn *turn = [controller valueForKey:@"activeTurn"];
        TLWAIFixtureClient *client = controller.clients.firstObject;
        client.onPlanDelta(@"返回前");
        [controller viewWillDisappear:NO];
        [controller viewWillAppear:NO];
        [controller viewDidAppear:NO];
        XCTAssertEqual([controller valueForKey:@"activeTurn"], turn);
        XCTAssertFalse(client.cancelled);
        client.onPlanDelta(@"返回后");
        [controller tl_stopAI];
        XCTAssertEqualObjects(turn.assistantMessage.text, @"返回前返回后");
    } @finally {
        [controller tl_stopAI];
        configuration.accessToken = previous;
    }
}

- (void)testTransientNetworkErrorsPreservePartialReplyAndOfferRegeneration {
    AGDefaultConfiguration *configuration = AGDefaultConfiguration.sharedConfig;
    NSString *previous = configuration.accessToken;
    @try {
        configuration.accessToken = @"local-fixture";
        for (NSNumber *code in @[@(NSURLErrorNetworkConnectionLost), @(NSURLErrorNotConnectedToInternet), @(NSURLErrorTimedOut)]) {
            TLWAIFixtureController *controller = [TLWAIFixtureController new];
            [controller loadViewIfNeeded];
            [(TLWAIAssistantView *)[controller valueForKey:@"myView"] setInputText:@"弱网测试"];
            [controller tl_send];
            TLWAIConversationTurn *turn = [controller valueForKey:@"activeTurn"];
            TLWAIFixtureClient *client = controller.clients.firstObject;
            client.onPlanDelta(@"已收到的正文 👨‍👩‍👧‍👦");
            client.onError([NSError errorWithDomain:NSURLErrorDomain code:code.integerValue userInfo:nil], nil);
            XCTAssertTrue([turn.assistantMessage.text containsString:@"已收到的正文 👨‍👩‍👧‍👦"]);
            XCTAssertTrue(turn.assistantMessage.canContinue, @"Transient error %@ must allow an explicit new generation", code);
            XCTAssertFalse(turn.assistantMessage.completed);
            XCTAssertNil([controller valueForKey:@"activeTurn"]);
        }
    } @finally { configuration.accessToken = previous; }
}

- (void)testMidstreamSilenceShowsWaitingWithoutReplacingReplyAndHeartbeatClearsIt {
    AGDefaultConfiguration *configuration = AGDefaultConfiguration.sharedConfig;
    NSString *previous = configuration.accessToken;
    TLWAIFixtureController *controller = [TLWAIFixtureController new];
    @try {
        configuration.accessToken = @"local-fixture";
        [controller loadViewIfNeeded];
        [(TLWAIAssistantView *)[controller valueForKey:@"myView"] setInputText:@"中途等待"];
        [controller tl_send];
        TLWAIConversationTurn *turn = [controller valueForKey:@"activeTurn"];
        TLWAIFixtureClient *client = controller.clients.firstObject;
        client.onPlanFinal(@"已经生成的正文");
        XCTNSPredicateExpectation *waiting = [[XCTNSPredicateExpectation alloc] initWithPredicate:[NSPredicate predicateWithBlock:^BOOL(id object, NSDictionary *bindings) {
            return turn.assistantMessage.status == TLWAIAssistantMessageStatusWaiting;
        }] object:nil];
        [self waitForExpectations:@[waiting] timeout:10];
        XCTAssertEqualObjects(turn.assistantMessage.text, @"已经生成的正文");
        client.onHeartbeat(@"keepalive");
        XCTAssertEqual(turn.assistantMessage.status, TLWAIAssistantMessageStatusSending);
        XCTAssertEqualObjects(turn.assistantMessage.text, @"已经生成的正文");
        XCTAssertEqual([controller valueForKey:@"activeTurn"], turn);
    } @finally {
        [controller tl_stopAI];
        configuration.accessToken = previous;
    }
}

- (void)testAuthRebuildDoesNotConcatenateOldConnectionOrPendingText {
    AGDefaultConfiguration *configuration = AGDefaultConfiguration.sharedConfig;
    NSString *previous = configuration.accessToken;
    configuration.accessToken = @"local-fixture";
    TLWAIFixtureController *controller = [TLWAIFixtureController new];
    [controller loadViewIfNeeded];
    [(TLWAIAssistantView *)[controller valueForKey:@"myView"] setInputText:@"鉴权重建"];
    [controller tl_send];
    TLWAIConversationTurn *turn = [controller valueForKey:@"activeTurn"];
    TLWAIFixtureClient *old = controller.clients.firstObject;
    old.onPlanDelta(@"不能重复的旧段");
    old.onAuthFailure();
    XCTAssertEqual(controller.clients.count, 2u);
    old.onPlanDelta(@"旧连接迟到");
    TLWAIFixtureClient *current = controller.clients.lastObject;
    current.onPlanDelta(@"重建后的正文");
    current.onDone(@{});
    XCTAssertEqualObjects(turn.assistantMessage.text, @"重建后的正文");
    XCTAssertEqual(turn.state, TLWAIConversationTurnStateCompleted);
    XCTAssertNil([controller valueForKey:@"activeTurn"]);
    configuration.accessToken = previous;
}
- (void)testSecondRequestExtraInfoNamesPreviousDiseaseWithoutUnauthorizedLocation {
    AGDefaultConfiguration *configuration = AGDefaultConfiguration.sharedConfig;
    NSString *previous = configuration.accessToken;
    configuration.accessToken = @"local-fixture";
    TLWAIFixtureController *controller = [TLWAIFixtureController new];
    [controller loadViewIfNeeded];
    TLWAIAssistantView *view = [controller valueForKey:@"myView"];
    [view setInputText:@"叶子发黄"];
    [controller tl_send];
    TLWAIFixtureClient *first = controller.clients.firstObject;
    first.onDiseaseList(@[@{@"diseaseName": @"番茄早疫病", @"confidence": @0.92}]);
    first.onDone(@{});
    [view setInputText:@"还要打药吗"];
    [controller tl_send];
    id request = [controller valueForKeyPath:@"activeTurn.request"];
    NSString *extra = [request valueForKey:@"extraInfo"];
    XCTAssertTrue([extra containsString:@"番茄早疫病"]);
    XCTAssertFalse([extra containsString:@"用户已单独授权附带定位"]);
    XCTAssertFalse([extra containsString:@"还要打药吗"]);
    [controller tl_stopAI];
    configuration.accessToken = previous;
}
#if DEBUG
- (void)testLocalStreamNeedsNoLoginAndDoesNotRestoreTestMessagesInAnotherController {
    NSString *previousEnvironment = getenv("TLW_AI_STREAM_TEST_URL") ? @(getenv("TLW_AI_STREAM_TEST_URL")) : nil;
    AGDefaultConfiguration *configuration = AGDefaultConfiguration.sharedConfig;
    NSString *previousToken = configuration.accessToken;
    setenv("TLW_AI_STREAM_TEST_URL", "http://127.0.0.1:8765/api/v1/agent/chat/stream", 1);
    configuration.accessToken = @"";
    TLWAIFixtureController *first = [TLWAIFixtureController new];
    @try {
        [first loadViewIfNeeded];
        TLWAIAssistantView *view = [first valueForKey:@"myView"];
        [view setInputText:@"local-only-question-not-for-real-history"];
        [first tl_send];
        XCTAssertEqual(first.clients.count, 1u, @"local text streaming must not require a real login");
        if (!first.clients.firstObject) return;
        first.clients.firstObject.onPlanDelta(@"本地测试正文");
        first.clients.firstObject.onDone(@{});
        TLWAIFixtureController *second = [TLWAIFixtureController new];
        [second loadViewIfNeeded];
        NSArray<TLWAIAssistantMessage *> *messages = [second valueForKeyPath:@"session.messages"];
        for (TLWAIAssistantMessage *message in messages) {
            XCTAssertFalse([message.text containsString:@"local-only-question-not-for-real-history"]);
            XCTAssertFalse([message.text containsString:@"本地测试正文"]);
        }
    } @finally {
        [first tl_stopAI];
        configuration.accessToken = previousToken;
        if (previousEnvironment) setenv("TLW_AI_STREAM_TEST_URL", previousEnvironment.UTF8String, 1);
        else unsetenv("TLW_AI_STREAM_TEST_URL");
    }
}
- (void)testLocalImageSendSkipsUploadAndAttachesGestureStrip {
    NSString *previousEnvironment = getenv("TLW_AI_STREAM_TEST_URL") ? @(getenv("TLW_AI_STREAM_TEST_URL")) : nil;
    setenv("TLW_AI_STREAM_TEST_URL", "http://127.0.0.1:8765/api/v1/agent/chat/stream", 1);
    TLWAIFixtureController *controller = [TLWAIFixtureController new];
    @try {
        [controller loadViewIfNeeded];
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(8, 8), YES, 1);
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        [controller setValue:[@[image] mutableCopy] forKey:@"pendingImages"];
        [controller tl_send];
        XCTAssertEqual(controller.clients.count, 1u, @"local image send must stream without the production uploader");
        XCTAssertNil([controller valueForKeyPath:@"activeTurn.request.imageUrl"]);
    } @finally {
        [controller tl_stopAI];
        if (previousEnvironment) setenv("TLW_AI_STREAM_TEST_URL", previousEnvironment.UTF8String, 1);
        else unsetenv("TLW_AI_STREAM_TEST_URL");
    }
}
#endif
- (void)testSameJobContinueReusesExistingBubbleAndPreservesReceivedPrefix {
    AGDefaultConfiguration *configuration = AGDefaultConfiguration.sharedConfig;
    NSString *previous = configuration.accessToken;
    TLWAIFixtureController *controller = [TLWAIFixtureController new];
    @try {
        configuration.accessToken = @"controlled-fixture";
        [controller loadViewIfNeeded];
        TLWAIAssistantView *view = [controller valueForKey:@"myView"];
        [view setInputText:@"继续原任务"];
        [controller tl_send];
        TLWAIConversationTurn *original = [controller valueForKey:@"activeTurn"];
        TLWAIAssistantMessage *message = original.assistantMessage;
        TLWAIAssistantMessage *user = original.userMessage;
        controller.clients.lastObject.onIncompleteEOF(0);
        TLWAIAssistantSession *session = [controller valueForKey:@"session"];
        message.recoveryCheckpoint = @{@"version":@1, @"clientRequestId":@"stable-original", @"jobId":@"original-job",
            @"seq":@5, @"cursor":@"opaque-original", @"status":@"running", @"text":@"已可靠收到👩🏽‍🌾",
            @"diseases":@[], @"meta":@{}, @"completionInfo":@{}, @"fallbackTexts":@[], @"errorMessage":@"",
            @"ownerId":@0, @"sessionId":session.identifier, @"messageId":message.identifier,
            @"userMessageId":user.identifier, @"request":@{@"text":@"继续原任务", @"useSingleModel":@YES, @"saveHistory":@NO}};
        message.canContinue = YES; message.canResumeJob = YES;
        NSArray *previousMessages = session.messages.copy;
        [controller tl_continueFromMessage:message];
        TLWAIConversationTurn *resumed = [controller valueForKey:@"activeTurn"];
        XCTAssertEqualObjects(session.messages, previousMessages);
        XCTAssertEqual(resumed.assistantMessage, message);
        XCTAssertEqualObjects(resumed.clientRequestId, @"stable-original");
        controller.clients.lastObject.onPlanDelta(@"接续尾部");
        [controller tl_stopAI];
        XCTAssertEqualObjects(message.text, @"已可靠收到👩🏽‍🌾接续尾部");
        XCTAssertFalse(message.canContinue);
    } @finally {
        [controller tl_stopAI];
        configuration.accessToken = previous;
    }
}
@end
