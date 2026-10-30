#import "TLWAIStreamClient.h"
#import "TLWAIRecoveryState.h"
static inline BOOL TLWAIJobFlag(NSDictionary * _Nullable checkpoint, NSString * _Nonnull key) {
    id value = [checkpoint isKindOfClass:NSDictionary.class] ? checkpoint[key] : nil;
    return [value isKindOfClass:NSNumber.class] && [value boolValue];
}
/// 只有从未发出，或服务端明确拒绝且已持久化该拒绝时，才允许 POST。已发出但没有 jobId 必须先查询。
static inline BOOL TLWAIJobMaySilentlyCreate(NSDictionary * _Nullable checkpoint) {
    id job = [checkpoint isKindOfClass:NSDictionary.class] ? checkpoint[@"jobId"] : nil;
    if ([job isKindOfClass:NSString.class] && [(NSString *)job length]) return NO;
    return !TLWAIJobFlag(checkpoint, @"creationSent") || TLWAIJobFlag(checkpoint, @"creationRejected");
}
NS_ASSUME_NONNULL_BEGIN
/// stream-job.v1 适配器；创建与订阅分离，不会回退到旧 chat POST。
@interface TLWAIJobStreamClient : TLWAIStreamClient
- (instancetype)initWithJobsURL:(nullable NSURL *)url localTest:(BOOL)localTest
                    checkpoint:(NSDictionary *)checkpoint commit:(TLWAIRecoveryCommit)commit;
@property (nonatomic, copy, nullable) void (^onRestoreCheckpoint)(NSDictionary *checkpoint);
@property (nonatomic, copy, nullable) void (^onRecoveryStateChanged)(BOOL recovering);
@property (nonatomic, copy, nullable) dispatch_block_t onServerCancelled;
/// 复用页面的路径监测；恢复网络只唤醒已排队的同 job 恢复，不创建新任务。
@property (nonatomic, assign) BOOL networkAvailable;
/// 明确的用户停止；返回本地取消检查点是否已保存，不代表服务端取消 ACK。
- (BOOL)cancelJob;
@end
NS_ASSUME_NONNULL_END
