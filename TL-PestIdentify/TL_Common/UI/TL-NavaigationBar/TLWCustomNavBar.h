//
//  TLWCustomNavBar.h
//  TL-PestIdentify
//
//  Created by Northern Lights on 2026/4/4.
//  职责：声明组件化顶部导航栏接口。
//
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TLWCustomNavBar : UIView

/// 返回按钮
@property (nonatomic, strong, readonly) UIButton *backButton;
/// 标题 Label
@property (nonatomic, strong, readonly) UILabel  *titleLabel;
/// 标题左侧图标（可选，默认隐藏）
@property (nonatomic, strong, readonly) UIImageView *titleIcon;
/// 右侧按钮（可选，默认隐藏）
@property (nonatomic, strong, readonly) UIButton *rightButton;

/// 导航栏整体高度（safeAreaTop 到底部），只读，用于外部布局参考
@property (nonatomic, assign, readonly) CGFloat barHeight;

/// 纯标题
- (instancetype)initWithTitle:(NSString *)title;

/// 标题 + 标题图标
- (instancetype)initWithTitle:(NSString *)title iconName:(nullable NSString *)iconName;

/// 配置右侧文字按钮（如"筛选"）
- (void)setRightButtonTitle:(NSString *)title iconName:(nullable NSString *)iconName;

@end

NS_ASSUME_NONNULL_END
