//
//  AppDelegate.m
//  TL-PestIdentify
//
//  Created by xiaoli pop on 2026/3/5.
//

#import "AppDelegate.h"
#import <SpeechEngineToB/SpeechEngine.h>
#import <TargetConditionals.h>
@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  NSDictionary *env = [NSProcessInfo processInfo].environment;
  BOOL isRunningTests = (env[@"XCTestConfigurationFilePath"] != nil);
  // 单元测试宿主启动时跳过语音 SDK 初始化，避免影响测试进程拉起。
  if (!isRunningTests) {
    // 初始化火山引擎 Dialog 语音 SDK 环境
    [SpeechEngine prepareEnvironment];
  }
  return YES;
}


#pragma mark - UISceneSession lifecycle


- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
  // Called when a new scene session is being created.
  // Use this method to select a configuration to create the new scene with.
  return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}


- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions {
  // Called when the user discards a scene session.
  // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
  // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
}


@end
