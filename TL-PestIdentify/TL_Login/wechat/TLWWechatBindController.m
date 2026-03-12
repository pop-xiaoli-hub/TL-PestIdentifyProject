//
//  TLWWechatBindController.m
//  TL-PestIdentify
//
//  微信登录绑定页 Controller
//

#import "TLWWechatBindController.h"
#import "TLWWechatBindView.h"
#import "TLWGuideController.h"

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

    [self.bindView.phoneLoginButton addTarget:self
                                       action:@selector(handlePhoneLogin)
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

- (void)handlePhoneLogin {
    NSLog(@"手机号登录");
    // TODO: 跳转到手机验证登录页
}

@end
