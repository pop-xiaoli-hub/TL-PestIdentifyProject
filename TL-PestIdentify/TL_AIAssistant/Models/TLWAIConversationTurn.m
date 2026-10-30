#import "TLWAIConversationTurn.h"
#import "TLWAIAssistantMessage.h"
#import "TLWAIStreamClient.h"
#import "TLWAIFramePacer.h"
#import "TLWAITrace.h"
#import "TLWAITextPresentation.h"
@interface TLWAIConversationTurn ()
@property (nonatomic, assign, readwrite) TLWAIConversationTurnState state;
@property (nonatomic, assign, readwrite) NSUInteger generation;
@property (nonatomic, assign, readwrite) NSUInteger retryCount;
@property (nonatomic, assign, readwrite) NSUInteger lastAppliedSeq;
@end
@implementation TLWAIConversationTurn
- (instancetype)initWithUserMessage:(TLWAIAssistantMessage *)userMessage assistantMessage:(TLWAIAssistantMessage *)assistantMessage {
    if ((self = [super init])) {
        _identifier = NSUUID.UUID.UUIDString.lowercaseString;
        NSString *savedClientID = assistantMessage.recoveryCheckpoint[@"clientRequestId"];
        _clientRequestId = [savedClientID isKindOfClass:NSString.class] && savedClientID.length ? savedClientID.copy : _identifier;
        _userMessage = userMessage; _assistantMessage = assistantMessage;
        _pendingDelta = [NSMutableString string]; _textPresentation = [TLWAITextPresentation new];
        NSString *received = assistantMessage.recoveryCheckpoint[@"text"];
        if ([received isKindOfClass:NSString.class] && received.length)
            [_textPresentation appendText:received atTime:NSProcessInfo.processInfo.systemUptime];
        _state = TLWAIConversationTurnStateIdle;
        _trace = [TLWAITrace new];
        _assistantMessage.trace = _trace;
        [_trace mark:TLWAITraceStageSend count:0];
    }
    return self;
}
- (NSString *)planAccumulated { return self.textPresentation.source; }
- (BOOL)isTerminal { return self.state >= TLWAIConversationTurnStateCompleted; }
- (BOOL)beginUpload {
    if (self.state != TLWAIConversationTurnStateIdle) return NO;
    self.state = TLWAIConversationTurnStateUploading;
    self.assistantMessage.status = TLWAIAssistantMessageStatusSending;
    return YES;
}
- (BOOL)beginConnection {
    if (self.state != TLWAIConversationTurnStateIdle && self.state != TLWAIConversationTurnStateUploading && self.state != TLWAIConversationTurnStateAuthRefresh) return NO;
    self.generation++;
    self.state = TLWAIConversationTurnStateConnecting;
    self.assistantMessage.status = TLWAIAssistantMessageStatusSending;
    return YES;
}
- (BOOL)acceptsIdentifier:(NSString *)identifier generation:(NSUInteger)generation {
    return !self.isTerminal && self.state != TLWAIConversationTurnStateAuthRefresh &&
        [self.identifier isEqualToString:identifier] && self.generation == generation;
}
- (BOOL)recordFrameForGeneration:(NSUInteger)generation {
    if (![self acceptsIdentifier:self.identifier generation:generation] ||
        (self.state != TLWAIConversationTurnStateConnecting && self.state != TLWAIConversationTurnStateStreaming && self.state != TLWAIConversationTurnStateRecovering)) return NO;
    self.state = TLWAIConversationTurnStateStreaming;
    self.lastAppliedSeq++;
    return YES;
}
- (void)appendDelta:(NSString *)delta generation:(NSUInteger)generation {
    if (![self recordFrameForGeneration:generation] || delta.length == 0) return;
    [self.pendingDelta appendString:delta];
}
- (void)replacePlan:(NSString *)text generation:(NSUInteger)generation {
    if (![self recordFrameForGeneration:generation]) return;
    [self.pendingDelta setString:@""]; [self.textPresentation reset];
    [self.textPresentation appendText:text ?: @"" atTime:NSProcessInfo.processInfo.systemUptime];
    [self.textPresentation finish];
}
- (void)restoreReceivedPlan:(NSString *)text generation:(NSUInteger)generation {
    if (![self acceptsIdentifier:self.identifier generation:generation]) return;
    [self.pendingDelta setString:@""];
    [self.textPresentation reset];
    [self.textPresentation appendText:text ?: @"" atTime:NSProcessInfo.processInfo.systemUptime];
}
- (void)setRecovering:(BOOL)recovering generation:(NSUInteger)generation {
    if (![self acceptsIdentifier:self.identifier generation:generation]) return;
    if (recovering) self.state = TLWAIConversationTurnStateRecovering;
    else if (self.state == TLWAIConversationTurnStateRecovering) self.state = TLWAIConversationTurnStateStreaming;
}
- (NSString *)consumePendingWithBudget:(NSUInteger)budget {
    if (budget == 0 || self.pendingDelta.length == 0) return @"";
    __block NSUInteger length = self.pendingDelta.length;
    if (budget != NSUIntegerMax) {
        __block NSUInteger count = 0;
        length = 0;
        [self.pendingDelta enumerateSubstringsInRange:NSMakeRange(0, self.pendingDelta.length) options:NSStringEnumerationByComposedCharacterSequences usingBlock:^(NSString *substring, NSRange range, NSRange enclosing, BOOL *stop) {
            length = NSMaxRange(range); count++;
            if (count >= budget) *stop = YES;
        }];
    }
    NSString *chunk = [self.pendingDelta substringToIndex:length];
    [self.textPresentation appendText:chunk atTime:NSProcessInfo.processInfo.systemUptime];
    [self.pendingDelta deleteCharactersInRange:NSMakeRange(0, length)];
    return chunk;
}
- (NSString *)flushAllPendingDelta { return [self consumePendingWithBudget:NSUIntegerMax]; }
- (BOOL)prepareAuthRefresh {
    if ((self.state != TLWAIConversationTurnStateConnecting && self.state != TLWAIConversationTurnStateStreaming &&
         self.state != TLWAIConversationTurnStateRecovering) || self.retryCount != 0) return NO;
    self.retryCount = 1; self.generation++; self.state = TLWAIConversationTurnStateAuthRefresh;
    BOOL preserve = self.streamClient.supportsJobRecovery;
    [self.streamClient cancel]; self.streamClient = nil;
    [self.framePacer invalidate]; self.framePacer = nil;
    if (!preserve) {
        [self.pendingDelta setString:@""]; [self.textPresentation reset];
        [self.assistantMessage resetAssistantMetadata]; self.serverRequestId = nil;
    }
    return YES;
}
- (BOOL)finishWithState:(TLWAIConversationTurnState)state {
    if (self.isTerminal || state < TLWAIConversationTurnStateCompleted) return NO;
    [self flushAllPendingDelta];
    [self.textPresentation finish];
    [self.uploadTask cancel]; self.uploadTask = nil;
    [self.streamClient cancel]; self.streamClient = nil;
    [self.framePacer invalidate]; self.framePacer = nil;
    self.authRestart = nil; self.generation++; self.state = state;
    self.assistantMessage.completed = state == TLWAIConversationTurnStateCompleted;
    self.assistantMessage.status = (state == TLWAIConversationTurnStateFailed || state == TLWAIConversationTurnStateIncomplete)
        ? TLWAIAssistantMessageStatusFailed : TLWAIAssistantMessageStatusIdle;
    [self.trace mark:TLWAITraceStageTerminal count:state];
    return YES;
}
@end
