#import <XCTest/XCTest.h>
#import "TLWAITurnStore.h"
#import "TLWAIAssistantSession.h"
#import "TLWAIAssistantMessage.h"
@interface TLWAIContextBudgetTests : XCTestCase @end
@implementation TLWAIContextBudgetTests
- (void)appendPairTo:(TLWAIAssistantSession *)session disease:(NSString *)disease completed:(BOOL)completed {
    TLWAIAssistantMessage *user = [TLWAIAssistantMessage messageWithRole:TLWAIAssistantMessageRoleUser text:@"叶片有斑点"];
    user.remoteImageURLs = @[@"https://private.invalid/photo"];
    TLWAIAssistantMessage *ai = [TLWAIAssistantMessage messageWithRole:TLWAIAssistantMessageRoleAssistant text:@"先核对病斑与发生条件"];
    ai.diseaseNames = @[disease]; ai.completed = completed;
    [session appendMessage:user]; [session appendMessage:ai];
}
- (void)testOnlyThreeRecentCompletedPairsAndNoImageURLAreUsed {
    TLWAIAssistantSession *session = [TLWAIAssistantSession new];
    [self appendPairTo:session disease:@"已过期病名" completed:YES];
    for (NSString *name in @[@"病名一", @"病名二", @"番茄早疫病"]) [self appendPairTo:session disease:name completed:YES];
    [self appendPairTo:session disease:@"未完成不能当诊断" completed:NO];
    NSString *context = [session recentContextWithMaxCharacters:3000 excludingUserIdentifier:@"current"];
    XCTAssertTrue([context containsString:@"番茄早疫病"]);
    XCTAssertFalse([context containsString:@"已过期病名"]);
    XCTAssertFalse([context containsString:@"未完成不能当诊断"]);
    XCTAssertFalse([context containsString:@"private.invalid"]);
}
- (void)testBudgetNeverSplitsComposedClustersAndCurrentUserCanBeExcluded {
    TLWAIAssistantSession *session = [TLWAIAssistantSession new];
    [self appendPairTo:session disease:@"番茄早疫病" completed:YES];
    TLWAIAssistantMessage *user = session.messages.firstObject;
    user.text = [@"👨‍👩‍👧‍👦" stringByPaddingToLength:11000 withString:@"👨‍👩‍👧‍👦" startingAtIndex:0];
    NSString *context = [session recentContextWithMaxCharacters:96 excludingUserIdentifier:@"current"];
    __block NSUInteger clusters = 0;
    [context enumerateSubstringsInRange:NSMakeRange(0, context.length) options:NSStringEnumerationByComposedCharacterSequences usingBlock:^(NSString *s, NSRange range, NSRange enclosing, BOOL *stop) { clusters++; }];
    XCTAssertLessThanOrEqual(clusters, 96u);
    XCTAssertTrue([context containsString:@"番茄早疫病"]);
    XCTAssertNotNil([context dataUsingEncoding:NSUTF8StringEncoding]);
    XCTAssertEqualObjects([session recentContextWithMaxCharacters:3000 excludingUserIdentifier:user.identifier], @"");
}
- (void)testSwitchingSessionsNeverCrossesConversationContext {
    TLWAITurnStore *store = [[TLWAITurnStore alloc] initWithUserIdentifier:17];
    TLWAIAssistantSession *first = store.currentSession;
    [self appendPairTo:first disease:@"番茄早疫病" completed:YES];
    TLWAIAssistantSession *second = [store createSession];
    [self appendPairTo:second disease:@"水稻稻瘟病" completed:YES];
    NSString *context = [second recentContextWithMaxCharacters:3000 excludingUserIdentifier:@"new"];
    XCTAssertTrue([context containsString:@"水稻稻瘟病"]); XCTAssertFalse([context containsString:@"番茄早疫病"]);
    XCTAssertTrue([store selectSessionWithIdentifier:first.identifier]);
    XCTAssertEqual(store.currentSession, first);
    XCTAssertFalse([store selectSessionWithIdentifier:@"missing"]);
    XCTAssertEqual(store.currentSession, first);
}
@end
