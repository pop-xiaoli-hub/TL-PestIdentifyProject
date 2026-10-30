#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN
typedef NS_ENUM(NSUInteger, TLWAITraceStage) {
    TLWAITraceStageSend, TLWAITraceStageRequestStart, TLWAITraceStageTTFB,
    TLWAITraceStageFirstFrame, TLWAITraceStageModelDelta, TLWAITraceStageFirstVisible,
    TLWAITraceStageVisibleFrame, TLWAITraceStageTerminal, TLWAITraceStagePathChange,
};
/// 仅记录受控阶段、长度和耗时，不接受正文/URL/token；TTFT 是 firstVisible 而非 TTFB。
@interface TLWAITrace : NSObject
@property (nonatomic, copy, readonly) NSString *identifier;
@property (nonatomic, assign, readonly) NSTimeInterval firstVisibleElapsed;
/// 线程安全，首类阶段只记录一次；count 是字节/字形簇数量或终态枚举值。
- (void)mark:(TLWAITraceStage)stage count:(NSUInteger)count;
@end
NS_ASSUME_NONNULL_END
