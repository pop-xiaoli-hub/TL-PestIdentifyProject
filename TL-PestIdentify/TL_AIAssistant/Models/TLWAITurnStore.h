#import <Foundation/Foundation.h>
@class TLWAIAssistantSession;
NS_ASSUME_NONNULL_BEGIN
/// 主线程会话所有者；账号隔离，不隐式重发历史 turn。
@interface TLWAITurnStore : NSObject
@property (nonatomic, assign, readonly) NSInteger userIdentifier;
@property (nonatomic, copy, readonly) NSArray<TLWAIAssistantSession *> *sessions;
@property (nonatomic, strong, readonly) TLWAIAssistantSession *currentSession;
/// 绑定创建时账号，后续账号变化应创建新 store。
- (instancetype)initWithUserIdentifier:(NSInteger)userIdentifier NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
/// 新建空会话并切换，不复制旧会话上下文。
- (TLWAIAssistantSession *)createSession;
/// 仅按稳定 identifier 切换；未知标识返回 NO。
- (BOOL)selectSessionWithIdentifier:(NSString *)identifier;
/// 用已落库会话替换内存列表；空数组不替换当前空会话。
- (void)replaceWithSessions:(NSArray<TLWAIAssistantSession *> *)sessions currentIdentifier:(nullable NSString *)identifier;
@end
NS_ASSUME_NONNULL_END
