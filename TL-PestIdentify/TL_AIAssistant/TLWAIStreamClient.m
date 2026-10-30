//
//  TLWAIStreamClient.m
//  TL-PestIdentify
//

#import "TLWAIStreamClient.h"
#import "TLWAISSEParser.h"
#import <AgriPestClient/AGChatRequest.h>
#import <AgriPestClient/AGDefaultConfiguration.h>
#import <AgriPestClient/AGServiceCode.h>
#import "TLWAIStreamDebugConfiguration.h"
#import "TLWPerfLog.h"
#import "TLWAITrace.h"
#import "TLWAIEventEnvelope.h"

@interface TLWAIStreamClient () <NSURLSessionDataDelegate>
@property (nonatomic, strong, nullable) NSURLSession *session;
@property (nonatomic, strong, nullable) NSURLSessionDataTask *currentTask;
@property (nonatomic, strong) NSMutableData *buffer;   // 仅用于累积非 2xx 的错误响应体
@property (nonatomic, strong) TLWAISSEParser *parser;  // 2xx 流的切帧解析器
@property (nonatomic, assign) BOOL authFailed;         // 命中 token 失效后丢弃后续事件
@property (nonatomic, assign) BOOL finished;           // 已 done/error，避免重复回调
@property (nonatomic, assign) NSInteger responseStatusCode;
@property (nonatomic, assign) CFAbsoluteTime requestStartTime;
@property (nonatomic, assign) BOOL didLogFirstByte;
@property (nonatomic, assign) NSUInteger captureChunkIndex;
@property (nonatomic, assign) BOOL metadataChanged;
@property (nonatomic, copy, nullable) NSString *responseRetryAfter;
@end

@implementation TLWAIStreamClient

- (NSURLSessionDataTask *)streamChatWithRequest:(AGChatRequest *)chatRequest
                                    accessToken:(NSString *)accessToken {
    @synchronized (self) {
    NSString *testEndpoint = TLWAIStreamTestEndpoint();
    BOOL localTest = testEndpoint != nil;
    NSURL *url = nil;
    if (localTest) {
        url = TLWAIValidatedStreamTestURL(testEndpoint);
    } else {
        NSString *host = [AGDefaultConfiguration sharedConfig].host;
        if (host.length == 0) {
            [self tl_invokeErrorWithMessage:@"后端地址未配置"];
            return nil;
        }
        url = [NSURL URLWithString:[host stringByAppendingString:@"/api/v1/agent/chat/stream"]];
    }
    if (!url) {
        [self tl_invokeErrorWithMessage:localTest ? @"本地流式测试地址无效，请检查 TLW_AI_STREAM_TEST_URL" : @"后端地址无效"];
        return nil;
    }

    NSMutableDictionary *body = [NSMutableDictionary dictionary];
    if (chatRequest.text.length > 0)     body[@"text"] = chatRequest.text;
    if (chatRequest.imageUrl.length > 0) body[@"imageUrl"] = chatRequest.imageUrl;
    if (chatRequest.useSingleModel)      body[@"useSingleModel"] = chatRequest.useSingleModel;
    if (chatRequest.saveHistory)         body[@"saveHistory"] = chatRequest.saveHistory;
    if (chatRequest.extraInfo.length > 0) body[@"extraInfo"] = chatRequest.extraInfo;

    NSError *jsonErr = nil;
    NSData *bodyData = [NSJSONSerialization dataWithJSONObject:body options:0 error:&jsonErr];
    if (jsonErr || !bodyData) {
        [self tl_invokeErrorWithMessage:@"请求体序列化失败"];
        return nil;
    }
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    req.HTTPMethod = @"POST";
    req.HTTPBody = bodyData;
    [req setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [req setValue:@"text/event-stream" forHTTPHeaderField:@"Accept"];
    [req setValue:@"no-cache" forHTTPHeaderField:@"Cache-Control"];
    if (self.clientRequestId.length > 0) {
        [req setValue:self.clientRequestId forHTTPHeaderField:@"X-Client-Request-ID"];
    }
    if (!localTest && accessToken.length > 0) {
        [req setValue:[NSString stringWithFormat:@"Bearer %@", accessToken]
            forHTTPHeaderField:@"Authorization"];
    }
    return [self tl_startRequest:req localTest:localTest];
    }
}

- (BOOL)supportsJobRecovery { return NO; }

- (NSURLSessionDataTask *)subscribeToEventsAtURL:(NSURL *)url lastEventID:(NSString *)eventID
                                   accessToken:(NSString *)accessToken localTest:(BOOL)localTest {
    NSString *scheme = url.scheme.lowercaseString;
    if (!url.host.length || (![scheme isEqualToString:@"http"] && ![scheme isEqualToString:@"https"]) ||
        url.user || url.password || url.fragment ||
        (eventID.length && [eventID rangeOfCharacterFromSet:NSCharacterSet.newlineCharacterSet].location != NSNotFound)) {
        [self tl_invokeErrorWithMessage:@"任务订阅地址或游标无效"];
        return nil;
    }
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"GET";
    [request setValue:@"text/event-stream" forHTTPHeaderField:@"Accept"];
    [request setValue:@"no-cache" forHTTPHeaderField:@"Cache-Control"];
    if (eventID.length) [request setValue:eventID forHTTPHeaderField:@"Last-Event-ID"];
    if (!localTest && accessToken.length)
        [request setValue:[@"Bearer " stringByAppendingString:accessToken] forHTTPHeaderField:@"Authorization"];
    return [self tl_startRequest:request localTest:localTest];
}

- (NSURLSessionDataTask *)tl_startRequest:(NSMutableURLRequest *)request localTest:(BOOL)localTest {
    @synchronized (self) {
        [self.currentTask cancel];
        [self.session invalidateAndCancel];
        request.timeoutInterval = 60;
        NSURLSessionConfiguration *configuration = localTest ? NSURLSessionConfiguration.ephemeralSessionConfiguration : NSURLSessionConfiguration.defaultSessionConfiguration;
        if (localTest || self.onEventEnvelope) {
            request.HTTPShouldHandleCookies = NO;
            configuration.HTTPCookieStorage = nil;
            configuration.HTTPShouldSetCookies = NO;
            configuration.URLCredentialStorage = nil;
        }
        configuration.timeoutIntervalForRequest = 60;
        configuration.timeoutIntervalForResource = 600;
        NSOperationQueue *queue = [NSOperationQueue new];
        queue.maxConcurrentOperationCount = 1;
        self.session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:queue];
        self.buffer = [NSMutableData data];
        self.parser = [TLWAISSEParser new];
        [self tl_bindParser];
        self.authFailed = NO;
        self.finished = NO;
        self.responseStatusCode = 0;
        self.responseRetryAfter = nil;
        self.metadataChanged = NO;
        self.requestStartTime = TLWPerfTick();
        self.didLogFirstByte = NO;
        self.captureChunkIndex = 0;
        TLWPerfLog(@"ai-stream request start bodyBytes=%lu", (unsigned long)request.HTTPBody.length);
        self.currentTask = [self.session dataTaskWithRequest:request];
        [self.trace mark:TLWAITraceStageRequestStart count:0];
        [self.currentTask resume];
        return self.currentTask;
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
    willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)request
    completionHandler:(void (^)(NSURLRequest *))completionHandler {
    // 不跟随重定向：保留 POST 语义，并避免 Bearer/Cookie 被转发到其他 origin。
    completionHandler(nil);
}

- (void)cancel {
    @synchronized (self) {
    self.finished = YES;
    [self.currentTask cancel];
    self.currentTask = nil;
    [self.session invalidateAndCancel];
    self.session = nil;
    }
}

#pragma mark - NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    @synchronized (self) {
    if (self.finished || self.authFailed || (dataTask && dataTask != self.currentTask)) {
        completionHandler(NSURLSessionResponseCancel);
        return;
    }
    if (![response isKindOfClass:[NSHTTPURLResponse class]]) {
        [self tl_invokeErrorWithMessage:@"服务端返回了无效响应"];
        completionHandler(NSURLSessionResponseCancel);
        return;
    }
    NSHTTPURLResponse *http = (NSHTTPURLResponse *)response;
    NSInteger code = http.statusCode;
    self.responseStatusCode = code;
    self.responseRetryAfter = [http valueForHTTPHeaderField:@"Retry-After"];
    [self.trace mark:TLWAITraceStageTTFB count:(NSUInteger)MAX(0, code)];
    TLWPerfLog(@"ai-stream response status=%ld ttfb=%.0fms sse=%d",
               (long)code, TLWPerfMs(self.requestStartTime), [http.MIMEType.lowercaseString isEqualToString:@"text/event-stream"]);
    if (code == 401) {
        [self tl_invokeAuthFailure];
        completionHandler(NSURLSessionResponseCancel);
        return;
    }
    if (code < 200 || code >= 300) {
        // 先读取 JSON 错误体：403 可能是 4003 权限不足，也可能包含 4006 Token 过期。
        completionHandler(NSURLSessionResponseAllow);
        return;
    }
    if (![http.MIMEType.lowercaseString isEqualToString:@"text/event-stream"]) {
        [self tl_invokeErrorWithMessage:@"响应不是事件流，请稍后重试"];
        completionHandler(NSURLSessionResponseCancel);
        return;
    }
    completionHandler(NSURLSessionResponseAllow);
    }
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data {
    @synchronized (self) {
    if (self.authFailed || self.finished || (dataTask && dataTask != self.currentTask)) return;
    dispatch_block_t activity = self.onActivity;
    if (activity) dispatch_async(dispatch_get_main_queue(), activity);
    if (!self.didLogFirstByte) {
        self.didLogFirstByte = YES;
        TLWPerfLog(@"ai-stream firstByte=%.0fms", TLWPerfMs(self.requestStartTime));
    }
    if (self.responseStatusCode >= 200 && self.responseStatusCode < 300) {
        self.captureChunkIndex += 1;
        TLWPerfLog(@"ai-stream chunk #%lu bytes=%lu",
                   (unsigned long)self.captureChunkIndex,
                   (unsigned long)data.length);
        [self.parser appendData:data];
        [self tl_flushMetadata];
        return;
    }
    // 非 2xx：错误体要在完成时整体解析，仍然累积到 buffer。
    if (data.length > 1024 * 1024 - MIN(self.buffer.length, (NSUInteger)(1024 * 1024))) {
        [self tl_invokeErrorWithMessage:@"错误响应体超过安全上限"];
        return;
    }
    [self.buffer appendData:data];
    }
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error {
    @synchronized (self) {
    if (self.authFailed || self.finished || (task && task != self.currentTask)) return;
    if (error) {
        [self tl_invokeError:error message:nil];
        return;
    }
    if (self.responseStatusCode < 200 || self.responseStatusCode >= 300) {
        NSDictionary *payload = [self tl_errorResponsePayload];
        id codeValue = payload[@"code"];
        NSInteger serviceCode = 0;
        if ([codeValue isKindOfClass:[NSNumber class]] || [codeValue isKindOfClass:[NSString class]]) {
            serviceCode = [codeValue integerValue];
        }
        if (serviceCode == 401 || serviceCode == AGServiceCodeInvalidTokenOrTokenExpired) {
            [self tl_invokeAuthFailure];
            return;
        }

        NSString *message = nil;
        for (NSString *key in @[@"message", @"msg", @"error"]) {
            id value = payload[key];
            if ([value isKindOfClass:[NSString class]] && [value length] > 0) {
                message = value;
                break;
            }
        }
        if (message.length == 0) {
            message = [NSString stringWithFormat:@"服务端返回异常(%ld)", (long)self.responseStatusCode];
        }
        NSMutableDictionary *info = [@{NSLocalizedDescriptionKey:message, @"httpStatus":@(self.responseStatusCode)} mutableCopy];
        if (self.responseRetryAfter.length) info[@"retryAfter"] = self.responseRetryAfter;
        [self tl_invokeError:[NSError errorWithDomain:@"TLWAIStreamClient" code:self.responseStatusCode userInfo:info] message:message];
        return;
    }
    // 仅剩 2xx 自然 EOF 且没有业务 done/error：按规范丢弃残帧并通知调用方不完整。
    self.finished = YES;
    NSUInteger leftover = [self.parser finish];
    [self tl_closeSession];
    TLWPerfLog(@"ai-stream eofWithoutDone status=%ld leftover=%lu", (long)self.responseStatusCode, (unsigned long)leftover);
    void (^cb)(NSUInteger) = self.onIncompleteEOF;
    if (!cb) return;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (cb) cb(leftover);
    });
    }
}

#pragma mark - 解析层接线

/// parser 在 delegate 队列（串行）回调；这里转成领域事件后由 tl_dispatchEvent 统一切主线程。
- (void)tl_bindParser {
    __weak typeof(self) weakSelf = self;
    self.parser.onComment = ^(NSString *comment) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf || strongSelf.authFailed || strongSelf.finished) return;
        TLWPerfLog(@"ai-stream comment length=%lu", (unsigned long)comment.length);
        void (^cb)(NSString *) = strongSelf.onHeartbeat;
        NSString *snapshot = comment.copy;
        if (!cb) return;
        dispatch_async(dispatch_get_main_queue(), ^{
            if (cb) cb(snapshot);
        });
    };
    self.parser.onBufferOverflow = ^{
        [weakSelf tl_invokeErrorWithMessage:@"事件帧超过安全上限"];
    };
    self.parser.onMetadata = ^(NSString *eventID, NSNumber *retry) { weakSelf.metadataChanged = YES; };
    self.parser.onEvent = ^(NSString *eventName, NSString *data) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        if (strongSelf.authFailed || strongSelf.finished) return;
        [strongSelf tl_flushMetadata];
        [strongSelf.trace mark:TLWAITraceStageFirstFrame count:data.length];
        TLWPerfLog(@"ai-stream frame length=%lu", (unsigned long)data.length);
        [strongSelf tl_dispatchEvent:eventName data:data];
    };
}

- (void)tl_flushMetadata {
    if (!self.metadataChanged) return;
    self.metadataChanged = NO;
    void (^callback)(NSString *, NSNumber *) = self.onMetadata;
    NSString *eventID = self.parser.lastEventID;
    NSNumber *retry = self.parser.retryMilliseconds;
    if (callback) dispatch_async(dispatch_get_main_queue(), ^{ callback(eventID, retry); });
}

- (void)tl_dispatchEvent:(NSString *)eventName data:(NSString *)dataString {
    if (self.onEventEnvelope) {
        id json = [self tl_jsonObjectFromString:dataString];
        TLWAIEventEnvelope *envelope = [[TLWAIEventEnvelope alloc] initWithEventName:eventName
            eventID:self.parser.lastEventID payload:[json isKindOfClass:NSDictionary.class] ? json : @{}];
        void (^callback)(TLWAIEventEnvelope *) = self.onEventEnvelope;
        dispatch_async(dispatch_get_main_queue(), ^{ callback(envelope); });
        return;
    }
    if ([eventName isEqualToString:@"meta"]) {
        id json = [self tl_jsonObjectFromString:dataString];
        if ([json isKindOfClass:[NSDictionary class]]) {
            void (^cb)(NSDictionary *) = self.onMeta;
            NSDictionary *dict = json;
            dispatch_async(dispatch_get_main_queue(), ^{
                if (cb) cb(dict);
            });
        }
        return;
    }
    if ([eventName isEqualToString:@"disease"]) {
        id json = [self tl_jsonObjectFromString:dataString];
        NSArray *list = nil;
        if ([json isKindOfClass:[NSArray class]]) {
            list = json;
        } else if ([json isKindOfClass:[NSDictionary class]]) {
            id inner = ((NSDictionary *)json)[@"diseases"];
            list = [inner isKindOfClass:[NSArray class]] ? inner : @[json];
        }
        if (list.count > 0) {
            void (^cb)(NSArray *) = self.onDiseaseList;
            NSArray *snapshot = list;
            dispatch_async(dispatch_get_main_queue(), ^{
                if (cb) cb(snapshot);
            });
        }
        return;
    }
    if ([eventName isEqualToString:@"plan_delta"]) {
        NSString *text = [self tl_deltaTextFromRawData:dataString];
        if (text.length > 0) {
            [self.trace mark:TLWAITraceStageModelDelta count:text.length];
            void (^cb)(NSString *) = self.onPlanDelta;
            dispatch_async(dispatch_get_main_queue(), ^{
                if (cb) cb(text);
            });
        }
        return;
    }
    if ([eventName isEqualToString:@"plan"]) {
        NSString *text = [self tl_planFinalFromRawData:dataString];
        if (text.length > 0) {
            void (^cb)(NSString *) = self.onPlanFinal;
            dispatch_async(dispatch_get_main_queue(), ^{
                if (cb) cb(text);
            });
        }
        return;
    }
    if ([eventName isEqualToString:@"done"]) {
        self.finished = YES;
        [self tl_closeSession];
        TLWPerfLog(@"ai-stream done total=%.0fms", TLWPerfMs(self.requestStartTime));
        id json = [self tl_jsonObjectFromString:dataString];
        NSDictionary *info = [json isKindOfClass:[NSDictionary class]] ? json : @{};
        void (^cb)(NSDictionary *) = self.onDone;
        dispatch_async(dispatch_get_main_queue(), ^{
            if (cb) cb(info);
        });
        return;
    }
    if ([eventName isEqualToString:@"error"]) {
        id json = [self tl_jsonObjectFromString:dataString];
        NSString *msg = nil;
        if ([json isKindOfClass:[NSDictionary class]]) {
            NSDictionary *dict = json;
            msg = [self tl_firstStringInDictionary:dict];
        } else if ([json isKindOfClass:NSString.class]) {
            msg = json;
        } else if (!json) {
            // 后端也会发送纯文本错误，例如 "HTTP 400 "；不能用通用文案覆盖原因。
            msg = dataString;
        }
        [self tl_invokeError:nil message:msg.length > 0 ? msg : @"回复失败"];
        return;
    }
    id json = [self tl_jsonObjectFromString:dataString];
    NSDictionary *payload = [json isKindOfClass:NSDictionary.class] ? json : @{};
    TLWAIEventEnvelope *envelope = [[TLWAIEventEnvelope alloc] initWithEventName:eventName eventID:self.parser.lastEventID payload:payload];
    void (^callback)(TLWAIEventEnvelope *) = self.onUnknownEvent;
    if (callback) dispatch_async(dispatch_get_main_queue(), ^{ callback(envelope); });
}

#pragma mark - Helpers

- (NSDictionary *)tl_errorResponsePayload {
    if (self.buffer.length == 0) return @{};
    id json = [NSJSONSerialization JSONObjectWithData:self.buffer options:0 error:nil];
    return [json isKindOfClass:[NSDictionary class]] ? json : @{};
}

- (void)tl_invokeAuthFailure {
    if (self.finished) return;
    self.authFailed = YES;
    self.finished = YES;
    [self tl_closeSession];
    void (^cb)(void) = self.onAuthFailure;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (cb) cb();
    });
}

- (id)tl_jsonObjectFromString:(NSString *)string {
    if (string.length == 0) return nil;
    NSData *d = [string dataUsingEncoding:NSUTF8StringEncoding];
    if (!d) return nil;
    NSError *err = nil;
    return [NSJSONSerialization JSONObjectWithData:d options:NSJSONReadingAllowFragments error:&err];
}

- (NSString *)tl_firstStringInDictionary:(NSDictionary *)dictionary {
    NSString * const keys[] = {@"controlPlan", @"text", @"delta", @"content", @"plan", @"answer", @"advice", @"solution", @"reason", @"message", @"error", @"msg", @"fallbackText"};
    for (NSUInteger index = 0; index < sizeof(keys) / sizeof(keys[0]); index++) {
        id value = dictionary[keys[index]];
        if ([value isKindOfClass:NSString.class] && [value length] > 0) return value;
    }
    return @"";
}
- (NSString *)tl_deltaTextFromRawData:(NSString *)dataString {
    id json = [self tl_jsonObjectFromString:dataString];
    if ([json isKindOfClass:NSString.class]) return json;
    if ([json isKindOfClass:NSDictionary.class]) return [self tl_firstStringInDictionary:json];
    if (json || [dataString hasPrefix:@"{"] || [dataString hasPrefix:@"["]) return @"";
    return dataString ?: @"";
}
- (NSString *)tl_planFinalFromRawData:(NSString *)dataString {
    id json = [self tl_jsonObjectFromString:dataString];
    if ([json isKindOfClass:NSDictionary.class]) {
        NSString *text = [self tl_firstStringInDictionary:json];
        if (text.length) return text;
        id nested = json[@"data"];
        return [nested isKindOfClass:NSDictionary.class] ? [self tl_firstStringInDictionary:nested] : @"";
    }
    return [self tl_deltaTextFromRawData:dataString];
}

- (void)tl_invokeErrorWithMessage:(NSString *)message {
    [self tl_invokeError:nil message:message];
}

- (void)tl_invokeError:(NSError *)error message:(NSString *)message {
    if (self.finished) return;
    self.finished = YES;
    [self tl_closeSession];
    NSError *finalErr = error;
    if (!finalErr) {
        finalErr = [NSError errorWithDomain:@"TLWAIStreamClient"
                                        code:-1
                                    userInfo:@{NSLocalizedDescriptionKey: message ?: @"请求失败"}];
    }
    void (^cb)(NSError *, NSString *) = self.onError;
    NSString *serverMsg = message;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (cb) cb(finalErr, serverMsg);
    });
}

/// 在持有 self 锁的终态路径调用；业务 done 后也主动结束 task，释放 session 对 delegate 的持有。
- (void)tl_closeSession {
    [self.currentTask cancel];
    self.currentTask = nil;
    [self.session finishTasksAndInvalidate];
    self.session = nil;
}

@end
