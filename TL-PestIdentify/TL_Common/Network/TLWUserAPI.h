//
//  TLWUserAPI.h
//  TL-PestIdentify
//

#import <Foundation/Foundation.h>
#import "TLWNetworkManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface TLWUserAPI : NSObject

/// 获取当前用户资料
+ (void)getMyProfileWithSuccess:(nullable TLWNetworkSuccess)success
                        failure:(nullable TLWNetworkFailure)failure;

/// 更新当前用户资料（部分更新，传哪个改哪个）
+ (void)updateMyProfile:(NSDictionary *)params
                success:(nullable TLWNetworkSuccess)success
                failure:(nullable TLWNetworkFailure)failure;

/// 换绑手机号
+ (void)changePhone:(NSString *)newPhone
            success:(nullable TLWNetworkSuccess)success
            failure:(nullable TLWNetworkFailure)failure;

/// 关注用户
+ (void)followUser:(NSInteger)userId
           success:(nullable TLWNetworkSuccess)success
           failure:(nullable TLWNetworkFailure)failure;

/// 取消关注
+ (void)unfollowUser:(NSInteger)userId
             success:(nullable TLWNetworkSuccess)success
             failure:(nullable TLWNetworkFailure)failure;

@end

NS_ASSUME_NONNULL_END
