#import "TLWAISSEParser.h"
#import <limits.h>
@interface TLWAISSEParser ()
@property (nonatomic, strong) NSMutableData *line;
@property (nonatomic, strong) NSMutableData *prefix;
@property (nonatomic, strong) NSMutableString *dataText;
@property (nonatomic, strong) NSMutableString *commentText;
@property (nonatomic, copy) NSString *eventName;
@property (nonatomic, copy, readwrite) NSString *lastEventID;
@property (nonatomic, strong, readwrite) NSNumber *retryMilliseconds;
@property (nonatomic) BOOL atStart;
@property (nonatomic) BOOL previousCR;
@property (nonatomic) BOOL hasData;
@property (nonatomic) BOOL hasComment;
@property (nonatomic) BOOL invalidFrame;
@property (nonatomic) BOOL overflowed;
@property (nonatomic) NSUInteger frameBytes;
@end
@implementation TLWAISSEParser
- (instancetype)init {
    if ((self = [super init])) {
        _line = [NSMutableData data]; _prefix = [NSMutableData data];
        _dataText = [NSMutableString string]; _commentText = [NSMutableString string];
        [self reset];
    }
    return self;
}
- (void)appendData:(NSData *)data {
    if (self.overflowed) return;
    const uint8_t *bytes = data.bytes;
    static const uint8_t bom[] = {0xEF, 0xBB, 0xBF};
    for (NSUInteger index = 0; index < data.length && !self.overflowed; index++) {
        uint8_t byte = bytes[index];
        if (self.atStart) {
            [self.prefix appendBytes:&byte length:1];
            NSUInteger position = self.prefix.length - 1;
            if (byte == bom[position]) {
                if (self.prefix.length == 3) { self.atStart = NO; [self.prefix setLength:0]; }
                continue;
            }
            self.atStart = NO;
            const uint8_t *prefixBytes = self.prefix.bytes;
            for (NSUInteger p = 0; p < self.prefix.length; p++) [self tl_processByte:prefixBytes[p]];
            [self.prefix setLength:0];
        } else [self tl_processByte:byte];
    }
}
- (void)tl_processByte:(uint8_t)byte {
    if (self.overflowed) return;
    if (self.previousCR && byte == '\n') { self.previousCR = NO; return; }
    self.previousCR = NO;
    self.frameBytes++;
    if (self.frameBytes > 1024 * 1024) {
        [self tl_clearFrame]; [self.line setLength:0]; self.overflowed = YES;
        if (self.onBufferOverflow) self.onBufferOverflow();
        return;
    }
    if (byte == '\r' || byte == '\n') {
        [self tl_consumeLine];
        self.previousCR = byte == '\r';
    } else [self.line appendBytes:&byte length:1];
}
- (void)tl_consumeLine {
    if (self.line.length == 0) {
        if (!self.invalidFrame) {
            if (self.hasData && self.eventName.length && self.onEvent) self.onEvent(self.eventName, self.dataText.copy);
            else if (!self.hasData && self.hasComment && self.onComment) self.onComment(self.commentText.copy);
        }
        [self tl_clearFrame];
        return;
    }
    NSString *line = [[NSString alloc] initWithData:self.line encoding:NSUTF8StringEncoding];
    [self.line setLength:0];
    if (!line) { self.invalidFrame = YES; return; }
    if ([line hasPrefix:@":"]) {
        NSString *value = [line substringFromIndex:1];
        if ([value hasPrefix:@" "]) value = [value substringFromIndex:1];
        if (self.hasComment) [self.commentText appendString:@"\n"];
        self.hasComment = YES; [self.commentText appendString:value];
        return;
    }
    NSRange colon = [line rangeOfString:@":"];
    NSString *field = colon.location == NSNotFound ? line : [line substringToIndex:colon.location];
    NSString *value = colon.location == NSNotFound ? @"" : [line substringFromIndex:colon.location + 1];
    if ([value hasPrefix:@" "]) value = [value substringFromIndex:1];
    if ([field isEqualToString:@"event"]) self.eventName = value;
    else if ([field isEqualToString:@"data"]) {
        if (self.hasData) [self.dataText appendString:@"\n"];
        self.hasData = YES; [self.dataText appendString:value];
    } else if ([field isEqualToString:@"id"]) {
        unichar nul = 0;
        if ([value rangeOfString:[NSString stringWithCharacters:&nul length:1]].location != NSNotFound) return;
        self.lastEventID = value;
        if (self.onMetadata) self.onMetadata(self.lastEventID, self.retryMilliseconds);
    } else if ([field isEqualToString:@"retry"] && value.length) {
        unsigned long long milliseconds = 0;
        for (NSUInteger i = 0; i < value.length; i++) {
            unichar digit = [value characterAtIndex:i];
            if (digit < '0' || digit > '9' || milliseconds > (ULLONG_MAX - (digit - '0')) / 10) return;
            milliseconds = milliseconds * 10 + digit - '0';
        }
        self.retryMilliseconds = @(milliseconds);
        if (self.onMetadata) self.onMetadata(self.lastEventID, self.retryMilliseconds);
    }
}
- (void)tl_clearFrame {
    self.eventName = nil; self.hasData = NO; self.hasComment = NO; self.invalidFrame = NO;
    [self.dataText setString:@""]; [self.commentText setString:@""]; self.frameBytes = 0;
}
- (NSUInteger)finish {
    NSUInteger leftover = self.bufferedByteCount;
    [self.line setLength:0]; [self.prefix setLength:0]; [self tl_clearFrame];
    return leftover;
}
- (void)reset {
    [self.line setLength:0]; [self.prefix setLength:0]; [self tl_clearFrame];
    self.atStart = YES; self.previousCR = NO; self.overflowed = NO;
    self.lastEventID = @""; self.retryMilliseconds = nil;
}
- (NSUInteger)bufferedByteCount { return self.frameBytes + self.prefix.length; }
@end
