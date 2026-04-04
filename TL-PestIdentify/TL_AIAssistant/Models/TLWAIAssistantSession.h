//
//  TLWAIAssistantSession.h
//  TL-PestIdentify
//
//  Created by Northern Lights on 2026/4/3.
//  职责：定义AI助手数据模型。
//
#import <Foundation/Foundation.h>

@class TLWAIAssistantMessage;

NS_ASSUME_NONNULL_BEGIN

@interface TLWAIAssistantSession : NSObject

@property (nonatomic, copy, readonly) NSArray<TLWAIAssistantMessage *> *messages;

- (void)replaceMessages:(NSArray<TLWAIAssistantMessage *> *)messages;
- (void)appendMessage:(TLWAIAssistantMessage *)message;
- (void)removeAllMessages;
- (BOOL)hasMessages;

/// 当消息超过上限时，清除早期消息的本地图片以释放内存
- (void)trimImageMemoryIfNeeded;

@end

NS_ASSUME_NONNULL_END
