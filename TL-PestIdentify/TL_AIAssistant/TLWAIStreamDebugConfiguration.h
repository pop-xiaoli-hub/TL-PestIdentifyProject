#ifndef TLWAIStreamDebugConfiguration_h
#define TLWAIStreamDebugConfiguration_h

#import <Foundation/Foundation.h>
#import <stdlib.h>

/// 仅显式设置的进程环境变量启用测试；空值/非法地址也属于测试模式，必须失败而非回退线上。
static inline NSString * _Nullable TLWAIStreamTestEndpoint(void) {
#if DEBUG
    const char *value = getenv("TLW_AI_STREAM_TEST_URL");
    return value ? ([NSString stringWithUTF8String:value] ?: @"") : nil;
#else
    return nil;
#endif
}

static inline NSURL * _Nullable TLWAIValidatedStreamTestURL(NSString * _Nonnull value) {
    NSURLComponents *components = [NSURLComponents componentsWithString:value];
    NSString *scheme = components.scheme.lowercaseString;
    if ((![scheme isEqualToString:@"http"] && ![scheme isEqualToString:@"https"]) ||
        !components.host.length || components.user != nil || components.password != nil ||
        components.query != nil || components.fragment != nil ||
        (![components.path isEqualToString:@"/api/v1/agent/chat/stream"] &&
         ![components.path isEqualToString:@"/api/v1/agent/jobs"])) return nil;
    return components.URL;
}

/// 新协议必须明确选择，不能因旧接口失败自动切换，也不能在新接口失败后回退旧 POST。
static inline BOOL TLWAIJobProtocolEnabled(void) {
    NSString *testEndpoint = TLWAIStreamTestEndpoint();
    if (testEndpoint != nil) return [[NSURLComponents componentsWithString:testEndpoint].path isEqualToString:@"/api/v1/agent/jobs"];
    return [[NSBundle.mainBundle objectForInfoDictionaryKey:@"TLWAIJobProtocolEnabled"] boolValue];
}

#endif
