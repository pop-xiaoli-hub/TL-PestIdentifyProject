#import "TLWAIMarkdownRenderPatch.h"

@interface TLWAIMarkdownRenderPatch ()
@property (nonatomic, assign, readwrite) NSRange oldRenderedRange;
@property (nonatomic, copy, readwrite) NSAttributedString *replacement;
@end

static NSUInteger TLWPatchStartBoundary(NSString *text, NSUInteger index) {
    return index < text.length ? [text rangeOfComposedCharacterSequenceAtIndex:index].location : index;
}

static NSUInteger TLWPatchEndBoundary(NSString *text, NSUInteger index) {
    if (index >= text.length) return index;
    NSRange cluster = [text rangeOfComposedCharacterSequenceAtIndex:index];
    return cluster.location < index ? NSMaxRange(cluster) : index;
}

@implementation TLWAIMarkdownRenderPatch
+ (instancetype)patchFrom:(NSAttributedString *)previous to:(NSAttributedString *)next {
    if (previous == next) return nil;
    NSString *oldText = previous.string;
    NSString *newText = next.string;
    NSUInteger limit = MIN(previous.length, next.length);
    NSUInteger prefix = 0;
    while (prefix < limit) {
        NSRange oldRun, newRun;
        NSDictionary *oldAttributes = [previous attributesAtIndex:prefix effectiveRange:&oldRun];
        NSDictionary *newAttributes = [next attributesAtIndex:prefix effectiveRange:&newRun];
        if (![oldAttributes isEqualToDictionary:newAttributes]) break;
        NSUInteger end = MIN(limit, MIN(NSMaxRange(oldRun), NSMaxRange(newRun)));
        while (prefix < end && [oldText characterAtIndex:prefix] == [newText characterAtIndex:prefix]) prefix++;
        if (prefix < end) break;
    }
    if (prefix == previous.length && prefix == next.length) return nil;
    // 一次追加可能使旧末尾字符与新组合标记组成同一个字形簇。
    NSUInteger boundary;
    do {
        boundary = prefix;
        prefix = MIN(TLWPatchStartBoundary(oldText, prefix), TLWPatchStartBoundary(newText, prefix));
    } while (prefix != boundary);

    NSUInteger oldEnd = previous.length;
    NSUInteger newEnd = next.length;
    while (oldEnd > prefix && newEnd > prefix) {
        NSRange oldRun, newRun;
        NSDictionary *oldAttributes = [previous attributesAtIndex:oldEnd - 1 effectiveRange:&oldRun];
        NSDictionary *newAttributes = [next attributesAtIndex:newEnd - 1 effectiveRange:&newRun];
        if (![oldAttributes isEqualToDictionary:newAttributes]) break;
        NSUInteger count = MIN(oldEnd - MAX(prefix, oldRun.location), newEnd - MAX(prefix, newRun.location));
        NSUInteger matched = 0;
        while (matched < count && [oldText characterAtIndex:oldEnd - 1] == [newText characterAtIndex:newEnd - 1]) {
            oldEnd--; newEnd--; matched++;
        }
        if (matched < count) break;
    }
    // 两侧保留同样长的共同后缀；任一侧落在簇内部，就一起缩短保留后缀。
    for (;;) {
        NSUInteger expansion = MAX(TLWPatchEndBoundary(oldText, oldEnd) - oldEnd,
                                   TLWPatchEndBoundary(newText, newEnd) - newEnd);
        if (!expansion) break;
        oldEnd += expansion;
        newEnd += expansion;
    }
    TLWAIMarkdownRenderPatch *patch = [self new];
    patch.oldRenderedRange = NSMakeRange(prefix, oldEnd - prefix);
    patch.replacement = [next attributedSubstringFromRange:NSMakeRange(prefix, newEnd - prefix)];
    return patch;
}
@end
