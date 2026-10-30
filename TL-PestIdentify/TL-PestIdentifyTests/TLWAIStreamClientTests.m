#import <XCTest/XCTest.h>
#import "../TL_AIAssistant/TLWAIStreamClient.h"
#import "../TL_AIAssistant/TLWAISSEParser.h"
#import "TLWAIEventEnvelope.h"
#import "TLWAIAssistantMessage.h"
#import "TLWAIAssistantMessageCell.h"
#import "../Pods/Headers/Public/AgriPestClient/AGDefaultConfiguration.h"

@interface TLWAIStreamClient (DelegateTests) <NSURLSessionDataDelegate>
- (void)tl_bindParser;
@end

@interface TLWAIStreamClientTests : XCTestCase
@end
@implementation TLWAIStreamClientTests

- (TLWAIStreamClient *)fixtureClient {
    TLWAIStreamClient *client = [TLWAIStreamClient new];
    [client setValue:[TLWAISSEParser new] forKey:@"parser"];
    [client setValue:[NSMutableData data] forKey:@"buffer"];
    [client setValue:@200 forKey:@"responseStatusCode"];
    [client tl_bindParser];
    return client;
}

#if DEBUG
- (void)testDebugEndpointReplacesOnlyStreamRouteAndNeverForwardsCredentials {
    AGDefaultConfiguration *config = AGDefaultConfiguration.sharedConfig;
    NSString *previousHost = config.host;
    NSString *previousEnvironment = getenv("TLW_AI_STREAM_TEST_URL") ? @(getenv("TLW_AI_STREAM_TEST_URL")) : nil;
    setenv("TLW_AI_STREAM_TEST_URL", "http://127.0.0.1:8765/api/v1/agent/chat/stream", 1);
    config.host = @"https://fixture.invalid";
    TLWAIStreamClient *client = [TLWAIStreamClient new];
    id request = [NSClassFromString(@"AGChatRequest") new];
    [request setValue:@"arbitrary text" forKey:@"text"];
    @try {
        NSURLSessionDataTask *task = [client streamChatWithRequest:request accessToken:@"fixture-token"];
        XCTAssertEqualObjects(task.originalRequest.URL.host, @"127.0.0.1");
        XCTAssertEqualObjects(task.originalRequest.URL.port, @8765);
        XCTAssertNil([task.originalRequest valueForHTTPHeaderField:@"Authorization"]);
        XCTAssertNil([task.originalRequest valueForHTTPHeaderField:@"Cookie"]);
        XCTAssertFalse(task.originalRequest.HTTPShouldHandleCookies);
        XCTAssertEqualObjects(config.host, @"https://fixture.invalid");
    } @finally {
        [client cancel];
        config.host = previousHost;
        if (previousEnvironment) setenv("TLW_AI_STREAM_TEST_URL", previousEnvironment.UTF8String, 1);
        else unsetenv("TLW_AI_STREAM_TEST_URL");
    }
}

- (void)testInvalidDebugEndpointFailsLocallyInsteadOfCallingNormalBackend {
    AGDefaultConfiguration *config = AGDefaultConfiguration.sharedConfig;
    NSString *previousHost = config.host;
    NSString *previousEnvironment = getenv("TLW_AI_STREAM_TEST_URL") ? @(getenv("TLW_AI_STREAM_TEST_URL")) : nil;
    setenv("TLW_AI_STREAM_TEST_URL", "not-a-valid-endpoint", 1);
    config.host = @"https://fixture.invalid";
    TLWAIStreamClient *client = [TLWAIStreamClient new];
    XCTestExpectation *end = [self expectationWithDescription:@"invalid local URL rejected"];
    client.onError = ^(NSError *error, NSString *message) { [end fulfill]; };
    client.onDone = ^(NSDictionary *info) { XCTFail(@"invalid test URL must not call the normal backend"); [end fulfill]; };
    @try {
        id request = [NSClassFromString(@"AGChatRequest") new];
        [request setValue:@"do not send" forKey:@"text"];
        XCTAssertNil([client streamChatWithRequest:request accessToken:@"fixture-token"]);
        [self waitForExpectations:@[end] timeout:3];
    } @finally {
        [client cancel];
        config.host = previousHost;
        if (previousEnvironment) setenv("TLW_AI_STREAM_TEST_URL", previousEnvironment.UTF8String, 1);
        else unsetenv("TLW_AI_STREAM_TEST_URL");
    }
}
#endif

- (void)testEOFDiscardsUnclosedFrameAndPreservesClosedSuffix {
    TLWAIStreamClient *client = [self fixtureClient];
    NSMutableString *body = [NSMutableString string];
    XCTestExpectation *end = [self expectationWithDescription:@"incomplete"];
    client.onPlanDelta = ^(NSString *text) { [body appendString:text]; };
    client.onDone = ^(NSDictionary *info) { XCTFail(@"EOF without done is not completion"); };
    client.onIncompleteEOF = ^(NSUInteger bytes) {
        XCTAssertGreaterThan(bytes, 0u);
        XCTAssertEqualObjects(body, @"保留后缀");
        [end fulfill];
    };
    [client URLSession:nil dataTask:nil didReceiveData:[@"event: plan_delta\ndata: {\"text\":\"保留后缀\"}\n\nevent: done\ndata: {" dataUsingEncoding:NSUTF8StringEncoding]];
    [client URLSession:nil task:nil didCompleteWithError:nil];
    [self waitForExpectations:@[end] timeout:1];
}

- (void)testTimeoutIsFailureNotAuthRetryOrIncomplete {
    TLWAIStreamClient *client = [self fixtureClient];
    NSMutableString *body = [NSMutableString string];
    XCTestExpectation *failure = [self expectationWithDescription:@"timeout"];
    client.onPlanDelta = ^(NSString *text) { [body appendString:text]; };
    client.onAuthFailure = ^{ XCTFail(@"network failure must not refresh auth"); };
    client.onIncompleteEOF = ^(NSUInteger bytes) { XCTFail(@"timeout is not successful EOF"); };
    client.onError = ^(NSError *error, NSString *message) {
        XCTAssertEqual(error.code, NSURLErrorTimedOut);
        XCTAssertEqualObjects(body, @"完整帧尾部");
        [failure fulfill];
    };
    [client URLSession:nil dataTask:nil didReceiveData:[@"event: plan_delta\ndata: 完整帧尾部\n\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [client URLSession:nil task:nil didCompleteWithError:[NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorTimedOut userInfo:nil]];
    [self waitForExpectations:@[failure] timeout:1];
}

- (void)testPlainTextStreamErrorPreservesServerReasonAndParsedBody {
    TLWAIStreamClient *client = [self fixtureClient];
    NSMutableString *body = [NSMutableString string];
    XCTestExpectation *failure = [self expectationWithDescription:@"server error preserved"];
    client.onPlanDelta = ^(NSString *text) { [body appendString:text]; };
    client.onDone = ^(NSDictionary *info) { XCTFail(@"an error frame is not completion"); };
    client.onError = ^(NSError *error, NSString *message) {
        XCTAssertEqualObjects(body, @"已收到的正文");
        XCTAssertEqualObjects(message, @"HTTP 400 ");
        XCTAssertEqualObjects(error.localizedDescription, @"HTTP 400 ");
        [failure fulfill];
    };
    [client URLSession:nil dataTask:nil didReceiveData:
        [@"event:plan_delta\ndata:已收到的正文\n\nevent:error\ndata:HTTP 400 \n\n"
            dataUsingEncoding:NSUTF8StringEncoding]];
    [self waitForExpectations:@[failure] timeout:1];
}

- (void)testObjectFieldsNeverBecomeRawJSONOrReceiveStringSelectors {
    TLWAIStreamClient *client = [self fixtureClient];
    XCTestExpectation *done = [self expectationWithDescription:@"typed payload"];
    __block NSString *body = @"";
    client.onPlanDelta = ^(NSString *text) { XCTFail(@"object is not text"); };
    client.onPlanFinal = ^(NSString *text) { body = text; };
    client.onDone = ^(NSDictionary *info) { XCTAssertEqualObjects(body, @"安全快照"); [done fulfill]; };
    [client URLSession:nil dataTask:nil didReceiveData:[@"event: plan_delta\ndata: {\"text\":{\"bad\":1}}\n\nevent: plan\ndata: {\"controlPlan\":{\"bad\":1},\"text\":\"安全快照\"}\n\nevent: done\ndata: {}\n\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [self waitForExpectations:@[done] timeout:1];
}
- (void)testHTMLSuccessResponseFailsWithoutDisplayingBody {
    TLWAIStreamClient *client = [TLWAIStreamClient new];
    XCTestExpectation *failure = [self expectationWithDescription:@"HTML rejected"];
    client.onError = ^(NSError *error, NSString *message) { [failure fulfill]; };
    client.onPlanDelta = ^(NSString *text) { XCTFail(@"HTML must not become answer"); };
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@"https://fixture.invalid/"] statusCode:200 HTTPVersion:@"HTTP/1.1" headerFields:@{@"Content-Type":@"text/html"}];
    [client URLSession:nil dataTask:nil didReceiveResponse:response completionHandler:^(NSURLSessionResponseDisposition disposition) {
        XCTAssertEqual(disposition, NSURLSessionResponseCancel);
    }];
    [self waitForExpectations:@[failure] timeout:1];
}

- (void)testCancelSuppressesLateDeltaAndAuthFailure {
    TLWAIStreamClient *client = [TLWAIStreamClient new];
    [client setValue:[TLWAISSEParser new] forKey:@"parser"];
    [client tl_bindParser];
    [client setValue:@200 forKey:@"responseStatusCode"];
    __block BOOL callback = NO;
    client.onPlanDelta = ^(NSString *text) { callback = YES; };
    client.onAuthFailure = ^{ callback = YES; };
    client.onError = ^(NSError *error, NSString *text) { callback = YES; };
    [client cancel];
    [client URLSession:nil dataTask:nil didReceiveData:[@"event: plan_delta\ndata: late\n\n" dataUsingEncoding:NSUTF8StringEncoding]];
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@"https://fixture.invalid/"] statusCode:401 HTTPVersion:@"HTTP/1.1" headerFields:@{}];
    [client URLSession:nil dataTask:nil didReceiveResponse:response completionHandler:^(NSURLSessionResponseDisposition disposition) {
        XCTAssertEqual(disposition, NSURLSessionResponseCancel);
    }];
    XCTestExpectation *drain = [self expectationWithDescription:@"main queue drained"];
    dispatch_async(dispatch_get_main_queue(), ^{ XCTAssertFalse(callback); [drain fulfill]; });
    [self waitForExpectations:@[drain] timeout:1];
}
- (void)testUnknownEventOnlyDisplaysExplicitStringFallbackAndKeepsRealID {
    TLWAIStreamClient *client = [self fixtureClient];
    TLWAIAssistantMessage *message = [TLWAIAssistantMessage messageWithRole:TLWAIAssistantMessageRoleAssistant text:@""];
    message.status = TLWAIAssistantMessageStatusSending;
    TLWAIAssistantMessageCell *cell = [[TLWAIAssistantMessageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    XCTestExpectation *done = [self expectationWithDescription:@"unknown compatibility"];
    __block NSUInteger count = 0;
    client.onPlanDelta = ^(NSString *text) { XCTFail(@"unknown JSON must not become a plan"); };
    client.onUnknownEvent = ^(TLWAIEventEnvelope *envelope) {
        [message appendSupplementalText:envelope.fallbackText]; [cell configureWithMessage:message];
        XCTAssertEqualObjects(envelope.eventID, @"real-1");
        if (++count == 1) XCTAssertNil([cell valueForKey:@"auxiliaryTextView"]);
    };
    client.onDone = ^(NSDictionary *info) {
        XCTAssertEqual(count, 2u);
        NSString *text = ((UITextView *)[cell valueForKey:@"auxiliaryTextView"]).text;
        XCTAssertEqualObjects(text, @"兼容说明");
        XCTAssertFalse([text containsString:@"secretInternal"]);
        [done fulfill];
    };
    NSString *frames = @"id: real-1\nevent: future_card\ndata: {\"secretInternal\":{\"type\":\"unsupported\"},\"fallbackText\":{}}\n\nevent: future_card\ndata: {\"fallbackText\":\"兼容说明\"}\n\nevent: done\ndata: {}\n\n";
    [client URLSession:nil dataTask:nil didReceiveData:[frames dataUsingEncoding:NSUTF8StringEncoding]];
    [self waitForExpectations:@[done] timeout:1];
}
@end
