//
//  TLWSettingView.h
//  TL-PestIdentify
//

#import <UIKit/UIKit.h>

@interface TLWSettingView : UIView

@property (nonatomic, strong, readonly) UISwitch *notificationSwitch;
@property (nonatomic, strong, readonly) UIButton *aboutRowButton;
@property (nonatomic, strong, readonly) UIButton *feedbackRowButton;
@property (nonatomic, strong, readonly) UIButton *permissionRowButton;
@property (nonatomic, strong, readonly) UIButton *agreementRowButton;
@property (nonatomic, strong, readonly) UIButton *privacyRowButton;
@property (nonatomic, strong, readonly) UIButton *logoutButton;

@end
