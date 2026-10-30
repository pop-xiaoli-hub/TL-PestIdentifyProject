#import <XCTest/XCTest.h>
#import "TLWAIRecoveryState.h"
#import "TLWAIEventEnvelope.h"
#import "../TL_AIAssistant/TLWAIJobStreamClient.h"

@interface TLWAIRecoveryStateTests : XCTestCase
@end
@implementation TLWAIRecoveryStateTests
- (NSDictionary *)initialCheckpoint {
    return @{ @"version":@1, @"clientRequestId":@"client", @"jobId":@"job", @"seq":@0,
        @"cursor":@"", @"status":@"running", @"text":@"", @"diseases":@[], @"meta":@{},
        @"completionInfo":@{}, @"fallbackTexts":@[], @"errorMessage":@"", @"request":@{@"text":@"question"},
        @"ownerId":@9, @"sessionId":@"session", @"messageId":@"assistant", @"userMessageId":@"user" };
}
- (TLWAIEventEnvelope *)event:(NSString *)name seq:(NSNumber *)seq payload:(NSDictionary *)payload {
    return [[TLWAIEventEnvelope alloc] initWithEventName:name eventID:[NSString stringWithFormat:@"opaque-%@", seq]
        payload:@{@"jobId":@"job", @"seq":seq, @"payload":payload}];
}
- (NSDictionary *)snapshot:(NSString *)text seq:(NSNumber *)seq status:(NSString *)status {
    return @{ @"protocol":@"stream-job.v1", @"jobId":@"job", @"status":status, @"snapshotSeq":seq,
        @"resumeCursor":@"opaque-snapshot", @"canonicalMessage":@{@"text":text, @"diseases":@[], @"meta":@{},
        @"completionInfo":@{}, @"fallbackTexts":@[], @"errorMessage":@""} };
}
- (void)testDuplicateDoesNotAppendUnicodeOrAdvanceCursor {
    TLWAIRecoveryState *state = [[TLWAIRecoveryState alloc] initWithCheckpoint:self.initialCheckpoint];
    __block NSUInteger writes = 0;
    TLWAIRecoveryCommit commit = ^BOOL(NSDictionary *record) { writes++; return YES; };
    TLWAIEventEnvelope *first = [self event:@"plan_delta" seq:@1 payload:@{@"text":@"A👩🏽‍🌾e\u0301"}];
    XCTAssertEqual([state applyEnvelope:first commit:commit error:nil], TLWAIRecoveryApplyResultAccepted);
    XCTAssertEqual([state applyEnvelope:first commit:commit error:nil], TLWAIRecoveryApplyResultDuplicate);
    XCTAssertEqualObjects(state.checkpoint[@"text"], @"A👩🏽‍🌾e\u0301");
    XCTAssertEqualObjects(state.checkpoint[@"cursor"], @"opaque-1");
    XCTAssertEqual(writes, 1u);
}
- (void)testGapNeverAppendsOutOfOrderText {
    TLWAIRecoveryState *state = [[TLWAIRecoveryState alloc] initWithCheckpoint:self.initialCheckpoint];
    TLWAIRecoveryCommit commit = ^BOOL(NSDictionary *record) { return YES; };
    [state applyEnvelope:[self event:@"plan_delta" seq:@1 payload:@{@"text":@"prefix"}] commit:commit error:nil];
    XCTAssertEqual([state applyEnvelope:[self event:@"plan_delta" seq:@3 payload:@{@"text":@"wrong-tail"}] commit:commit error:nil], TLWAIRecoveryApplyResultGap);
    XCTAssertEqualObjects(state.checkpoint[@"text"], @"prefix");
    XCTAssertEqualObjects(state.checkpoint[@"seq"], @1);
}
- (void)testStorageFailureKeepsCanonicalAndCursorAtSamePreviousPoint {
    TLWAIRecoveryState *state = [[TLWAIRecoveryState alloc] initWithCheckpoint:self.initialCheckpoint];
    [state applyEnvelope:[self event:@"plan_delta" seq:@1 payload:@{@"text":@"saved"}] commit:^BOOL(NSDictionary *r) { return YES; } error:nil];
    NSError *error = nil;
    XCTAssertEqual([state applyEnvelope:[self event:@"plan_delta" seq:@2 payload:@{@"text":@"unsaved"}]
        commit:^BOOL(NSDictionary *r) { return NO; } error:&error], TLWAIRecoveryApplyResultStorageFailed);
    XCTAssertEqualObjects(state.checkpoint[@"text"], @"saved");
    XCTAssertEqualObjects(state.checkpoint[@"seq"], @1);
    XCTAssertEqualObjects(state.checkpoint[@"cursor"], @"opaque-1");
    XCTAssertEqualObjects(error.domain, @"TLWAIRecoveryState");
}
- (void)testAuthoritativeSnapshotReplacesPartialAndPreservesRequestIdentity {
    TLWAIRecoveryState *state = [[TLWAIRecoveryState alloc] initWithCheckpoint:self.initialCheckpoint];
    TLWAIRecoveryCommit commit = ^BOOL(NSDictionary *record) { return YES; };
    [state applyEnvelope:[self event:@"plan_delta" seq:@1 payload:@{@"text":@"partial"}] commit:commit error:nil];
    XCTAssertTrue([state applySnapshot:[self snapshot:@"authoritative" seq:@8 status:@"running"] commit:commit error:nil]);
    XCTAssertEqualObjects(state.checkpoint[@"text"], @"authoritative");
    XCTAssertEqualObjects(state.checkpoint[@"seq"], @8);
    XCTAssertEqualObjects(state.checkpoint[@"ownerId"], @9);
    XCTAssertEqualObjects(state.checkpoint[@"request"], @{@"text":@"question"});
    XCTAssertFalse([state applySnapshot:[self snapshot:@"stale" seq:@7 status:@"running"] commit:commit error:nil]);
    XCTAssertEqualObjects(state.checkpoint[@"text"], @"authoritative");
}
- (void)testPlanIsReplacementAndTerminalCannotBeRevived {
    TLWAIRecoveryState *state = [[TLWAIRecoveryState alloc] initWithCheckpoint:self.initialCheckpoint];
    TLWAIRecoveryCommit commit = ^BOOL(NSDictionary *record) { return YES; };
    [state applyEnvelope:[self event:@"plan_delta" seq:@1 payload:@{@"text":@"old"}] commit:commit error:nil];
    [state applyEnvelope:[self event:@"plan" seq:@2 payload:@{@"controlPlan":@"final"}] commit:commit error:nil];
    [state applyEnvelope:[self event:@"done" seq:@3 payload:@{}] commit:commit error:nil];
    XCTAssertEqual([state applyEnvelope:[self event:@"plan_delta" seq:@4 payload:@{@"text":@"late"}] commit:commit error:nil], TLWAIRecoveryApplyResultInvalid);
    XCTAssertFalse([state applySnapshot:[self snapshot:@"revived" seq:@4 status:@"running"] commit:commit error:nil]);
    XCTAssertEqualObjects(state.checkpoint[@"text"], @"final");
    XCTAssertEqualObjects(state.checkpoint[@"status"], @"completed");
}
- (void)testForeignJobAndInvalidNumericSequenceCannotMutateCanonical {
    TLWAIRecoveryState *state = [[TLWAIRecoveryState alloc] initWithCheckpoint:self.initialCheckpoint];
    TLWAIRecoveryCommit commit = ^BOOL(NSDictionary *record) { return YES; };
    for (NSNumber *sequence in @[@YES, @1.5, @(-1)])
        XCTAssertEqual([state applyEnvelope:[self event:@"plan_delta" seq:sequence payload:@{@"text":@"bad"}] commit:commit error:nil], TLWAIRecoveryApplyResultInvalid);
    NSMutableDictionary *snapshot = [[self snapshot:@"foreign" seq:@2 status:@"running"] mutableCopy];
    snapshot[@"jobId"] = @"other-job";
    XCTAssertFalse([state applySnapshot:snapshot commit:commit error:nil]);
    XCTAssertEqualObjects(state.checkpoint[@"text"], @"");
    XCTAssertEqualObjects(state.checkpoint[@"seq"], @0);
}
- (void)testAdvancingSequenceCannotReusePreviousResumeCursor {
    TLWAIRecoveryState *state = [[TLWAIRecoveryState alloc] initWithCheckpoint:self.initialCheckpoint];
    TLWAIRecoveryCommit commit = ^BOOL(NSDictionary *record) { return YES; };
    [state applyEnvelope:[self event:@"plan_delta" seq:@1 payload:@{@"text":@"saved"}] commit:commit error:nil];
    TLWAIEventEnvelope *bad = [[TLWAIEventEnvelope alloc] initWithEventName:@"plan_delta" eventID:@"opaque-1"
        payload:@{@"jobId":@"job", @"seq":@2, @"payload":@{@"text":@"unsafe"}}];
    XCTAssertEqual([state applyEnvelope:bad commit:commit error:nil], TLWAIRecoveryApplyResultInvalid);
    XCTAssertEqualObjects(state.checkpoint[@"text"], @"saved");
    XCTAssertEqualObjects(state.checkpoint[@"seq"], @1);
}
- (void)testServerCancelledEventIsTerminalNotSuccessfulCompletion {
    TLWAIRecoveryState *state = [[TLWAIRecoveryState alloc] initWithCheckpoint:self.initialCheckpoint];
    TLWAIRecoveryCommit commit = ^BOOL(NSDictionary *record) { return YES; };
    [state applyEnvelope:[self event:@"plan_delta" seq:@1 payload:@{@"text":@"partial"}] commit:commit error:nil];
    [state applyEnvelope:[self event:@"error" seq:@2 payload:@{@"code":@"cancelled", @"message":@"cancelled"}] commit:commit error:nil];
    XCTAssertEqualObjects(state.checkpoint[@"status"], @"cancelled");
    XCTAssertEqual([state applyEnvelope:[self event:@"done" seq:@3 payload:@{}] commit:commit error:nil], TLWAIRecoveryApplyResultInvalid);
    XCTAssertEqualObjects(state.checkpoint[@"text"], @"partial");
}
- (void)testBindingRequiresSameClientRequestAndDoesNotSkipCompletedJobReplay {
    NSMutableDictionary *initial = [self.initialCheckpoint mutableCopy];
    initial[@"jobId"] = @""; initial[@"status"] = @"creating";
    TLWAIRecoveryState *state = [[TLWAIRecoveryState alloc] initWithCheckpoint:initial];
    TLWAIRecoveryCommit commit = ^BOOL(NSDictionary *record) { return YES; };
    NSMutableDictionary *response = [@{@"protocol":@"stream-job.v1", @"jobId":@"remote", @"clientRequestId":@"wrong", @"status":@"completed"} mutableCopy];
    XCTAssertFalse([state bindCreatedJob:response commit:commit error:nil]);
    XCTAssertEqualObjects(state.checkpoint[@"jobId"], @"");
    response[@"clientRequestId"] = @"client";
    XCTAssertTrue([state bindCreatedJob:response commit:commit error:nil]);
    XCTAssertEqualObjects(state.checkpoint[@"jobId"], @"remote");
    XCTAssertEqualObjects(state.checkpoint[@"status"], @"running");
    XCTAssertEqualObjects(state.checkpoint[@"seq"], @0);
}
- (void)testRestartedCreateWithoutJobMustLookupInsteadOfPosting {
    NSMutableDictionary *sent = [self.initialCheckpoint mutableCopy];
    sent[@"jobId"] = @""; sent[@"creationSent"] = @YES; sent[@"creationRejected"] = @NO;
    XCTAssertFalse(TLWAIJobMaySilentlyCreate(sent));
    sent[@"creationRejected"] = @YES;
    XCTAssertTrue(TLWAIJobMaySilentlyCreate(sent));
    [sent removeObjectForKey:@"creationSent"]; [sent removeObjectForKey:@"creationRejected"];
    XCTAssertTrue(TLWAIJobMaySilentlyCreate(sent));
    sent[@"jobId"] = @"job"; sent[@"creationSent"] = @YES; sent[@"creationRejected"] = @YES;
    XCTAssertFalse(TLWAIJobMaySilentlyCreate(sent));
}
@end
