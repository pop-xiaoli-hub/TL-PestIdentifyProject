//
//  TLWGuideController.m
//  TL-PestIdentify
//
//  Created by 吴桐 on 2026/3/12.
//

#import "TLWGuideController.h"
#import "TLWGuideView.h"
#import "TLWPreferenceController.h"
#import "TLWMainTabBarController.h"
#import "TLWSDKManager.h"

/// 选项枚举
typedef NS_ENUM(NSInteger, TLWGuideOption) {
    TLWGuideOptionNone   = -1,
    TLWGuideOptionNeed   =  0,   // 需要适老化
    TLWGuideOptionNoNeed =  1,   // 不需要
};

@interface TLWGuideController ()

@property (nonatomic, strong) TLWGuideView *guideView;
@property (nonatomic, assign) TLWGuideOption selectedOption;

@end

@implementation TLWGuideController

- (void)loadView {
    self.guideView = [[TLWGuideView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.view = self.guideView;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.selectedOption = TLWGuideOptionNone;

    [self.guideView.needButton addTarget:self
                                  action:@selector(handleNeed)
                        forControlEvents:UIControlEventTouchUpInside];

    [self.guideView.noNeedButton addTarget:self
                                    action:@selector(handleNoNeed)
                          forControlEvents:UIControlEventTouchUpInside];

    [self.guideView.confirmButton addTarget:self
                                     action:@selector(handleConfirm)
                           forControlEvents:UIControlEventTouchUpInside];
}

#pragma mark - Actions

- (void)handleNeed {
    self.selectedOption = TLWGuideOptionNeed;
    [self.guideView setSelectedOption:TLWGuideOptionNeed];
}

- (void)handleNoNeed {
    self.selectedOption = TLWGuideOptionNoNeed;
    [self.guideView setSelectedOption:TLWGuideOptionNoNeed];
}

- (void)handleConfirm {
    if (self.selectedOption == TLWGuideOptionNone) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                       message:@"请先选择一个选项"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"好" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }

    BOOL needElderMode = (self.selectedOption == TLWGuideOptionNeed);
    NSLog(@"用户选择适老化模式: %@", needElderMode ? @"是" : @"否");

    // 保存适老化设置到本地（按 userId 隔离）
    NSInteger currentUserId = [TLWSDKManager shared].sessionManager.userId;
    NSString *elderModeKey = [NSString stringWithFormat:@"TLW_elder_mode_%ld", (long)currentUserId];
    NSString *elderSetKey  = [NSString stringWithFormat:@"TLW_elder_mode_set_%ld", (long)currentUserId];
    [[NSUserDefaults standardUserDefaults] setBool:needElderMode forKey:elderModeKey];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:elderSetKey];
    [self tl_continueAfterGuide];
}

#pragma mark - Navigation

- (void)tl_continueAfterGuide {
    AGUserProfileDto *cachedProfile = [TLWSDKManager shared].sessionManager.cachedProfile;
    if (cachedProfile) {
        [self tl_routeAfterGuideWithProfile:cachedProfile];
        return;
    }

    __weak typeof(self) weakSelf = self;
    [[TLWSDKManager shared].sessionManager fetchProfileWithCompletion:^(AGUserProfileDto *profile) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        [strongSelf tl_routeAfterGuideWithProfile:profile];
    }];
}

- (void)tl_routeAfterGuideWithProfile:(AGUserProfileDto *)profile {
    BOOL hasCrops = (profile.followedCrops.count > 0);
    if (hasCrops) {
        [self tl_navigateToMain];
        return;
    }

    TLWPreferenceController *prefVC = [[TLWPreferenceController alloc] init];
    prefVC.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:prefVC animated:YES completion:nil];
}

- (void)tl_navigateToMain {
    TLWMainTabBarController *tabBar = [[TLWMainTabBarController alloc] init];
    UIWindow *window = self.view.window ?: [TLWSDKManager tl_activeWindow];
    if (!window) return;

    window.rootViewController = tabBar;
    [UIView transitionWithView:window
                      duration:0.3
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:nil
                    completion:nil];
}

@end
