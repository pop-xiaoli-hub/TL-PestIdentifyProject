#import "TLWAITextPresentation.h"

typedef NS_ENUM(NSUInteger, TLWAIInlineHold) { TLWAIInlineHoldNone, TLWAIInlineHoldStar, TLWAIInlineHoldCode, TLWAIInlineHoldBold, TLWAIInlineHoldLink };
@interface TLWAITextPresentation ()
@property (nonatomic, strong) NSMutableString *raw;
@property (nonatomic, strong) NSMutableString *held;
@property (nonatomic, strong) NSMutableString *line;
@property (nonatomic, copy, nullable) NSString *visibleSnapshot;
@property (nonatomic, assign) NSUInteger visibleLength;
@property (nonatomic, assign) TLWAIInlineHold hold;
@property (nonatomic, assign) NSUInteger heldClusters;
@property (nonatomic, assign) NSTimeInterval heldSince;
@property (nonatomic, assign) NSUInteger linkPhase;
@property (nonatomic, assign) BOOL previousStar;
@property (nonatomic, assign) BOOL escaped;
/// 仅为围栏内的字面量放行保存词法上下文，不生成块结构。
@property (nonatomic, assign) BOOL inFence;
@property (nonatomic, assign) BOOL openingFenceLine;
@property (nonatomic, assign) unichar fenceCharacter;
@property (nonatomic, assign) NSUInteger fenceLength;
@end

@implementation TLWAITextPresentation
- (instancetype)init {
    if ((self = [super init])) {
        _raw = [NSMutableString string]; _held = [NSMutableString string]; _line = [NSMutableString string];
    }
    return self;
}
- (NSString *)source { return self.raw; }
- (NSString *)visibleText {
    if (!self.visibleSnapshot) self.visibleSnapshot = [self.raw substringToIndex:self.visibleLength];
    return self.visibleSnapshot;
}
- (BOOL)hasHeldTail { return self.hold != TLWAIInlineHoldNone; }
- (void)tl_emitLength:(NSUInteger)length {
    if (!length) return;
    self.visibleLength += length; self.visibleSnapshot = nil;
}
- (void)tl_releaseHeld {
    [self tl_emitLength:self.held.length]; [self.held setString:@""];
    self.hold = TLWAIInlineHoldNone; self.heldClusters = 0;
    self.linkPhase = 0; self.previousStar = NO; self.escaped = NO;
}
- (BOOL)releaseExpiredAtTime:(NSTimeInterval)time {
    if (!self.hasHeldTail || time - self.heldSince < 0.25) return NO;
    [self tl_releaseHeld]; return YES;
}
- (void)tl_inline:(NSString *)character time:(NSTimeInterval)time {
    if ([character rangeOfCharacterFromSet:NSCharacterSet.newlineCharacterSet].location != NSNotFound) {
        [self tl_releaseHeld]; [self tl_emitLength:character.length]; return;
    }
    if (!self.hasHeldTail) {
        if (self.escaped) { [self tl_emitLength:character.length]; self.escaped = NO; return; }
        if ([character isEqualToString:@"\\"]) { [self tl_emitLength:character.length]; self.escaped = YES; return; }
        if ([character isEqualToString:@"`"]) self.hold = TLWAIInlineHoldCode;
        else if ([character isEqualToString:@"*"]) self.hold = TLWAIInlineHoldStar;
        else if ([character isEqualToString:@"["]) self.hold = TLWAIInlineHoldLink;
        else { [self tl_emitLength:character.length]; return; }
        [self.held appendString:character]; self.heldClusters = 1; self.heldSince = time; return;
    }
    if (self.hold == TLWAIInlineHoldStar && ![character isEqualToString:@"*"]) {
        [self tl_releaseHeld]; [self tl_inline:character time:time]; return;
    }
    if (self.hold == TLWAIInlineHoldLink && self.linkPhase == 1 && ![character isEqualToString:@"("]) {
        [self tl_releaseHeld]; [self tl_inline:character time:time]; return;
    }
    [self.held appendString:character]; self.heldClusters++;
    if (self.escaped) self.escaped = NO;
    else if ([character isEqualToString:@"\\"]) self.escaped = YES;
    else if (self.hold == TLWAIInlineHoldStar) self.hold = TLWAIInlineHoldBold;
    else if (self.hold == TLWAIInlineHoldCode && [character isEqualToString:@"`"]) [self tl_releaseHeld];
    else if (self.hold == TLWAIInlineHoldBold) {
        if (self.previousStar && [character isEqualToString:@"*"]) [self tl_releaseHeld];
        else self.previousStar = [character isEqualToString:@"*"];
    } else if (self.hold == TLWAIInlineHoldLink) {
        if (self.linkPhase == 0 && [character isEqualToString:@"]"]) self.linkPhase = 1;
        else if (self.linkPhase == 1) self.linkPhase = 2;
        else if (self.linkPhase == 2 && [character isEqualToString:@")"]) [self tl_releaseHeld];
    }
    if (self.heldClusters > 64) [self tl_releaseHeld];
}
static NSUInteger TLWAIPresentationFenceRun(NSString *line, unichar *character, NSUInteger *end) {
    NSUInteger start = 0;
    while (start < line.length && [line characterAtIndex:start] == ' ' && start < 4) start++;
    if (start > 3 || start >= line.length) return 0;
    unichar c = [line characterAtIndex:start];
    if (c != '`' && c != '~') return 0;
    NSUInteger cursor = start;
    while (cursor < line.length && [line characterAtIndex:cursor] == c) cursor++;
    if (character) *character = c;
    if (end) *end = cursor;
    return cursor - start;
}
- (void)appendText:(NSString *)text atTime:(NSTimeInterval)time {
    [self releaseExpiredAtTime:time]; [self.raw appendString:text];
    [text enumerateSubstringsInRange:NSMakeRange(0, text.length) options:NSStringEnumerationByComposedCharacterSequences usingBlock:^(NSString *character, NSRange range, NSRange enclosing, BOOL *stop) {
        [self.line appendString:character];
        if (!self.inFence && self.line.length <= 7) {
            unichar marker = 0;
            NSUInteger run = TLWAIPresentationFenceRun(self.line, &marker, NULL);
            if (run >= 3) {
                self.inFence = YES; self.openingFenceLine = YES;
                self.fenceCharacter = marker; self.fenceLength = run;
            }
        }
        if (self.inFence) { [self tl_releaseHeld]; [self tl_emitLength:character.length]; }
        else [self tl_inline:character time:time];
        if ([character rangeOfCharacterFromSet:NSCharacterSet.newlineCharacterSet].location != NSNotFound) {
            if (self.inFence) {
                unichar marker = 0; NSUInteger end = 0;
                NSUInteger run = TLWAIPresentationFenceRun(self.line, &marker, &end);
                if (self.openingFenceLine) { self.fenceLength = run; self.openingFenceLine = NO; }
                else if (marker == self.fenceCharacter && run >= self.fenceLength &&
                         [[self.line substringFromIndex:end] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet].length == 0) self.inFence = NO;
            }
            [self.line setString:@""];
        }
    }];
}
- (void)finish { [self tl_releaseHeld]; }
- (void)reset {
    [self.raw setString:@""]; [self.held setString:@""]; [self.line setString:@""];
    self.visibleLength = 0; self.visibleSnapshot = nil;
    self.hold = TLWAIInlineHoldNone; self.heldClusters = 0; self.heldSince = 0; self.linkPhase = 0;
    self.previousStar = NO; self.escaped = NO; self.inFence = NO; self.openingFenceLine = NO;
    self.fenceCharacter = 0; self.fenceLength = 0;
}
@end
