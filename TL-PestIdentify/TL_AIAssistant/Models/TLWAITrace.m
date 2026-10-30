#import "TLWAITrace.h"
#import <os/signpost.h>
@interface TLWAITrace ()
@property (nonatomic, strong) NSObject *lock;
@property (nonatomic) CFAbsoluteTime startedAt;
@property (nonatomic) NSUInteger recorded;
@property (nonatomic) os_signpost_id_t signpostID;
@property (nonatomic, assign, readwrite) NSTimeInterval firstVisibleElapsed;
@end
@implementation TLWAITrace
static os_log_t TLWAITraceLog(void) {
    static os_log_t log; static dispatch_once_t once;
    dispatch_once(&once, ^{ log = os_log_create("com.tlw.assistant", "stream"); });
    return log;
}
- (instancetype)init {
    if ((self = [super init])) {
        _identifier = NSUUID.UUID.UUIDString.lowercaseString;
        _lock = [NSObject new]; _startedAt = CFAbsoluteTimeGetCurrent();
        _signpostID = os_signpost_id_generate(TLWAITraceLog());
        _firstVisibleElapsed = -1;
    }
    return self;
}
- (void)mark:(TLWAITraceStage)stage count:(NSUInteger)count {
    @synchronized (self.lock) {
        BOOL once = stage != TLWAITraceStageModelDelta && stage != TLWAITraceStageVisibleFrame && stage != TLWAITraceStagePathChange;
        NSUInteger bit = (NSUInteger)1 << stage;
        if (once && (self.recorded & bit)) return;
        self.recorded |= bit;
        double elapsed = (CFAbsoluteTimeGetCurrent() - self.startedAt) * 1000;
        if (stage == TLWAITraceStageFirstVisible) self.firstVisibleElapsed = elapsed / 1000;
#define TLWAI_TRACE_EVENT(NAME) os_signpost_event_emit(TLWAITraceLog(), self.signpostID, NAME, "elapsed_ms=%.3f count=%lu", elapsed, (unsigned long)count)
        switch (stage) {
            case TLWAITraceStageSend: TLWAI_TRACE_EVENT("send"); break;
            case TLWAITraceStageRequestStart: TLWAI_TRACE_EVENT("requestStart"); break;
            case TLWAITraceStageTTFB: TLWAI_TRACE_EVENT("ttfb"); break;
            case TLWAITraceStageFirstFrame: TLWAI_TRACE_EVENT("firstFrame"); break;
            case TLWAITraceStageModelDelta: TLWAI_TRACE_EVENT("modelDelta"); break;
            case TLWAITraceStageFirstVisible: TLWAI_TRACE_EVENT("firstVisible"); break;
            case TLWAITraceStageVisibleFrame: TLWAI_TRACE_EVENT("visibleFrame"); break;
            case TLWAITraceStageTerminal: TLWAI_TRACE_EVENT("terminal"); break;
            case TLWAITraceStagePathChange: TLWAI_TRACE_EVENT("pathChange"); break;
        }
#undef TLWAI_TRACE_EVENT
    }
}
@end
