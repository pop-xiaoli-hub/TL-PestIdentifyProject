//
//  TLWChangePasswordController.m
//  TL-PestIdentify
//

#import "TLWChangePasswordController.h"
#import "TLWChangePasswordView.h"
#import "TLWSDKManager.h"
#import <Masonry/Masonry.h>

@interface TLWChangePasswordController ()
@property (nonatomic, strong) TLWChangePasswordView *myView;
@end

@implementation TLWChangePasswordController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.hidesBottomBarWhenPushed = YES;
    [self.view addSubview:self.myView];
    [self.myView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    [self setupActions];
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
        [self showToast:@"密码长度需为6-20位"];
        return;
    }
    if (![newPwd isEqualToString:confirmPwd]) {
        [self showToast:@"两次密码不一致"];
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
                [self showToast:error.localizedDescription ?: output.message ?: @"修改失败"];
                return;
            }
            [self showToast:@"密码修改成功"];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self.navigationController popViewControllerAnimated:YES];
            });
        });
    }];
}

#pragma mark - Toast

- (void)showToast:(NSString *)text {
    UILabel *toast = [UILabel new];
    toast.text            = text;
    toast.font            = [UIFont systemFontOfSize:15];
    toast.textColor       = [UIColor colorWithRed:0.20 green:0.20 blue:0.20 alpha:1];
    toast.textAlignment   = NSTextAlignmentCenter;
    toast.backgroundColor = UIColor.whiteColor;
    toast.layer.cornerRadius  = 8;
    toast.layer.masksToBounds = NO;
    toast.layer.shadowColor   = [UIColor colorWithWhite:0 alpha:0.15].CGColor;
    toast.layer.shadowOpacity = 1;
    toast.layer.shadowRadius  = 6;
    toast.layer.shadowOffset  = CGSizeMake(0, 2);
    [self.view addSubview:toast];
    [toast mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.centerY.equalTo(self.view).multipliedBy(0.72);
        make.width.mas_greaterThanOrEqualTo(120);
        make.height.mas_equalTo(38);
    }];

    toast.alpha = 0;
    [UIView animateWithDuration:0.25 animations:^{ toast.alpha = 1; } completion:^(BOOL f) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.25 animations:^{ toast.alpha = 0; } completion:^(BOOL done) {
                [toast removeFromSuperview];
            }];
        });
    }];
}

@end
