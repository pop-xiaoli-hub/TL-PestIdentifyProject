#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
/// 普通正文自然展开；代码与表格仅在横向溢出时滚动，纵向统一交给消息列表。
@interface TLWAIMarkdownBodyView : UIView
@property (nonatomic, weak, nullable) id<UITextViewDelegate> textDelegate;
@property (nonatomic, copy, nullable) dispatch_block_t onInteractionChanged;
@property (nonatomic, readonly) BOOL interactionActive;
/// 停掉已松手的横向减速。手指仍按住时返回 YES，调用方应延后改写外层 offset。
- (BOOL)stopDecelerationForExplicitJump;
/// 仅受选区、局部横滑或可见结构切换保护的块尚未追上最新 source。
@property (nonatomic, readonly) BOOL hasDeferredUpdates;
@property (nonatomic, copy, readonly) NSArray<UITextView *> *textViews;
@property (nonatomic, copy, readonly) NSAttributedString *attributedText;
@property (nonatomic, copy, readonly) NSString *text;
- (void)applySource:(NSString *)source literal:(BOOL)literal selectable:(BOOL)selectable textColor:(UIColor *)color;
- (CGFloat)heightForWidth:(CGFloat)width;
@end
NS_ASSUME_NONNULL_END
