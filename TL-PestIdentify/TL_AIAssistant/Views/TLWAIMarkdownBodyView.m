#import "TLWAIMarkdownBodyView.h"
#import "TLWAIIncrementalMarkdown.h"
#import "TLWAIMarkdownRenderPatch.h"
#import "TLWAIGestureCoordinator.h"

static UIFont *TLWBodyFont(CGFloat size, UIFontWeight weight) {
    return [[UIFontMetrics metricsForTextStyle:UIFontTextStyleBody] scaledFontForFont:[UIFont systemFontOfSize:size weight:weight]];
}

static NSAttributedString *TLWInline(NSString *source, UIFont *font, UIColor *color, BOOL literal) {
    NSMutableAttributedString *result;
    if (!literal && source.length) {
        NSAttributedStringMarkdownParsingOptions *options = [NSAttributedStringMarkdownParsingOptions new];
        options.interpretedSyntax = NSAttributedStringMarkdownInterpretedSyntaxInlineOnlyPreservingWhitespace;
        result = [[NSMutableAttributedString alloc] initWithMarkdownString:source options:options baseURL:nil error:nil];
    }
    if (!result) result = [[NSMutableAttributedString alloc] initWithString:source ?: @""];
    [result enumerateAttributesInRange:NSMakeRange(0, result.length) options:0 usingBlock:^(NSDictionary *attributes, NSRange range, BOOL *stop) {
        NSInlinePresentationIntent intent = [attributes[NSInlinePresentationIntentAttributeName] unsignedIntegerValue];
        BOOL code = (intent & NSInlinePresentationIntentCode) != 0;
        BOOL strong = (intent & NSInlinePresentationIntentStronglyEmphasized) != 0;
        UIFont *resolved = code ?
            [[UIFontMetrics metricsForTextStyle:UIFontTextStyleBody] scaledFontForFont:[UIFont monospacedSystemFontOfSize:14 weight:strong ? UIFontWeightBold : UIFontWeightRegular]] :
            (strong ? [UIFont systemFontOfSize:font.pointSize weight:UIFontWeightBold] : font);
        if (intent & NSInlinePresentationIntentEmphasized) {
            UIFontDescriptor *descriptor = [resolved.fontDescriptor fontDescriptorWithSymbolicTraits:resolved.fontDescriptor.symbolicTraits | UIFontDescriptorTraitItalic];
            if (descriptor) resolved = [UIFont fontWithDescriptor:descriptor size:resolved.pointSize];
        }
        [result addAttributes:@{NSFontAttributeName: resolved, NSForegroundColorAttributeName: color} range:range];
        if (intent & NSInlinePresentationIntentCode) [result addAttribute:NSBackgroundColorAttributeName value:UIColor.tertiarySystemFillColor range:range];
        if (intent & NSInlinePresentationIntentStrikethrough) [result addAttribute:NSStrikethroughStyleAttributeName value:@(NSUnderlineStyleSingle) range:range];
    }];
    // 语义已物化成显示属性。UITextView 会消耗该标记，继续缓存会制造虚假的属性变更。
    [result removeAttribute:NSInlinePresentationIntentAttributeName range:NSMakeRange(0, result.length)];
    return result;
}

static NSAttributedString *TLWParagraph(NSString *source, UIColor *color, BOOL literal) {
    if (literal) return TLWInline(source, TLWBodyFont(15, UIFontWeightMedium), color, YES);
    NSMutableAttributedString *result = [NSMutableAttributedString new];
    NSArray<NSString *> *lines = [source componentsSeparatedByString:@"\n"];
    for (NSUInteger index = 0; index < lines.count; index++) {
        NSString *line = lines[index];
        NSUInteger leading = 0;
        while (leading < line.length && [line characterAtIndex:leading] == ' ') leading++;
        NSString *content = [line substringFromIndex:leading];
        UIFont *font = TLWBodyFont(15, UIFontWeightMedium);
        NSMutableParagraphStyle *style = [NSMutableParagraphStyle new];
        style.lineSpacing = 3;
        NSUInteger headingStart = 0;
        NSUInteger heading = TLWAIATXHeadingLevel(line, &headingStart);
        if (heading) {
            content = [line substringFromIndex:headingStart];
            font = TLWBodyFont(heading == 1 ? 20 : (heading == 2 ? 18 : 16), UIFontWeightBold);
            style.paragraphSpacing = 6;
        } else if (content.length >= 2 && ([content hasPrefix:@"- "] || [content hasPrefix:@"* "] || [content hasPrefix:@"+ "])) {
            content = [@"• " stringByAppendingString:[content substringFromIndex:2]];
            style.firstLineHeadIndent = leading * 4;
            style.headIndent = leading * 4 + 16;
            style.paragraphSpacing = 4;
        } else if ([content hasPrefix:@"> "]) {
            content = [content substringFromIndex:2];
            style.firstLineHeadIndent = 12;
            style.headIndent = 12;
        } else {
            NSUInteger digits = 0;
            while (digits < content.length && [content characterAtIndex:digits] >= '0' && [content characterAtIndex:digits] <= '9') digits++;
            if (digits && digits + 1 < content.length && ([content characterAtIndex:digits] == '.' || [content characterAtIndex:digits] == ')') && [content characterAtIndex:digits + 1] == ' ') {
                style.firstLineHeadIndent = leading * 4;
                style.headIndent = leading * 4 + 22;
                style.paragraphSpacing = 4;
            } else content = line;
        }
        NSMutableAttributedString *part = [TLWInline(content, font, color, NO) mutableCopy];
        if (part.length) [part addAttribute:NSParagraphStyleAttributeName value:style range:NSMakeRange(0, part.length)];
        [result appendAttributedString:part];
        if (index + 1 < lines.count) [result appendAttributedString:TLWInline(@"\n", font, color, YES)];
    }
    // 分块器把段落分隔空行保留在 source 中；块间距由布局统一承担。
    while ([result.string hasSuffix:@"\n"]) [result deleteCharactersInRange:NSMakeRange(result.length - 1, 1)];
    return result;
}

static NSString *TLWCode(NSString *source) {
    NSMutableArray<NSString *> *lines = [[source componentsSeparatedByString:@"\n"] mutableCopy];
    if (!lines.count) return @"";
    NSString *opening = [lines.firstObject stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
    unichar marker = opening.length ? [opening characterAtIndex:0] : '`';
    NSUInteger fenceLength = 0;
    while (fenceLength < opening.length && [opening characterAtIndex:fenceLength] == marker) fenceLength++;
    [lines removeObjectAtIndex:0];
    NSInteger last = (NSInteger)lines.count - 1;
    while (last >= 0 && ![lines[(NSUInteger)last] length]) last--;
    if (last >= 0) {
        NSString *closing = [lines[(NSUInteger)last] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
        NSUInteger run = 0;
        while (run < closing.length && [closing characterAtIndex:run] == marker) run++;
        if (run >= fenceLength && run == closing.length) [lines removeObjectsInRange:NSMakeRange((NSUInteger)last, lines.count - (NSUInteger)last)];
    }
    return [lines componentsJoinedByString:@"\n"];
}

static NSArray<NSString *> *TLWTableCells(NSString *line) {
    NSString *trimmed = [line stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if ([trimmed hasPrefix:@"|"]) trimmed = [trimmed substringFromIndex:1];
    if ([trimmed hasSuffix:@"|"] && ![trimmed hasSuffix:@"\\|"]) trimmed = [trimmed substringToIndex:trimmed.length - 1];
    NSMutableArray *cells = [NSMutableArray new];
    NSMutableString *cell = [NSMutableString new];
    BOOL escaped = NO, inCode = NO;
    for (NSUInteger i = 0; i < trimmed.length; i++) {
        unichar c = [trimmed characterAtIndex:i];
        if (escaped) { [cell appendFormat:@"%C", c]; escaped = NO; continue; }
        if (c == '\\') { escaped = YES; continue; }
        if (c == '`') inCode = !inCode;
        if (c == '|' && !inCode) {
            [cells addObject:[cell stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet]];
            [cell setString:@""];
        } else [cell appendFormat:@"%C", c];
    }
    if (escaped) [cell appendString:@"\\"];
    [cells addObject:[cell stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet]];
    return cells;
}

static NSArray<NSArray<NSString *> *> *TLWTableRows(NSString *source) {
    NSMutableArray *rows = [NSMutableArray new];
    NSArray *lines = [source componentsSeparatedByString:@"\n"];
    for (NSUInteger i = 0; i < lines.count; i++) {
        if (i == 1 || ![lines[i] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet].length) continue;
        [rows addObject:TLWTableCells(lines[i])];
    }
    return rows;
}

@interface TLWMarkdownSection : UIView
@property TLWAITextBlockKind kind;
@property (nonatomic, copy) NSString *source;
/// sourceRange 属于该块已应用的 Markdown 快照；受保护块补齐前保留旧范围。
@property (nonatomic) NSRange sourceRange;
/// 普通段落使用本段 textStorage 的坐标；复合代码/表格不使用该范围做补丁。
@property (nonatomic) NSRange renderedRange;
@property (nonatomic, copy) NSAttributedString *plainText;
@property (nonatomic, strong) TLWAIHorizontalScrollView *horizontal;
@property (nonatomic, strong) NSMutableArray<UITextView *> *texts;
@property (nonatomic, strong) NSArray<NSArray<UITextView *> *> *rows;
@property (nonatomic, strong) NSArray<NSNumber *> *columnWidths;
@property (nonatomic) CGFloat naturalCodeWidth;
@property (nonatomic) CGFloat measuredWidth;
@property (nonatomic) CGFloat measuredHeight;
@property (nonatomic) BOOL needsConfiguration;
- (BOOL)interactionProtected;
- (void)configure:(NSString *)source kind:(TLWAITextBlockKind)kind literal:(BOOL)literal color:(UIColor *)color;
- (CGFloat)heightForWidth:(CGFloat)width;
@end

@implementation TLWMarkdownSection
- (BOOL)interactionProtected {
    if (self.horizontal.tracking || self.horizontal.dragging || self.horizontal.decelerating) return YES;
    for (UITextView *text in self.texts) if (text.selectedRange.length > 0) return YES;
    return NO;
}
- (UITextView *)makeText:(NSAttributedString *)text {
    UITextView *view = [UITextView new];
    view.editable = NO;
    view.scrollEnabled = NO;
    view.scrollsToTop = NO;
    view.backgroundColor = UIColor.clearColor;
    view.textContainerInset = UIEdgeInsetsZero;
    view.textContainer.lineFragmentPadding = 0;
    view.attributedText = text;
    [self.texts addObject:view];
    return view;
}
- (void)configure:(NSString *)source kind:(TLWAITextBlockKind)kind literal:(BOOL)literal color:(UIColor *)color {
    self.source = source;
    self.kind = kind;
    self.measuredWidth = -1;
    if (kind == TLWAITextBlockKindParagraph || literal) {
        UITextView *text = !self.horizontal && self.texts.count == 1 ? self.texts.firstObject : nil;
        self.plainText = TLWParagraph(source, color, literal);
        if (text) {
            NSTextStorage *storage = text.textStorage;
            self.renderedRange = NSMakeRange(0, storage.length);
            TLWAIMarkdownRenderPatch *patch = [TLWAIMarkdownRenderPatch patchFrom:storage to:self.plainText];
            if (patch) {
                NSAssert(NSMaxRange(patch.oldRenderedRange) <= NSMaxRange(self.renderedRange), @"Patch exceeds its paragraph storage");
                [storage beginEditing];
                [storage replaceCharactersInRange:patch.oldRenderedRange withAttributedString:patch.replacement];
                [storage endEditing];
            }
        } else {
            for (UIView *view in self.subviews) [view removeFromSuperview];
            self.texts = [NSMutableArray new];
            [self addSubview:[self makeText:self.plainText]];
        }
        self.renderedRange = NSMakeRange(0, self.plainText.length);
        self.rows = nil; self.horizontal = nil; self.columnWidths = nil;
        return;
    }
    CGPoint previousOffset = self.horizontal.contentOffset;
    self.renderedRange = NSMakeRange(NSNotFound, 0);
    for (UIView *view in self.subviews) [view removeFromSuperview];
    self.texts = [NSMutableArray new];
    self.rows = nil;
    self.horizontal = nil;
    self.horizontal = [TLWAIHorizontalScrollView new];
    self.horizontal.scrollsToTop = NO;
    self.horizontal.directionalLockEnabled = YES;
    self.horizontal.showsHorizontalScrollIndicator = YES;
    // AI 气泡沿用白底深色正文，局部背景不跟随系统深色切换成深底。
    self.horizontal.backgroundColor = [UIColor colorWithWhite:0.96 alpha:1];
    self.horizontal.layer.cornerRadius = 8;
    [self addSubview:self.horizontal];
    if (kind == TLWAITextBlockKindCode) {
        UIFont *font = [[UIFontMetrics metricsForTextStyle:UIFontTextStyleBody] scaledFontForFont:[UIFont monospacedSystemFontOfSize:14 weight:UIFontWeightRegular]];
        self.plainText = TLWInline(TLWCode(source), font, color, YES);
        UITextView *text = [self makeText:self.plainText];
        self.naturalCodeWidth = ceil([self.plainText boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size.width) + 4;
        [self.horizontal addSubview:text];
    } else {
        NSMutableArray *rows = [NSMutableArray new];
        NSMutableArray<NSNumber *> *widths = [NSMutableArray new];
        NSMutableAttributedString *plain = [NSMutableAttributedString new];
        NSArray *sources = TLWTableRows(source);
        NSUInteger columns = 0;
        for (NSArray *row in sources) columns = MAX(columns, row.count);
        for (NSUInteger col = 0; col < columns; col++) [widths addObject:@96];
        for (NSUInteger rowIndex = 0; rowIndex < sources.count; rowIndex++) {
            NSArray *cells = sources[rowIndex];
            NSMutableArray *row = [NSMutableArray new];
            for (NSUInteger col = 0; col < columns; col++) {
                NSAttributedString *value = TLWInline(col < cells.count ? cells[col] : @"", TLWBodyFont(14, rowIndex == 0 ? UIFontWeightSemibold : UIFontWeightRegular), color, NO);
                UITextView *text = [self makeText:value];
                text.textContainerInset = UIEdgeInsetsMake(8, 10, 8, 10);
                text.layer.borderWidth = 0.5;
                text.layer.borderColor = [UIColor colorWithWhite:0.78 alpha:1].CGColor;
                if (rowIndex == 0) text.backgroundColor = [UIColor colorWithWhite:0.90 alpha:1];
                [self.horizontal addSubview:text];
                [row addObject:text];
                CGFloat natural = ceil([value boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin context:nil].size.width) + 24;
                widths[col] = @(MAX(widths[col].doubleValue, MIN(220, natural)));
                if (col) [plain appendAttributedString:TLWInline(@"\t", TLWBodyFont(14, UIFontWeightRegular), color, YES)];
                [plain appendAttributedString:value];
            }
            if (rowIndex + 1 < sources.count) [plain appendAttributedString:TLWInline(@"\n", TLWBodyFont(14, UIFontWeightRegular), color, YES)];
            [rows addObject:row];
        }
        self.rows = rows;
        self.columnWidths = widths;
        self.plainText = plain;
    }
    self.horizontal.contentOffset = previousOffset;
}
- (CGFloat)heightForWidth:(CGFloat)width {
    width = MAX(1, width);
    if (fabs(self.measuredWidth - width) < 0.5) return self.measuredHeight;
    self.measuredWidth = width;
    CGFloat height = 0;
    if (!self.horizontal) {
        UITextView *text = self.texts.firstObject;
        height = self.plainText.length ? ceil([text sizeThatFits:CGSizeMake(width, CGFLOAT_MAX)].height) : 0;
        text.frame = CGRectMake(0, 0, width, height);
    } else if (self.kind == TLWAITextBlockKindCode) {
        CGFloat contentWidth = MAX(width, self.naturalCodeWidth + 20);
        UITextView *text = self.texts.firstObject;
        CGFloat textHeight = ceil([text sizeThatFits:CGSizeMake(contentWidth - 20, CGFLOAT_MAX)].height);
        height = MAX(38, textHeight + 20);
        text.frame = CGRectMake(10, 10, contentWidth - 20, textHeight);
        self.horizontal.contentSize = CGSizeMake(contentWidth, height);
    } else {
        CGFloat naturalWidth = 0;
        for (NSNumber *value in self.columnWidths) naturalWidth += value.doubleValue;
        CGFloat extra = self.columnWidths.count ? MAX(0, width - naturalWidth) / self.columnWidths.count : 0;
        CGFloat y = 0;
        for (NSArray<UITextView *> *row in self.rows) {
            CGFloat rowHeight = 36;
            for (NSUInteger col = 0; col < row.count; col++) rowHeight = MAX(rowHeight, ceil([row[col] sizeThatFits:CGSizeMake(self.columnWidths[col].doubleValue + extra, CGFLOAT_MAX)].height));
            CGFloat x = 0;
            for (NSUInteger col = 0; col < row.count; col++) {
                CGFloat columnWidth = self.columnWidths[col].doubleValue + extra;
                row[col].frame = CGRectMake(x, y, columnWidth, rowHeight);
                x += columnWidth;
            }
            y += rowHeight;
        }
        height = y;
        self.horizontal.contentSize = CGSizeMake(MAX(width, naturalWidth), height);
    }
    self.horizontal.frame = CGRectMake(0, 0, width, height);
    CGPoint offset = self.horizontal.contentOffset;
    offset.x = MIN(MAX(0, offset.x), MAX(0, self.horizontal.contentSize.width - width));
    offset.y = 0;
    self.horizontal.contentOffset = offset;
    self.measuredHeight = height;
    return height;
}
@end

@interface TLWAIMarkdownBodyView () <UIScrollViewDelegate>
@property (nonatomic, strong) TLWAIIncrementalMarkdown *parser;
@property (nonatomic, copy) NSString *source;
@property (nonatomic) BOOL literal;
@property (nonatomic, strong) UIColor *bodyColor;
@property (nonatomic, strong) NSMutableArray<TLWMarkdownSection *> *sections;
@property (nonatomic, strong) NSAttributedString *cachedAttributedText;
@property (nonatomic, copy) NSString *sizeCategory;
@property (nonatomic, readwrite) BOOL hasDeferredUpdates;
@end

@implementation TLWAIMarkdownBodyView
- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) { _sections = [NSMutableArray new]; _parser = [TLWAIIncrementalMarkdown new]; }
    return self;
}
- (BOOL)tl_shouldDeferSection:(TLWMarkdownSection *)section kind:(TLWAITextBlockKind)kind {
    if (section.interactionProtected) return YES;
    if (section.kind == kind) return NO;
    for (UIView *view = self.superview; view; view = view.superview) {
        if (![view isKindOfClass:UITableView.class]) continue;
        UITableView *table = (UITableView *)view;
        if (!table.tracking && !table.dragging && !table.decelerating) return NO;
        CGRect rect = [section convertRect:section.bounds toView:table];
        return !CGRectIsEmpty(rect) && CGRectIntersectsRect(rect, table.bounds);
    }
    return NO;
}
- (void)applySource:(NSString *)source literal:(BOOL)literal selectable:(BOOL)selectable textColor:(UIColor *)color {
    BOOL representationChanged = self.literal != literal;
    BOOL styleChanged = representationChanged || ![self.bodyColor isEqual:color] || ![self.sizeCategory isEqualToString:self.traitCollection.preferredContentSizeCategory];
    BOOL sourceChanged = ![self.source isEqualToString:source];
    if (sourceChanged || styleChanged || self.hasDeferredUpdates) {
        if (representationChanged || ![source hasPrefix:self.source ?: @""]) [self.parser reset];
        if (!literal) {
            NSUInteger oldLength = self.parser.source.length;
            if (source.length >= oldLength) [self.parser appendText:[source substringFromIndex:oldLength]];
        }
        self.source = source;
        self.literal = literal;
        self.bodyColor = color;
        self.sizeCategory = self.traitCollection.preferredContentSizeCategory;
        self.cachedAttributedText = nil;
        self.hasDeferredUpdates = NO;
        NSMutableArray<NSString *> *sources = [NSMutableArray new];
        NSMutableArray<NSNumber *> *kinds = [NSMutableArray new];
        if (literal) { [sources addObject:source]; [kinds addObject:@(TLWAITextBlockKindParagraph)]; }
        else {
            NSUInteger consumed = 0;
            for (TLWAITextBlock *block in self.parser.closedBlocks) {
                [sources addObject:block.source]; [kinds addObject:@(block.kind)]; consumed += block.source.length;
            }
            if (consumed < source.length) { [sources addObject:[source substringFromIndex:consumed]]; [kinds addObject:@(self.parser.openBlockKind)]; }
        }
        NSUInteger sourceOffset = 0;
        for (NSUInteger index = 0; index < sources.count; index++) {
            TLWMarkdownSection *section;
            if (index < self.sections.count) section = self.sections[index];
            else { section = [TLWMarkdownSection new]; [self.sections addObject:section]; [self addSubview:section]; }
            NSRange sourceRange = NSMakeRange(sourceOffset, sources[index].length);
            sourceOffset = NSMaxRange(sourceRange);
            BOOL changed = styleChanged || section.needsConfiguration || section.kind != kinds[index].integerValue || ![section.source isEqualToString:sources[index]];
            if (changed && !representationChanged && [self tl_shouldDeferSection:section kind:kinds[index].integerValue]) {
                section.needsConfiguration = YES;
                self.hasDeferredUpdates = YES;
            } else if (changed) {
                [section configure:sources[index] kind:kinds[index].integerValue literal:literal color:color];
                section.needsConfiguration = NO;
                section.sourceRange = sourceRange;
            } else {
                section.sourceRange = sourceRange;
            }
            section.horizontal.delegate = self;
        }
        while (self.sections.count > sources.count) {
            if (!representationChanged && self.sections.lastObject.interactionProtected) {
                self.hasDeferredUpdates = YES;
                break;
            }
            [self.sections.lastObject removeFromSuperview];
            [self.sections removeLastObject];
        }
        [self setNeedsLayout];
    }
    for (UITextView *text in self.textViews) {
        if (selectable || text.selectedRange.length == 0) text.selectable = selectable;
        text.delegate = self.textDelegate;
    }
}
- (void)setTextDelegate:(id<UITextViewDelegate>)textDelegate {
    _textDelegate = textDelegate;
    for (UITextView *text in self.textViews) text.delegate = textDelegate;
}
- (NSArray<UITextView *> *)textViews {
    NSMutableArray *texts = [NSMutableArray new];
    for (TLWMarkdownSection *section in self.sections) [texts addObjectsFromArray:section.texts];
    return texts;
}
- (NSAttributedString *)attributedText {
    if (!self.cachedAttributedText) {
        NSMutableAttributedString *text = [NSMutableAttributedString new];
        for (TLWMarkdownSection *section in self.sections) {
            if (text.length && section.plainText.length) [text appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n\n"]];
            [text appendAttributedString:section.plainText];
        }
        self.cachedAttributedText = text;
    }
    return self.cachedAttributedText;
}
- (NSString *)text { return self.attributedText.string; }
- (CGFloat)heightForWidth:(CGFloat)width {
    CGFloat y = 0;
    for (TLWMarkdownSection *section in self.sections) {
        CGFloat height = [section heightForWidth:width];
        if (height > 0 && y > 0) y += 8;
        section.frame = CGRectMake(0, y, width, height);
        y += height;
    }
    return MAX(22, y);
}
- (void)layoutSubviews { [super layoutSubviews]; if (self.bounds.size.width > 0) [self heightForWidth:self.bounds.size.width]; }
- (BOOL)interactionActive {
    for (TLWMarkdownSection *section in self.sections) if (section.horizontal.tracking || section.horizontal.dragging || section.horizontal.decelerating) return YES;
    return NO;
}
- (BOOL)stopDecelerationForExplicitJump {
    BOOL fingerDown = NO;
    for (TLWMarkdownSection *section in self.sections) {
        UIScrollView *scrollView = section.horizontal;
        if (!scrollView) continue;
        if (scrollView.isTracking || scrollView.isDragging) fingerDown = YES;
        else if (scrollView.isDecelerating) scrollView.contentOffset = scrollView.contentOffset;
    }
    return fingerDown;
}
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView { if (self.onInteractionChanged) self.onInteractionChanged(); }
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate { if (!decelerate && self.onInteractionChanged) self.onInteractionChanged(); }
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView { if (self.onInteractionChanged) self.onInteractionChanged(); }
@end
