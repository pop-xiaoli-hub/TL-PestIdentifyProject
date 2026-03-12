//
//  TLWMainTabBarController.m
//  TL-PestIdentify
//
//  Created by xiaoli pop on 2026/3/11.
//

#import "TLWMainTabBarController.h"
#import "TLWTabBar.h"
#import "TLWTabBarItemView.h"
#import "TLWHomePageController.h"
@interface TLWMainTabBarController ()

@end

@implementation TLWMainTabBarController

- (void)viewDidLoad {
  [super viewDidLoad];

  TLWTabBar *custom = [TLWTabBar new];
  __weak typeof(self) weakSelf = self;
  custom.selectionHandler = ^(NSInteger idx) {
    weakSelf.selectedIndex = idx;
  };
  [self setValue:custom forKey:@"tabBar"];

  TLWHomePageController *homeVC = [TLWHomePageController new];
  UINavigationController *homeNav = [[UINavigationController alloc] initWithRootViewController:homeVC];

  UIViewController *communityVC = [UIViewController new];
  communityVC.view.backgroundColor = UIColor.whiteColor;
  UINavigationController *communityNav = [[UINavigationController alloc] initWithRootViewController:communityVC];

  UIViewController *msgVC = [UIViewController new];
  msgVC.view.backgroundColor = UIColor.redColor;
  UINavigationController *msgNav = [[UINavigationController alloc] initWithRootViewController:msgVC];

  UIViewController *meVC = [UIViewController new];
  meVC.view.backgroundColor = UIColor.yellowColor;
  UINavigationController *meNav = [[UINavigationController alloc] initWithRootViewController:meVC];

  self.viewControllers = @[homeNav, communityNav, msgNav, meNav];
  self.selectedIndex = 0;
  [custom tl_setSelectedIndex:0];
}

- (void)setSelectedIndex:(NSUInteger)selectedIndex {
  [super setSelectedIndex:selectedIndex];
  TLWTabBar *tb = (TLWTabBar *)self.tabBar;
  [tb tl_setSelectedIndex:selectedIndex];
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
