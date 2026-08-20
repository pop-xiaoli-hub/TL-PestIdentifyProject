//
//  TLWMetricKitReporter.h
//  TL-PestIdentify
//
//  iOS 13+ MetricKit 订阅器，将系统下发的性能/诊断数据落本地。
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TLWMetricKitReporter : NSObject

/// 单例
+ (instancetype)sharedInstance;

/// 启动订阅。建议在 `application:didFinishLaunchingWithOptions:` 调用。iOS 12 直接 no-op。
- (void)start;

/// Documents/PerfMetrics 目录路径
- (NSString *)payloadsDirectory;

/// dump 最近一次接收到的 payload 摘要文本，便于 debug 时 lookin/console 查看
- (nullable NSString *)latestPayloadSummary;

@end

NS_ASSUME_NONNULL_END
