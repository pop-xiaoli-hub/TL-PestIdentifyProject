//
//  TLWAuthAPI.m
//  TL-PestIdentify
//

#import "TLWAuthAPI.h"

@implementation TLWAuthAPI

+ (void)saveAuthData:(NSDictionary *)data {
    TLWNetworkManager *nm = [TLWNetworkManager shared];
    nm.token        = data[@"token"];
    nm.refreshToken = data[@"refreshToken"];
    nm.userId       = [data[@"userId"] integerValue];
    nm.username     = data[@"username"];
}

+ (void)sendCodeWithPhone:(NSString *)phone
                  success:(TLWNetworkSuccess)success
                  failure:(TLWNetworkFailure)failure {
    [[TLWNetworkManager shared] POST:@"/api/auth/send-code"
                          parameters:@{@"phone": phone}
                             success:success
                             failure:failure];
}

+ (void)loginBySmsWithPhone:(NSString *)phone
                       code:(NSString *)code
                    success:(TLWNetworkSuccess)success
                    failure:(TLWNetworkFailure)failure {
    [[TLWNetworkManager shared] POST:@"/api/auth/login-by-sms"
                          parameters:@{@"phone": phone, @"code": code}
                             success:^(id data) {
        [self saveAuthData:data];
        if (success) success(data);
    } failure:failure];
}

+ (void)loginWithUsernameOrPhone:(NSString *)account
                        password:(NSString *)password
                         success:(TLWNetworkSuccess)success
                         failure:(TLWNetworkFailure)failure {
    [[TLWNetworkManager shared] POST:@"/api/auth/login"
                          parameters:@{@"usernameOrPhone": account, @"password": password}
                             success:^(id data) {
        [self saveAuthData:data];
        if (success) success(data);
    } failure:failure];
}

+ (void)registerWithUsername:(NSString *)username
                       phone:(NSString *)phone
                    password:(NSString *)password
                     success:(TLWNetworkSuccess)success
                     failure:(TLWNetworkFailure)failure {
    [[TLWNetworkManager shared] POST:@"/api/auth/register"
                          parameters:@{@"username": username, @"phone": phone, @"password": password}
                             success:^(id data) {
        [self saveAuthData:data];
        if (success) success(data);
    } failure:failure];
}

+ (void)refreshTokenWithSuccess:(TLWNetworkSuccess)success
                        failure:(TLWNetworkFailure)failure {
    NSString *rt = [TLWNetworkManager shared].refreshToken;
    if (!rt) {
        if (failure) failure(@"无刷新令牌");
        return;
    }
    [[TLWNetworkManager shared] POST:@"/api/auth/refresh"
                          parameters:@{@"refreshToken": rt}
                             success:^(id data) {
        [self saveAuthData:data];
        if (success) success(data);
    } failure:failure];
}

+ (void)logout {
    [[TLWNetworkManager shared] logout];
}

@end
