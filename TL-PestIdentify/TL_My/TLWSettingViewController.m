//
//  TLWSettingViewController.m
//  TL-PestIdentify
//

#import "TLWSettingViewController.h"
#import "TLWSettingView.h"
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

- (void)viewDidLoad {
    [super viewDidLoad];
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

#pragma mark - Actions

- (void)setupActions {
    [_myView.backButton          addTarget:self action:@selector(onBack)        forControlEvents:UIControlEventTouchUpInside];
    [_myView.aboutRowButton      addTarget:self action:@selector(onAbout)       forControlEvents:UIControlEventTouchUpInside];
    [_myView.feedbackRowButton   addTarget:self action:@selector(onFeedback)    forControlEvents:UIControlEventTouchUpInside];
    [_myView.permissionRowButton addTarget:self action:@selector(onPermission)  forControlEvents:UIControlEventTouchUpInside];
    [_myView.agreementRowButton  addTarget:self action:@selector(onAgreement)   forControlEvents:UIControlEventTouchUpInside];
    [_myView.privacyRowButton    addTarget:self action:@selector(onPrivacy)     forControlEvents:UIControlEventTouchUpInside];
    [_myView.logoutButton        addTarget:self action:@selector(onLogout)      forControlEvents:UIControlEventTouchUpInside];
}

- (void)onBack {
    [self.navigationController popViewControllerAnimated:YES];
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
        // TODO: 清除登录态（删除 NSUserDefaults 中的 token、userId 等），跳转登录页
        //   [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"token"];
        //   UIWindow *window = [UIApplication sharedApplication].windows.firstObject;
        //   window.rootViewController = [[TLWSmsLoginController alloc] init];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Lazy

- (TLWSettingView *)myView {
    if (!_myView) _myView = [[TLWSettingView alloc] initWithFrame:CGRectZero];
    return _myView;
}

@end
