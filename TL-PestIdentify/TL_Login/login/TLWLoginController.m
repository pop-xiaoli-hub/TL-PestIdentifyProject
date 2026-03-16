//
//  TLWLoginController.m
//  TL-PestIdentify
//
//  Created by 吴桐 on 2026/3/12.
//

#import "TLWLoginController.h"
#import "TLWLoginView.h"
#import "TLWWechatBindController.h"
#import "TLWMainTabBarController.h"

@interface TLWLoginController ()

@property (nonatomic, strong) TLWLoginView *loginView;
@property (nonatomic, assign) BOOL agreedToTerms;

@end

@implementation TLWLoginController

- (void)loadView {
    self.loginView = [[TLWLoginView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.view = self.loginView;
}

- (void)viewDidLoad {
    [super viewDidLoad];

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
    // TODO: POST /api/auth/sendCode，参数 {"phone": phone}
    //   成功回调：开始 60s 倒计时，禁用发送按钮
    //   失败回调：弹 toast 提示
}

- (void)handleLogin {
    NSString *phone = self.loginView.phoneField.text;
    NSString *code  = self.loginView.codeField.text;

    if (phone.length == 0 || code.length == 0) {
        [self showAlertWithMessage:@"请输入手机号和验证码"];
        return;
    }
    // TODO: POST /api/auth/login，参数 {"phone": phone, "code": code}
    //   成功回调：持久化 token（NSUserDefaults），调用 [self handleSkip] 跳转主页
    //   失败回调：弹 toast 提示验证码错误
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
    NSLog(@"本机号码一键登录");
    // TODO: 接入运营商一键登录 SDK
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
