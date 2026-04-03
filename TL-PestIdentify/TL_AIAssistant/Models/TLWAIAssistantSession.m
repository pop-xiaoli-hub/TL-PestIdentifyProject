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

@end
