//
//  TLWTabBarItemView.h
//  TL-PestIdentify
//
//  Created by TommyWu on 2026/4/4.
//  职责：声明底部导航栏单项视图接口。
//
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^TLTabSelectionHandler)(NSInteger idx);
@interface TLWTabBarItemView : UIControl
@property (nonatomic, copy) TLTabSelectionHandler selectionHandler;
@property (nonatomic, strong) UIView *circleView;
@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) CAGradientLayer *selectedGradient;
@property (nonatomic, assign) BOOL tl_selected;
- (instancetype)initWithTitle:(NSString *)title icon:(UIImage *)icon;
- (void)tl_applySelected:(BOOL)selected;
@end

NS_ASSUME_NONNULL_END
