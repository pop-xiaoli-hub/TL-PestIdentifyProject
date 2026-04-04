//
//  TLWTabBar.h
//  TL-PestIdentify
//
//  Created by TommyWu on 2026/4/4.
//  职责：声明组件化底部导航栏接口。
//
#import <UIKit/UIKit.h>
#import "TLWTabBarItemView.h"
NS_ASSUME_NONNULL_BEGIN

typedef void(^TLTabSelectionHandler)(NSInteger idx);
@interface TLWTabBar : UITabBar
@property (nonatomic, copy) TLTabSelectionHandler selectionHandler;
@property (nonatomic, strong) UIView *pillView;
@property (nonatomic, strong) CAGradientLayer *pillGradient;
@property (nonatomic, strong) NSArray<TLWTabBarItemView *> *itemViews;
@property (nonatomic, assign) NSInteger currentIndex;
- (void)tl_setSelectedIndex:(NSInteger)idx;
@end

NS_ASSUME_NONNULL_END
