#import <Foundation/Foundation.h>
@class TLWAIEventEnvelope;
NS_ASSUME_NONNULL_BEGIN
typedef NS_ENUM(NSInteger, TLWAIRecoveryApplyResult) {
    TLWAIRecoveryApplyResultAccepted = 0,
    TLWAIRecoveryApplyResultDuplicate,
    TLWAIRecoveryApplyResultGap,
    TLWAIRecoveryApplyResultInvalid,
    TLWAIRecoveryApplyResultStorageFailed,
};
typedef BOOL (^TLWAIRecoveryCommit)(NSDictionary *checkpoint);
/// 单 owner queue 使用；checkpoint 是可靠接收进度，不是已经显示到屏幕的字符数。
@interface TLWAIRecoveryState : NSObject
@property (nonatomic, copy, readonly) NSDictionary *checkpoint;
- (nullable instancetype)initWithCheckpoint:(NSDictionary *)checkpoint;
/// 同一幂等键绑定任务，任务终态仍须通过事件或一致快照补齐内容。
- (BOOL)bindCreatedJob:(NSDictionary *)response commit:(TLWAIRecoveryCommit)commit error:(NSError * _Nullable * _Nullable)error;
/// candidate 持久化成功后才推进正文/seq/cursor；重复不提交，缺口不拼接。
- (TLWAIRecoveryApplyResult)applyEnvelope:(TLWAIEventEnvelope *)envelope commit:(TLWAIRecoveryCommit)commit error:(NSError * _Nullable * _Nullable)error;
/// 一致快照替换，不追加；不能回滚 seq、跨 job 或复活终态。
- (BOOL)applySnapshot:(NSDictionary *)snapshot commit:(TLWAIRecoveryCommit)commit error:(NSError * _Nullable * _Nullable)error;
@end
NS_ASSUME_NONNULL_END
