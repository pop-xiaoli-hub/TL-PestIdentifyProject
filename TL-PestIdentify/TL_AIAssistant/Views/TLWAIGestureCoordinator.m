#import "TLWAIGestureCoordinator.h"
#import <math.h>
#import "TLWAIPanSplitter.h"
@interface TLWAIGestureCoordinator ()
@property (nonatomic, weak) UIViewController *controller;
@property (nonatomic, weak) UIGestureRecognizer *edgePop;
@property (nonatomic, weak) UIGestureRecognizer *contentPop;
@property (nonatomic, weak) id<UIGestureRecognizerDelegate> oldEdgeDelegate;
@property (nonatomic, weak) id<UIGestureRecognizerDelegate> oldContentDelegate;
@property (nonatomic, assign) BOOL contentPopWasEnabled;
@property (nonatomic, strong) NSMapTable<UIGestureRecognizer *, UIView *> *touchViews;
@property (nonatomic, strong) NSMapTable<UITextView *, NSNumber *> *innerBounces;
@property (nonatomic, weak) UITableView *outerTable;
@property (nonatomic, weak) UITextView *activeInner;
@property (nonatomic, assign) CGFloat innerStartY;
@property (nonatomic, assign) CGFloat outerStartY;
@property (nonatomic, assign) CGFloat startTranslationY;
@property (nonatomic, assign) BOOL applyingOffsets;
@end
@implementation TLWAIGestureCoordinator
- (void)installForController:(UIViewController *)controller {
    if (self.controller == controller) {
        // Base.viewWillAppear 会清空 edge delegate；取消交互返回后重新接管，但不重置正文 pan。
        self.edgePop.delegate = self;
        return;
    }
    [self uninstall];
    self.controller = controller;
    self.touchViews = [NSMapTable weakToWeakObjectsMapTable];
    UINavigationController *navigation = controller.navigationController;
    self.edgePop = navigation.interactivePopGestureRecognizer;
    self.oldEdgeDelegate = self.edgePop.delegate;
    self.edgePop.delegate = self;
    if (@available(iOS 26.0, *)) {
        self.contentPop = navigation.interactiveContentPopGestureRecognizer;
        self.oldContentDelegate = self.contentPop.delegate;
        self.contentPopWasEnabled = self.contentPop.enabled;
        self.contentPop.delegate = self;
        // 正文、代码块和图片的横向拖动不触发返回；保留系统左边缘返回。
        self.contentPop.enabled = NO;
    }
}
- (void)uninstall {
    if (self.edgePop.delegate == self) self.edgePop.delegate = self.oldEdgeDelegate;
    if (self.contentPop.delegate == self) {
        self.contentPop.delegate = self.oldContentDelegate;
        self.contentPop.enabled = self.contentPopWasEnabled;
    }
    self.edgePop = nil; self.contentPop = nil;
    self.oldEdgeDelegate = nil; self.oldContentDelegate = nil;
    self.controller = nil; self.touchViews = nil;
    for (UITextView *inner in self.innerBounces) {
        [inner.panGestureRecognizer removeTarget:self action:@selector(tl_innerPan:)];
        inner.bounces = [[self.innerBounces objectForKey:inner] boolValue];
        if ([inner isKindOfClass:TLWAIRelayTextView.class]) ((TLWAIRelayTextView *)inner).relayCoordinator = nil;
    }
    self.innerBounces = nil; self.activeInner = nil; self.outerTable = nil;
}
- (void)registerTextView:(UITextView *)inner outerTable:(UITableView *)outer {
    if (!self.innerBounces) self.innerBounces = [NSMapTable weakToStrongObjectsMapTable];
    if (![self.innerBounces objectForKey:inner]) {
        [self.innerBounces setObject:@(inner.bounces) forKey:inner];
        [inner.panGestureRecognizer addTarget:self action:@selector(tl_innerPan:)];
    }
    self.outerTable = outer;
    inner.bounces = NO; // 内层不吞边界回弹；越界位移交给外层。
    if ([inner isKindOfClass:TLWAIRelayTextView.class]) ((TLWAIRelayTextView *)inner).relayCoordinator = self;
    if ([outer isKindOfClass:TLWAIRelayTableView.class]) ((TLWAIRelayTableView *)outer).relayCoordinator = self;
}
- (BOOL)allowsSimultaneous:(UIGestureRecognizer *)gesture other:(UIGestureRecognizer *)other {
    UIGestureRecognizer *outer = self.outerTable.panGestureRecognizer;
    UIGestureRecognizer *candidate = gesture == outer ? other : (other == outer ? gesture : nil);
    if (![candidate.view isKindOfClass:UITextView.class]) return NO;
    UITextView *inner = (UITextView *)candidate.view;
    return candidate == inner.panGestureRecognizer && [self.innerBounces objectForKey:inner] &&
           inner.scrollEnabled && inner.selectedRange.length == 0;
}
- (BOOL)relaying { return self.activeInner != nil; }
- (void)tl_innerPan:(UIPanGestureRecognizer *)pan {
    UITextView *inner = (UITextView *)pan.view;
    if (pan.state == UIGestureRecognizerStateBegan && inner.selectedRange.length == 0) {
        self.activeInner = inner;
        self.innerStartY = inner.contentOffset.y;
        self.outerStartY = self.outerTable.contentOffset.y;
        self.startTranslationY = [pan translationInView:self.outerTable].y;
    }
    if (pan.state == UIGestureRecognizerStateChanged) [self correctRelayOffsets];
    if (pan.state == UIGestureRecognizerStateEnded || pan.state == UIGestureRecognizerStateCancelled ||
        pan.state == UIGestureRecognizerStateFailed) {
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            if (weakSelf.activeInner == inner && pan.state != UIGestureRecognizerStateBegan &&
                pan.state != UIGestureRecognizerStateChanged) weakSelf.activeInner = nil;
        });
    }
}
- (void)correctRelayOffsets {
    UITextView *inner = self.activeInner;
    UITableView *outer = self.outerTable;
    if (!inner || !outer || self.applyingOffsets ||
        (inner.panGestureRecognizer.state != UIGestureRecognizerStateBegan &&
         inner.panGestureRecognizer.state != UIGestureRecognizerStateChanged)) return;
    CGFloat innerMin = -inner.adjustedContentInset.top;
    CGFloat innerMax = MAX(innerMin, inner.contentSize.height - inner.bounds.size.height + inner.adjustedContentInset.bottom);
    CGFloat outerMin = -outer.adjustedContentInset.top;
    CGFloat outerMax = MAX(outerMin, outer.contentSize.height - outer.bounds.size.height + outer.adjustedContentInset.bottom);
    CGFloat dy = [inner.panGestureRecognizer translationInView:outer].y - self.startTranslationY;
    TLWAIPanSplit split = TLWAISplitPan(self.innerStartY, self.outerStartY, dy, innerMin, innerMax, outerMin, outerMax);
    self.applyingOffsets = YES;
    if (fabs(inner.contentOffset.y - split.innerOffset) > 0.01) inner.contentOffset = CGPointMake(inner.contentOffset.x, split.innerOffset);
    if (fabs(outer.contentOffset.y - split.outerOffset) > 0.01) outer.contentOffset = CGPointMake(outer.contentOffset.x, split.outerOffset);
    // 提交本次位移，而非一直从手势起点重算；反向时内层立即重新优先消费。
    self.innerStartY = split.innerOffset;
    self.outerStartY = split.outerOffset;
    self.startTranslationY += dy;
    self.applyingOffsets = NO;
}
- (void)constrainOuterTarget:(inout CGPoint *)target velocity:(CGPoint)velocity {
    UITextView *inner = self.activeInner;
    if (!inner) return;
    CGFloat minimum = -inner.adjustedContentInset.top;
    CGFloat maximum = MAX(minimum, inner.contentSize.height - inner.bounds.size.height + inner.adjustedContentInset.bottom);
    BOOL canConsume = (velocity.y > 0 && inner.contentOffset.y < maximum - 0.5) ||
                      (velocity.y < 0 && inner.contentOffset.y > minimum + 0.5);
    if (canConsume) target->y = self.outerTable.contentOffset.y;
}
+ (BOOL)shouldBlockPopForView:(UIView *)view velocity:(CGPoint)velocity {
    for (UIView *surface = view; surface; surface = surface.superview) {
        if ([surface isKindOfClass:UITextView.class] && ((UITextView *)surface).selectedRange.length > 0) return YES;
        if (![surface isKindOfClass:UIScrollView.class] || fabs(velocity.x) <= fabs(velocity.y)) continue;
        UIScrollView *scroll = (UIScrollView *)surface;
        if (!scroll.scrollEnabled) continue;
        CGFloat minX = -scroll.adjustedContentInset.left;
        CGFloat maxX = MAX(minX, scroll.contentSize.width - scroll.bounds.size.width + scroll.adjustedContentInset.right);
        if (maxX <= minX + 0.5) continue;
        if ((velocity.x > 0 && scroll.contentOffset.x > minX + 0.5) ||
            (velocity.x < 0 && scroll.contentOffset.x < maxX - 0.5)) return YES;
    }
    return NO;
}
- (id<UIGestureRecognizerDelegate>)tl_original:(UIGestureRecognizer *)gesture {
    return gesture == self.edgePop ? self.oldEdgeDelegate : self.oldContentDelegate;
}
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gesture {
    if (gesture == self.contentPop) return NO;
    UINavigationController *navigation = self.controller.navigationController;
    if (navigation.topViewController != self.controller || navigation.viewControllers.count <= 1 || navigation.transitionCoordinator) return NO;
    CGPoint velocity = CGPointZero;
    if ([gesture respondsToSelector:@selector(velocityInView:)]) velocity = [(UIPanGestureRecognizer *)gesture velocityInView:self.controller.view];
    UIView *touched = [self.touchViews objectForKey:gesture];
    if (!touched) touched = [self.controller.view hitTest:[gesture locationInView:self.controller.view] withEvent:nil];
    if ([self.class shouldBlockPopForView:touched velocity:velocity]) return NO;
    id<UIGestureRecognizerDelegate> original = [self tl_original:gesture];
    return ![original respondsToSelector:_cmd] || [original gestureRecognizerShouldBegin:gesture];
}
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gesture shouldReceiveTouch:(UITouch *)touch {
    if (touch.view) [self.touchViews setObject:touch.view forKey:gesture];
    id<UIGestureRecognizerDelegate> original = [self tl_original:gesture];
    return ![original respondsToSelector:_cmd] || [original gestureRecognizer:gesture shouldReceiveTouch:touch];
}
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gesture shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)other {
    id<UIGestureRecognizerDelegate> original = [self tl_original:gesture];
    return [original respondsToSelector:_cmd] && [original gestureRecognizer:gesture shouldRecognizeSimultaneouslyWithGestureRecognizer:other];
}
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gesture shouldRequireFailureOfGestureRecognizer:(UIGestureRecognizer *)other {
    id<UIGestureRecognizerDelegate> original = [self tl_original:gesture];
    return [original respondsToSelector:_cmd] && [original gestureRecognizer:gesture shouldRequireFailureOfGestureRecognizer:other];
}
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gesture shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer *)other {
    id<UIGestureRecognizerDelegate> original = [self tl_original:gesture];
    return [original respondsToSelector:_cmd] && [original gestureRecognizer:gesture shouldBeRequiredToFailByGestureRecognizer:other];
}
@end
@implementation TLWAIRelayTextView
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gesture shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)other {
    return [self.relayCoordinator allowsSimultaneous:gesture other:other];
}
@end
@implementation TLWAIRelayTableView
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gesture shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)other {
    return [self.relayCoordinator allowsSimultaneous:gesture other:other];
}
@end
@implementation TLWAIHorizontalScrollView
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gesture {
    if (gesture == self.panGestureRecognizer) {
        CGPoint velocity = [self.panGestureRecognizer velocityInView:self];
        // 起手速度可能接近 0。只有明显更快的纵向才交给外层，避免细代码行上的横滑被列表抢走。
        if (fabs(velocity.y) > fabs(velocity.x) * 1.2 && fabs(velocity.y) > 40) return NO;
    }
    return [super gestureRecognizerShouldBegin:gesture];
}
@end
