//
//  TLWHomePageView.h
//  TL-PestIdentify
//
//  Created by xiaoli pop on 2026/3/9.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TLWHomePageView : UIView

@property (nonatomic, strong, readonly) UITableView *tableView;
@property (nonatomic, strong, readonly) UIImageView *userAvatarImageView;
@property (nonatomic, strong, readonly) UIButton *userVersionButton;

/// 底部"开启定位"Banner 的回调
@property (nonatomic, copy, nullable) void(^onOpenLocationTapped)(void);
@property (nonatomic, copy, nullable) void(^onCloseLocationBanner)(void);

- (void)configureWithUserName:(NSString* )name;
- (void)configureElderModeEnabled:(BOOL)enabled;

/// 更新 header 中的定位城市名（nil 或空字符串时显示"未定位"）
- (void)configureWithLocationName:(nullable NSString *)locationName;

/// 显示底部"开启定位服务"Banner
- (void)showLocationBanner;

/// 更新天气展示（temperature 仅传数字，内部会自动拼接 ℃）
- (void)configureWithTemperature:(nullable NSString *)temperature
                     weatherText:(nullable NSString *)weatherText
                        iconCode:(nullable NSString *)iconCode;

/// 隐藏底部"开启定位服务"Banner
- (void)hideLocationBanner;

@end

NS_ASSUME_NONNULL_END
