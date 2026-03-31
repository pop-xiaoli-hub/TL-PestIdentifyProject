//
//  TLWWechatBindController.m
//  TL-PestIdentify
//
//  Created by 吴桐 on 2026/3/12.
//

#import "TLWWechatBindController.h"
#import "TLWWechatBindView.h"
#import "TLWGuideController.h"
#import "TLWSmsLoginController.h"
#import "TLWPasswordLoginController.h"

@interface TLWWechatBindController ()

@property (nonatomic, strong) TLWWechatBindView *bindView;

@end

@implementation TLWWechatBindController

- (void)loadView {
    self.bindView = [[TLWWechatBindView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.view = self.bindView;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.bindView.wechatAuthButton addTarget:self
                                       action:@selector(handleWechatAuth)
                             forControlEvents:UIControlEventTouchUpInside];

    [self.bindView.qqLoginButton addTarget:self
                                    action:@selector(handleQQLogin)
                          forControlEvents:UIControlEventTouchUpInside];

    [self.bindView.smsLoginButton addTarget:self
                                     action:@selector(handleSmsLogin)
                           forControlEvents:UIControlEventTouchUpInside];

    [self.bindView.passwordLoginButton addTarget:self
                                          action:@selector(handlePasswordLogin)
                             forControlEvents:UIControlEventTouchUpInside];
}

#pragma mark - Actions

- (void)handleWechatAuth {
    // TODO: 接入微信 SDK 授权后再跳转，此处直接进入引导页
    TLWGuideController *guideVC = [[TLWGuideController alloc] init];
    guideVC.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:guideVC animated:YES completion:nil];
}

- (void)handleQQLogin {
    NSLog(@"QQ登录");
    // TODO: 接入 QQ SDK
}

- (void)handleSmsLogin {
    UIViewController *presenter = self.presentingViewController;
    [self dismissViewControllerAnimated:YES completion:^{
        if ([presenter isKindOfClass:[TLWSmsLoginController class]]) {
            return;
        }
        UINavigationController *nav = presenter.navigationController;
        if (!nav) return;
        TLWSmsLoginController *smsVC = [[TLWSmsLoginController alloc] init];
        [nav pushViewController:smsVC animated:YES];
    }];
}

- (void)handlePasswordLogin {
    UIViewController *presenter = self.presentingViewController;
    [self dismissViewControllerAnimated:YES completion:^{
        if ([presenter isKindOfClass:[TLWPasswordLoginController class]]) {
            return;
        }
        if ([presenter isKindOfClass:[TLWSmsLoginController class]]) {
            [presenter.navigationController popViewControllerAnimated:YES];
        }
    }];
}

@end
