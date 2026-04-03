//
//  TLWBaseViewController.h
//  TL-PestIdentify
//
//  基础控制器：自动隐藏系统导航栏 + 恢复右滑返回手势
//  可选内置 TLWCustomNavBar
//

#import <UIKit/UIKit.h>
#import "TLWCustomNavBar.h"

NS_ASSUME_NONNULL_BEGIN

@interface TLWBaseViewController : UIViewController

/// 自定义导航栏（hideNavBar=YES 时为 nil）
@property (nonatomic, strong, readonly, nullable) TLWCustomNavBar *navBar;

/// 内容区域，位于导航栏下方（hideNavBar=YES 时铺满整个 view）
@property (nonatomic, strong, readonly) UIView *contentView;

/// 是否隐藏自定义导航栏，默认 NO。必须在 viewDidLoad 之前设置（如 init 中）
@property (nonatomic, assign) BOOL hideNavBar;

/// 子类 override 此方法返回页面标题，默认返回 nil
- (nullable NSString *)navTitle;

/// 子类 override 此方法返回标题图标名，默认返回 nil
- (nullable NSString *)navTitleIconName;

/// 返回按钮点击，默认执行 pop。子类可 override
- (void)onBackAction;

@end

NS_ASSUME_NONNULL_END
