//
//  TLWMetricKitReporter.m
//  TL-PestIdentify
//

#import "TLWMetricKitReporter.h"
#import "TLWPerfLog.h"

#if __has_include(<MetricKit/MetricKit.h>)
#import <MetricKit/MetricKit.h>
#define TLW_HAS_METRICKIT 1
#else
#define TLW_HAS_METRICKIT 0
#endif

#if TLW_HAS_METRICKIT
API_AVAILABLE(ios(13.0))
@interface TLWMetricKitReporter () <MXMetricManagerSubscriber>
@end
#endif

@interface TLWMetricKitReporter ()
@property (nonatomic, copy, nullable) NSString *latestSummary;
@property (nonatomic, assign) BOOL didStart;
@end

@implementation TLWMetricKitReporter

+ (instancetype)sharedInstance {
    static TLWMetricKitReporter *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[TLWMetricKitReporter alloc] init];
    });
    return instance;
}

- (void)start {
    if (self.didStart) return;
    self.didStart = YES;
#if TLW_HAS_METRICKIT
    if (@available(iOS 13.0, *)) {
        [[MXMetricManager sharedManager] addSubscriber:self];
        [self ensureDirectory];
        TLWPerfLog(@"metrickit subscriber started dir=%@", [self payloadsDirectory]);
    }
#endif
}

- (NSString *)payloadsDirectory {
    NSString *docs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    return [docs stringByAppendingPathComponent:@"PerfMetrics"];
}

- (void)ensureDirectory {
    NSString *dir = [self payloadsDirectory];
    if (![[NSFileManager defaultManager] fileExistsAtPath:dir]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:dir
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:nil];
    }
}

- (nullable NSString *)latestPayloadSummary {
    return self.latestSummary;
}

#if TLW_HAS_METRICKIT

- (void)didReceiveMetricPayloads:(NSArray<MXMetricPayload *> *)payloads API_AVAILABLE(ios(13.0)) {
    [self ensureDirectory];
    NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
    fmt.dateFormat = @"yyyy-MM-dd_HHmmss";
    for (MXMetricPayload *payload in payloads) {
        NSData *json = [payload JSONRepresentation];
        if (json.length == 0) continue;
        NSString *fname = [NSString stringWithFormat:@"metric_%@.json", [fmt stringFromDate:payload.timeStampEnd ?: [NSDate date]]];
        NSString *path = [[self payloadsDirectory] stringByAppendingPathComponent:fname];
        [json writeToFile:path atomically:YES];

        NSString *summary = [self summaryForMetricPayload:payload];
        self.latestSummary = summary;
        TLWPerfLog(@"metrickit metric saved=%@\n%@", fname, summary);
    }
}

- (void)didReceiveDiagnosticPayloads:(NSArray<MXDiagnosticPayload *> *)payloads API_AVAILABLE(ios(14.0)) {
    [self ensureDirectory];
    NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
    fmt.dateFormat = @"yyyy-MM-dd_HHmmss";
    for (MXDiagnosticPayload *payload in payloads) {
        NSData *json = [payload JSONRepresentation];
        if (json.length == 0) continue;
        NSString *fname = [NSString stringWithFormat:@"diag_%@.json", [fmt stringFromDate:payload.timeStampEnd ?: [NSDate date]]];
        NSString *path = [[self payloadsDirectory] stringByAppendingPathComponent:fname];
        [json writeToFile:path atomically:YES];
        TLWPerfLog(@"metrickit diagnostic saved=%@", fname);
    }
}

- (NSString *)summaryForMetricPayload:(MXMetricPayload *)payload API_AVAILABLE(ios(13.0)) {
    NSMutableString *s = [NSMutableString string];
    [s appendFormat:@"  app=%@ build=%@\n", payload.latestApplicationVersion ?: @"-", payload.metaData.applicationBuildVersion ?: @"-"];
    if (payload.applicationLaunchMetrics) {
        MXHistogram<NSUnitDuration *> *firstDraw = payload.applicationLaunchMetrics.histogrammedTimeToFirstDraw;
        [s appendFormat:@"  launch.firstDraw buckets=%lu totalCount=%llu\n",
         (unsigned long)firstDraw.totalBucketCount, (unsigned long long)firstDraw.totalBucketCount];
    }
    if (payload.memoryMetrics) {
        [s appendFormat:@"  mem.peak=%@ mem.avgSuspended=%@\n",
         payload.memoryMetrics.peakMemoryUsage, payload.memoryMetrics.averageSuspendedMemory];
    }
    if (@available(iOS 14.0, *)) {
        if (payload.applicationResponsivenessMetrics) {
            MXHistogram<NSUnitDuration *> *hangs = payload.applicationResponsivenessMetrics.histogrammedApplicationHangTime;
            [s appendFormat:@"  hang.totalBuckets=%lu\n", (unsigned long)hangs.totalBucketCount];
        }
    }
    return [s copy];
}

#endif

@end
