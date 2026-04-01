//
//  TLWNotificationView.h
//  TL-PestIdentify
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TLWNotificationView : UIView

@property (nonatomic, strong, readonly) UIButton              *backButton;
@property (nonatomic, strong, readonly) UITableView           *tableView;
// 4 tab filter buttons: index 0=全部, 1=系统通知, 2=病害消息, 3=用户调研
@property (nonatomic, strong, readonly) NSArray<UIButton *>   *tabButtons;

@end

NS_ASSUME_NONNULL_END
