//
//  TLWMainTabBarController.m
//  TL-PestIdentify
//
//  Created by xiaoli pop on 2026/3/11.
//

#import "TLWMainTabBarController.h"
#import "TLWTabBar.h"
#import "TLWHomePageController.h"
#import "TLWCommunityController.h"
#import "TLWMessageController.h"
#import "TLWMyController.h"
#import "TLWSDKManager.h"
#import <Masonry/Masonry.h>
#import "TLWDBManager.h"
@interface TLWMainTabBarController () <UINavigationControllerDelegate>

// 存放四个模块的 NavigationController
@property (nonatomic, strong) NSArray<UIViewController *> *childVCs;

// 自定义胶囊 TabBar，直接作为普通子视图添加，不走系统 UITabBar 逻辑
@property (nonatomic, strong) TLWTabBar *mainTabBar;

// 当前选中的 tab 下标
@property (nonatomic, assign) NSInteger selectedIndex;

// 胶囊外围的白色半透明背景，用遮罩挖掉胶囊区域
@property (nonatomic, strong) UIView *whiteBg;
@property (nonatomic, strong) CAShapeLayer *whiteBgMask;

@end

@implementation TLWMainTabBarController

- (void)viewDidLoad {
    [super viewDidLoad];

    // ── 1. 初始化四个子模块 ──────────────────────────────────────
    // 首页：有真实实现
    TLWHomePageController *homeVC = [TLWHomePageController new];
    UINavigationController *homeNav = [[UINavigationController alloc] initWithRootViewController:homeVC];

    // 社区
    TLWCommunityController *communityVC = [TLWCommunityController new];
    UINavigationController *communityNav = [[UINavigationController alloc] initWithRootViewController:communityVC];

    // 消息
    TLWMessageController *msgVC = [TLWMessageController new];
    UINavigationController *msgNav = [[UINavigationController alloc] initWithRootViewController:msgVC];

    // 我的
    TLWMyController *meVC = [TLWMyController new];
    UINavigationController *meNav = [[UINavigationController alloc] initWithRootViewController:meVC];

    _childVCs = @[homeNav, communityNav, msgNav, meNav];

    // 全局隐藏系统导航栏，所有页面统一使用自定义导航栏
    for (UINavigationController *nav in _childVCs) {
        nav.navigationBarHidden = YES;
        nav.delegate = self;
    }

    // ── 2. 注册子 VC，走正确的生命周期 ──────────────────────────
    // addChildViewController 会让子 VC 正确收到 viewWillAppear 等回调
    for (UIViewController *vc in _childVCs) {
        [self addChildViewController:vc];
        [vc didMoveToParentViewController:self];
    }

    // ── 3. 一次性添加所有子 VC 的 view，切换时只改 hidden ──────
    for (NSInteger i = 0; i < _childVCs.count; i++) {
        UIView *childView = _childVCs[i].view;
        childView.hidden = (i != 0);
        [self.view addSubview:childView];
        [childView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.view);
        }];
    }
    _selectedIndex = 0;

    // ── 4. 创建 TabBar，直接 addSubview，彻底脱离系统 UITabBar ──
    // 原来用 [self setValue:custom forKey:@"tabBar"] 的 KVC 方式
    // 在 iOS 26 上会被系统强加 Liquid Glass 效果，改为直接添加子视图
    _mainTabBar = [TLWTabBar new];
    __weak typeof(self) weakSelf = self;
    _mainTabBar.selectionHandler = ^(NSInteger idx) {
        // 用户点击 TabBar 按钮时切换对应页面
        [weakSelf switchToIndex:idx];
    };
    [self.view addSubview:_mainTabBar];
    [_mainTabBar tl_setSelectedIndex:0];

    // 白色半透明背景，用 CAShapeLayer 遮罩挖掉胶囊区域，避免影响胶囊本身的颜色
    _whiteBg = [UIView new];
    _whiteBg.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.5];
    _whiteBg.userInteractionEnabled = NO;
    _whiteBg.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _whiteBg.frame = _mainTabBar.bounds;
    _whiteBgMask = [CAShapeLayer layer];
    _whiteBgMask.fillRule = kCAFillRuleEvenOdd; // 偶奇规则：路径重叠处镂空
    _whiteBg.layer.mask = _whiteBgMask;
    [_mainTabBar insertSubview:_whiteBg atIndex:0];

    // TabBar 贴底部，左右撑满，高度由 sizeThatFits 决定（含安全区）
    // offset(10) 让胶囊稍微往下沉一点，视觉上更贴底
    CGFloat tabHeight = [_mainTabBar sizeThatFits:self.view.bounds.size].height;
    [_mainTabBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.bottom.equalTo(self.view).offset(10);
        make.height.mas_equalTo(tabHeight);
    }];
}

#pragma mark - Layout

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    if (!_whiteBgMask || !_mainTabBar.pillView) return;

    // 外框：whiteBg 整个区域
    UIBezierPath *path = [UIBezierPath bezierPathWithRect:_whiteBg.bounds];

    // 把胶囊的 frame 从 mainTabBar 坐标系转换到 whiteBg 坐标系
    CGRect pillInBg = [_mainTabBar convertRect:_mainTabBar.pillView.frame toView:_whiteBg];
    CGFloat radius = _mainTabBar.pillView.layer.cornerRadius;
    // 挖掉胶囊形状（偶奇规则下，两个路径重叠的地方会镂空）
    UIBezierPath *hole = [UIBezierPath bezierPathWithRoundedRect:pillInBg cornerRadius:radius];
    [path appendPath:hole];

    _whiteBgMask.path = path.CGPath;
    _whiteBgMask.frame = _whiteBg.bounds;
}

#pragma mark - UINavigationControllerDelegate

- (void)navigationController:(UINavigationController *)navigationController
      willShowViewController:(UIViewController *)viewController
                    animated:(BOOL)animated {
    BOOL hide = viewController.hidesBottomBarWhenPushed;
    [UIView animateWithDuration:animated ? 0.25 : 0 animations:^{
        self->_mainTabBar.alpha = hide ? 0 : 1;
        self->_whiteBg.alpha   = hide ? 0 : 1;
    }];
    _mainTabBar.userInteractionEnabled = !hide;
}

#pragma mark - Tab 切换

- (void)switchToIndex:(NSInteger)idx {
    if (idx == _selectedIndex) return;

    UIViewController *fromVC = _childVCs[_selectedIndex];
    UIViewController *toVC   = _childVCs[idx];

    // 正确触发 viewWillDisappear / viewWillAppear 等生命周期
    [fromVC beginAppearanceTransition:NO animated:NO];
    [toVC   beginAppearanceTransition:YES animated:NO];

    fromVC.view.hidden = YES;
    toVC.view.hidden   = NO;

    [fromVC endAppearanceTransition];
    [toVC   endAppearanceTransition];

    _selectedIndex = idx;
    [_mainTabBar tl_setSelectedIndex:idx];
}

@end
