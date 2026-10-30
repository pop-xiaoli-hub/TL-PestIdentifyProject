//
//  TLWAIAssistantSession.m
//  TL-PestIdentify
//
//  Created by Northern Lights on 2026/4/3.
//  职责：定义AI助手数据模型。
//
#import "TLWAIAssistantSession.h"
#import "TLWAIAssistantMessage.h"

@interface TLWAIAssistantSession ()
@property (nonatomic, strong) NSMutableArray<TLWAIAssistantMessage *> *mutableMessages;
@end

/// 预算与切片只遍历需要的字形簇，避免先复制长历史全文。
static NSUInteger TLWAIAppendContext(NSMutableString *output, NSString *text, NSUInteger budget) {
    if (!budget || !text.length) return 0;
    __block NSUInteger count = 0, length = 0;
    [text enumerateSubstringsInRange:NSMakeRange(0, text.length) options:NSStringEnumerationByComposedCharacterSequences usingBlock:^(NSString *substring, NSRange range, NSRange enclosing, BOOL *stop) {
        count++; length = NSMaxRange(range); if (count >= budget) *stop = YES;
    }];
    [output appendString:[text substringToIndex:length]];
    return count;
}
@implementation TLWAIAssistantSession

- (instancetype)init {
    self = [super init];
    if (self) {
        _mutableMessages = [NSMutableArray array];
        _identifier = NSUUID.UUID.UUIDString.lowercaseString;
        _title = @"新问诊"; _updatedAt = [NSDate date];
    }
    return self;
}

- (NSArray<TLWAIAssistantMessage *> *)messages {
    return [self.mutableMessages copy];
}

- (void)replaceMessages:(NSArray<TLWAIAssistantMessage *> *)messages {
    [self.mutableMessages removeAllObjects];
    if (messages.count > 0) {
        [self.mutableMessages addObjectsFromArray:messages];
    }
}

- (void)appendMessage:(TLWAIAssistantMessage *)message {
    if (!message) return;
    [self.mutableMessages addObject:message];
    self.updatedAt = [NSDate date];
    if (message.role == TLWAIAssistantMessageRoleUser && [self.title isEqualToString:@"新问诊"]) {
        NSMutableString *title = [NSMutableString string];
        NSString *text = [message.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        TLWAIAppendContext(title, text, 18);
        self.title = title.length ? title : @"图片问诊";
    }
}

- (void)removeAllMessages {
    [self.mutableMessages removeAllObjects];
}

- (BOOL)hasMessages {
    return self.mutableMessages.count > 0;
}

- (NSString *)recentContextWithMaxCharacters:(NSUInteger)budget excludingUserIdentifier:(NSString *)identifier {
    if (!budget) return @"";
    NSMutableArray<NSArray<TLWAIAssistantMessage *> *> *pairs = [NSMutableArray arrayWithCapacity:3];
    for (NSInteger i = (NSInteger)self.mutableMessages.count - 1; i >= 0 && pairs.count < 3; i--) {
        TLWAIAssistantMessage *assistant = self.mutableMessages[i];
        if (assistant.role != TLWAIAssistantMessageRoleAssistant || !assistant.completed) continue;
        for (NSInteger j = i - 1; j >= 0; j--) {
            TLWAIAssistantMessage *user = self.mutableMessages[j];
            if (user.role != TLWAIAssistantMessageRoleUser) continue;
            if (![user.identifier isEqualToString:identifier]) [pairs addObject:@[user, assistant]];
            i = j; break;
        }
    }
    if (!pairs.count) return @"";
    NSMutableString *header = [NSMutableString string];
    NSUInteger remaining = budget - TLWAIAppendContext(header, @"以下仅为本会话已完成的问诊摘要，可能有误，请结合本轮重新判断；未包含定位或图片URL。\n", budget);
    NSMutableArray<NSString *> *entries = [NSMutableArray arrayWithCapacity:pairs.count];
    for (NSArray<TLWAIAssistantMessage *> *pair in pairs) {
        if (!remaining) break;
        TLWAIAssistantMessage *user = pair[0], *assistant = pair[1];
        NSMutableString *entry = [NSMutableString string];
        remaining -= TLWAIAppendContext(entry, @"\n先前问诊\n云端疑似病害：", remaining);
        remaining -= TLWAIAppendContext(entry, [assistant.diseaseNames componentsJoinedByString:@"、"], MIN(remaining, 256));
        remaining -= TLWAIAppendContext(entry, @"\n用户：", remaining);
        remaining -= TLWAIAppendContext(entry, user.text.length ? user.text : @"（未记录文字）", MIN(remaining, 300));
        remaining -= TLWAIAppendContext(entry, @"\n助手：", remaining);
        remaining -= TLWAIAppendContext(entry, assistant.text, MIN(remaining, 900));
        [entries addObject:entry];
    }
    for (NSString *entry in entries.reverseObjectEnumerator) [header appendString:entry];
    return header;
}

static NSUInteger const kMaxMessageCount = 100;
static NSUInteger const kImageKeepCount  = 20;

- (void)trimImageMemoryIfNeeded {
    // 超出上限时，移除最早的消息
    while (self.mutableMessages.count > kMaxMessageCount) {
        [self.mutableMessages removeObjectAtIndex:0];
    }
    // 只保留最近 kImageKeepCount 条消息的本地图片，更早的清空以释放内存
    if (self.mutableMessages.count > kImageKeepCount) {
        NSUInteger clearEnd = self.mutableMessages.count - kImageKeepCount;
        for (NSUInteger i = 0; i < clearEnd; i++) {
            TLWAIAssistantMessage *msg = self.mutableMessages[i];
            if (msg.previewImages.count > 0) {
                msg.previewImages = nil;
            }
            if (msg.localImages.count > 0) {
                msg.localImages = nil;
            }
        }
    }
}

@end
