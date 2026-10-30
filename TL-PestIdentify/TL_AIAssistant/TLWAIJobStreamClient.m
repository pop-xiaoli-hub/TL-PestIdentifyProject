#import "TLWAIJobStreamClient.h"
#import "TLWAIEventEnvelope.h"
#import "TLWAITrace.h"
#import <AgriPestClient/AGChatRequest.h>
#import <math.h>

static BOOL TLWAIJobTerminal(NSString *status) {
    return [status isEqual:@"completed"] || [status isEqual:@"failed"] || [status isEqual:@"cancelled"];
}
static NSError *TLWAIJobError(NSInteger code, NSString *message, BOOL resume, BOOL regenerate) {
    return [NSError errorWithDomain:@"TLWAIJobStreamClient" code:code userInfo:@{NSLocalizedDescriptionKey:message,
        @"canResumeJob":@(resume), @"offersRegeneration":@(regenerate)}];
}

@interface TLWAIJobStreamClient () <NSURLSessionTaskDelegate>
@property (nonatomic, copy) NSURL *jobsURL;
@property (nonatomic, assign) BOOL localTest;
@property (nonatomic, copy) TLWAIRecoveryCommit commit;
@property (nonatomic, strong) TLWAIRecoveryState *recovery;
@property (nonatomic, strong) NSURLSession *JSONSession;
@property (nonatomic, strong) NSURLSessionDataTask *JSONTask;
@property (nonatomic, strong) TLWAIStreamClient *subscriber;
@property (nonatomic, strong) NSURLSessionDataTask *subscriptionTask;
@property (nonatomic, copy) NSString *accessToken;
@property (nonatomic, assign) BOOL stopped;
@property (nonatomic, assign) BOOL recovering;
@property (nonatomic, assign) BOOL needsSnapshot;
@property (nonatomic, assign) BOOL waitingForPath;
@property (nonatomic, assign) BOOL silenceScheduled;
@property (nonatomic, assign) BOOL mayCreateInActivation;
@property (nonatomic, assign) BOOL jsonCreation;
@property (nonatomic, assign) NSUInteger connectionGeneration;
@property (nonatomic, assign) NSUInteger recoveryTicket;
@property (nonatomic, assign) NSUInteger lifetime;
@property (nonatomic, assign) NSUInteger recoveryAttempts;
@property (nonatomic, assign) NSTimeInterval recoveryStartedAt;
@property (nonatomic, assign) NSTimeInterval lastActivity;
@end

@implementation TLWAIJobStreamClient
- (instancetype)initWithJobsURL:(NSURL *)url localTest:(BOOL)localTest checkpoint:(NSDictionary *)checkpoint commit:(TLWAIRecoveryCommit)commit {
    if ((self = [super init])) {
        _jobsURL = url.copy; _localTest = localTest; _commit = [commit copy];
        _recovery = [[TLWAIRecoveryState alloc] initWithCheckpoint:checkpoint];
        _networkAvailable = YES;
    }
    return self;
}
- (BOOL)supportsJobRecovery { return YES; }
- (BOOL)acceptsGeneration:(NSUInteger)generation { return !self.stopped && self.connectionGeneration == generation; }
- (void)setRecovering:(BOOL)recovering {
    if (_recovering == recovering) return;
    _recovering = recovering;
    if (self.onRecoveryStateChanged) self.onRecoveryStateChanged(recovering);
}
- (void)setNetworkAvailable:(BOOL)available {
    _networkAvailable = available;
    if (available && self.waitingForPath && !self.stopped) {
        self.waitingForPath = NO;
        [self performRecoveryForTicket:self.recoveryTicket generation:self.connectionGeneration];
    }
}
- (NSURL *)jobResource:(NSString *)resource {
    NSString *job = self.recovery.checkpoint[@"jobId"];
    NSCharacterSet *invalid = [[NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_"] invertedSet];
    if (![job isKindOfClass:NSString.class] || !job.length || [job rangeOfCharacterFromSet:invalid].location != NSNotFound) return nil;
    NSURL *url = [self.jobsURL URLByAppendingPathComponent:job];
    return resource.length ? [url URLByAppendingPathComponent:resource] : url;
}
- (NSURLSessionConfiguration *)JSONConfiguration {
    NSURLSessionConfiguration *configuration = NSURLSessionConfiguration.ephemeralSessionConfiguration;
    configuration.HTTPCookieStorage = nil; configuration.HTTPShouldSetCookies = NO; configuration.URLCredentialStorage = nil;
    configuration.timeoutIntervalForRequest = 30; configuration.timeoutIntervalForResource = 30;
    return configuration;
}
- (NSMutableURLRequest *)requestForURL:(NSURL *)url method:(NSString *)method body:(NSDictionary *)body error:(NSError **)error {
    if (!url) {
        if (error) *error = TLWAIJobError(1, @"任务接口地址无效", NO, NO);
        return nil;
    }
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = method; request.timeoutInterval = 30; request.HTTPShouldHandleCookies = NO;
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    if (body) {
        request.HTTPBody = [NSJSONSerialization dataWithJSONObject:body options:0 error:error];
        if (!request.HTTPBody) return nil;
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    }
    if (!self.localTest && self.accessToken.length)
        [request setValue:[@"Bearer " stringByAppendingString:self.accessToken] forHTTPHeaderField:@"Authorization"];
    return request;
}
- (NSURLSessionDataTask *)streamChatWithRequest:(AGChatRequest *)chatRequest accessToken:(NSString *)accessToken {
    NSAssert(NSThread.isMainThread, @"Job client is main-queue owned");
    self.accessToken = accessToken ?: @"";
    self.stopped = NO; self.lifetime++; self.connectionGeneration++;
    NSString *scheme = self.jobsURL.scheme.lowercaseString;
    if (!self.recovery || !self.jobsURL.host.length || self.jobsURL.user || self.jobsURL.password || self.jobsURL.query || self.jobsURL.fragment ||
        ![self.jobsURL.path isEqual:@"/api/v1/agent/jobs"] ||
        (![scheme isEqual:@"https"] && !(self.localTest && [scheme isEqual:@"http"]))) {
        [self fail:TLWAIJobError(1, @"任务协议配置或检查点无效，未调用旧接口", NO, NO)];
        return nil;
    }
    NSString *endpoint = self.recovery.checkpoint[@"endpoint"];
    if ((endpoint && ![endpoint isEqual:self.jobsURL.absoluteString]) ||
        (self.clientRequestId.length && ![self.clientRequestId isEqual:self.recovery.checkpoint[@"clientRequestId"]])) {
        [self fail:TLWAIJobError(2, @"任务所属服务或客户端身份已变化，拒绝跨环境续传", NO, YES)];
        return nil;
    }
    NSMutableDictionary *body = [NSMutableDictionary dictionary];
    if (chatRequest.text.length) body[@"text"] = chatRequest.text;
    if (chatRequest.imageUrl.length) body[@"imageUrl"] = chatRequest.imageUrl;
    if (chatRequest.useSingleModel) body[@"useSingleModel"] = chatRequest.useSingleModel;
    if (chatRequest.saveHistory) body[@"saveHistory"] = chatRequest.saveHistory;
    if (chatRequest.extraInfo.length) body[@"extraInfo"] = chatRequest.extraInfo;
    NSDictionary *savedRequest = self.recovery.checkpoint[@"request"];
    if (savedRequest.count && ![body isEqual:savedRequest]) {
        [self fail:TLWAIJobError(409, @"同一任务的输入已变化，拒绝重复创建", NO, NO)];
        return nil;
    }
    self.mayCreateInActivation = NO;
    BOOL hasJob = [self.recovery.checkpoint[@"jobId"] length] > 0;
    if (!hasJob && TLWAIJobFlag(self.recovery.checkpoint, @"creationSent") && !endpoint.length) {
        [self fail:TLWAIJobError(2, @"无法确认任务所属服务，请重新生成", NO, YES)];
        return nil;
    }
    if (!hasJob && TLWAIJobMaySilentlyCreate(self.recovery.checkpoint)) {
        NSMutableDictionary *initial = [self.recovery.checkpoint mutableCopy];
        initial[@"request"] = savedRequest.count ? savedRequest : body.copy;
        initial[@"endpoint"] = self.jobsURL.absoluteString;
        initial[@"creationSent"] = @YES;
        initial[@"creationRejected"] = @NO;
        if (!self.commit(initial)) { [self fail:TLWAIJobError(3, @"创建请求未可靠保存，未发送任务", YES, NO)]; return nil; }
        self.recovery = [[TLWAIRecoveryState alloc] initWithCheckpoint:initial];
        self.mayCreateInActivation = YES;
    }
    self.lastActivity = NSProcessInfo.processInfo.systemUptime;
    if (self.onRestoreCheckpoint) self.onRestoreCheckpoint(self.recovery.checkpoint);
    if ([self publishTerminalIfNeeded]) return nil;
    self.JSONSession = [NSURLSession sessionWithConfiguration:[self JSONConfiguration] delegate:self delegateQueue:nil];
    [self scheduleSilenceWatch];
    if (hasJob) [self subscribe];
    else if (self.mayCreateInActivation) [self createJob];
    else [self lookupExistingJob];
    return self.JSONTask ?: self.subscriptionTask;
}
- (void)noteActivity {
    self.lastActivity = NSProcessInfo.processInfo.systemUptime;
    if (self.onActivity) self.onActivity();
}
- (void)scheduleSilenceWatch {
    if (self.silenceScheduled || self.stopped) return;
    self.silenceScheduled = YES;
    NSUInteger lifetime = self.lifetime;
    NSTimeInterval delay = MAX(0, 30 - (NSProcessInfo.processInfo.systemUptime - self.lastActivity));
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        typeof(self) owner = weakSelf;
        if (!owner || owner.stopped || owner.lifetime != lifetime) return;
        owner.silenceScheduled = NO;
        if (owner.recovering) return;
        if (NSProcessInfo.processInfo.systemUptime - owner.lastActivity < 30) [owner scheduleSilenceWatch];
        else [owner recover:TLWAIJobError(30, @"任务流持续静默，恢复原任务", YES, NO) snapshot:NO retryAfter:0];
    });
}
- (void)requestJSON:(NSURL *)url method:(NSString *)method body:(NSDictionary *)body creation:(BOOL)creation
        completion:(void (^)(NSDictionary *value))completion {
    NSError *error = nil;
    NSMutableURLRequest *request = [self requestForURL:url method:method body:body error:&error];
    if (!request) { [self fail:error]; return; }
    self.jsonCreation = creation;
    if (creation) [request setValue:self.recovery.checkpoint[@"clientRequestId"] forHTTPHeaderField:@"Idempotency-Key"];
    NSUInteger generation = self.connectionGeneration;
    __weak typeof(self) weakSelf = self;
    self.JSONTask = [self.JSONSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *failure) {
        dispatch_async(dispatch_get_main_queue(), ^{
            typeof(self) owner = weakSelf;
            if (![owner acceptsGeneration:generation]) return;
            owner.JSONTask = nil;
            if (failure) { [owner handleTransportError:failure snapshot:NO]; return; }
            [owner noteActivity];
            NSHTTPURLResponse *http = [response isKindOfClass:NSHTTPURLResponse.class] ? (id)response : nil;
            id value = data.length > 0 && data.length <= 4 * 1024 * 1024 ? [NSJSONSerialization JSONObjectWithData:data options:0 error:nil] : nil;
            NSDictionary *object = [value isKindOfClass:NSDictionary.class] ? value : nil;
            NSInteger code = [object[@"code"] respondsToSelector:@selector(integerValue)] ? [object[@"code"] integerValue] : 0;
            if (http.statusCode == 401 || code == 401 || code == 4006) { [owner requireAuth]; return; }
            NSInteger status = http.statusCode;
            if (status < 200 || status >= 300) {
                NSString *message = [object[@"message"] isKindOfClass:NSString.class] ? object[@"message"] : [NSString stringWithFormat:@"任务接口返回 %ld", (long)status];
                if (status == 429 || status == 502 || status == 503 || status == 504) {
                    [owner recover:TLWAIJobError(status, message, YES, NO) snapshot:NO retryAfter:[owner retryAfter:[http valueForHTTPHeaderField:@"Retry-After"]]];
                } else if ((status == 404 || status == 410) && ![owner.recovery.checkpoint[@"jobId"] length]) {
                    [owner uncertainCreation];
                } else if (status == 404 || status == 410) {
                    [owner expireJob];
                } else [owner fail:TLWAIJobError(status, message, NO, NO)];
                return;
            }
            if (!object || ![http.MIMEType.lowercaseString isEqual:@"application/json"]) {
                [owner fail:TLWAIJobError(2, @"任务接口没有返回有效 JSON", NO, NO)]; return;
            }
            completion(object);
        });
    }];
    [self.JSONTask resume];
}
- (void)createJob {
    __weak typeof(self) weakSelf = self;
    [self requestJSON:self.jobsURL method:@"POST" body:self.recovery.checkpoint[@"request"] creation:YES completion:^(NSDictionary *value) {
        typeof(self) owner = weakSelf;
        NSError *error = nil;
        if (![owner.recovery bindCreatedJob:value commit:owner.commit error:&error]) { [owner fail:error]; return; }
        [owner subscribe];
    }];
}
- (NSURL *)lookupURL {
    NSString *clientID = self.recovery.checkpoint[@"clientRequestId"];
    NSCharacterSet *invalid = [[NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_"] invertedSet];
    if (![clientID isKindOfClass:NSString.class] || !clientID.length || clientID.length > 128 ||
        [clientID rangeOfCharacterFromSet:invalid].location != NSNotFound) return nil;
    return [[self.jobsURL URLByAppendingPathComponent:@"by-client-request"] URLByAppendingPathComponent:clientID];
}
- (void)lookupExistingJob {
    NSURL *url = [self lookupURL];
    if (!url) { [self fail:TLWAIJobError(2, @"客户端请求标识无效，无法查询原任务", NO, YES)]; return; }
    __weak typeof(self) weakSelf = self;
    [self requestJSON:url method:@"GET" body:nil creation:NO completion:^(NSDictionary *value) {
        typeof(self) owner = weakSelf;
        NSError *error = nil;
        if (![owner.recovery bindCreatedJob:value commit:owner.commit error:&error]) { [owner fail:error]; return; }
        if (owner.onRestoreCheckpoint) owner.onRestoreCheckpoint(owner.recovery.checkpoint);
        if (![owner publishTerminalIfNeeded]) [owner subscribe];
    }];
}
- (void)uncertainCreation {
    NSMutableDictionary *record = [self.recovery.checkpoint mutableCopy];
    record[@"status"] = @"failed";
    record[@"offersRegeneration"] = @YES;
    record[@"errorMessage"] = @"无法确认原任务是否已创建，请重新生成";
    if (self.commit(record)) self.recovery = [[TLWAIRecoveryState alloc] initWithCheckpoint:record];
    [self fail:TLWAIJobError(404, record[@"errorMessage"], NO, YES)];
}
- (void)subscribe {
    self.jsonCreation = NO;
    NSURL *url = [self jobResource:@"events"];
    if (!url) { [self fail:TLWAIJobError(2, @"服务端任务标识无效", NO, NO)]; return; }
    self.lastActivity = NSProcessInfo.processInfo.systemUptime;
    [self scheduleSilenceWatch];
    NSUInteger generation = self.connectionGeneration;
    TLWAIStreamClient *subscriber = [TLWAIStreamClient new];
    self.subscriber = subscriber;
    subscriber.trace = self.trace;
    __weak typeof(self) weakSelf = self;
    subscriber.onActivity = ^{ typeof(self) owner = weakSelf; if ([owner acceptsGeneration:generation]) [owner noteActivity]; };
    subscriber.onHeartbeat = ^(NSString *comment) {
        typeof(self) owner = weakSelf;
        if (![owner acceptsGeneration:generation]) return;
        [owner noteActivity]; owner.recovering = NO;
        if (owner.onHeartbeat) owner.onHeartbeat(comment);
    };
    subscriber.onEventEnvelope = ^(TLWAIEventEnvelope *envelope) {
        typeof(self) owner = weakSelf;
        if (![owner acceptsGeneration:generation]) return;
        NSError *error = nil;
        TLWAIRecoveryApplyResult result = [owner.recovery applyEnvelope:envelope commit:owner.commit error:&error];
        if (result == TLWAIRecoveryApplyResultDuplicate) return;
        if (result == TLWAIRecoveryApplyResultGap) { [owner recover:TLWAIJobError(2, @"事件出现缺口，读取一致快照", YES, NO) snapshot:YES retryAfter:0]; return; }
        if (result != TLWAIRecoveryApplyResultAccepted) { [owner fail:error]; return; }
        owner.recovering = NO;
        if (owner.onMetadata) owner.onMetadata(owner.recovery.checkpoint[@"cursor"], nil);
        [owner publishEnvelope:envelope];
    };
    subscriber.onError = ^(NSError *error, NSString *message) { typeof(self) owner = weakSelf; if ([owner acceptsGeneration:generation]) [owner handleTransportError:error snapshot:YES]; };
    subscriber.onIncompleteEOF = ^(NSUInteger bytes) {
        typeof(self) owner = weakSelf;
        if ([owner acceptsGeneration:generation]) [owner recover:TLWAIJobError(10, @"连接中断，继续接收同一任务", YES, NO) snapshot:NO retryAfter:0];
    };
    subscriber.onAuthFailure = ^{ typeof(self) owner = weakSelf; if ([owner acceptsGeneration:generation]) [owner requireAuth]; };
    self.subscriptionTask = [subscriber subscribeToEventsAtURL:url lastEventID:self.recovery.checkpoint[@"cursor"] accessToken:self.accessToken localTest:self.localTest];
}
- (void)publishEnvelope:(TLWAIEventEnvelope *)envelope {
    NSDictionary *payload = envelope.payload[@"payload"];
    NSString *name = envelope.eventName;
    if ([name isEqual:@"meta"] && self.onMeta) self.onMeta(payload);
    else if ([name isEqual:@"disease"] && self.onDiseaseList) self.onDiseaseList(payload[@"diseases"]);
    else if ([name isEqual:@"plan_delta"] && self.onPlanDelta) { [self.trace mark:TLWAITraceStageModelDelta count:[payload[@"text"] length]]; self.onPlanDelta(payload[@"text"]); }
    else if ([name isEqual:@"plan"] && self.onPlanFinal) self.onPlanFinal(payload[@"controlPlan"]);
    else if (![name isEqual:@"done"] && ![name isEqual:@"error"] && self.onUnknownEvent)
        self.onUnknownEvent([[TLWAIEventEnvelope alloc] initWithEventName:name eventID:envelope.eventID payload:payload]);
    if (!self.stopped) [self publishTerminalIfNeeded];
}
- (BOOL)publishTerminalIfNeeded {
    NSDictionary *record = self.recovery.checkpoint;
    if (!TLWAIJobTerminal(record[@"status"])) return NO;
    NSString *status = record[@"status"];
    [self cancel];
    if ([status isEqual:@"completed"]) { if (self.onDone) self.onDone(record[@"completionInfo"]); }
    else if ([status isEqual:@"cancelled"]) { if (self.onServerCancelled) self.onServerCancelled(); }
    else if (self.onError) self.onError(TLWAIJobError(20, record[@"errorMessage"], NO, NO), record[@"errorMessage"]);
    return YES;
}
- (void)fetchSnapshot {
    __weak typeof(self) weakSelf = self;
    [self requestJSON:[self jobResource:@""] method:@"GET" body:nil creation:NO completion:^(NSDictionary *value) {
        typeof(self) owner = weakSelf;
        NSError *error = nil;
        if (![owner.recovery applySnapshot:value commit:owner.commit error:&error]) { [owner fail:error]; return; }
        if (owner.onRestoreCheckpoint) owner.onRestoreCheckpoint(owner.recovery.checkpoint);
        if (![owner publishTerminalIfNeeded]) { owner.needsSnapshot = NO; [owner subscribe]; }
    }];
}
- (NSTimeInterval)retryAfter:(NSString *)value {
    if (!value.length) return 0;
    NSScanner *scanner = [NSScanner scannerWithString:value]; double seconds = 0;
    if ([scanner scanDouble:&seconds] && scanner.isAtEnd && isfinite(seconds)) return MAX(0, seconds);
    static NSDateFormatter *formatter; static dispatch_once_t once;
    dispatch_once(&once, ^{ formatter = [NSDateFormatter new]; formatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"]; formatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0]; formatter.dateFormat = @"EEE, dd MMM yyyy HH:mm:ss zzz"; });
    return MAX(0, [[formatter dateFromString:value] timeIntervalSinceNow]);
}
- (void)handleTransportError:(NSError *)error snapshot:(BOOL)allowSnapshot {
    NSInteger status = [error.userInfo[@"httpStatus"] integerValue];
    if (allowSnapshot && status == 410) { [self recover:error snapshot:YES retryAfter:0]; return; }
    if (status == 404 || status == 410) { [self expireJob]; return; }
    BOOL transient = [error.domain isEqual:NSURLErrorDomain] &&
        (error.code == NSURLErrorNetworkConnectionLost || error.code == NSURLErrorNotConnectedToInternet || error.code == NSURLErrorTimedOut || error.code == NSURLErrorCannotConnectToHost || error.code == NSURLErrorCannotFindHost);
    if (transient || status == 429 || status == 502 || status == 503 || status == 504)
        [self recover:error snapshot:NO retryAfter:[self retryAfter:error.userInfo[@"retryAfter"]]];
    else [self fail:error];
}
- (void)recover:(NSError *)error snapshot:(BOOL)snapshot retryAfter:(NSTimeInterval)retryAfter {
    if (self.stopped) return;
    self.connectionGeneration++; self.recoveryTicket++;
    [self.subscriber cancel]; self.subscriber = nil;
    [self.JSONTask cancel]; self.JSONTask = nil;
    self.needsSnapshot |= snapshot;
    self.recovering = YES;
    if (self.stopped) return;
    NSTimeInterval now = NSProcessInfo.processInfo.systemUptime;
    if (!self.recoveryStartedAt) {
        self.recoveryStartedAt = now;
        NSUInteger lifetime = self.lifetime;
        __weak typeof(self) weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 60 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            typeof(self) owner = weakSelf;
            if (owner && !owner.stopped && owner.lifetime == lifetime && owner.recovering)
                [owner fail:TLWAIJobError(60, @"恢复等待已超时，可继续接收原任务", YES, NO)];
        });
    }
    NSTimeInterval remaining = 60 - (now - self.recoveryStartedAt);
    if (self.recoveryAttempts >= 3 || remaining <= 0) {
        [self fail:TLWAIJobError(60, @"自动恢复已达上限，可继续接收原任务", YES, NO)]; return;
    }
    double randomUnit = (double)arc4random_uniform(1000000) / 1000000.0;
    NSTimeInterval delay = MAX(retryAfter, (1u << self.recoveryAttempts) * randomUnit);
    if (delay > remaining) { [self fail:TLWAIJobError(60, @"服务端要求稍后重试，已保留原任务", YES, NO)]; return; }
    NSUInteger ticket = self.recoveryTicket, generation = self.connectionGeneration;
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [weakSelf performRecoveryForTicket:ticket generation:generation];
    });
}
- (void)performRecoveryForTicket:(NSUInteger)ticket generation:(NSUInteger)generation {
    if (![self acceptsGeneration:generation] || ticket != self.recoveryTicket) return;
    if (NSProcessInfo.processInfo.systemUptime - self.recoveryStartedAt >= 60 || self.recoveryAttempts >= 3) {
        [self fail:TLWAIJobError(60, @"恢复等待已达上限，可继续接收原任务", YES, NO)]; return;
    }
    if (!self.networkAvailable) { self.waitingForPath = YES; return; }
    self.waitingForPath = NO; self.recoveryAttempts++;
    self.lastActivity = NSProcessInfo.processInfo.systemUptime;
    if (self.needsSnapshot && [self.recovery.checkpoint[@"jobId"] length]) [self fetchSnapshot];
    else if ([self.recovery.checkpoint[@"jobId"] length]) [self subscribe];
    else if (self.mayCreateInActivation) [self createJob];
    else [self lookupExistingJob];
}
- (void)requireAuth {
    if (self.jsonCreation && ![self.recovery.checkpoint[@"jobId"] length]) {
        NSMutableDictionary *record = [self.recovery.checkpoint mutableCopy];
        record[@"creationRejected"] = @YES;
        if (self.commit(record)) self.recovery = [[TLWAIRecoveryState alloc] initWithCheckpoint:record];
    }
    self.jsonCreation = NO;
    [self cancel];
    if (self.onAuthFailure) self.onAuthFailure();
}
- (void)expireJob {
    NSMutableDictionary *record = [self.recovery.checkpoint mutableCopy];
    record[@"status"] = @"failed"; record[@"offersRegeneration"] = @YES; record[@"errorMessage"] = @"原任务已过期，无法续传，请重新生成";
    if (self.commit(record)) self.recovery = [[TLWAIRecoveryState alloc] initWithCheckpoint:record];
    [self fail:TLWAIJobError(404, @"原任务已过期，无法续传，请重新生成", NO, YES)];
}
- (void)fail:(NSError *)error {
    if (self.stopped) return;
    if ([error.domain isEqual:@"TLWAIRecoveryState"] && error.code == 3)
        error = TLWAIJobError(3, error.localizedDescription, YES, NO);
    [self cancel];
    if (self.onError) self.onError(error ?: TLWAIJobError(2, @"任务恢复协议异常", NO, NO), error.localizedDescription);
}
- (void)cancel {
    self.stopped = YES; self.connectionGeneration++; self.recoveryTicket++; self.lifetime++;
    self.waitingForPath = NO; self.silenceScheduled = NO;
    [self.subscriber cancel]; self.subscriber = nil;
    self.subscriptionTask = nil;
    [self.JSONTask cancel]; self.JSONTask = nil;
    [self.JSONSession invalidateAndCancel]; self.JSONSession = nil;
}
- (BOOL)cancelJob {
    if (TLWAIJobTerminal(self.recovery.checkpoint[@"status"])) { [self cancel]; return YES; }
    NSURL *url = [self.recovery.checkpoint[@"jobId"] length] ? [self jobResource:@"cancel"] : [self.jobsURL URLByAppendingPathComponent:@"cancel"];
    NSDictionary *body = [self.recovery.checkpoint[@"jobId"] length] ? nil : @{@"clientRequestId":self.recovery.checkpoint[@"clientRequestId"] ?: @""};
    NSMutableDictionary *record = [self.recovery.checkpoint mutableCopy]; record[@"status"] = @"cancelled";
    BOOL saved = self.commit(record);
    if (saved) self.recovery = [[TLWAIRecoveryState alloc] initWithCheckpoint:record];
    NSError *error = nil;
    NSMutableURLRequest *request = [self requestForURL:url method:@"POST" body:body error:&error];
    [self cancel];
    if (request) {
        NSURLSession *session = [NSURLSession sessionWithConfiguration:[self JSONConfiguration] delegate:self delegateQueue:nil];
        [[session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *failure) {
            [session finishTasksAndInvalidate]; // best effort；不在已终态后刷新鉴权或修改 UI。
        }] resume];
    }
    return saved;
}
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response
        newRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURLRequest *))completionHandler { completionHandler(nil); }
- (void)dealloc { [self.subscriber cancel]; [self.JSONSession invalidateAndCancel]; }
@end
