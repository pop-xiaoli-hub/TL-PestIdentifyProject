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

NS_ASSUME_NONNULL_BEGIN

@interface TLWAIStreamClient : NSObject

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
/// SSE event: error 或底层请求失败。serverMessage 为服务端给出的提示文案（可空）。
@property (nonatomic, copy, nullable) void (^onError)(NSError * _Nullable error, NSString * _Nullable serverMessage);
/// HTTP 状态码命中 401/403 时回调，调用方负责触发 token 续期 + 重建 stream。
@property (nonatomic, copy, nullable) void (^onAuthFailure)(void);

/// 发起一次流式对话。
/// @param chatRequest AGChatRequest：text / imageUrl / useSingleModel 等字段
/// @param accessToken 当前 access token，内部自动拼 Bearer 前缀
/// @return dataTask 供外层 cancel；配置错误时返回 nil 并立即触发 onError。
- (nullable NSURLSessionDataTask *)streamChatWithRequest:(AGChatRequest *)chatRequest
                                             accessToken:(nullable NSString *)accessToken;

/// 取消当前进行中的流式请求（如果有）。
- (void)cancel;

@end

NS_ASSUME_NONNULL_END
