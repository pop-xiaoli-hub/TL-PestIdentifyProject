//
//  TLWPasswordLoginController.m
//  TL-PestIdentify
//

#import "TLWPasswordLoginController.h"
#import "TLWPasswordLoginView.h"
#import "TLWWechatBindController.h"
#import "TLWMainTabBarController.h"
#import "TLWSDKManager.h"
#import <AgriPestClient/AGApiService.h>
#import <AgriPestClient/AGLoginRequest.h>
#import <AgriPestClient/AGResultAuthResponse.h>
#import <AgriPestClient/AGAuthResponse.h>
#import "TLWLoginController.h"
#import "TLWGuideController.h"

@interface TLWPasswordLoginController ()

@property (nonatomic, strong) TLWPasswordLoginView *passwordLoginView;

@end

@implementation TLWPasswordLoginController

- (void)loadView {
    self.passwordLoginView = [[TLWPasswordLoginView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.view = self.passwordLoginView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBarHidden = YES;
    self.passwordLoginView.backButton.hidden = YES;

    [self.passwordLoginView.loginTapButton addTarget:self
                                              action:@selector(handleLogin)
                                    forControlEvents:UIControlEventTouchUpInside];

    [self.passwordLoginView.togglePasswordButton addTarget:self
                                                    action:@selector(handleTogglePassword)
                                          forControlEvents:UIControlEventTouchUpInside];

    [self.passwordLoginView.backButton addTarget:self
                                          action:@selector(handleBack)
                                forControlEvents:UIControlEventTouchUpInside];

    [self.passwordLoginView.wechatLoginButton addTarget:self
                                                 action:@selector(handleWechatLogin)
                                       forControlEvents:UIControlEventTouchUpInside];

    [self.passwordLoginView.qqLoginButton addTarget:self
                                             action:@selector(handleQQLogin)
                                   forControlEvents:UIControlEventTouchUpInside];

    [self.passwordLoginView.phoneLoginButton addTarget:self
                                               action:@selector(handleSwitchToSms)
                                     forControlEvents:UIControlEventTouchUpInside];

    [self.passwordLoginView.skipButton addTarget:self
                                          action:@selector(handleSkip)
                                forControlEvents:UIControlEventTouchUpInside];

    // 点击空白处收起键盘
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self action:@selector(dismissKeyboard)];
    tap.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tap];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = YES;
    self.navigationController.interactivePopGestureRecognizer.delegate = nil;
}

#pragma mark - Actions

- (void)handleLogin {
    NSString *account  = self.passwordLoginView.accountField.text;
    NSString *password = self.passwordLoginView.passwordField.text;

    if (account.length == 0 || password.length == 0) {
        [self showAlertWithMessage:@"请输入账号和密码"];
        return;
    }

    AGLoginRequest *req = [[AGLoginRequest alloc] init];
    req.usernameOrPhone = account;
    req.password = password;

    [[TLWSDKManager shared].api loginWithLoginRequest:req completionHandler:^(AGResultAuthResponse *output, NSError *error) {
        if (error) {
            [self showAlertWithMessage:error.localizedDescription];
            return;
        }
        if (output.code.integerValue != 200) {
            [self showAlertWithMessage:output.message ?: @"登录失败"];
            return;
        }
        [[TLWSDKManager shared] saveAuthResponse:output.data];
        TLWGuideController *guideVC = [[TLWGuideController alloc] init];
        guideVC.modalPresentationStyle = UIModalPresentationFullScreen;
        [self presentViewController:guideVC animated:YES completion:nil];
    }];
}

- (void)handleTogglePassword {
    self.passwordLoginView.togglePasswordButton.selected = !self.passwordLoginView.togglePasswordButton.selected;
    self.passwordLoginView.passwordField.secureTextEntry = !self.passwordLoginView.togglePasswordButton.selected;
}

- (void)handleSwitchToSms {
    TLWLoginController *smsVC = [[TLWLoginController alloc] init];
    [self.navigationController pushViewController:smsVC animated:YES];
}

- (void)handleBack {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)handleSkip {
    TLWMainTabBarController *tabBar = [[TLWMainTabBarController alloc] init];
    UIWindow *window = [UIApplication sharedApplication].windows.firstObject;
    window.rootViewController = tabBar;
    [UIView transitionWithView:window
                      duration:0.35
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:nil
                    completion:nil];
}

- (void)handleWechatLogin {
    TLWWechatBindController *bindVC = [[TLWWechatBindController alloc] init];
    bindVC.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:bindVC animated:YES completion:nil];
}

- (void)handleQQLogin {
    NSLog(@"QQ登录");
}

- (void)dismissKeyboard {
    [self.view endEditing:YES];
}

#pragma mark - Helpers

- (void)showAlertWithMessage:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"好" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
