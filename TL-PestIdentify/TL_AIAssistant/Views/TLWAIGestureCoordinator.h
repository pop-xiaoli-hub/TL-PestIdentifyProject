#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN
/// 助手页局部仲裁，不修改 UIScrollView.panGestureRecognizer.delegate。
@interface TLWAIGestureCoordinator : NSObject <UIGestureRecognizerDelegate>
/// 本页保留左边缘返回，禁用 iOS 26+ 的 content pop；离页恢复原设置。
- (void)installForController:(UIViewController *)controller;
/// 离页恢复仍由自身持有的 recognizer 的 delegate 与 enabled 状态。
- (void)uninstall;
/// 命中可消费横向位移的滚动面或非空文本选区时，pop 必须失败。
+ (BOOL)shouldBlockPopForView:(UIView *)view velocity:(CGPoint)velocity;
/// 将有界文本卡的原生 pan 与外层 pan 纳入像素接力；不替换其 delegate。
- (void)registerTextView:(UITextView *)textView outerTable:(UITableView *)tableView;
/// 原生 didScroll 后按相邻输入位移修正 offset；修正期间禁止递归跟随。
- (void)correctRelayOffsets;
/// 内层仍可消费惯性时，外层不得同时启动重复惯性。
- (void)constrainOuterTarget:(inout CGPoint *)target velocity:(CGPoint)velocity;
@property (nonatomic, assign, readonly) BOOL relaying;
@property (nonatomic, assign, readonly) BOOL applyingOffsets;
/// 仅允许已登记文本卡 pan 与外层 pan 同时识别。
- (BOOL)allowsSimultaneous:(UIGestureRecognizer *)gesture other:(UIGestureRecognizer *)other;
@end
/// 保留 UIScrollView 自身作为原生 pan delegate，仅覆盖本页同时识别规则。
@interface TLWAIRelayTextView : UITextView
@property (nonatomic, weak, nullable) TLWAIGestureCoordinator *relayCoordinator;
@end
@interface TLWAIRelayTableView : UITableView
@property (nonatomic, weak, nullable) TLWAIGestureCoordinator *relayCoordinator;
@end
/// 横向图片条起手为纵向时不参与竞争。
@interface TLWAIHorizontalScrollView : UIScrollView
@end
NS_ASSUME_NONNULL_END
