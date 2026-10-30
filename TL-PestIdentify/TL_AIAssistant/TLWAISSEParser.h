//
//  TLWAISSEParser.h
//  TL-PestIdentify
//
//  职责：纯 Foundation 的 SSE 增量解析器。
//  原因：把“字节缓冲 → 完整事件帧”的解析从网络层剥出来，才能对
//        分块边界、UTF-8 截断、CRLF、多行 data、尾部残留做纯单元测试。
//
//  协议边界（与 WHATWG SSE 规范对齐的子集）：
//  - 事件必须以空行（\n\n / \r\n\r\n / \r\r）结束；EOF 时未闭合的帧按规范丢弃。
//  - 支持多行 data:、event:、注释、BOM、无冒号空字段；记录 id/retry，但不重连或续传。
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// SSE 解析回调。
/// @param eventName 事件名（规范要求无事件名的帧默认为 "message"，但当前后端协议总是显式命名；
///                  为保持向后兼容，此实现遇到无 event: 的帧会跳过，不派发 "message"）。
/// @param data      该帧所有 data: 行用 \n 拼接后的文本。
typedef void (^TLWAISSEParserEventCallback)(NSString *eventName, NSString *data);

@interface TLWAISSEParser : NSObject

/// 每解析出一个完整、无业务 data 的注释帧就回调一次；回调参数为该帧注释文本（多行以 \n 拼接）。
/// 注释帧不会触发 onEvent，也不会被当作业务正文。
@property (nonatomic, copy, nullable) void (^onComment)(NSString *comment);

/// 每解析出一个完整事件帧就回调一次（同步调用，调用方自负线程安全）。
/// parser 不负责事件分发到主线程，也不负责 JSON 解码。
@property (nonatomic, copy, nullable) TLWAISSEParserEventCallback onEvent;

/// 未成帧缓冲超过 1MiB 时同步回调一次；解析器随后拒绝数据，直到 reset。
@property (nonatomic, copy, nullable) void (^onBufferOverflow)(void);

/// 协议元数据变化时同步回调；无冒号 id 清为空值，retry 仅接受 ASCII 非负整数。
@property (nonatomic, copy, nullable) void (^onMetadata)(NSString *eventID, NSNumber * _Nullable retryMilliseconds);
@property (nonatomic, copy, readonly) NSString *lastEventID;
@property (nonatomic, strong, nullable, readonly) NSNumber *retryMilliseconds;

/// 追加网络分块并解析出所有完整事件帧。
/// 跨 chunk UTF-8 留在线缓冲；每字节仅扫描一次，只有空行才派发业务帧。
- (void)appendData:(NSData *)data;

/// 流式传输正常结束时调用。未闭合的残帧按 WHATWG 规范丢弃，不派发事件。
/// @return 丢弃的残帧字节数（用于日志/诊断；0 表示缓冲已清空）。
- (NSUInteger)finish;

/// 清空缓冲（用于请求复用前复位）。
- (void)reset;

/// 当前缓冲中未消费的字节数（诊断用）。
@property (nonatomic, readonly) NSUInteger bufferedByteCount;

@end

NS_ASSUME_NONNULL_END
