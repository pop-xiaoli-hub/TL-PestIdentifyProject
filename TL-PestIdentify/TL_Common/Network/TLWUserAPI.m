//
//  TLWUserAPI.m
//  TL-PestIdentify
//

#import "TLWUserAPI.h"

@implementation TLWUserAPI

+ (void)getMyProfileWithSuccess:(TLWNetworkSuccess)success
                        failure:(TLWNetworkFailure)failure {
    [[TLWNetworkManager shared] GET:@"/api/users/me"
                         parameters:nil
                            success:success
                            failure:failure];
}

+ (void)updateMyProfile:(NSDictionary *)params
                success:(TLWNetworkSuccess)success
                failure:(TLWNetworkFailure)failure {
    [[TLWNetworkManager shared] PUT:@"/api/users/me"
                         parameters:params
                            success:success
                            failure:failure];
}

+ (void)changePhone:(NSString *)newPhone
            success:(TLWNetworkSuccess)success
            failure:(TLWNetworkFailure)failure {
    [[TLWNetworkManager shared] PUT:@"/api/users/me/phone"
                         parameters:@{@"newPhone": newPhone}
                            success:success
                            failure:failure];
}

+ (void)followUser:(NSInteger)userId
           success:(TLWNetworkSuccess)success
           failure:(TLWNetworkFailure)failure {
    NSString *path = [NSString stringWithFormat:@"/api/users/%ld/follow", (long)userId];
    [[TLWNetworkManager shared] POST:path
                          parameters:nil
                             success:success
                             failure:failure];
}

+ (void)unfollowUser:(NSInteger)userId
             success:(TLWNetworkSuccess)success
             failure:(TLWNetworkFailure)failure {
    NSString *path = [NSString stringWithFormat:@"/api/users/%ld/follow", (long)userId];
    [[TLWNetworkManager shared] DELETE:path
                            parameters:nil
                               success:success
                               failure:failure];
}

@end
