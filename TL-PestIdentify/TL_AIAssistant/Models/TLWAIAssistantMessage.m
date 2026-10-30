//
//  TLWAIAssistantMessage.m
//  TL-PestIdentify
//
//  Created by Northern Lights on 2026/4/3.
//  职责：定义AI助手数据模型。
//
#import "TLWAIAssistantMessage.h"
@interface TLWAIAssistantMessage ()
@property (nonatomic, strong) NSMutableString *supplementalBuffer;
@property (nonatomic, copy, nullable) NSString *auxiliarySnapshot;
@end

@implementation TLWAIAssistantMessage
- (instancetype)init {
    if ((self = [super init])) {
        _diseaseSummary = @""; _diseaseNames = @[]; _imageRelativePaths = @[];
        _localHypothesis = @""; _moderationNote = @""; _completionInfo = @{};
        _eventEnvelopes = [NSMutableArray array]; _supplementalBuffer = [NSMutableString string];
    }
    return self;
}
- (void)setDiseaseSummary:(NSString *)summary {
    if ([_diseaseSummary isEqualToString:summary]) return;
    _diseaseSummary = [summary copy] ?: @""; self.auxiliarySnapshot = nil;
}
- (NSString *)supplementalText { return self.supplementalBuffer; }
- (NSString *)auxiliaryText {
    if (!self.auxiliarySnapshot) {
        NSMutableString *text = [NSMutableString string];
        if (self.diseaseSummary.length) [text appendFormat:@"识别结果\n%@\n用药以标签为准", self.diseaseSummary];
        if (self.supplementalBuffer.length) {
            if (text.length) [text appendString:@"\n\n"];
            [text appendString:self.supplementalBuffer];
        }
        self.auxiliarySnapshot = text;
    }
    return self.auxiliarySnapshot;
}
- (void)appendSupplementalText:(NSString *)text {
    if (![text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet].length) return;
    if (self.supplementalBuffer.length) [self.supplementalBuffer appendString:@"\n\n"];
    [self.supplementalBuffer appendString:text]; self.auxiliarySnapshot = nil;
}
- (void)resetAssistantMetadata {
    self.diseaseSummary = @""; self.diseaseNames = @[]; self.completionInfo = @{};
    [self.eventEnvelopes removeAllObjects]; [self.supplementalBuffer setString:@""]; self.auxiliarySnapshot = nil;
}

+ (instancetype)messageWithRole:(TLWAIAssistantMessageRole)role
                           text:(NSString *)text {
    return [self messageWithRole:role text:text localImages:nil remoteImageURLs:nil];
}

+ (instancetype)messageWithRole:(TLWAIAssistantMessageRole)role
                           text:(NSString *)text
                    localImages:(NSArray<UIImage *> *)localImages
                remoteImageURLs:(NSArray<NSString *> *)remoteImageURLs {
    TLWAIAssistantMessage *message = [[self alloc] init];
    message.identifier = NSUUID.UUID.UUIDString.lowercaseString;
    message.role = role;
    message.status = TLWAIAssistantMessageStatusIdle;
    message.text = text ?: @"";
    message.localImages = localImages ?: @[];
    message.remoteImageURLs = remoteImageURLs ?: @[];
    message.createdAt = [NSDate date];
    return message;
}

@end
