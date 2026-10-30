//
//  TLWAIStreamClient.h
//  TL-PestIdentify
//
//  职责：AI 对话 SSE 流式客户端，逐帧解析 /api/v1/agent/chat/stream 返回的事件流。
//  原因：SDK 里 chatStreamWithChatRequest: 基于 AFN，会把整段 body 收完再回调，
//  做不到逐帧消费，因此单独封装一层 NSURLSession + Data Delegate。
//

#import <Foundation/Foundation.h>

@class AGChatRequest;
@class TLWAITrace;
@class TLWAIEventEnvelope;

NS_ASSUME_NONNULL_BEGIN

@interface TLWAIStreamClient : NSObject

/// 客户端关联标识，随 X-Client-Request-ID 发送；不代表服务端已支持幂等或续传。
@property (nonatomic, copy, nullable) NSString *clientRequestId;
@property (nonatomic, strong, nullable) TLWAITrace *trace;
/// 任意字节（包括注释/半帧）到达的主线程通知，不能当正文或 firstVisible。
@property (nonatomic, copy, nullable) dispatch_block_t onActivity;
/// 只记录 SSE id/retry，调用方不得据此自动重连。
@property (nonatomic, copy, nullable) void (^onMetadata)(NSString *eventID, NSNumber * _Nullable retryMilliseconds);

/// SSE 注释帧心跳；仅在客户端解析到完整、无业务 data 的注释帧时主线程回调，不触发重连或重发。
@property (nonatomic, copy, nullable) void (^onHeartbeat)(NSString *comment);

/// SSE event: meta  —— 记录 requestId 等元信息。
@property (nonatomic, copy, nullable) void (^onMeta)(NSDictionary *meta);
/// SSE event: disease  —— 识别到的病害列表，主线程回调。
@property (nonatomic, copy, nullable) void (^onDiseaseList)(NSArray *diseases);
/// SSE event: plan_delta  —— 增量方案文本，已提取 .text 字段（若是 JSON）。
@property (nonatomic, copy, nullable) void (^onPlanDelta)(NSString *deltaText);
/// SSE event: plan  —— 服务端给出的完整方案，兜底替换增量累积结果。
@property (nonatomic, copy, nullable) void (^onPlanFinal)(NSString *fullText);
/// SSE event: done  —— 正常结束，附带 info。
@property (nonatomic, copy, nullable) void (^onDone)(NSDictionary *info);
/// 未知事件仅保留信封和实际 fallbackText；不解释未发布的卡片协议。
@property (nonatomic, copy, nullable) void (^onUnknownEvent)(TLWAIEventEnvelope *envelope);
/// Job 协议原始信封模式：非空时仅回调完整信封，不提前解释终态或再调用领域回调。
@property (nonatomic, copy, nullable) void (^onEventEnvelope)(TLWAIEventEnvelope *envelope);
/// 当前协议是否具备任务恢复；旧后端保持 NO，不因断线回退或自动重 POST。
@property (nonatomic, assign, readonly) BOOL supportsJobRecovery;
/// SSE event: error 或底层请求失败。serverMessage 为服务端给出的提示文案（可空）。
@property (nonatomic, copy, nullable) void (^onError)(NSError * _Nullable error, NSString * _Nullable serverMessage);
/// HTTP 401，或错误响应体业务码命中 4006 时回调，调用方负责触发 token 续期 + 重建 stream。
@property (nonatomic, copy, nullable) void (^onAuthFailure)(void);
/// HTTP 2xx 但流自然结束、且没有收到业务 done/error。
/// 未闭合的 SSE 残帧已按 WHATWG 规范丢弃；调用方应把已收正文标记为不完整，而不是当作成功。
/// @param leftoverBytes 被丢弃的残帧字节数（诊断用）。
@property (nonatomic, copy, nullable) void (^onIncompleteEOF)(NSUInteger leftoverBytes);

/// 发起一次流式对话。
/// @param chatRequest AGChatRequest：text / imageUrl / useSingleModel 等字段
/// @param accessToken 当前 access token，内部自动拼 Bearer 前缀
/// @return dataTask 供外层 cancel；配置错误时返回 nil 并立即触发 onError。
- (nullable NSURLSessionDataTask *)streamChatWithRequest:(AGChatRequest *)chatRequest
                                             accessToken:(nullable NSString *)accessToken;

/// 订阅由调用方可信配置构造的同源 job SSE；游标 opaque，不解析其中的数值。
- (nullable NSURLSessionDataTask *)subscribeToEventsAtURL:(NSURL *)url
                                           lastEventID:(nullable NSString *)eventID
                                           accessToken:(nullable NSString *)accessToken
                                             localTest:(BOOL)localTest;

/// 取消当前进行中的流式请求（如果有）。
- (void)cancel;

@end

NS_ASSUME_NONNULL_END
