#import <Foundation/Foundation.h>
@class TLWAIAssistantSession, TLWAIAssistantMessage;
NS_ASSUME_NONNULL_BEGIN
/// 助手独立库。不使用收藏、识别记录、我的发布表，也不删除图片文件。
@interface TLWAITurnPersistence : NSObject
@property (nonatomic, assign, readonly) NSInteger userIdentifier;
@property (nonatomic, copy, readonly) NSString *databasePath;
- (instancetype)initWithUserIdentifier:(NSInteger)userIdentifier directory:(nullable NSString *)directory NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
- (BOOL)upsertSession:(TLWAIAssistantSession *)session;
- (NSArray<TLWAIAssistantSession *> *)loadSessions;
/// 同一 WCDB 事务保存会话归属与单条消息检查点；canonical 与 seq/cursor 在同一 JSON 列。
/// 仅提交成功后更新 message.recoveryCheckpoint，失败保留上一可靠点。
- (BOOL)saveRecoveryCheckpoint:(NSDictionary *)checkpoint
                   forMessage:(TLWAIAssistantMessage *)message
                      session:(TLWAIAssistantSession *)session;
@end
NS_ASSUME_NONNULL_END
