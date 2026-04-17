//
//  TLWSettingViewController.m
//  TL-PestIdentify
//

#import "TLWSettingViewController.h"
#import "TLWSettingView.h"
#import "TLWSDKManager.h"
#import "TLWPasswordLoginController.h"
#import "TLWToast.h"
#import <UserNotifications/UserNotifications.h>
#import <Masonry/Masonry.h>

@interface TLWSettingViewController ()
@property (nonatomic, strong) TLWSettingView *myView;
@property (nonatomic, assign) BOOL isUpdatingNotificationSwitch;
@end

@implementation TLWSettingViewController

- (instancetype)init {
    self = [super init];
    if (self) self.hidesBottomBarWhenPushed = YES;
    return self;
}

- (NSString *)navTitle { return @"设置"; }

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view addSubview:self.myView];
    [self.myView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    [self.view bringSubviewToFront:self.navBar];
    [self setupActions];
    [self tl_syncNotificationSwitchState];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(tl_syncNotificationSwitchState)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
}

#pragma mark - Actions

- (void)setupActions {
    [_myView.notificationSwitch addTarget:self
                                   action:@selector(onNotificationSwitchChanged:)
                         forControlEvents:UIControlEventValueChanged];
    [_myView.aboutRowButton      addTarget:self action:@selector(onAbout)       forControlEvents:UIControlEventTouchUpInside];
    [_myView.feedbackRowButton   addTarget:self action:@selector(onFeedback)    forControlEvents:UIControlEventTouchUpInside];
    [_myView.permissionRowButton addTarget:self action:@selector(onPermission)  forControlEvents:UIControlEventTouchUpInside];
    [_myView.agreementRowButton  addTarget:self action:@selector(onAgreement)   forControlEvents:UIControlEventTouchUpInside];
    [_myView.privacyRowButton    addTarget:self action:@selector(onPrivacy)     forControlEvents:UIControlEventTouchUpInside];
    [_myView.logoutButton        addTarget:self action:@selector(onLogout)      forControlEvents:UIControlEventTouchUpInside];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)onNotificationSwitchChanged:(UISwitch *)sender {
    if (self.isUpdatingNotificationSwitch) {
        return;
    }
    if (sender.isOn) {
        [self tl_requestNotificationAuthorizationIfNeeded];
    } else {
        [self tl_handleNotificationDisableAttempt];
    }
}

- (void)onAbout       { [TLWToast show:@"开发中..."]; }
- (void)onFeedback    { [TLWToast show:@"开发中..."]; }
- (void)onPermission  { [TLWToast show:@"开发中..."]; }
- (void)onAgreement   { [TLWToast show:@"开发中..."]; }
- (void)onPrivacy     { [TLWToast show:@"开发中..."]; }

- (void)onLogout {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"退出登录"
                                                                   message:@"确定要退出登录吗？"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [[TLWSDKManager shared].sessionManager logout];
        UIWindow *window = self.view.window;
        TLWPasswordLoginController *loginVC = [[TLWPasswordLoginController alloc] init];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:loginVC];
        nav.navigationBarHidden = YES;
        window.rootViewController = nav;
        [UIView transitionWithView:window
                          duration:0.35
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:nil
                        completion:nil];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Notification Permission

- (void)tl_syncNotificationSwitchState {
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    [center getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
        BOOL enabled = [self tl_isNotificationAuthorizedForSettings:settings];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.isUpdatingNotificationSwitch = YES;
            [self.myView.notificationSwitch setOn:enabled animated:YES];
            self.isUpdatingNotificationSwitch = NO;
        });
    }];
}

- (void)tl_requestNotificationAuthorizationIfNeeded {
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    __weak typeof(self) weakSelf = self;
    [center getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;

        if ([strongSelf tl_isNotificationAuthorizedForSettings:settings]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [strongSelf tl_registerForRemoteNotifications];
                [TLWToast show:@"系统通知已开启"];
                [strongSelf tl_syncNotificationSwitchState];
            });
            return;
        }

        if (settings.authorizationStatus == UNAuthorizationStatusDenied) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [strongSelf tl_presentNotificationSettingsAlertWithMessage:@"系统通知权限已关闭，请前往系统设置开启。"];
                [strongSelf tl_syncNotificationSwitchState];
            });
            return;
        }

        [center requestAuthorizationWithOptions:(UNAuthorizationOptionAlert | UNAuthorizationOptionSound | UNAuthorizationOptionBadge)
                              completionHandler:^(BOOL granted, NSError * _Nullable error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (granted) {
                    [strongSelf tl_registerForRemoteNotifications];
                    [TLWToast show:@"系统通知已开启"];
                } else {
                    NSString *message = error.localizedDescription.length > 0 ? error.localizedDescription : @"请在系统设置中开启通知权限";
                    [TLWToast show:message];
                }
                [strongSelf tl_syncNotificationSwitchState];
            });
        }];
    }];
}

- (void)tl_handleNotificationDisableAttempt {
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    __weak typeof(self) weakSelf = self;
    [center getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;

        BOOL enabled = [strongSelf tl_isNotificationAuthorizedForSettings:settings];
        dispatch_async(dispatch_get_main_queue(), ^{
            [strongSelf tl_syncNotificationSwitchState];
            if (enabled) {
                [strongSelf tl_presentNotificationSettingsAlertWithMessage:@"iOS 不支持在应用内直接关闭系统通知，请前往系统设置关闭。"];
            }
        });
    }];
}

- (BOOL)tl_isNotificationAuthorizedForSettings:(UNNotificationSettings *)settings {
    UNAuthorizationStatus status = settings.authorizationStatus;
    return status == UNAuthorizationStatusAuthorized
        || status == UNAuthorizationStatusProvisional
        || status == UNAuthorizationStatusEphemeral;
}

- (void)tl_registerForRemoteNotifications {
    [[UIApplication sharedApplication] registerForRemoteNotifications];
}

- (void)tl_presentNotificationSettingsAlertWithMessage:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"系统消息通知"
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"去设置" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        if (url && [[UIApplication sharedApplication] canOpenURL:url]) {
            [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
        }
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Lazy

- (TLWSettingView *)myView {
    if (!_myView) _myView = [[TLWSettingView alloc] initWithFrame:CGRectZero];
    return _myView;
}

@end
