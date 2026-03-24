//
//  TLWSDKManager.m
//  TL-PestIdentify
//

#import "TLWSDKManager.h"
#import <AgriPestClient/AGApiService.h>
#import <AgriPestClient/AGDefaultConfiguration.h>
#import <AgriPestClient/AGAuthResponse.h>

static NSString * const kTokenKey    = @"TLW_access_token";
static NSString * const kRefreshKey  = @"TLW_refresh_token";
static NSString * const kUserIdKey   = @"TLW_user_id";
static NSString * const kUsernameKey = @"TLW_username";

@implementation TLWSDKManager

+ (instancetype)shared {
    static TLWSDKManager *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[TLWSDKManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // 配置 SDK
        AGDefaultConfiguration *config = [AGDefaultConfiguration sharedConfig];
        config.host = @"http://115.191.67.35:8080";
        // 从本地恢复登录态
        NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
        NSString *token = [ud stringForKey:kTokenKey];
        if (token.length > 0) {
            config.accessToken = token;
        }
        _userId   = [ud integerForKey:kUserIdKey];
        _username = [ud stringForKey:kUsernameKey];

        _api = [[AGApiService alloc] init];
    }
    return self;
}

#pragma mark - Public

- (BOOL)isLoggedIn {
    return [AGDefaultConfiguration sharedConfig].accessToken.length > 0;
}

- (void)saveAuthResponse:(AGAuthResponse *)auth {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];

    [AGDefaultConfiguration sharedConfig].accessToken = auth.token;

    [ud setObject:auth.token        forKey:kTokenKey];
    [ud setObject:auth.refreshToken forKey:kRefreshKey];
    [ud setInteger:auth.userId.integerValue forKey:kUserIdKey];
    [ud setObject:auth.username     forKey:kUsernameKey];

    _userId   = auth.userId.integerValue;
    _username = auth.username;
}

- (nullable NSString *)refreshToken {
    return [[NSUserDefaults standardUserDefaults] stringForKey:kRefreshKey];
}

- (void)logout {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [AGDefaultConfiguration sharedConfig].accessToken = nil;

    [ud removeObjectForKey:kTokenKey];
    [ud removeObjectForKey:kRefreshKey];
    [ud removeObjectForKey:kUserIdKey];
    [ud removeObjectForKey:kUsernameKey];

    _userId   = 0;
    _username = nil;
}

@end
