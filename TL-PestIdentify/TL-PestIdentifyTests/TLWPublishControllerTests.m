#import <XCTest/XCTest.h>
#import <objc/runtime.h>
#import "TLWPublishController.h"
#import "TLWPublishView.h"
#import "TLWCommunityPost.h"
#import "TLWDBManager.h"

// 与现有 Auth tests 一致：引用宿主 App 已链接的真实 SDK 类型，不引入 Pods 头搜索配置。
@interface TLWSDKManager : NSObject
+ (instancetype)shared;
@end
@interface AGPostCreateRequest : NSObject @end
@interface AGPostResponseDto : NSObject
@property (nonatomic, strong) NSNumber *_id;
@end
@interface AGResultPostResponseDto : NSObject
@property (nonatomic, strong) NSNumber *code;
@property (nonatomic, strong) AGPostResponseDto *data;
@end
@interface AGUserProfileDto : NSObject
@property (nonatomic, copy) NSString *username;
@end
@interface TLWPublishController (PublishTesting)
- (void)tl_confirmPublishTapped;
@end
@interface TLWPublishTransport : NSObject
@property (nonatomic, copy) void (^uploadCompletion)(NSArray<NSString *> *, NSError *);
@property (nonatomic, copy) void (^postCompletion)(AGResultPostResponseDto *, NSError *);
@property (nonatomic, strong) AGPostCreateRequest *request;
@property (nonatomic) NSUInteger uploadRequests;
@property (nonatomic, strong) id sessionManager;
@end
@implementation TLWPublishTransport
- (id)api { return self; }
- (NSURLSessionTask *)uploadImages:(NSArray *)images prefix:(NSString *)prefix completion:(void (^)(NSArray *, NSError *))completion {
    self.uploadRequests++;
    self.uploadCompletion = completion;
    return nil;
}
- (NSURLSessionTask *)createPostWithPostCreateRequest:(AGPostCreateRequest *)request completionHandler:(void (^)(AGResultPostResponseDto *, NSError *))completion {
    self.request = request;
    self.postCompletion = completion;
    return nil;
}
- (BOOL)upsertMyPublishedPostFromDto:(AGPostResponseDto *)dto { return YES; }
@end
@interface TLWPublishSessionFixture : NSObject
@property (nonatomic, strong) AGUserProfileDto *cachedProfile;
@property (nonatomic) NSInteger userId;
@end
@implementation TLWPublishSessionFixture
- (BOOL)shouldAttemptTokenRefreshForCode:(NSNumber *)code error:(NSError *)error { return NO; }
@end

@interface TLWPublishControllerTests : XCTestCase
@property (nonatomic, strong) TLWPublishTransport *transport;
@property (nonatomic, strong) TLWPublishController *controller;
@property (nonatomic, strong) TLWPublishView *publishView;
@property (nonatomic) IMP originalSDK;
@property (nonatomic) IMP originalDB;
@property (nonatomic) IMP stubSDK;
@property (nonatomic) IMP stubDB;
@end
@implementation TLWPublishControllerTests
- (void)setUp {
    [super setUp];
    TLWPublishTransport *transport = [TLWPublishTransport new];
    TLWPublishSessionFixture *session = [TLWPublishSessionFixture new];
    session.cachedProfile = [AGUserProfileDto new];
    session.cachedProfile.username = @"publish-fixture";
    transport.sessionManager = session;
    self.transport = transport;
    Method sdk = class_getClassMethod(TLWSDKManager.class, @selector(shared));
    Method database = class_getClassMethod(TLWDBManager.class, @selector(shared));
    self.originalSDK = method_getImplementation(sdk);
    self.originalDB = method_getImplementation(database);
    self.stubSDK = imp_implementationWithBlock(^id(id receiver) { return transport; });
    self.stubDB = imp_implementationWithBlock(^id(id receiver) { return transport; });
    method_setImplementation(sdk, self.stubSDK);
    method_setImplementation(database, self.stubDB);
    self.controller = [TLWPublishController new];
    [self.controller loadViewIfNeeded];
    self.publishView = [self.controller valueForKey:@"myView"];
    self.publishView.titleTextField.text = @"待确认的帖子";
    self.publishView.contentTextView.text = @"服务端确认前保留这段草稿";
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(8, 8), YES, 1);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    [self.controller setValue:[@[image] mutableCopy] forKey:@"selectedImages"];
    [self.controller setValue:[@[@"番茄"] mutableCopy] forKey:@"selectedCrops"];
}
- (void)tearDown {
    method_setImplementation(class_getClassMethod(TLWSDKManager.class, @selector(shared)), self.originalSDK);
    method_setImplementation(class_getClassMethod(TLWDBManager.class, @selector(shared)), self.originalDB);
    imp_removeBlock(self.stubSDK);
    imp_removeBlock(self.stubDB);
    self.controller = nil;
    [super tearDown];
}
- (void)drainMainQueue {
    XCTestExpectation *drained = [self expectationWithDescription:@"main callbacks drained"];
    dispatch_async(dispatch_get_main_queue(), ^{ [drained fulfill]; });
    [self waitForExpectations:@[drained] timeout:2];
}
- (AGResultPostResponseDto *)responseWithCode:(NSInteger)code identifier:(NSNumber *)identifier {
    AGResultPostResponseDto *response = [AGResultPostResponseDto new];
    response.code = @(code);
    response.data = [AGPostResponseDto new];
    response.data._id = identifier;
    return response;
}
- (void)testOnlyServerAcknowledgementPublishesAConfirmedPost {
    __block TLWCommunityPost *confirmed;
    XCTestExpectation *published = [self expectationWithDescription:@"server-confirmed publication"];
    self.controller.onPublished = ^(TLWCommunityPost *post) { confirmed = post; if (post._id) [published fulfill]; };
    [self.controller tl_confirmPublishTapped];
    XCTAssertNil(confirmed);
    XCTAssertFalse(self.publishView.confirmPublishButton.enabled);
    XCTAssertNotNil(self.transport.uploadCompletion);
    if (!self.transport.uploadCompletion) return;
    self.transport.uploadCompletion(@[@"https://example.org/post.jpg"], nil);
    [self drainMainQueue];
    XCTAssertNil(confirmed);
    XCTAssertNotNil(self.transport.postCompletion);
    if (!self.transport.postCompletion) return;
    self.transport.postCompletion([self responseWithCode:200 identifier:@901], nil);
    [self waitForExpectations:@[published] timeout:2];
    XCTAssertEqualObjects(confirmed._id, @901);
    XCTAssertEqualObjects(confirmed.images, (@[@"https://example.org/post.jpg"]));
    XCTAssertEqualObjects(confirmed.title, @"待确认的帖子");
}
- (void)testUploadFailureKeepsDraftAndAllowsRetry {
    __block BOOL published = NO;
    self.controller.onPublished = ^(TLWCommunityPost *post) { published = YES; };
    [self.controller tl_confirmPublishTapped];
    if (self.transport.uploadCompletion) self.transport.uploadCompletion(nil, [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorTimedOut userInfo:nil]);
    [self drainMainQueue];
    XCTAssertFalse(published);
    XCTAssertTrue(self.publishView.confirmPublishButton.enabled);
    XCTAssertEqualObjects(self.publishView.titleTextField.text, @"待确认的帖子");
    XCTAssertEqualObjects(self.publishView.contentTextView.text, @"服务端确认前保留这段草稿");
    XCTAssertEqual([[self.controller valueForKey:@"selectedImages"] count], 1u);
}
- (void)testBusinessFailureDoesNotReportSuccessOrDiscardDraft {
    __block BOOL published = NO;
    self.controller.onPublished = ^(TLWCommunityPost *post) { published = YES; };
    [self.controller tl_confirmPublishTapped];
    if (self.transport.uploadCompletion) self.transport.uploadCompletion(@[@"https://example.org/post.jpg"], nil);
    [self drainMainQueue];
    if (self.transport.postCompletion) self.transport.postCompletion([self responseWithCode:500 identifier:nil], nil);
    [self drainMainQueue];
    XCTAssertFalse(published);
    XCTAssertTrue(self.publishView.confirmPublishButton.enabled);
    XCTAssertEqualObjects(self.publishView.contentTextView.text, @"服务端确认前保留这段草稿");
}
- (void)testRepeatedTapCannotStartDuplicateUploads {
    [self.controller tl_confirmPublishTapped];
    [self.controller tl_confirmPublishTapped];
    XCTAssertEqual(self.transport.uploadRequests, 1u);
}
@end
