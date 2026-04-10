#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TLWLoadingIndicator : NSObject

/// 在指定 view 居中显示旋转 loading（默认 50x50）
+ (void)showInView:(UIView *)view;

/// 在指定 view 显示旋转 loading，可自定义尺寸和偏移
+ (void)showInView:(UIView *)view size:(CGFloat)size offset:(CGPoint)offset;

/// 在指定 view 顶部固定位置显示旋转 loading（用 Masonry 约束，不依赖 bounds）
+ (void)showAtTopOfView:(UIView *)view topOffset:(CGFloat)topOffset size:(CGFloat)size;

/// 在滚动视图的下拉刷新区域显示旋转 loading，优先贴近 refreshControl 底部
+ (void)showPullToRefreshInScrollView:(UIScrollView *)scrollView size:(CGFloat)size;

/// 隐藏并移除指定 view 上的 loading
+ (void)hideInView:(UIView *)view;

/// 创建一个旋转 loading 的 UIView（用于 tableFooterView 等场景）
+ (UIView *)footerLoadingViewWithWidth:(CGFloat)width height:(CGFloat)height;

/// 停止 footer loading view 上的动画
+ (void)stopFooterLoadingView:(UIView *)view;

@end

NS_ASSUME_NONNULL_END
