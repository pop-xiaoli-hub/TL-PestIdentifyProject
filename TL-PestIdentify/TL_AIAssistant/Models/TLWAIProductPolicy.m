#import "TLWAIProductPolicy.h"

NSString *TLWAIComposeExtraInfo(NSString *context, NSString *authorizedLocation) {
    NSMutableString *info = [NSMutableString string];
    if (context.length) [info appendString:context];
    NSString *location = [authorizedLocation stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (location.length) {
        if (info.length) [info appendString:@"\n"];
        [info appendFormat:@"用户已单独授权附带定位：%@", location];
    }
    return info;
}

BOOL TLWAIShouldCommitSpeechPartial(BOOL cancelZone, BOOL recordingCancelled) {
    return !cancelZone && !recordingCancelled;
}

TLWAILinkDecision TLWAIDecideLink(NSString *scheme, NSString *host, BOOL hostConfirmed) {
    if (![[scheme lowercaseString] isEqualToString:@"https"]) return TLWAILinkDecisionDeny;
    if (!host.length) return TLWAILinkDecisionDeny;
    return hostConfirmed ? TLWAILinkDecisionAllow : TLWAILinkDecisionConfirm;
}

NSString *TLWAIAccessibilityLabel(BOOL streaming, NSString *plainText) {
    return streaming ? @"正在回复" : (plainText ?: @"");
}

BOOL TLWAIShouldRepostAfterPathChange(void) { return NO; }

BOOL TLWAIOffersContinue(BOOL recoverableNetworkError, BOOL incomplete) {
    return recoverableNetworkError || incomplete;
}

BOOL TLWAITextNeedsLabelDisclaimer(NSString *text) {
    if (!text.length || [text containsString:@"以标签为准"]) return NO;
    for (NSString *word in @[@"农药", @"用药", @"打药", @"喷施"]) {
        if ([text containsString:word]) return YES;
    }
    return NO;
}

NSString *TLWAILabelDisclaimer(void) { return @"用药以标签为准"; }
NSString *TLWAIModerationPlaceholder(void) { return @"未经内容审核"; }

NSString *TLWAILocalHypothesisText(NSString *name, float confidence) {
    if (confidence < 0.60f) return @"";
    NSString *trimmed = [name stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (!trimmed.length) return @"";
    return [NSString stringWithFormat:@"本地初判（假设）：%@ (%.0f%%)，云端结论优先", trimmed, confidence * 100.0];
}
