//
//  TLWAIStreamClient.m
//  TL-PestIdentify
//

#import "TLWAIStreamClient.h"
#import <AgriPestClient/AGChatRequest.h>
#import <AgriPestClient/AGDefaultConfiguration.h>

@interface TLWAIStreamClient () <NSURLSessionDataDelegate>
@property (nonatomic, strong, nullable) NSURLSession *session;
@property (nonatomic, strong, nullable) NSURLSessionDataTask *currentTask;
@property (nonatomic, strong) NSMutableData *buffer;   // 切帧前的原始字节缓冲（防粘包）
@property (nonatomic, assign) BOOL authFailed;         // 命中 401/403 后丢弃后续事件
@property (nonatomic, assign) BOOL finished;           // 已 done/error，避免重复回调
@end

@implementation TLWAIStreamClient

- (NSURLSessionDataTask *)streamChatWithRequest:(AGChatRequest *)chatRequest
                                    accessToken:(NSString *)accessToken {
    NSString *host = [AGDefaultConfiguration sharedConfig].host;
    if (host.length == 0) {
        [self tl_invokeErrorWithMessage:@"后端地址未配置"];
        return nil;
    }
    NSURL *url = [NSURL URLWithString:[host stringByAppendingString:@"/api/v1/agent/chat/stream"]];
    if (!url) {
        [self tl_invokeErrorWithMessage:@"后端地址无效"];
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
    NSLog(@"[AIAssistant] stream request body: %@", body);

    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    req.HTTPMethod = @"POST";
    req.HTTPBody = bodyData;
    [req setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [req setValue:@"text/event-stream" forHTTPHeaderField:@"Accept"];
    [req setValue:@"no-cache" forHTTPHeaderField:@"Cache-Control"];
    if (accessToken.length > 0) {
        [req setValue:[NSString stringWithFormat:@"Bearer %@", accessToken]
            forHTTPHeaderField:@"Authorization"];
    }
    req.timeoutInterval = 60.0;

    NSURLSessionConfiguration *cfg = [NSURLSessionConfiguration defaultSessionConfiguration];
    cfg.timeoutIntervalForRequest = 60.0;
    cfg.timeoutIntervalForResource = 120.0;
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    queue.maxConcurrentOperationCount = 1;
    self.session = [NSURLSession sessionWithConfiguration:cfg delegate:self delegateQueue:queue];
    self.buffer = [NSMutableData data];
    self.authFailed = NO;
    self.finished = NO;

    self.currentTask = [self.session dataTaskWithRequest:req];
    [self.currentTask resume];
    return self.currentTask;
}

- (void)cancel {
    self.finished = YES;
    [self.currentTask cancel];
    self.currentTask = nil;
    [self.session invalidateAndCancel];
    self.session = nil;
}

#pragma mark - NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    NSHTTPURLResponse *http = (NSHTTPURLResponse *)response;
    NSInteger code = http.statusCode;
    NSLog(@"[AIAssistant] stream response status=%ld headers=%@", (long)code, http.allHeaderFields ?: @{});
    if (code == 401 || code == 403) {
        self.authFailed = YES;
        self.finished = YES;
        void (^cb)(void) = self.onAuthFailure;
        dispatch_async(dispatch_get_main_queue(), ^{
            if (cb) cb();
        });
        completionHandler(NSURLSessionResponseCancel);
        return;
    }
    if (code < 200 || code >= 300) {
        [self tl_invokeErrorWithMessage:[NSString stringWithFormat:@"服务端返回异常(%ld)", (long)code]];
        completionHandler(NSURLSessionResponseCancel);
        return;
    }
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data {
    if (self.authFailed || self.finished) return;
    NSString *chunk = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"[AIAssistant] stream raw chunk: %@", chunk ?: [NSString stringWithFormat:@"<non-utf8 %lu bytes>", (unsigned long)data.length]);
    [self.buffer appendData:data];
    [self tl_drainBuffer];
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error {
    if (self.authFailed || self.finished) return;
    if (error && error.code != NSURLErrorCancelled) {
        [self tl_invokeError:error message:nil];
        return;
    }
    self.finished = YES;
}

#pragma mark - SSE 帧解析

- (void)tl_drainBuffer {
    while (YES) {
        NSRange sep = [self tl_frameSeparatorRangeInBuffer:self.buffer];
        if (sep.location == NSNotFound) break;

        NSData *frameData = [self.buffer subdataWithRange:NSMakeRange(0, sep.location)];
        NSUInteger consumed = sep.location + sep.length;
        [self.buffer replaceBytesInRange:NSMakeRange(0, consumed) withBytes:NULL length:0];

        NSString *frame = [[NSString alloc] initWithData:frameData encoding:NSUTF8StringEncoding];
        if (frame.length == 0) continue;
        [self tl_parseFrame:frame];
    }
}

- (NSRange)tl_frameSeparatorRangeInBuffer:(NSData *)buffer {
    NSData *lfLfData = [@"\n\n" dataUsingEncoding:NSUTF8StringEncoding];
    NSData *crLfCrLfData = [@"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding];
    NSRange all = NSMakeRange(0, buffer.length);
    NSRange lfLf = [buffer rangeOfData:lfLfData options:0 range:all];
    NSRange crLfCrLf = [buffer rangeOfData:crLfCrLfData options:0 range:all];
    if (lfLf.location == NSNotFound) return crLfCrLf;
    if (crLfCrLf.location == NSNotFound) return lfLf;
    return (lfLf.location < crLfCrLf.location) ? lfLf : crLfCrLf;
}

- (void)tl_parseFrame:(NSString *)frame {
    NSLog(@"[AIAssistant] stream raw frame: %@", frame);
    NSArray<NSString *> *lines = [frame componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    NSString *eventName = nil;
    NSMutableString *dataJoined = [NSMutableString string];
    for (NSString *raw in lines) {
        if (raw.length == 0) continue;
        if ([raw hasPrefix:@":"]) continue;   // SSE 注释，如 ":close"、":keepalive"
        if ([raw hasPrefix:@"event:"]) {
            NSString *value = [raw substringFromIndex:6];
            eventName = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            continue;
        }
        if ([raw hasPrefix:@"data:"]) {
            NSString *value = [raw substringFromIndex:5];
            if ([value hasPrefix:@" "]) value = [value substringFromIndex:1];
            if (dataJoined.length > 0) [dataJoined appendString:@"\n"];
            [dataJoined appendString:value];
            continue;
        }
        // id:、retry: 等其他字段忽略
    }
    if (eventName.length == 0) return;
    NSLog(@"[AIAssistant] stream event=%@ data=%@", eventName, dataJoined.copy ?: @"");
    [self tl_dispatchEvent:eventName data:dataJoined.copy];
}

- (void)tl_dispatchEvent:(NSString *)eventName data:(NSString *)dataString {
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
            msg = dict[@"message"] ?: dict[@"error"] ?: dict[@"msg"];
        }
        [self tl_invokeError:nil message:msg.length > 0 ? msg : dataString];
        return;
    }
    // "delta" 等不关心的事件直接丢弃（和 plan_delta 重复）
}

#pragma mark - Helpers

- (id)tl_jsonObjectFromString:(NSString *)string {
    if (string.length == 0) return nil;
    NSData *d = [string dataUsingEncoding:NSUTF8StringEncoding];
    if (!d) return nil;
    NSError *err = nil;
    return [NSJSONSerialization JSONObjectWithData:d options:NSJSONReadingAllowFragments error:&err];
}

- (NSString *)tl_deltaTextFromRawData:(NSString *)dataString {
    if (dataString.length == 0) return @"";
    id json = [self tl_jsonObjectFromString:dataString];
    if ([json isKindOfClass:[NSString class]]) return (NSString *)json;
    if ([json isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dict = json;
        NSString *v = dict[@"text"] ?: dict[@"delta"] ?: dict[@"content"];
        if (v.length > 0) return v;
    }
    return dataString;
}

- (NSString *)tl_planFinalFromRawData:(NSString *)dataString {
    if (dataString.length == 0) return @"";
    id json = [self tl_jsonObjectFromString:dataString];
    if ([json isKindOfClass:[NSString class]]) return (NSString *)json;
    if ([json isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dict = json;
        NSString *v = dict[@"controlPlan"] ?:
                      dict[@"text"] ?:
                      dict[@"plan"] ?:
                      dict[@"content"] ?:
                      dict[@"answer"] ?:
                      dict[@"advice"] ?:
                      dict[@"solution"] ?:
                      dict[@"reason"] ?:
                      dict[@"message"];
        if (v.length > 0) return v;

        id nested = dict[@"data"];
        if ([nested isKindOfClass:[NSDictionary class]]) {
            NSDictionary *nestedDict = (NSDictionary *)nested;
            v = nestedDict[@"controlPlan"] ?:
                nestedDict[@"text"] ?:
                nestedDict[@"plan"] ?:
                nestedDict[@"content"] ?:
                nestedDict[@"answer"] ?:
                nestedDict[@"advice"] ?:
                nestedDict[@"solution"] ?:
                nestedDict[@"reason"] ?:
                nestedDict[@"message"];
        }
        if (v.length > 0) return v;
    }
    return dataString;
}

- (void)tl_invokeErrorWithMessage:(NSString *)message {
    [self tl_invokeError:nil message:message];
}

- (void)tl_invokeError:(NSError *)error message:(NSString *)message {
    if (self.finished) return;
    self.finished = YES;
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

@end
