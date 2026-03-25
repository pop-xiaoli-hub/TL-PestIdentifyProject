//
//  TLWSmsLoginController.m
//  TL-PestIdentify
//
//  Created by 吴桐 on 2026/3/12.
//

#import "TLWSmsLoginController.h"
#import "TLWSmsLoginView.h"
#import "TLWWechatBindController.h"
#import "TLWMainTabBarController.h"
#import "TLWSDKManager.h"
#import "TLWGuideController.h"
#import "TLWPreferenceController.h"

@interface TLWSmsLoginController ()

@property (nonatomic, strong) TLWSmsLoginView *loginView;
@property (nonatomic, assign) BOOL agreedToTerms;
@property (nonatomic, strong) NSTimer *countdownTimer;
@property (nonatomic, assign) NSInteger countdown;

@end

@implementation TLWSmsLoginController

- (void)loadView {
    self.loginView = [[TLWSmsLoginView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.view = self.loginView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBarHidden = YES;

    self.agreedToTerms = NO;

    [self.loginView.sendCodeButton addTarget:self
                                      action:@selector(handleSendCode)
                            forControlEvents:UIControlEventTouchUpInside];

    [self.loginView.loginTapButton addTarget:self
                                      action:@selector(handleLogin)
                            forControlEvents:UIControlEventTouchUpInside];

    [self.loginView.wechatLoginButton addTarget:self
                                         action:@selector(handleWechatLogin)
                               forControlEvents:UIControlEventTouchUpInside];

    [self.loginView.qqLoginButton addTarget:self
                                     action:@selector(handleQQLogin)
                           forControlEvents:UIControlEventTouchUpInside];

    [self.loginView.localPhoneLoginButton addTarget:self
                                             action:@selector(handleLocalPhoneLogin)
                                   forControlEvents:UIControlEventTouchUpInside];

    [self.loginView.skipButton addTarget:self
                                  action:@selector(handleSkip)
                        forControlEvents:UIControlEventTouchUpInside];

    // 点击空白处收起键盘
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self action:@selector(dismissKeyboard)];
    tap.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tap];
}

#pragma mark - Actions

- (void)handleSendCode {
    NSString *phone = self.loginView.phoneField.text;
    if (phone.length < 11) {
        [self showAlertWithMessage:@"请输入正确的手机号"];
        return;
    }
    self.loginView.sendCodeButton.enabled = NO;
    AGSendSmsRequest *req = [[AGSendSmsRequest alloc] init];
    req.phone = phone;
    [[TLWSDKManager shared].api sendSmsCodeWithSendSmsRequest:req completionHandler:^(AGResultVoid *output, NSError *error) {
        if (error) {
            self.loginView.sendCodeButton.enabled = YES;
            [self showAlertWithMessage:error.localizedDescription];
            return;
        }
        if (output.code.integerValue != 200) {
            self.loginView.sendCodeButton.enabled = YES;
            [self showAlertWithMessage:output.message ?: @"发送失败"];
            return;
        }
        [self startCountdown];
    }];
}

- (void)startCountdown {
    self.countdown = 60;
    [self.loginView.sendCodeButton setTitle:[NSString stringWithFormat:@"%lds", (long)self.countdown] forState:UIControlStateDisabled];
    self.loginView.sendCodeButton.enabled = NO;

    self.countdownTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 repeats:YES block:^(NSTimer *timer) {
        self.countdown--;
        if (self.countdown <= 0) {
            [timer invalidate];
            self.countdownTimer = nil;
            self.loginView.sendCodeButton.enabled = YES;
            [self.loginView.sendCodeButton setTitle:@"获取验证码" forState:UIControlStateNormal];
        } else {
            [self.loginView.sendCodeButton setTitle:[NSString stringWithFormat:@"%lds", (long)self.countdown] forState:UIControlStateDisabled];
        }
    }];
}

- (void)handleLogin {
    NSString *phone = self.loginView.phoneField.text;
    NSString *code  = self.loginView.codeField.text;
    if (phone.length == 0 || code.length == 0) {
        [self showAlertWithMessage:@"请输入手机号和验证码"];
        return;
    }
    AGSmsLoginRequest *req = [[AGSmsLoginRequest alloc] init];
    req.phone = phone;
    req.code  = code;
    [[TLWSDKManager shared].api loginBySmsWithSmsLoginRequest:req completionHandler:^(AGResultAuthResponse *output, NSError *error) {
        if (error) {
            [self showAlertWithMessage:error.localizedDescription];
            return;
        }
        if (output.code.integerValue != 200) {
            [self showAlertWithMessage:output.message ?: @"登录失败"];
            return;
        }
        [[TLWSDKManager shared] saveAuthResponse:output.data];
        [self navigateAfterLogin];
    }];
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
    // TODO: 接入 QQ SDK
}

- (void)handleLocalPhoneLogin {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)dismissKeyboard {
    [self.view endEditing:YES];
}

#pragma mark - 登录后导航

- (void)navigateAfterLogin {
    BOOL hasElderSetting = [[NSUserDefaults standardUserDefaults] boolForKey:@"TLW_elder_mode_set"];

    [[TLWSDKManager shared].api getCurrentUserProfileWithCompletionHandler:^(AGResultUserProfileDto *output, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            BOOL hasCrops = (output.data.followedCrops.count > 0);

            if (hasElderSetting && hasCrops) {
                [self goToMain];
            } else if (hasElderSetting && !hasCrops) {
                TLWPreferenceController *prefVC = [[TLWPreferenceController alloc] init];
                prefVC.modalPresentationStyle = UIModalPresentationFullScreen;
                [self presentViewController:prefVC animated:YES completion:nil];
            } else {
                TLWGuideController *guideVC = [[TLWGuideController alloc] init];
                guideVC.modalPresentationStyle = UIModalPresentationFullScreen;
                [self presentViewController:guideVC animated:YES completion:nil];
            }
        });
    }];
}

- (void)goToMain {
    TLWMainTabBarController *tabBar = [[TLWMainTabBarController alloc] init];
    UIWindow *window = [UIApplication sharedApplication].windows.firstObject;
    window.rootViewController = tabBar;
    [UIView transitionWithView:window
                      duration:0.35
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:nil
                    completion:nil];
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
