#import <Foundation/Foundation.h>

@class TLWAIAssistantMessage;

NS_ASSUME_NONNULL_BEGIN

@interface TLWAIAssistantSession : NSObject

@property (nonatomic, copy, readonly) NSArray<TLWAIAssistantMessage *> *messages;

- (void)replaceMessages:(NSArray<TLWAIAssistantMessage *> *)messages;
- (void)appendMessage:(TLWAIAssistantMessage *)message;
- (void)removeAllMessages;
- (BOOL)hasMessages;

@end

NS_ASSUME_NONNULL_END
