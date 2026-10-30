#import "TLWAIFramePacer.h"
#import <UIKit/UIKit.h>
@interface TLWAIFramePacer ()
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, copy) dispatch_block_t tick;
@end
@implementation TLWAIFramePacer
- (instancetype)initWithTick:(dispatch_block_t)tick {
    if ((self = [super init])) {
        _tick = [tick copy];
        _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(tl_tick:)];
        _displayLink.paused = YES;
        [_displayLink addToRunLoop:NSRunLoop.mainRunLoop forMode:NSRunLoopCommonModes];
    }
    return self;
}
- (void)tl_tick:(CADisplayLink *)link { if (self.tick) self.tick(); }
- (BOOL)isPaused { return self.displayLink.paused; }
- (void)setPaused:(BOOL)paused { self.displayLink.paused = paused; }
- (void)invalidate { [self.displayLink invalidate]; self.displayLink = nil; self.tick = nil; }
@end
