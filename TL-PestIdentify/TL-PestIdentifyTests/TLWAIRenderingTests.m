#import <XCTest/XCTest.h>
#import "../TL_AIAssistant/Views/Cells/TLWAIAssistantMessageCell.h"
#import "../TL_AIAssistant/Models/TLWAIAssistantMessage.h"

#import "TLWAIMarkdownBodyView.h"
@interface TLWAIRenderingTests : XCTestCase @end
@implementation TLWAIRenderingTests
- (TLWAIMarkdownBodyView *)bodyForMessage:(TLWAIAssistantMessage *)message {
    TLWAIAssistantMessageCell *cell = [[TLWAIAssistantMessageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    cell.frame = CGRectMake(0, 0, 350, 300);
    [cell configureWithMessage:message];
    TLWAIMarkdownBodyView *body = [cell valueForKey:@"messageBody"];
    [body heightForWidth:312];
    return body;
}
- (void)testStreamingMarkdownShowsBoldListAndCodeInsteadOfLiteralDelimiters {
    TLWAIAssistantMessage *message = [TLWAIAssistantMessage messageWithRole:TLWAIAssistantMessageRoleAssistant text:@"**病害** 👨‍👩‍👧‍👦\n\n- 第一项\n- 第二项\n\n```text\n# literal\n**literal**\n```"];
    message.status = TLWAIAssistantMessageStatusSending;
    NSAttributedString *rendered = [self bodyForMessage:message].attributedText;
    XCTAssertFalse([rendered.string containsString:@"**病害**"]);
    XCTAssertTrue([rendered.string containsString:@"👨‍👩‍👧‍👦"]);
    XCTAssertTrue([rendered.string containsString:@"• 第一项"]);
    XCTAssertTrue([rendered.string containsString:@"# literal\n**literal**"]);
    NSRange heading = [rendered.string rangeOfString:@"病害"];
    UIFont *font = [rendered attribute:NSFontAttributeName atIndex:heading.location effectiveRange:nil];
    XCTAssertTrue((font.fontDescriptor.symbolicTraits & UIFontDescriptorTraitBold) != 0);
}

- (void)testOrdinaryStreamingBodyExpandsBeyondOldViewportCap {
    NSString *text = [@"一行普通正文\n" stringByPaddingToLength:2000 withString:@"一行普通正文\n" startingAtIndex:0];
    TLWAIAssistantMessage *message = [TLWAIAssistantMessage messageWithRole:TLWAIAssistantMessageRoleAssistant text:text];
    message.status = TLWAIAssistantMessageStatusSending;
    TLWAIAssistantMessageCell *cell = [[TLWAIAssistantMessageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    cell.frame = CGRectMake(0, 0, 350, 300);
    [cell configureWithMessage:message];
    CGSize size = [cell systemLayoutSizeFittingSize:CGSizeMake(350, UILayoutFittingCompressedSize.height)
        withHorizontalFittingPriority:UILayoutPriorityRequired verticalFittingPriority:UILayoutPriorityFittingSizeLevel];
    XCTAssertGreaterThan(size.height, 500.0);
}

- (void)testUserMarkdownIsLiteralAndCodeFenceContentsAreNotRewritten {
    TLWAIAssistantMessage *user = [TLWAIAssistantMessage messageWithRole:TLWAIAssistantMessageRoleUser text:@"  # 标题\n- 原文\n**不是样式**  "];
    XCTAssertEqualObjects([self bodyForMessage:user].text, user.text);
    TLWAIAssistantMessage *assistant = [TLWAIAssistantMessage messageWithRole:TLWAIAssistantMessageRoleAssistant text:@"```text\n# literal\n- item\n**literal**\n```"];
    NSString *code = [self bodyForMessage:assistant].text;
    XCTAssertTrue([code containsString:@"# literal\n- item\n**literal**"]);
    XCTAssertFalse([code containsString:@"•"]);
}
- (void)testDiseaseCardStaysIndependentAndStableAcrossPlanDeltas {
    TLWAIAssistantMessage *message = [TLWAIAssistantMessage messageWithRole:TLWAIAssistantMessageRoleAssistant text:@"方案"];
    message.status = TLWAIAssistantMessageStatusSending;
    message.diseaseSummary = @"番茄早疫病 (92%)";
    TLWAIAssistantMessageCell *cell = [[TLWAIAssistantMessageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    [cell configureWithMessage:message];
    UITextView *card = [cell valueForKey:@"auxiliaryTextView"];
    XCTAssertTrue([card.text containsString:@"番茄早疫病 (92%)"]);
    XCTAssertTrue([card.text containsString:@"以标签为准"]);
    for (NSUInteger i=0; i<30; i++) {
        message.text = [message.text stringByAppendingString:@"追加"];
        [cell applyStreamingText:message.text];
    }
    XCTAssertEqual([cell valueForKey:@"auxiliaryTextView"], card);
    XCTAssertEqualObjects(((TLWAIMarkdownBodyView *)[cell valueForKey:@"messageBody"]).text, message.text);
    XCTAssertFalse([message.text containsString:@"番茄早疫病"]);
}

- (void)testTableUsesAlignedNativeCellsAndHorizontalOverflow {
    TLWAIMarkdownBodyView *body = [TLWAIMarkdownBodyView new];
    [body applySource:@"|项目|风险|动作|时间|备注|\n|---|---|---|---|---|\n|叶片|低|`保留|管道`|明天|记录|\n|叶片\\|根部|中|检查|今天|观察|\n"
        literal:NO selectable:YES textColor:UIColor.labelColor];
    CGFloat height = [body heightForWidth:300];
    NSArray<UITextView *> *texts = body.textViews;
    XCTAssertEqual(texts.count, 15u);
    XCTAssertEqualObjects(texts[7].text, @"保留|管道");
    XCTAssertEqualObjects(texts[10].text, @"叶片|根部");
    XCTAssertEqualWithAccuracy(texts[0].frame.origin.y, texts[1].frame.origin.y, 0.5);
    XCTAssertEqualWithAccuracy(texts[0].frame.origin.x, texts[5].frame.origin.x, 0.5);
    XCTAssertGreaterThan(texts[1].frame.origin.x, texts[0].frame.origin.x);
    XCTAssertGreaterThan(height, CGRectGetMaxY(texts[0].frame));
    UIScrollView *horizontal = (UIScrollView *)texts.firstObject.superview;
    XCTAssertTrue([horizontal isKindOfClass:UIScrollView.class]);
    XCTAssertGreaterThan(horizontal.contentSize.width, 300);
    XCTAssertFalse(texts.firstObject.scrollEnabled);
}

- (void)testAppendingAfterClosedCodePreservesHorizontalReadingPosition {
    TLWAIMarkdownBodyView *body = [TLWAIMarkdownBodyView new];
    NSString *source = @"```text\n**literal**   一个不会自动换行的超长代码行 abcdefghijklmnopqrstuvwxyz_abcdefghijklmnopqrstuvwxyz_abcdefghijklmnopqrstuvwxyz\n```\n\n正文";
    [body applySource:source literal:NO selectable:NO textColor:UIColor.labelColor];
    [body heightForWidth:300];
    UITextView *code = body.textViews.firstObject;
    UIScrollView *horizontal = (UIScrollView *)code.superview;
    XCTAssertTrue([code.text hasPrefix:@"**literal**   "]);
    XCTAssertGreaterThan(horizontal.contentSize.width, 300);
    horizontal.contentOffset = CGPointMake(60, 0);
    [body applySource:[source stringByAppendingString:@"继续输出 👨‍👩‍👧‍👦"] literal:NO selectable:NO textColor:UIColor.labelColor];
    [body heightForWidth:300];
    XCTAssertEqual(body.textViews.firstObject, code);
    XCTAssertEqualWithAccuracy(horizontal.contentOffset.x, 60, 0.5);
    XCTAssertTrue([body.text containsString:@"继续输出 👨‍👩‍👧‍👦"]);
}

- (void)testSelectedBlockIsPreservedWhileAnotherBlockUpdatesAndCatchesUpAfterSelection {
    TLWAIMarkdownBodyView *body = [TLWAIMarkdownBodyView new];
    [body applySource:@"稳定前缀\n\n后续" literal:NO selectable:YES textColor:UIColor.labelColor];
    [body heightForWidth:300];
    UITextView *selected = body.textViews.firstObject;
    selected.selectedRange = NSMakeRange(0, 2);
    NSString *updated = @"修订后的前缀\n\n后续继续输出";
    [body applySource:updated literal:NO selectable:YES textColor:UIColor.labelColor];
    XCTAssertEqual(body.textViews.firstObject, selected);
    XCTAssertEqualObjects(selected.text, @"稳定前缀");
    XCTAssertEqual(selected.selectedRange.length, 2u);
    XCTAssertTrue([body.text containsString:@"后续继续输出"]);
    selected.selectedRange = NSMakeRange(0, 0);
    [body applySource:updated literal:NO selectable:YES textColor:UIColor.labelColor];
    XCTAssertTrue([body.text containsString:@"修订后的前缀"]);
    XCTAssertFalse([body.text containsString:@"稳定前缀"]);
}
- (void)testGrowingParagraphReusesTextViewAndReinterpretsPreviouslyUnclosedBold {
    TLWAIMarkdownBodyView *body = [TLWAIMarkdownBodyView new];
    [body applySource:@"建议 **减少浇水" literal:NO selectable:NO textColor:UIColor.labelColor];
    CGFloat before = [body heightForWidth:180];
    UITextView *paragraph = body.textViews.firstObject;
    [body applySource:@"建议 **减少浇水**，保持通风，并持续观察叶片变化。\n下一步检查土壤湿度，避免重复浇水。"
        literal:NO selectable:NO textColor:UIColor.labelColor];
    CGFloat after = [body heightForWidth:180];
    XCTAssertEqualObjects(body.text, @"建议 减少浇水，保持通风，并持续观察叶片变化。\n下一步检查土壤湿度，避免重复浇水。");
    NSRange bold = [body.text rangeOfString:@"减少浇水"];
    UIFont *font = [body.attributedText attribute:NSFontAttributeName atIndex:bold.location effectiveRange:nil];
    XCTAssertTrue((font.fontDescriptor.symbolicTraits & UIFontDescriptorTraitBold) != 0);
    UIFont *displayedFont = [paragraph.textStorage attribute:NSFontAttributeName atIndex:bold.location effectiveRange:nil];
    XCTAssertTrue((displayedFont.fontDescriptor.symbolicTraits & UIFontDescriptorTraitBold) != 0);
    XCTAssertGreaterThan(after, before);
    XCTAssertEqual(body.textViews.firstObject, paragraph);
}
- (void)testReusedParagraphReplacementClearsOldLinkAndBoldAttributes {
    TLWAIMarkdownBodyView *body = [TLWAIMarkdownBodyView new];
    [body applySource:@"**[查看说明](https://example.org)**" literal:NO selectable:NO textColor:UIColor.labelColor];
    UITextView *paragraph = body.textViews.firstObject;
    [body applySource:@"普通正文" literal:NO selectable:NO textColor:UIColor.labelColor];
    XCTAssertEqualObjects(body.text, @"普通正文");
    XCTAssertEqual(body.textViews.firstObject, paragraph);
    [paragraph.attributedText enumerateAttributesInRange:NSMakeRange(0, paragraph.attributedText.length)
        options:0 usingBlock:^(NSDictionary *attributes, NSRange range, BOOL *stop) {
            XCTAssertNil(attributes[NSLinkAttributeName]);
            UIFont *font = attributes[NSFontAttributeName];
            XCTAssertFalse((font.fontDescriptor.symbolicTraits & UIFontDescriptorTraitBold) != 0);
        }];
    [body applySource:@"**保持原样**" literal:YES selectable:NO textColor:UIColor.labelColor];
    XCTAssertEqualObjects(body.text, @"**保持原样**");
    XCTAssertEqual(body.textViews.firstObject, paragraph);
}
- (void)testWidthChangeDoesNotHideHeightGrowthFromStreamingCaller {
    NSString *text = [@"中" stringByPaddingToLength:16 withString:@"中" startingAtIndex:0];
    TLWAIAssistantMessage *message = [TLWAIAssistantMessage messageWithRole:TLWAIAssistantMessageRoleAssistant text:text];
    message.status = TLWAIAssistantMessageStatusSending;
    TLWAIAssistantMessageCell *cell = [[TLWAIAssistantMessageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    cell.frame = CGRectMake(0, 0, 400, 200);
    [cell configureWithMessage:message];
    [cell setNeedsLayout];
    [cell layoutIfNeeded];
    TLWAIMarkdownBodyView *body = [cell valueForKey:@"messageBody"];
    UIFont *font = [body.textViews.firstObject.textStorage attribute:NSFontAttributeName atIndex:0 effectiveRange:nil];
    CGFloat naturalWidth = [text sizeWithAttributes:@{NSFontAttributeName: font}].width;
    CGFloat horizontalInsets = CGRectGetWidth(cell.bounds) - CGRectGetWidth(body.bounds);
    CGFloat wide = naturalWidth + horizontalInsets + 0.25;
    cell.frame = CGRectMake(0, 0, wide, 200);
    CGFloat before = [cell systemLayoutSizeFittingSize:CGSizeMake(wide, UILayoutFittingCompressedSize.height)
        withHorizontalFittingPriority:UILayoutPriorityRequired verticalFittingPriority:UILayoutPriorityFittingSizeLevel].height;
    cell.frame = CGRectMake(0, 0, wide - 0.5, 200);
    BOOL heightChanged = [cell applyStreamingText:text];
    CGFloat after = [cell systemLayoutSizeFittingSize:CGSizeMake(wide - 0.5, UILayoutFittingCompressedSize.height)
        withHorizontalFittingPriority:UILayoutPriorityRequired verticalFittingPriority:UILayoutPriorityFittingSizeLevel].height;
    XCTAssertGreaterThan(after, before + 5);
    XCTAssertTrue(heightChanged, @"Width-induced wrapping must be reported against the last measured row height");
}
@end
