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
#import <WebKit/WebKit.h>
#import <Masonry/Masonry.h>

static NSString * const kTLWComplianceBaseURLString = @"http://115.191.67.35:8080";

@interface TLWStaticWebPageController : TLWBaseViewController <WKNavigationDelegate>

- (instancetype)initWithTitle:(NSString *)title
                    urlString:(NSString *)urlString;

@end

@interface TLWStaticWebPageController ()

@property (nonatomic, copy) NSString *pageTitle;
@property (nonatomic, copy) NSString *urlString;
@property (nonatomic, strong) UIVisualEffectView *cardView;
@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) UIActivityIndicatorView *loadingView;
@property (nonatomic, strong) UILabel *errorLabel;

@end

@implementation TLWStaticWebPageController

- (instancetype)initWithTitle:(NSString *)title
                    urlString:(NSString *)urlString {
    self = [super init];
    if (self) {
        _pageTitle = [title copy];
        _urlString = [urlString copy];
        self.hidesBottomBarWhenPushed = YES;
    }
    return self;
}

- (NSString *)navTitle {
    return self.pageTitle;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.layer.contents = (__bridge id)[UIImage imageNamed:@"hp_backView"].CGImage;
    self.contentView.backgroundColor = [UIColor clearColor];

    UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    self.cardView = [[UIVisualEffectView alloc] initWithEffect:blur];
    self.cardView.layer.cornerRadius = 20.0;
    self.cardView.layer.masksToBounds = YES;
    [self.contentView addSubview:self.cardView];

    UIView *overlay = [[UIView alloc] init];
    overlay.backgroundColor = [UIColor colorWithRed:0.88 green:0.94 blue:0.97 alpha:0.60];
    [self.cardView.contentView addSubview:overlay];

    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
    self.webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:configuration];
    self.webView.navigationDelegate = self;
    self.webView.backgroundColor = [UIColor whiteColor];
    self.webView.opaque = NO;
    if (@available(iOS 15.0, *)) {
        self.webView.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentAutomatic;
    }
    [self.cardView.contentView addSubview:self.webView];

    self.loadingView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    self.loadingView.hidesWhenStopped = YES;
    [self.cardView.contentView addSubview:self.loadingView];

    self.errorLabel = [[UILabel alloc] init];
    self.errorLabel.hidden = YES;
    self.errorLabel.numberOfLines = 0;
    self.errorLabel.textAlignment = NSTextAlignmentCenter;
    self.errorLabel.textColor = [UIColor colorWithRed:0.45 green:0.47 blue:0.52 alpha:1.0];
    self.errorLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    [self.cardView.contentView addSubview:self.errorLabel];

    [self.cardView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView).offset(16);
        make.left.right.equalTo(self.contentView);
        make.bottom.equalTo(self.contentView.mas_safeAreaLayoutGuideBottom).offset(-16);
    }];
    [overlay mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.cardView.contentView);
    }];
    [self.webView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.cardView.contentView);
    }];
    [self.loadingView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.cardView.contentView);
    }];
    [self.errorLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.cardView.contentView);
        make.left.equalTo(self.cardView.contentView).offset(32);
        make.right.equalTo(self.cardView.contentView).offset(-32);
    }];

    [self tl_loadPage];
}

- (void)tl_loadPage {
    NSURL *url = [NSURL URLWithString:self.urlString];
    if (!url) {
        [self tl_showError:@"页面地址无效"];
        return;
    }

    self.errorLabel.hidden = YES;
    [self.loadingView startAnimating];
    [self.webView loadRequest:[NSURLRequest requestWithURL:url]];
}

- (void)tl_showError:(NSString *)message {
    [self.loadingView stopAnimating];
    self.errorLabel.text = message;
    self.errorLabel.hidden = NO;
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    self.errorLabel.hidden = YES;
    [self.loadingView startAnimating];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    [self.loadingView stopAnimating];
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    if (error.code == NSURLErrorCancelled) {
        return;
    }
    [self tl_showError:@"页面加载失败，请确认静态页服务可访问"];
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    if (error.code == NSURLErrorCancelled) {
        return;
    }
    [self tl_showError:@"页面加载失败，请确认静态页服务可访问"];
}

@end

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

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.myView configureElderModeEnabled:[self tl_isElderModeEnabled]];
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

- (void)onAbout      { [self tl_openStaticPageWithTitle:@"关于我们" path:@"about-us.html"]; }
- (void)onFeedback   { [self tl_openStaticPageWithTitle:@"我要反馈" path:@"feedback.html"]; }
- (void)onPermission { [self tl_openStaticPageWithTitle:@"系统权限" path:@"permissions.html"]; }
- (void)onAgreement  { [self tl_openStaticPageWithTitle:@"用户协议" path:@"terms.html"]; }
- (void)onPrivacy    { [self tl_openStaticPageWithTitle:@"隐私政策" path:@"privacy.html"]; }

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

- (void)tl_openStaticPageWithTitle:(NSString *)title path:(NSString *)path {
    NSString *urlString = [NSString stringWithFormat:@"%@/%@", kTLWComplianceBaseURLString, path];
    TLWStaticWebPageController *controller = [[TLWStaticWebPageController alloc] initWithTitle:title urlString:urlString];
    [self.navigationController pushViewController:controller animated:YES];
}

#pragma mark - Lazy

- (TLWSettingView *)myView {
    if (!_myView) _myView = [[TLWSettingView alloc] initWithFrame:CGRectZero];
    return _myView;
}

- (BOOL)tl_isElderModeEnabled {
    NSInteger currentUserId = [TLWSDKManager shared].sessionManager.userId;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *elderModeKey = [NSString stringWithFormat:@"TLW_elder_mode_%ld", (long)currentUserId];
    if ([defaults objectForKey:elderModeKey] != nil) {
        return [defaults boolForKey:elderModeKey];
    }
    if ([defaults objectForKey:@"TLW_elder_mode"] != nil) {
        return [defaults boolForKey:@"TLW_elder_mode"];
    }
    return NO;
}

@end
