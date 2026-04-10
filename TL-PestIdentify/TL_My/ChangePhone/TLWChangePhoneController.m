//
//  TLWChangePhoneController.m
//  TL-PestIdentify
//

#import "TLWChangePhoneController.h"
#import "TLWChangePhoneView.h"
#import "TLWSDKManager.h"
#import <Masonry/Masonry.h>

@interface TLWChangePhoneController ()

@property (nonatomic, strong) TLWChangePhoneView *myView;
@property (nonatomic, strong) NSTimer *countdownTimer;
@property (nonatomic, assign) NSInteger countdown;

@end

@implementation TLWChangePhoneController

- (instancetype)init {
    self = [super init];
    if (self) self.hidesBottomBarWhenPushed = YES;
    return self;
}

- (void)dealloc {
    [self invalidateCountdownTimer];
}

#pragma mark - Lifecycle

- (NSString *)navTitle { return @"换绑手机号"; }

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view addSubview:self.myView];
    [self.myView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    [self.view bringSubviewToFront:self.navBar];
    [self setupActions];
    [self applyCurrentPhone];

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self.view action:@selector(endEditing:)];
    [self.view addGestureRecognizer:tap];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (self.isMovingFromParentViewController || self.isBeingDismissed) {
        [self invalidateCountdownTimer];
    }
}

#pragma mark - Setup

- (void)applyCurrentPhone {
    NSString *phone = [TLWSDKManager shared].sessionManager.cachedProfile.phone;
    if (phone.length >= 11) {
        // 脱敏：138****1234
        NSString *masked = [NSString stringWithFormat:@"%@****%@",
                            [phone substringToIndex:3],
                            [phone substringFromIndex:phone.length - 4]];
        self.myView.currentPhoneLabel.text = masked;
    } else if (phone.length > 0) {
        self.myView.currentPhoneLabel.text = phone;
    } else {
        self.myView.currentPhoneLabel.text = @"未绑定";
    }
}

- (void)setupActions {
    [_myView.sendCodeButton addTarget:self action:@selector(onSendCode) forControlEvents:UIControlEventTouchUpInside];
    [_myView.confirmButton  addTarget:self action:@selector(onConfirm)  forControlEvents:UIControlEventTouchUpInside];
}

#pragma mark - Actions

- (void)onSendCode {
    NSString *phone = _myView.phoneField.text;
    if (phone.length < 11) {
        [self showAlert:@"请输入正确的手机号"];
        return;
    }

    _myView.sendCodeButton.enabled = NO;

    AGSendSmsRequest *req = [[AGSendSmsRequest alloc] init];
    req.phone = phone;
    [[TLWSDKManager shared].api sendSmsCodeWithSendSmsRequest:req completionHandler:^(AGResultVoid *output, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                self.myView.sendCodeButton.enabled = YES;
                [self showAlert:error.localizedDescription];
                return;
            }
            if (output.code.integerValue != 200) {
                if (output.code.integerValue == 401) {
                    [[TLWSDKManager shared].sessionManager handleUnauthorizedWithRetry:^{ [self onSendCode]; }];
                    return;
                }
                self.myView.sendCodeButton.enabled = YES;
                [self showAlert:output.message ?: @"发送失败"];
                return;
            }
            [self startCountdown];
        });
    }];
}

- (void)startCountdown {
    [self invalidateCountdownTimer];
    _countdown = 60;
    [_myView.sendCodeButton setTitle:[NSString stringWithFormat:@"%lds", (long)_countdown] forState:UIControlStateDisabled];
    _myView.sendCodeButton.enabled = NO;

    __weak typeof(self) weakSelf = self;
    _countdownTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 repeats:YES block:^(NSTimer *timer) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            [timer invalidate];
            return;
        }

        strongSelf.countdown--;
        if (strongSelf.countdown <= 0) {
            [timer invalidate];
            strongSelf.countdownTimer = nil;
            strongSelf.myView.sendCodeButton.enabled = YES;
            [strongSelf.myView.sendCodeButton setTitle:@"发送验证码" forState:UIControlStateNormal];
        } else {
            [strongSelf.myView.sendCodeButton setTitle:[NSString stringWithFormat:@"%lds", (long)strongSelf.countdown] forState:UIControlStateDisabled];
        }
    }];
}

- (void)onConfirm {
    NSString *phone = _myView.phoneField.text;

    if (phone.length < 11) {
        [self showAlert:@"请输入正确的手机号"];
        return;
    }

    _myView.confirmButton.userInteractionEnabled = NO;

    AGChangePhoneRequest *req = [[AGChangePhoneRequest alloc] init];
    req.varNewPhone = phone;
    [[TLWSDKManager shared].api changePhoneWithChangePhoneRequest:req completionHandler:^(AGResultVoid *output, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.myView.confirmButton.userInteractionEnabled = YES;

            if (error) {
                [self showAlert:error.localizedDescription];
                return;
            }
            if (output.code.integerValue != 200) {
                if (output.code.integerValue == 401) {
                    [[TLWSDKManager shared].sessionManager handleUnauthorizedWithRetry:^{ [self onConfirm]; }];
                    return;
                }
                [self showAlert:output.message ?: @"换绑失败"];
                return;
            }

            // 刷新缓存
            [[TLWSDKManager shared].sessionManager fetchProfileWithCompletion:nil];
            [self showAlert:@"换绑成功" completion:^{
                [self.navigationController popViewControllerAnimated:YES];
            }];
        });
    }];
}

#pragma mark - Alert

- (void)showAlert:(NSString *)msg {
    [self showAlert:msg completion:nil];
}

- (void)showAlert:(NSString *)msg completion:(void (^ _Nullable)(void))completion {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:msg
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        if (completion) completion();
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Lazy

- (TLWChangePhoneView *)myView {
    if (!_myView) _myView = [[TLWChangePhoneView alloc] initWithFrame:CGRectZero];
    return _myView;
}

- (void)invalidateCountdownTimer {
    [self.countdownTimer invalidate];
    self.countdownTimer = nil;
}

@end
