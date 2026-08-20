//
//  main.m
//  TL-PestIdentify
//
//  Created by xiaoli pop on 2026/3/5.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import "TLWPerfLog.h"

CFAbsoluteTime kTLWAppStartTimestamp = 0;

int main(int argc, char * argv[]) {
  kTLWAppStartTimestamp = CFAbsoluteTimeGetCurrent();
  NSString * appDelegateClassName;
  @autoreleasepool {
      // Setup code that might create autoreleased objects goes here.
      appDelegateClassName = NSStringFromClass([AppDelegate class]);
  }
  return UIApplicationMain(argc, argv, nil, appDelegateClassName);
}
