//
//  TLWPerfLog.h
//  TL-PestIdentify
//
//  统一性能埋点日志宏。
//  默认：Debug 输出，Release 静默。
//  性能基线测量（Release 配置 + 仍要拿业务级耗时）时：
//      Build Settings → Other C Flags（Release）追加 -DTLW_PERF_FORCE_LOG=1
//      或在 Run scheme 的 Arguments → Environment Variables 加 TLW_PERF_FORCE_LOG=1（运行时不生效，仅用于自我提醒；真正起效是编译期宏）
//

#ifndef TLWPerfLog_h
#define TLWPerfLog_h

#import <Foundation/Foundation.h>

#if defined(DEBUG) || defined(TLW_PERF_FORCE_LOG)
  #define TLWPerfLog(fmt, ...)  NSLog((@"[PERF] " fmt), ##__VA_ARGS__)
  #define TLWPerfTick()         CFAbsoluteTimeGetCurrent()
  #define TLWPerfMs(t0)         ((CFAbsoluteTimeGetCurrent() - (t0)) * 1000.0)
#else
  #define TLWPerfLog(fmt, ...)  ((void)0)
  #define TLWPerfTick()         (CFAbsoluteTime)0
  #define TLWPerfMs(t0)         ((double)0)
#endif

/// App 进程启动时间戳（main 进入时刻），用于度量 pre-main / 启动总耗时。
FOUNDATION_EXPORT CFAbsoluteTime kTLWAppStartTimestamp;

#endif /* TLWPerfLog_h */
