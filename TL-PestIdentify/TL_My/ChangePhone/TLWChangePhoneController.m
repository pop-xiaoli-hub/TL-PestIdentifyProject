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
    [_countdownTimer invalidate];
}

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view addSubview:self.myView];
    [self.myView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    [self setupActions];
    [self applyCurrentPhone];

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self.view action:@selector(endEditing:)];
    [self.view addGestureRecognizer:tap];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    self.navigationController.interactivePopGestureRecognizer.enabled  = YES;
    self.navigationController.interactivePopGestureRecognizer.delegate = nil;
}

#pragma mark - Setup

- (void)applyCurrentPhone {
    NSString *phone = [TLWSDKManager shared].cachedProfile.phone;
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
    [_myView.backButton     addTarget:self action:@selector(onBack)     forControlEvents:UIControlEventTouchUpInside];
    [_myView.sendCodeButton addTarget:self action:@selector(onSendCode) forControlEvents:UIControlEventTouchUpInside];
    [_myView.confirmButton  addTarget:self action:@selector(onConfirm)  forControlEvents:UIControlEventTouchUpInside];
}

#pragma mark - Actions

- (void)onBack {
    [self.navigationController popViewControllerAnimated:YES];
}

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
                self.myView.sendCodeButton.enabled = YES;
                [self showAlert:output.message ?: @"发送失败"];
                return;
            }
            [self startCountdown];
        });
    }];
}

- (void)startCountdown {
    _countdown = 60;
    [_myView.sendCodeButton setTitle:[NSString stringWithFormat:@"%lds", (long)_countdown] forState:UIControlStateDisabled];
    _myView.sendCodeButton.enabled = NO;

    _countdownTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 repeats:YES block:^(NSTimer *timer) {
        self.countdown--;
        if (self.countdown <= 0) {
            [timer invalidate];
            self.myView.sendCodeButton.enabled = YES;
            [self.myView.sendCodeButton setTitle:@"发送验证码" forState:UIControlStateNormal];
        } else {
            [self.myView.sendCodeButton setTitle:[NSString stringWithFormat:@"%lds", (long)self.countdown] forState:UIControlStateDisabled];
        }
    }];
}

- (void)onConfirm {
    NSString *phone = _myView.phoneField.text;
    NSString *code  = _myView.codeField.text;

    if (phone.length < 11) {
        [self showAlert:@"请输入正确的手机号"];
        return;
    }
    if (code.length == 0) {
        [self showAlert:@"请输入验证码"];
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
                [self showAlert:output.message ?: @"换绑失败"];
                return;
            }

            // 刷新缓存
            [[TLWSDKManager shared] fetchProfileWithCompletion:nil];
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

@end
