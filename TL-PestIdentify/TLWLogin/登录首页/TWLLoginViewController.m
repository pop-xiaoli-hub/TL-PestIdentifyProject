//
//  TWLLoginViewController.m
//  TL-PestIdentify
//
//  登录页 ViewController
//

#import "TWLLoginViewController.h"
#import "TWLLoginView.h"
#import "TWLWechatBindViewController.h"

@interface TWLLoginViewController ()

@property (nonatomic, strong) TWLLoginView *loginView;
@property (nonatomic, assign) BOOL agreedToTerms;

@end

@implementation TWLLoginViewController

- (void)loadView {
    self.loginView = [[TWLLoginView alloc] initWithFrame:[UIScreen mainScreen].bounds];
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
    // TODO: 调用发送验证码接口
    NSLog(@"发送验证码到: %@", phone);
}

- (void)handleLogin {
    NSString *phone = self.loginView.phoneField.text;
    NSString *code  = self.loginView.codeField.text;

    if (phone.length == 0 || code.length == 0) {
        [self showAlertWithMessage:@"请输入手机号和验证码"];
        return;
    }
    // TODO: 调用登录接口
    NSLog(@"登录 phone=%@ code=%@", phone, code);
}

- (void)handleWechatLogin {
    TWLWechatBindViewController *bindVC = [[TWLWechatBindViewController alloc] init];
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
