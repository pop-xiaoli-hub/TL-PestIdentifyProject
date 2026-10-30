#import "TLWAIRecoveryState.h"
#import "TLWAIEventEnvelope.h"
#import <math.h>

static BOOL TLWAIRecoveryInteger(id value) {
    if (![value isKindOfClass:NSNumber.class] || CFGetTypeID((__bridge CFTypeRef)value) == CFBooleanGetTypeID()) return NO;
    double number = [value doubleValue];
    return isfinite(number) && number >= 0 && number <= 9007199254740991.0 && floor(number) == number;
}
static BOOL TLWAIRecoveryString(id value) { return [value isKindOfClass:NSString.class]; }
static BOOL TLWAIRecoveryCursor(id value) {
    return TLWAIRecoveryString(value) &&
        [value rangeOfCharacterFromSet:NSCharacterSet.newlineCharacterSet].location == NSNotFound &&
        [value rangeOfCharacterFromSet:NSCharacterSet.controlCharacterSet].location == NSNotFound;
}
static BOOL TLWAIRecoveryTerminal(NSString *status) {
    return [status isEqualToString:@"completed"] || [status isEqualToString:@"failed"] || [status isEqualToString:@"cancelled"];
}
static BOOL TLWAIRecoveryStatus(id status) {
    return TLWAIRecoveryString(status) && ([status isEqualToString:@"creating"] || [status isEqualToString:@"running"] || TLWAIRecoveryTerminal(status));
}
static BOOL TLWAIRecoveryArray(id value, Class itemClass) {
    if (![value isKindOfClass:NSArray.class]) return NO;
    for (id item in value) if (![item isKindOfClass:itemClass]) return NO;
    return YES;
}
static BOOL TLWAIRecoveryCanonical(NSDictionary *value) {
    return [value isKindOfClass:NSDictionary.class] && TLWAIRecoveryString(value[@"text"]) &&
        TLWAIRecoveryString(value[@"errorMessage"]) && TLWAIRecoveryArray(value[@"diseases"], NSDictionary.class) &&
        TLWAIRecoveryArray(value[@"fallbackTexts"], NSString.class) &&
        [value[@"meta"] isKindOfClass:NSDictionary.class] && [value[@"completionInfo"] isKindOfClass:NSDictionary.class];
}
static NSError *TLWAIRecoveryError(NSInteger code, NSString *message) {
    return [NSError errorWithDomain:@"TLWAIRecoveryState" code:code userInfo:@{NSLocalizedDescriptionKey:message}];
}

@implementation TLWAIRecoveryState
- (instancetype)initWithCheckpoint:(NSDictionary *)checkpoint {
    if (![checkpoint isKindOfClass:NSDictionary.class] || !TLWAIRecoveryInteger(checkpoint[@"version"]) ||
        [checkpoint[@"version"] integerValue] != 1 || !TLWAIRecoveryInteger(checkpoint[@"seq"]) ||
        !TLWAIRecoveryInteger(checkpoint[@"ownerId"]) || !TLWAIRecoveryStatus(checkpoint[@"status"]) ||
        !TLWAIRecoveryString(checkpoint[@"jobId"]) || !TLWAIRecoveryCursor(checkpoint[@"cursor"]) ||
        !TLWAIRecoveryCanonical(checkpoint) || ![checkpoint[@"request"] isKindOfClass:NSDictionary.class]) return nil;
    for (NSString *key in @[@"clientRequestId", @"sessionId", @"messageId", @"userMessageId"])
        if (!TLWAIRecoveryString(checkpoint[key]) || ![checkpoint[key] length]) return nil;
    if ([checkpoint[@"seq"] unsignedLongLongValue] && ![checkpoint[@"cursor"] length]) return nil;
    if ((self = [super init])) _checkpoint = checkpoint.copy;
    return self;
}
- (BOOL)commitCandidate:(NSMutableDictionary *)candidate commit:(TLWAIRecoveryCommit)commit error:(NSError **)error {
    NSDictionary *record = candidate.copy;
    if (!commit || !commit(record)) {
        if (error) *error = TLWAIRecoveryError(3, @"回复检查点保存失败，已保留上次可靠进度");
        return NO;
    }
    _checkpoint = record;
    return YES;
}
- (BOOL)bindCreatedJob:(NSDictionary *)response commit:(TLWAIRecoveryCommit)commit error:(NSError **)error {
    if (![response isKindOfClass:NSDictionary.class]) {
        if (error) *error = TLWAIRecoveryError(1, @"创建任务响应不是对象");
        return NO;
    }
    NSString *job = response[@"jobId"];
    BOOL valid = [response isKindOfClass:NSDictionary.class] && [response[@"protocol"] isEqual:@"stream-job.v1"] &&
        TLWAIRecoveryString(job) && job.length && [response[@"clientRequestId"] isEqual:self.checkpoint[@"clientRequestId"]] &&
        TLWAIRecoveryStatus(response[@"status"]) && ![response[@"status"] isEqual:@"creating"] &&
        !TLWAIRecoveryTerminal(self.checkpoint[@"status"]);
    NSString *oldJob = self.checkpoint[@"jobId"];
    if (!valid || (oldJob.length && ![oldJob isEqualToString:job])) {
        if (error) *error = TLWAIRecoveryError(1, @"创建任务响应与当前请求不匹配");
        return NO;
    }
    NSMutableDictionary *candidate = [self.checkpoint mutableCopy];
    candidate[@"jobId"] = job;
    candidate[@"status"] = @"running"; // 先补齐日志/快照，不能仅凭创建 ACK 宣称已显示完成。
    return [self commitCandidate:candidate commit:commit error:error];
}
- (TLWAIRecoveryApplyResult)applyEnvelope:(TLWAIEventEnvelope *)envelope commit:(TLWAIRecoveryCommit)commit error:(NSError **)error {
    NSDictionary *wire = envelope.payload;
    id sequence = wire[@"seq"];
    NSDictionary *payload = wire[@"payload"];
    BOOL valid = [wire[@"jobId"] isEqual:self.checkpoint[@"jobId"]] && [wire[@"jobId"] length] &&
        TLWAIRecoveryInteger(sequence) && [sequence unsignedLongLongValue] > 0 &&
        TLWAIRecoveryCursor(envelope.eventID) && envelope.eventID.length && [payload isKindOfClass:NSDictionary.class];
    if (!valid) {
        if (error) *error = TLWAIRecoveryError(2, @"恢复事件的任务、序号或游标无效");
        return TLWAIRecoveryApplyResultInvalid;
    }
    unsigned long long current = [self.checkpoint[@"seq"] unsignedLongLongValue], next = [sequence unsignedLongLongValue];
    if (next <= current) return TLWAIRecoveryApplyResultDuplicate;
    if ([envelope.eventID isEqual:self.checkpoint[@"cursor"]]) {
        if (error) *error = TLWAIRecoveryError(2, @"新事件重复使用了旧恢复游标");
        return TLWAIRecoveryApplyResultInvalid;
    }
    if (TLWAIRecoveryTerminal(self.checkpoint[@"status"])) {
        if (error) *error = TLWAIRecoveryError(2, @"任务已结束，拒绝迟到事件");
        return TLWAIRecoveryApplyResultInvalid;
    }
    if (next != current + 1) return TLWAIRecoveryApplyResultGap;
    NSString *name = envelope.eventName;
    NSMutableDictionary *candidate = [self.checkpoint mutableCopy];
    if ([name isEqualToString:@"plan_delta"]) {
        valid = TLWAIRecoveryString(payload[@"text"]);
        if (valid) candidate[@"text"] = [self.checkpoint[@"text"] stringByAppendingString:payload[@"text"]];
    } else if ([name isEqualToString:@"plan"]) {
        valid = TLWAIRecoveryString(payload[@"controlPlan"]);
        if (valid) candidate[@"text"] = payload[@"controlPlan"];
    } else if ([name isEqualToString:@"disease"]) {
        valid = TLWAIRecoveryArray(payload[@"diseases"], NSDictionary.class);
        if (valid) candidate[@"diseases"] = [payload[@"diseases"] copy];
    } else if ([name isEqualToString:@"meta"]) {
        candidate[@"meta"] = payload.copy;
    } else if ([name isEqualToString:@"done"]) {
        candidate[@"status"] = @"completed";
        candidate[@"completionInfo"] = payload.copy;
    } else if ([name isEqualToString:@"error"]) {
        valid = TLWAIRecoveryString(payload[@"message"]);
        if (valid) {
            candidate[@"status"] = [payload[@"code"] isEqual:@"cancelled"] ? @"cancelled" : @"failed";
            candidate[@"errorMessage"] = payload[@"message"];
        }
    } else {
        TLWAIEventEnvelope *inner = [[TLWAIEventEnvelope alloc] initWithEventName:name eventID:envelope.eventID payload:payload];
        if (inner.fallbackText.length) candidate[@"fallbackTexts"] = [self.checkpoint[@"fallbackTexts"] arrayByAddingObject:inner.fallbackText];
    }
    if (!valid) {
        if (error) *error = TLWAIRecoveryError(2, @"任务事件的业务内容格式无效");
        return TLWAIRecoveryApplyResultInvalid;
    }
    candidate[@"seq"] = sequence;
    candidate[@"cursor"] = envelope.eventID;
    if (![self commitCandidate:candidate commit:commit error:error]) return TLWAIRecoveryApplyResultStorageFailed;
    return TLWAIRecoveryApplyResultAccepted;
}
- (BOOL)applySnapshot:(NSDictionary *)snapshot commit:(TLWAIRecoveryCommit)commit error:(NSError **)error {
    if (![snapshot isKindOfClass:NSDictionary.class]) {
        if (error) *error = TLWAIRecoveryError(4, @"任务快照不是对象");
        return NO;
    }
    NSDictionary *canonical = snapshot[@"canonicalMessage"];
    id sequence = snapshot[@"snapshotSeq"];
    NSString *cursor = snapshot[@"resumeCursor"], *status = snapshot[@"status"];
    BOOL valid = [snapshot isKindOfClass:NSDictionary.class] && [snapshot[@"protocol"] isEqual:@"stream-job.v1"] &&
        [snapshot[@"jobId"] isEqual:self.checkpoint[@"jobId"]] && [snapshot[@"jobId"] length] &&
        TLWAIRecoveryInteger(sequence) && [sequence unsignedLongLongValue] >= [self.checkpoint[@"seq"] unsignedLongLongValue] &&
        TLWAIRecoveryCursor(cursor) && ([sequence unsignedLongLongValue] == 0 || cursor.length) &&
        TLWAIRecoveryStatus(status) && ![status isEqualToString:@"creating"] && TLWAIRecoveryCanonical(canonical);
    if (TLWAIRecoveryTerminal(self.checkpoint[@"status"]))
        valid = valid && [status isEqual:self.checkpoint[@"status"]] && [sequence isEqual:self.checkpoint[@"seq"]];
    if (!valid) {
        if (error) *error = TLWAIRecoveryError(4, @"任务快照不一致，未覆盖当前回复");
        return NO;
    }
    NSMutableDictionary *candidate = [self.checkpoint mutableCopy];
    for (NSString *key in @[@"text", @"diseases", @"meta", @"completionInfo", @"fallbackTexts", @"errorMessage"])
        candidate[key] = [canonical[key] copy];
    candidate[@"seq"] = sequence;
    candidate[@"cursor"] = cursor;
    candidate[@"status"] = status;
    return [self commitCandidate:candidate commit:commit error:error];
}
@end
