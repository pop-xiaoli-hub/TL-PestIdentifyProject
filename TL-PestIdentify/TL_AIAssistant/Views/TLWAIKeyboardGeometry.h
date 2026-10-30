#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
/// 参数均在当前 view 坐标系；浮动键盘不顶起整条 composer。
NS_INLINE CGFloat TLWAIKeyboardOverlap(CGRect keyboard, CGRect bounds) {
    CGRect intersection = CGRectIntersection(keyboard, bounds);
    if (CGRectIsNull(intersection) || CGRectIsEmpty(intersection)) return 0;
    if (CGRectGetMaxY(keyboard) < CGRectGetMaxY(bounds) - 0.5 || CGRectGetWidth(intersection) < CGRectGetWidth(bounds) - 0.5) return 0;
    return MAX(0, CGRectGetHeight(intersection));
}
