#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN
/// 以字形簇计算每帧消费预算；大积压只保留最后 16 簇。
NS_INLINE NSUInteger TLWAIFrameBudget(NSUInteger backlog) {
    if (backlog == 0) return 0;
    if (backlog < 8) return 1;
    if (backlog <= 64) return (backlog + 3) / 4;
    return backlog - 16;
}
/// 可暂停的 CADisplayLink，网络接收不依赖该对象。
@interface TLWAIFramePacer : NSObject
@property (nonatomic, assign, getter=isPaused) BOOL paused;
/// tick 在主线程每个可见帧执行，调用方用弱引用捕获页面。
- (instancetype)initWithTick:(dispatch_block_t)tick;
/// 终态或离页必须失效，解除 displayLink 对 target 的持有。
- (void)invalidate;
@end
NS_ASSUME_NONNULL_END
