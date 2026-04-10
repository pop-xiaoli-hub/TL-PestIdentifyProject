//
//  SceneDelegate.m
//  TL-PestIdentify
//
//  Created by xiaoli pop on 2026/3/5.
//

#import "SceneDelegate.h"
#import "TLWPasswordLoginController.h"
#import "TLWMainTabBarController.h"
#import "TLWGuideController.h"
#import "TLWPreferenceController.h"
#import "TLWSDKManager.h"

@interface SceneDelegate ()

@property (nonatomic, copy) NSString *launchProfileValidationID;
@property (nonatomic, weak) UIViewController *launchProfileValidationRootController;
@property (nonatomic, assign) NSInteger launchProfileValidationUserId;

@end

@implementation SceneDelegate

- (void)tl_invalidateLaunchProfileValidation {
    self.launchProfileValidationID = nil;
    self.launchProfileValidationRootController = nil;
    self.launchProfileValidationUserId = 0;
}

- (void)tl_beginLaunchProfileValidationForRootController:(UIViewController *)rootController {
    self.launchProfileValidationID = [NSUUID UUID].UUIDString;
    self.launchProfileValidationRootController = rootController;
    self.launchProfileValidationUserId = [TLWSDKManager shared].sessionManager.userId;
    [self tl_fetchProfileWithRetry:3
                      validationID:self.launchProfileValidationID
            expectedRootController:rootController
                    expectedUserId:self.launchProfileValidationUserId];
}

- (BOOL)tl_isLaunchProfileValidationCurrent:(NSString *)validationID
                     expectedRootController:(UIViewController *)rootController
                             expectedUserId:(NSInteger)expectedUserId {
    if (validationID.length == 0) return NO;
    if (![self.launchProfileValidationID isEqualToString:validationID]) return NO;
    if (!rootController || self.window.rootViewController != rootController) return NO;
    if (![TLWSDKManager shared].sessionManager.isLoggedIn) return NO;
    if ([TLWSDKManager shared].sessionManager.userId != expectedUserId) return NO;
    return YES;
}

- (void)tl_switchToLoginRoot {
    [self tl_invalidateLaunchProfileValidation];
    TLWPasswordLoginController *loginVC = [[TLWPasswordLoginController alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:loginVC];
    nav.navigationBarHidden = YES;

    [UIView transitionWithView:self.window
                      duration:0.25
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
        self.window.rootViewController = nav;
    } completion:nil];
}


- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
  UIWindowScene *windowScene = (UIWindowScene *)scene;
  self.window = [[UIWindow alloc] initWithWindowScene:windowScene];

  if ([[TLWSDKManager shared].sessionManager isLoggedIn]) {
      // 有登录态，拉取用户资料后决定进哪个页面
      TLWMainTabBarController *tabBar = [[TLWMainTabBarController alloc] init];
      self.window.rootViewController = tabBar;
      [self.window makeKeyAndVisible];

      // 异步拉取资料，检查引导/偏好是否完成
      // 拉取失败不代表登录态无效，可能只是网络问题，3秒后自动重试。
      // 只有 token refresh 也失败时，handleUnauthorizedWithRetry 内部会自动 logout 跳登录页。
      [self tl_beginLaunchProfileValidationForRootController:tabBar];
  } else {
      // 没有登录态，进登录页
      [self tl_invalidateLaunchProfileValidation];
      TLWPasswordLoginController *loginVC = [[TLWPasswordLoginController alloc] init];
      UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:loginVC];
      nav.navigationBarHidden = YES;
      self.window.rootViewController = nav;
      [self.window makeKeyAndVisible];
  }
}


- (void)tl_fetchProfileWithRetry:(NSInteger)remainingRetries
                    validationID:(NSString *)validationID
          expectedRootController:(UIViewController *)rootController
                  expectedUserId:(NSInteger)expectedUserId {
    if (![self tl_isLaunchProfileValidationCurrent:validationID
                            expectedRootController:rootController
                                    expectedUserId:expectedUserId]) {
        return;
    }

    __weak typeof(self) weakSelf = self;
    [[TLWSDKManager shared].sessionManager fetchProfileWithCompletion:^(AGUserProfileDto *profile) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        if (![strongSelf tl_isLaunchProfileValidationCurrent:validationID
                                      expectedRootController:rootController
                                              expectedUserId:expectedUserId]) {
            return;
        }

        if (!profile) {
            // 网络或服务端异常，不登出，延迟重试
            if (remainingRetries > 0) {
                NSLog(@"[Launch] 拉取资料失败，%ld秒后重试（剩余%ld次）", (long)3, (long)remainingRetries);
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)),
                               dispatch_get_main_queue(), ^{
                    if (![strongSelf tl_isLaunchProfileValidationCurrent:validationID
                                                   expectedRootController:rootController
                                                           expectedUserId:expectedUserId]) {
                        return;
                    }
                    [strongSelf tl_fetchProfileWithRetry:remainingRetries - 1
                                            validationID:validationID
                                  expectedRootController:rootController
                                          expectedUserId:expectedUserId];
                });
            } else {
                NSLog(@"[Launch] 拉取资料多次失败，保留登录态等待用户操作");
                [strongSelf tl_invalidateLaunchProfileValidation];
            }
            return;
        }

        NSInteger currentUserId = [TLWSDKManager shared].sessionManager.userId;
        NSString *elderKey = [NSString stringWithFormat:@"TLW_elder_mode_set_%ld", (long)currentUserId];
        BOOL hasElderSetting = [[NSUserDefaults standardUserDefaults] boolForKey:elderKey];
        if (!hasElderSetting) {
            hasElderSetting = [[NSUserDefaults standardUserDefaults] boolForKey:@"TLW_elder_mode_set"];
        }
        BOOL hasCrops = (profile.followedCrops.count > 0);

        if (hasElderSetting && hasCrops) {
            [strongSelf tl_invalidateLaunchProfileValidation];
            return;
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            if (![strongSelf tl_isLaunchProfileValidationCurrent:validationID
                                          expectedRootController:rootController
                                                  expectedUserId:expectedUserId]) {
                return;
            }
            if (!hasElderSetting) {
                TLWGuideController *guideVC = [[TLWGuideController alloc] init];
                guideVC.modalPresentationStyle = UIModalPresentationFullScreen;
                [strongSelf.window.rootViewController presentViewController:guideVC animated:YES completion:nil];
            } else {
                TLWPreferenceController *prefVC = [[TLWPreferenceController alloc] init];
                prefVC.modalPresentationStyle = UIModalPresentationFullScreen;
                [strongSelf.window.rootViewController presentViewController:prefVC animated:YES completion:nil];
            }
            [strongSelf tl_invalidateLaunchProfileValidation];
        });
    }];
}

- (void)sceneDidDisconnect:(UIScene *)scene {
  // Called as the scene is being released by the system.
  // This occurs shortly after the scene enters the background, or when its session is discarded.
  // Release any resources associated with this scene that can be re-created the next time the scene connects.
  // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
}


- (void)sceneDidBecomeActive:(UIScene *)scene {
  // Called when the scene has moved from an inactive state to an active state.
  // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
}


- (void)sceneWillResignActive:(UIScene *)scene {
  // Called when the scene will move from an active state to an inactive state.
  // This may occur due to temporary interruptions (ex. an incoming phone call).
}


- (void)sceneWillEnterForeground:(UIScene *)scene {
  // Called as the scene transitions from the background to the foreground.
  // Use this method to undo the changes made on entering the background.
}


- (void)sceneDidEnterBackground:(UIScene *)scene {
  // Called as the scene transitions from the foreground to the background.
  // Use this method to save data, release shared resources, and store enough scene-specific state information
  // to restore the scene back to its current state.
}


@end
