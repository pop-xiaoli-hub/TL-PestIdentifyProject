#import "TLWAIIncrementalMarkdown.h"

NSUInteger TLWAIATXHeadingLevel(NSString *line, NSUInteger *contentStart) {
    NSUInteger start = 0;
    while (start < line.length && [line characterAtIndex:start] == ' ') start++;
    NSUInteger end = start;
    while (end < line.length && [line characterAtIndex:end] == '#') end++;
    NSUInteger level = end - start;
    if (!level || level > 6 || end == line.length || [line characterAtIndex:end] != ' ') return 0;
    if (contentStart) *contentStart = end + 1;
    return level;
}

@interface TLWAITextBlock ()
@property (nonatomic, assign, readwrite) TLWAITextBlockKind kind;
@property (nonatomic, copy, readwrite) NSString *source;
@end
@implementation TLWAITextBlock @end

@interface TLWAIIncrementalMarkdown ()
@property (nonatomic, strong) NSMutableString *raw;
@property (nonatomic, strong) NSMutableString *openRaw;
@property (nonatomic, strong) NSMutableString *line;
@property (nonatomic, strong) NSMutableArray<TLWAITextBlock *> *blocks;
@property (nonatomic, assign, readwrite) TLWAITextBlockKind openBlockKind;
@property (nonatomic, assign) BOOL inFence;
@property (nonatomic, assign) BOOL openingFenceLine;
@property (nonatomic, assign) unichar fenceCharacter;
@property (nonatomic, assign) NSUInteger fenceLength;
@property (nonatomic, assign) BOOL previousLineHasPipe;
@end
@implementation TLWAIIncrementalMarkdown
- (instancetype)init {
    if ((self = [super init])) {
        _raw = [NSMutableString string];
        _openRaw = [NSMutableString string]; _line = [NSMutableString string];
        _blocks = [NSMutableArray array];
    }
    return self;
}
- (NSString *)source { return self.raw; }
- (NSArray<TLWAITextBlock *> *)closedBlocks { return [self.blocks copy]; }
static NSUInteger TLWAIFenceRun(NSString *line, unichar *character, NSUInteger *end) {
    NSUInteger start = 0;
    while (start < line.length && [line characterAtIndex:start] == ' ' && start < 4) start++;
    if (start > 3 || start >= line.length) return 0;
    unichar c = [line characterAtIndex:start];
    if (c != '`' && c != '~') return 0;
    NSUInteger cursor = start;
    while (cursor < line.length && [line characterAtIndex:cursor] == c) cursor++;
    if (character) *character = c; if (end) *end = cursor;
    return cursor - start;
}
- (void)tl_freezeSource:(NSString *)source kind:(TLWAITextBlockKind)kind {
    if (!source.length) return;
    TLWAITextBlock *block = [TLWAITextBlock new]; block.kind = kind; block.source = source;
    [self.blocks addObject:block];
}
- (void)tl_closeBlock {
    [self tl_freezeSource:self.openRaw kind:self.openBlockKind];
    [self.openRaw setString:@""]; self.openBlockKind = TLWAITextBlockKindParagraph;
    self.inFence = NO; self.openingFenceLine = NO; self.previousLineHasPipe = NO;
}
- (BOOL)tl_isTableDelimiter:(NSString *)line {
    if (![line containsString:@"|"]) return NO;
    NSUInteger columns = 0;
    for (NSString *part in [line componentsSeparatedByString:@"|"]) {
        NSString *column = [part stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        if (!column.length) continue;
        if ([column hasPrefix:@":"]) column = [column substringFromIndex:1];
        if ([column hasSuffix:@":"]) column = [column substringToIndex:column.length-1];
        if (column.length < 3 || [column rangeOfCharacterFromSet:[[NSCharacterSet characterSetWithCharactersInString:@"-"] invertedSet]].location != NSNotFound) return NO;
        columns++;
    }
    return columns > 0;
}
- (void)tl_finishLine {
    NSString *trimmed = [self.line stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (self.inFence) {
        unichar c = 0; NSUInteger end = 0;
        NSUInteger run = TLWAIFenceRun(self.line, &c, &end);
        if (self.openingFenceLine) { self.fenceLength = run; self.openingFenceLine = NO; }
        else if (c == self.fenceCharacter && run >= self.fenceLength &&
                 [[self.line substringFromIndex:end] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet].length == 0) [self tl_closeBlock];
    } else if (!trimmed.length) [self tl_closeBlock];
    else {
        if (self.openBlockKind == TLWAITextBlockKindTable && ![self.line containsString:@"|"]) {
            NSUInteger prefix = self.openRaw.length - self.line.length;
            [self tl_freezeSource:[self.openRaw substringToIndex:prefix] kind:TLWAITextBlockKindTable];
            [self.openRaw setString:self.line];
            self.openBlockKind = TLWAITextBlockKindParagraph;
        } else if (self.openBlockKind == TLWAITextBlockKindParagraph && self.previousLineHasPipe && [self tl_isTableDelimiter:self.line]) {
            // 表格只接管上一行表头和当前分隔行，不能吞掉前面的普通段落。
            NSUInteger headerEnd = self.openRaw.length - self.line.length;
            NSRange beforeHeader = [self.openRaw rangeOfString:@"\n" options:NSBackwardsSearch range:NSMakeRange(0, headerEnd ? headerEnd - 1 : 0)];
            if (beforeHeader.location != NSNotFound) {
                NSUInteger prefix = NSMaxRange(beforeHeader);
                [self tl_freezeSource:[self.openRaw substringToIndex:prefix] kind:TLWAITextBlockKindParagraph];
                [self.openRaw deleteCharactersInRange:NSMakeRange(0, prefix)];
            }
            self.openBlockKind = TLWAITextBlockKindTable;
        }
        if (self.openBlockKind == TLWAITextBlockKindParagraph && TLWAIATXHeadingLevel(self.line, NULL)) {
            NSUInteger prefix = self.openRaw.length - self.line.length;
            if (prefix) [self tl_freezeSource:[self.openRaw substringToIndex:prefix] kind:TLWAITextBlockKindParagraph];
            [self tl_freezeSource:self.line kind:TLWAITextBlockKindParagraph];
            [self.openRaw setString:@""];
            self.previousLineHasPipe = NO;
            [self.line setString:@""];
            return;
        }
        self.previousLineHasPipe = [self.line containsString:@"|"];
    }
    [self.line setString:@""];
}
- (void)appendText:(NSString *)text {
    [self.raw appendString:text];
    [text enumerateSubstringsInRange:NSMakeRange(0, text.length) options:NSStringEnumerationByComposedCharacterSequences usingBlock:^(NSString *character, NSRange range, NSRange enclosing, BOOL *stop) {
        [self.line appendString:character]; [self.openRaw appendString:character];
        if (!self.inFence && self.line.length <= 7) {
            unichar c = 0; NSUInteger run = TLWAIFenceRun(self.line, &c, NULL);
            if (run >= 3) {
                NSUInteger prefix = self.openRaw.length - self.line.length;
                if (prefix) { [self tl_freezeSource:[self.openRaw substringToIndex:prefix] kind:self.openBlockKind]; [self.openRaw setString:self.line]; }
                self.inFence = YES; self.openingFenceLine = YES; self.fenceCharacter = c;
                self.fenceLength = run; self.openBlockKind = TLWAITextBlockKindCode;
            }
        }
        if ([character rangeOfCharacterFromSet:NSCharacterSet.newlineCharacterSet].location != NSNotFound) [self tl_finishLine];
    }];
}
- (void)finish { if (self.line.length) [self tl_finishLine]; if (self.openRaw.length) [self tl_closeBlock]; }
- (void)reset {
    [self.raw setString:@""]; [self.openRaw setString:@""]; [self.line setString:@""];
    [self.blocks removeAllObjects];
    self.inFence = NO; self.openingFenceLine = NO; self.fenceCharacter = 0; self.fenceLength = 0;
    self.previousLineHasPipe = NO; self.openBlockKind = TLWAITextBlockKindParagraph;
}
@end
