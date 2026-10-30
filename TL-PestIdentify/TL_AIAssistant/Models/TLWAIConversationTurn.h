#import <Foundation/Foundation.h>
@class AGChatRequest, TLWAIStreamClient, TLWAIAssistantMessage, TLWAIFramePacer;
@class TLWAITrace;
@class TLWAITextPresentation;
NS_ASSUME_NONNULL_BEGIN
typedef NS_ENUM(NSInteger, TLWAIConversationTurnState) {
    TLWAIConversationTurnStateIdle = 0,
    TLWAIConversationTurnStateUploading,
    TLWAIConversationTurnStateConnecting,
    TLWAIConversationTurnStateStreaming,
    TLWAIConversationTurnStateRecovering,
    TLWAIConversationTurnStateAuthRefresh,
    TLWAIConversationTurnStateCompleted,
    TLWAIConversationTurnStateIncomplete,
    TLWAIConversationTurnStateFailed,
    TLWAIConversationTurnStateCancelled,
};
/// 一轮请求及其展示缓冲；主线程约束，终态不可复活，Controller 清 activeTurn 后会话回到 Idle。
@interface TLWAIConversationTurn : NSObject
@property (nonatomic, copy, readonly) NSString *identifier;
@property (nonatomic, copy, readonly) NSString *clientRequestId;
/// 仅接受 meta.requestId，缺字段保持 nil，不推测服务端 ID。
@property (nonatomic, copy, nullable) NSString *serverRequestId;
@property (nonatomic, copy, nullable) NSString *lastEventID;
@property (nonatomic, strong, nullable) NSNumber *retryMilliseconds;
@property (nonatomic, strong, readonly) TLWAITrace *trace;
/// 最近网络活动的 systemUptime，单调时钟，仅保存在本轮内存。
@property (nonatomic, assign) NSTimeInterval lastByteAt;
/// 本地已应用业务帧序号，不是服务端 SSE id/seq。
@property (nonatomic, assign, readonly) NSUInteger lastAppliedSeq;
@property (nonatomic, assign, readonly) NSUInteger generation;
@property (nonatomic, assign, readonly) NSUInteger retryCount;
@property (nonatomic, assign, readonly) TLWAIConversationTurnState state;
@property (nonatomic, assign, readonly, getter=isTerminal) BOOL terminal;
@property (nonatomic, strong, readonly) TLWAIAssistantMessage *userMessage;
@property (nonatomic, strong, readonly) TLWAIAssistantMessage *assistantMessage;
@property (nonatomic, strong, nullable) AGChatRequest *request;
@property (nonatomic, strong, nullable) NSURLSessionTask *uploadTask;
@property (nonatomic, strong, nullable) TLWAIStreamClient *streamClient;
@property (nonatomic, strong, nullable) TLWAIFramePacer *framePacer;
@property (nonatomic, copy, nullable) dispatch_block_t authRestart;
@property (nonatomic, strong, readonly) NSMutableString *pendingDelta;
/// 已消费原文由展示门控持有；pendingDelta 仍保存尚未消费的正文。
@property (nonatomic, copy, readonly) NSString *planAccumulated;
@property (nonatomic, strong, readonly) TLWAITextPresentation *textPresentation;
/// 绑定本轮用户/助手消息，初态 Idle。
- (instancetype)initWithUserMessage:(TLWAIAssistantMessage *)userMessage assistantMessage:(TLWAIAssistantMessage *)assistantMessage;
/// 有图时先进入 Uploading；返回是否接受该转移。
- (BOOL)beginUpload;
/// Idle/Uploading/AuthRefresh 到 Connecting，并推进 connection generation。
- (BOOL)beginConnection;
/// 验证本轮标识与连接代际，终态或 AuthRefresh 不接收旧连接事件。
- (BOOL)acceptsIdentifier:(NSString *)identifier generation:(NSUInteger)generation;
/// 接受一帧业务输出，推进本地序号并进入 Streaming。
- (BOOL)recordFrameForGeneration:(NSUInteger)generation;
/// 只有活动代际可以追加已闭合帧正文。
- (void)appendDelta:(NSString *)delta generation:(NSUInteger)generation;
/// 最终方案为快照，替换已有方案及未展示增量。
- (void)replacePlan:(NSString *)text generation:(NSUInteger)generation;
/// 恢复尚未完成的 canonical 前缀，保留字面量上下文并允许后续追加。
- (void)restoreReceivedPlan:(NSString *)text generation:(NSUInteger)generation;
/// 外层轮次代际不变；Job 适配器内部单独隔离重连连接和重试 ticket。
- (void)setRecovering:(BOOL)recovering generation:(NSUInteger)generation;
/// Unicode 字形簇消费预算；NSUIntegerMax 表示完整 drain。
- (NSString *)consumePendingWithBudget:(NSUInteger)budget;
/// 完整 drain 已解析正文，未闭合协议帧不在此层。
- (NSString *)flushAllPendingDelta;
/// 仅允许一次鉴权重建；Job 保留可靠正文/展示缓冲，旧协议重建才清空。
- (BOOL)prepareAuthRefresh;
/// 终态唯一出口，先 drain 后 cancel 资源；返回 NO 表示重复/非法转移。
- (BOOL)finishWithState:(TLWAIConversationTurnState)state;
@end
NS_ASSUME_NONNULL_END
