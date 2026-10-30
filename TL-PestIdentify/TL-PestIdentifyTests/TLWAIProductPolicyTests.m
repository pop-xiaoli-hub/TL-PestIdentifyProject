#import <XCTest/XCTest.h>
#import "../TL_AIAssistant/Models/TLWAIImageArchive.h"
#import "../TL_AIAssistant/Models/TLWAIProductPolicy.h"
#import "../TL_AIAssistant/Models/TLWAIAssistantSession.h"
#import "../TL_AIAssistant/Models/TLWAIAssistantMessage.h"

@interface TLWAIProductPolicyTests : XCTestCase
@end

@implementation TLWAIProductPolicyTests

- (void)testSecondRequestContextNamesPreviousDiseaseAndOmitsUnauthorizedLocation {
    TLWAIAssistantSession *session = [TLWAIAssistantSession new];
    TLWAIAssistantMessage *user = [TLWAIAssistantMessage messageWithRole:TLWAIAssistantMessageRoleUser text:@"叶子发黄"];
    TLWAIAssistantMessage *assistant = [TLWAIAssistantMessage messageWithRole:TLWAIAssistantMessageRoleAssistant text:@"建议观察病斑"];
    assistant.completed = YES;
    assistant.diseaseNames = @[@"番茄早疫病"];
    [session appendMessage:user];
    [session appendMessage:assistant];
    TLWAIAssistantMessage *current = [TLWAIAssistantMessage messageWithRole:TLWAIAssistantMessageRoleUser text:@"还要打药吗"];
    NSString *context = [session recentContextWithMaxCharacters:2400 excludingUserIdentifier:current.identifier];
    NSString *extra = TLWAIComposeExtraInfo(context, nil);
    XCTAssertTrue([extra containsString:@"番茄早疫病"]);
    XCTAssertFalse([extra containsString:@"用户已单独授权附带定位"]);
    NSString *located = TLWAIComposeExtraInfo(context, @"杭州市余杭区");
    XCTAssertTrue([located containsString:@"用户已单独授权附带定位：杭州市余杭区"]);
    XCTAssertTrue([located containsString:@"番茄早疫病"]);
    XCTAssertTrue([located containsString:@"杭州市余杭区"]);
}

- (void)testSpeechCancelDoesNotCommitPartial {
    XCTAssertFalse(TLWAIShouldCommitSpeechPartial(YES, NO));
    XCTAssertFalse(TLWAIShouldCommitSpeechPartial(NO, YES));
    XCTAssertTrue(TLWAIShouldCommitSpeechPartial(NO, NO));
}

- (void)testLinksRequireHTTPSAndFirstConfirmation {
    XCTAssertEqual(TLWAIDecideLink(@"http", @"example.com", NO), TLWAILinkDecisionDeny);
    XCTAssertEqual(TLWAIDecideLink(@"https", @"", NO), TLWAILinkDecisionDeny);
    XCTAssertEqual(TLWAIDecideLink(@"https", @"example.com", NO), TLWAILinkDecisionConfirm);
    XCTAssertEqual(TLWAIDecideLink(@"https", @"example.com", YES), TLWAILinkDecisionAllow);
}

- (void)testVoiceOverStaysQuietUntilTerminalPlainText {
    XCTAssertEqualObjects(TLWAIAccessibilityLabel(YES, @"正在生长的正文"), @"正在回复");
    XCTAssertEqualObjects(TLWAIAccessibilityLabel(NO, @"最终纯文本"), @"最终纯文本");
}

- (void)testPathChangeNeverRepostsAndConnectionLossOffersContinue {
    XCTAssertFalse(TLWAIShouldRepostAfterPathChange());
    XCTAssertTrue(TLWAIOffersContinue(YES, NO));
    XCTAssertTrue(TLWAIOffersContinue(NO, YES));
    XCTAssertFalse(TLWAIOffersContinue(NO, NO));
}

- (void)testPesticideAdviceRequiresLabelDisclaimerAndModerationIsPlaceholder {
    XCTAssertTrue(TLWAITextNeedsLabelDisclaimer(@"建议喷施农药"));
    XCTAssertFalse(TLWAITextNeedsLabelDisclaimer(@"建议喷施农药，用药以标签为准"));
    XCTAssertFalse(TLWAITextNeedsLabelDisclaimer(@"只是观察叶片"));
    XCTAssertEqualObjects(TLWAILabelDisclaimer(), @"用药以标签为准");
    XCTAssertEqualObjects(TLWAIModerationPlaceholder(), @"未经内容审核");
}

- (void)testLocalHypothesisUsesIdentifyPageThresholdAndDoesNotOverrideCloud {
    XCTAssertEqualObjects(TLWAILocalHypothesisText(@"番茄晚疫病", 0.59f), @"");
    NSString *shown = TLWAILocalHypothesisText(@"番茄晚疫病", 0.60f);
    XCTAssertTrue([shown containsString:@"番茄晚疫病"]);
    XCTAssertTrue([shown containsString:@"假设"]);
    XCTAssertTrue([shown containsString:@"云端"]);
    XCTAssertFalse([shown containsString:@"云端疑似病害"]);
}
- (void)testTrimClearsMemoryImagesButLeavesArchiveFile {
    NSString *root = [NSTemporaryDirectory() stringByAppendingPathComponent:NSUUID.UUID.UUIDString];
    UIGraphicsBeginImageContext(CGSizeMake(2, 2));
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    NSString *relative = [TLWAIImageArchive writeImage:image userIdentifier:3 root:root messageIdentifier:@"m" index:0];
    XCTAssertNotNil(relative);
    TLWAIAssistantSession *session = [TLWAIAssistantSession new];
    TLWAIAssistantMessage *first = [TLWAIAssistantMessage messageWithRole:TLWAIAssistantMessageRoleUser text:@"图" localImages:@[image] remoteImageURLs:nil];
    first.imageRelativePaths = @[relative];
    [session appendMessage:first];
    for (NSUInteger i = 0; i < 20; i++) {
        [session appendMessage:[TLWAIAssistantMessage messageWithRole:TLWAIAssistantMessageRoleUser text:@"后续"]];
    }
    [session trimImageMemoryIfNeeded];
    XCTAssertEqual(first.localImages.count, 0u);
    XCTAssertTrue([TLWAIImageArchive fileExistsForRelativePath:relative userIdentifier:3 root:root]);
}

@end
