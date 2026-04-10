//
//  TLWSettingViewController.m
//  TL-PestIdentify
//

#import "TLWSettingViewController.h"
#import "TLWSettingView.h"
#import "TLWSDKManager.h"
#import "TLWPasswordLoginController.h"
#import <Masonry/Masonry.h>

@interface TLWSettingViewController ()
@property (nonatomic, strong) TLWSettingView *myView;
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
}

#pragma mark - Actions

- (void)setupActions {
    [_myView.aboutRowButton      addTarget:self action:@selector(onAbout)       forControlEvents:UIControlEventTouchUpInside];
    [_myView.feedbackRowButton   addTarget:self action:@selector(onFeedback)    forControlEvents:UIControlEventTouchUpInside];
    [_myView.permissionRowButton addTarget:self action:@selector(onPermission)  forControlEvents:UIControlEventTouchUpInside];
    [_myView.agreementRowButton  addTarget:self action:@selector(onAgreement)   forControlEvents:UIControlEventTouchUpInside];
    [_myView.privacyRowButton    addTarget:self action:@selector(onPrivacy)     forControlEvents:UIControlEventTouchUpInside];
    [_myView.logoutButton        addTarget:self action:@selector(onLogout)      forControlEvents:UIControlEventTouchUpInside];
}

- (void)onAbout       { /* TODO: 关于我们 */ }
- (void)onFeedback    { /* TODO: 我要反馈 */ }
- (void)onPermission  { /* TODO: 系统权限 */ }
- (void)onAgreement   { /* TODO: 用户协议 */ }
- (void)onPrivacy     { /* TODO: 隐私政策 */ }

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

#pragma mark - Lazy

- (TLWSettingView *)myView {
    if (!_myView) _myView = [[TLWSettingView alloc] initWithFrame:CGRectZero];
    return _myView;
}

@end
