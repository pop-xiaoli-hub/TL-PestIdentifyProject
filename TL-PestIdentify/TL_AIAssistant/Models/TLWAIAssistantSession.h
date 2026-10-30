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

/// 本地会话稳定标识与菜单标题，不当作服务端 conversationId。
@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, strong) NSDate *updatedAt;
@property (nonatomic, copy, readonly) NSArray<TLWAIAssistantMessage *> *messages;

- (void)replaceMessages:(NSArray<TLWAIAssistantMessage *> *)messages;
- (void)appendMessage:(TLWAIAssistantMessage *)message;
- (void)removeAllMessages;
- (BOOL)hasMessages;

/// 当消息超过上限时，清除早期消息的本地图片以释放内存
- (void)trimImageMemoryIfNeeded;
/// 最近最多三轮已完成问诊的纯文本摘要；按字形簇预算，不包含图片URL/定位/天气。
/// @param identifier 本轮用户消息，必须排除，避免将当前问题重复拼入 extraInfo。
- (NSString *)recentContextWithMaxCharacters:(NSUInteger)budget excludingUserIdentifier:(NSString *)identifier;

@end

NS_ASSUME_NONNULL_END
