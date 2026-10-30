#import <XCTest/XCTest.h>
#import "../TL_AIAssistant/Persistence/TLWAITurnPersistence.h"
#import "../TL_AIAssistant/Models/TLWAIAssistantSession.h"
#import "../TL_AIAssistant/Models/TLWAIAssistantMessage.h"

@interface TLWAITurnPersistenceTests : XCTestCase
@end

@implementation TLWAITurnPersistenceTests

- (void)testIndependentTableRoundTripsDiseaseAndDoesNotUseBusinessDatabaseName {
    NSString *root = [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]];
    TLWAITurnPersistence *store = [[TLWAITurnPersistence alloc] initWithUserIdentifier:9 directory:root];
    XCTAssertTrue([store.databasePath containsString:@"tlw_ai_assistant_9.db"]);
    XCTAssertFalse([store.databasePath containsString:@"tlw_database_"]);
    TLWAIAssistantSession *session = [TLWAIAssistantSession new];
    TLWAIAssistantMessage *assistant = [TLWAIAssistantMessage messageWithRole:TLWAIAssistantMessageRoleAssistant text:@"方案"];
    assistant.completed = YES;
    assistant.diseaseNames = @[@"番茄早疫病"];
    assistant.imageRelativePaths = @[@"keep.jpg"];
    [session appendMessage:assistant];
    XCTAssertTrue([store upsertSession:session]);
    NSString *sidecar = [root stringByAppendingPathComponent:@"keep.jpg"];
    XCTAssertTrue([@"x" writeToFile:sidecar atomically:YES encoding:NSUTF8StringEncoding error:nil]);
    TLWAITurnPersistence *reopened = [[TLWAITurnPersistence alloc] initWithUserIdentifier:9 directory:root];
    TLWAIAssistantMessage *loaded = reopened.loadSessions.firstObject.messages.firstObject;
    XCTAssertEqualObjects(loaded.diseaseNames.firstObject, @"番茄早疫病");
    XCTAssertEqualObjects(loaded.imageRelativePaths.firstObject, @"keep.jpg");
    XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:sidecar]);
}

- (NSDictionary *)checkpointForMessage:(TLWAIAssistantMessage *)message session:(TLWAIAssistantSession *)session {
    return @{@"version":@1, @"clientRequestId":@"stable-client", @"jobId":@"job", @"seq":@8, @"cursor":@"opaque-point",
        @"status":@"running", @"text":@"可靠正文👩🏽‍🌾", @"diseases":@[], @"meta":@{}, @"completionInfo":@{},
        @"fallbackTexts":@[], @"errorMessage":@"", @"ownerId":@9, @"sessionId":session.identifier,
        @"messageId":message.identifier, @"userMessageId":@"user", @"request":@{@"text":@"question"}};
}
- (void)testCanonicalAndCursorReopenTogetherEvenWhenVisibleTextLags {
    NSString *root = [NSTemporaryDirectory() stringByAppendingPathComponent:NSUUID.UUID.UUIDString];
    TLWAITurnPersistence *store = [[TLWAITurnPersistence alloc] initWithUserIdentifier:9 directory:root];
    TLWAIAssistantSession *session = [TLWAIAssistantSession new];
    TLWAIAssistantMessage *message = [TLWAIAssistantMessage messageWithRole:TLWAIAssistantMessageRoleAssistant text:@"屏幕旧前缀"];
    [session appendMessage:message];
    NSDictionary *checkpoint = [self checkpointForMessage:message session:session];
    XCTAssertTrue([store saveRecoveryCheckpoint:checkpoint forMessage:message session:session]);
    TLWAITurnPersistence *reopened = [[TLWAITurnPersistence alloc] initWithUserIdentifier:9 directory:root];
    TLWAIAssistantMessage *loaded = reopened.loadSessions.firstObject.messages.firstObject;
    XCTAssertEqualObjects(loaded.recoveryCheckpoint[@"text"], @"可靠正文👩🏽‍🌾");
    XCTAssertEqualObjects(loaded.recoveryCheckpoint[@"seq"], @8);
    XCTAssertEqualObjects(loaded.recoveryCheckpoint[@"cursor"], @"opaque-point");
    XCTAssertEqualObjects(loaded.identifier, message.identifier);
}
- (void)testForeignOwnerCheckpointCannotOverwritePreviousCommittedState {
    NSString *root = [NSTemporaryDirectory() stringByAppendingPathComponent:NSUUID.UUID.UUIDString];
    TLWAITurnPersistence *store = [[TLWAITurnPersistence alloc] initWithUserIdentifier:9 directory:root];
    TLWAIAssistantSession *session = [TLWAIAssistantSession new];
    TLWAIAssistantMessage *message = [TLWAIAssistantMessage messageWithRole:TLWAIAssistantMessageRoleAssistant text:@"original"];
    [session appendMessage:message];
    NSDictionary *checkpoint = [self checkpointForMessage:message session:session];
    XCTAssertTrue([store saveRecoveryCheckpoint:checkpoint forMessage:message session:session]);
    NSMutableDictionary *foreign = [checkpoint mutableCopy]; foreign[@"ownerId"] = @10; foreign[@"text"] = @"foreign";
    XCTAssertFalse([store saveRecoveryCheckpoint:foreign forMessage:message session:session]);
    TLWAITurnPersistence *reopened = [[TLWAITurnPersistence alloc] initWithUserIdentifier:9 directory:root];
    NSDictionary *loaded = reopened.loadSessions.firstObject.messages.firstObject.recoveryCheckpoint;
    XCTAssertEqualObjects(loaded[@"text"], @"可靠正文👩🏽‍🌾");
    XCTAssertEqualObjects(loaded[@"cursor"], @"opaque-point");
    XCTAssertEqualObjects(message.recoveryCheckpoint, checkpoint);
}
- (void)testInitialCheckpointAlsoDurablyPreservesItsQuestion {
    NSString *root = [NSTemporaryDirectory() stringByAppendingPathComponent:NSUUID.UUID.UUIDString];
    TLWAITurnPersistence *store = [[TLWAITurnPersistence alloc] initWithUserIdentifier:9 directory:root];
    TLWAIAssistantSession *session = [TLWAIAssistantSession new];
    TLWAIAssistantMessage *user = [TLWAIAssistantMessage messageWithRole:TLWAIAssistantMessageRoleUser text:@"question"];
    TLWAIAssistantMessage *message = [TLWAIAssistantMessage messageWithRole:TLWAIAssistantMessageRoleAssistant text:@"thinking"];
    [session appendMessage:user]; [session appendMessage:message];
    NSMutableDictionary *checkpoint = [[self checkpointForMessage:message session:session] mutableCopy];
    checkpoint[@"jobId"] = @""; checkpoint[@"seq"] = @0; checkpoint[@"cursor"] = @"";
    checkpoint[@"status"] = @"creating"; checkpoint[@"text"] = @""; checkpoint[@"userMessageId"] = user.identifier;
    XCTAssertTrue([store saveRecoveryCheckpoint:checkpoint forMessage:message session:session]);
    TLWAITurnPersistence *reopened = [[TLWAITurnPersistence alloc] initWithUserIdentifier:9 directory:root];
    NSArray<TLWAIAssistantMessage *> *loaded = reopened.loadSessions.firstObject.messages;
    XCTAssertEqual(loaded.count, 2u);
    XCTAssertTrue([loaded valueForKey:@"identifier"] && [[loaded valueForKey:@"identifier"] containsObject:user.identifier]);
    TLWAIAssistantMessage *savedQuestion = nil;
    for (TLWAIAssistantMessage *candidate in loaded) if ([candidate.identifier isEqual:user.identifier]) savedQuestion = candidate;
    XCTAssertEqualObjects(savedQuestion.text, @"question");
}
@end
