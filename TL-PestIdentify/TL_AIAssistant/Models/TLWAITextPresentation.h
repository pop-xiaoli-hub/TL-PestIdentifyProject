#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN
/// 正文展示门控：保留原文，只短暂暂存未完成的行内语法；不维护 Markdown 块或视图。
@interface TLWAITextPresentation : NSObject
@property (nonatomic, copy, readonly) NSString *source;
@property (nonatomic, copy, readonly) NSString *visibleText;
@property (nonatomic, assign, readonly) BOOL hasHeldTail;
/// time 为 systemUptime；测试可以注入单调时间。暂存最多 64 字形簇/250ms。
- (void)appendText:(NSString *)text atTime:(NSTimeInterval)time;
- (BOOL)releaseExpiredAtTime:(NSTimeInterval)time;
/// 释放全部已消费正文，不伪造 Markdown 闭合符号。
- (void)finish;
- (void)reset;
@end
NS_ASSUME_NONNULL_END
