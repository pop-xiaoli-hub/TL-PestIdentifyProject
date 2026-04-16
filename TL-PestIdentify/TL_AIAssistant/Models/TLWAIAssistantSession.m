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

@implementation TLWAIAssistantSession

- (instancetype)init {
    self = [super init];
    if (self) {
        _mutableMessages = [NSMutableArray array];
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
}

- (void)removeAllMessages {
    [self.mutableMessages removeAllObjects];
}

- (BOOL)hasMessages {
    return self.mutableMessages.count > 0;
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
