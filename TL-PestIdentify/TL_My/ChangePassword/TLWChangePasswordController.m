//
//  TLWChangePasswordController.m
//  TL-PestIdentify
//

#import "TLWChangePasswordController.h"
#import "TLWChangePasswordView.h"
#import "TLWSDKManager.h"
#import "TLWToast.h"
#import <Masonry/Masonry.h>

@interface TLWChangePasswordController ()
@property (nonatomic, strong) TLWChangePasswordView *myView;
@property (nonatomic, copy)   NSString *currentPassword;
@end

@implementation TLWChangePasswordController

- (instancetype)initWithCurrentPassword:(NSString *)password {
    self = [super init];
    if (self) {
        self.hidesBottomBarWhenPushed = YES;
        _currentPassword = [password copy];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.hidesBottomBarWhenPushed = YES;
    [self.view addSubview:self.myView];
    [self.myView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    [self setupActions];
    if (_currentPassword.length > 0) {
        _myView.currentPassword = _currentPassword;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    self.navigationController.interactivePopGestureRecognizer.enabled  = YES;
    self.navigationController.interactivePopGestureRecognizer.delegate = nil;
}

- (TLWChangePasswordView *)myView {
    if (!_myView) _myView = [[TLWChangePasswordView alloc] initWithFrame:CGRectZero];
    return _myView;
}

- (void)setupActions {
    [_myView.backButton    addTarget:self action:@selector(onBack)    forControlEvents:UIControlEventTouchUpInside];
    [_myView.confirmButton addTarget:self action:@selector(onConfirm) forControlEvents:UIControlEventTouchUpInside];
}

#pragma mark - Actions

- (void)onBack {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)onConfirm {
    NSString *newPwd     = _myView.passwordField.text ?: @"";
    NSString *confirmPwd = _myView.confirmPasswordField.text ?: @"";

    if (newPwd.length < 6 || newPwd.length > 20) {
        [TLWToast show:@"密码长度需为6-20位"];
        return;
    }
    if (![newPwd isEqualToString:confirmPwd]) {
        [TLWToast show:@"两次密码不一致"];
        return;
    }

    _myView.confirmButton.enabled = NO;
    [[TLWSDKManager shared].api updatePasswordWithVarNewPassword:newPwd completionHandler:^(AGResultVoid *output, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self->_myView.confirmButton.enabled = YES;
            if (error || output.code.integerValue != 200) {
                if (!error && output.code.integerValue == 401) {
                    [[TLWSDKManager shared] handleUnauthorizedWithRetry:^{ [self onConfirm]; }];
                    return;
                }
                [TLWToast show:error.localizedDescription ?: output.message ?: @"修改失败"];
                return;
            }
            // 修改成功后清除旧密码记录
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"TLW_generated_password"];
            [TLWToast show:@"密码修改成功"];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self.navigationController popViewControllerAnimated:YES];
            });
        });
    }];
}

@end
