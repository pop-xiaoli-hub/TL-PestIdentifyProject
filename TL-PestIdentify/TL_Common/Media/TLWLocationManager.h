//
//  TLWLocationManager.h
//  TL-PestIdentify
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * const TLWLocationDidUpdateNotification;

@interface TLWLocationManager : NSObject

+ (instancetype)shared;

/// 当前城市名（反向地理编码结果），无定位时为 nil
@property (nonatomic, copy, readonly, nullable) NSString *cityName;

/// 当前定位完整展示文案，优先包含区县信息
@property (nonatomic, copy, readonly, nullable) NSString *currentLocationDisplayName;

/// 用户手动选择的城市名
@property (nonatomic, copy, readonly, nullable) NSString *selectedLocationName;

/// 页面展示用定位名，优先返回手动选择结果
@property (nonatomic, copy, readonly, nullable) NSString *displayLocationName;

/// 当前定位纬度
@property (nonatomic, assign, readonly) CLLocationDegrees latitude;

/// 当前定位经度
@property (nonatomic, assign, readonly) CLLocationDegrees longitude;

/// 是否已获取到有效位置
@property (nonatomic, assign, readonly) BOOL hasLocation;

/// 定位权限是否被拒绝
@property (nonatomic, assign, readonly) BOOL locationDenied;

/// 请求定位权限并开始定位
- (void)requestLocationPermission;

/// 手动触发一次定位
- (void)startUpdatingLocation;

/// 选择一个手动城市
- (void)selectLocationName:(NSString *)locationName;

/// 清除手动城市，恢复展示当前定位
- (void)clearSelectedLocationName;

@end

NS_ASSUME_NONNULL_END
