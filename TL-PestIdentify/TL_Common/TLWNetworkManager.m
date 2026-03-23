//
//  TLWNetworkManager.m
//  TL-PestIdentify
//

#import "TLWNetworkManager.h"
#import <AFNetworking/AFNetworking.h>

static NSString * const kBaseURL       = @"http://115.191.67.35:8080";
static NSString * const kTokenKey      = @"TLW_access_token";
static NSString * const kRefreshKey    = @"TLW_refresh_token";
static NSString * const kUserIdKey     = @"TLW_user_id";
static NSString * const kUsernameKey   = @"TLW_username";

@interface TLWNetworkManager ()
@property (nonatomic, strong) AFHTTPSessionManager *manager;
@end

@implementation TLWNetworkManager

+ (instancetype)shared {
    static TLWNetworkManager *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[TLWNetworkManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _manager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:kBaseURL]];
        _manager.requestSerializer  = [AFJSONRequestSerializer serializer];
        _manager.responseSerializer = [AFJSONResponseSerializer serializer];
        [_manager.requestSerializer setTimeoutInterval:15];

        // 从本地恢复登录态
        NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
        _token        = [ud stringForKey:kTokenKey];
        _refreshToken = [ud stringForKey:kRefreshKey];
        _userId       = [ud integerForKey:kUserIdKey];
        _username     = [ud stringForKey:kUsernameKey];
    }
    return self;
}

#pragma mark - Token 管理

- (void)setToken:(NSString *)token {
    _token = [token copy];
    [[NSUserDefaults standardUserDefaults] setObject:token forKey:kTokenKey];
}

- (void)setRefreshToken:(NSString *)refreshToken {
    _refreshToken = [refreshToken copy];
    [[NSUserDefaults standardUserDefaults] setObject:refreshToken forKey:kRefreshKey];
}

- (void)setUserId:(NSInteger)userId {
    _userId = userId;
    [[NSUserDefaults standardUserDefaults] setInteger:userId forKey:kUserIdKey];
}

- (void)setUsername:(NSString *)username {
    _username = [username copy];
    [[NSUserDefaults standardUserDefaults] setObject:username forKey:kUsernameKey];
}

- (BOOL)isLoggedIn {
    return self.token.length > 0;
}

- (void)logout {
    self.token        = nil;
    self.refreshToken = nil;
    self.userId       = 0;
    self.username     = nil;
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kTokenKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kRefreshKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kUserIdKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kUsernameKey];
}

#pragma mark - 请求头

- (void)applyAuthHeader {
    if (self.token.length > 0) {
        [self.manager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", self.token]
                             forHTTPHeaderField:@"Authorization"];
    } else {
        [self.manager.requestSerializer setValue:nil forHTTPHeaderField:@"Authorization"];
    }
}

#pragma mark - 统一响应处理

- (void)handleResponse:(id)responseObject
               success:(TLWNetworkSuccess)success
               failure:(TLWNetworkFailure)failure {
    if (![responseObject isKindOfClass:[NSDictionary class]]) {
        if (success) success(responseObject);
        return;
    }
    NSDictionary *dict = (NSDictionary *)responseObject;
    NSInteger code = [dict[@"code"] integerValue];
    if (code == 200) {
        if (success) success(dict[@"data"]);
    } else {
        NSString *msg = dict[@"message"] ?: @"请求失败";
        if (failure) failure(msg);
    }
}

- (void)handleError:(NSError *)error failure:(TLWNetworkFailure)failure {
    if (!failure) return;
    // 尝试从服务端返回的 JSON 中提取 message
    NSData *errorData = error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey];
    if (errorData) {
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:errorData options:0 error:nil];
        if ([dict isKindOfClass:[NSDictionary class]] && dict[@"message"]) {
            failure(dict[@"message"]);
            return;
        }
    }
    failure(error.localizedDescription ?: @"网络连接失败");
}

#pragma mark - 公开方法

- (void)GET:(NSString *)path
 parameters:(NSDictionary *)parameters
    success:(TLWNetworkSuccess)success
    failure:(TLWNetworkFailure)failure {
    [self applyAuthHeader];
    [self.manager GET:path parameters:parameters headers:nil progress:nil
              success:^(NSURLSessionDataTask *task, id responseObject) {
        [self handleResponse:responseObject success:success failure:failure];
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        [self handleError:error failure:failure];
    }];
}

- (void)POST:(NSString *)path
  parameters:(NSDictionary *)parameters
     success:(TLWNetworkSuccess)success
     failure:(TLWNetworkFailure)failure {
    [self applyAuthHeader];
    [self.manager POST:path parameters:parameters headers:nil progress:nil
               success:^(NSURLSessionDataTask *task, id responseObject) {
        [self handleResponse:responseObject success:success failure:failure];
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        [self handleError:error failure:failure];
    }];
}

- (void)PUT:(NSString *)path
 parameters:(NSDictionary *)parameters
    success:(TLWNetworkSuccess)success
    failure:(TLWNetworkFailure)failure {
    [self applyAuthHeader];
    [self.manager PUT:path parameters:parameters headers:nil
              success:^(NSURLSessionDataTask *task, id responseObject) {
        [self handleResponse:responseObject success:success failure:failure];
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        [self handleError:error failure:failure];
    }];
}

- (void)DELETE:(NSString *)path
    parameters:(NSDictionary *)parameters
       success:(TLWNetworkSuccess)success
       failure:(TLWNetworkFailure)failure {
    [self applyAuthHeader];
    [self.manager DELETE:path parameters:parameters headers:nil
                 success:^(NSURLSessionDataTask *task, id responseObject) {
        [self handleResponse:responseObject success:success failure:failure];
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        [self handleError:error failure:failure];
    }];
}

@end
