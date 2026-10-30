#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>
typedef struct {
    CGFloat innerOffset;
    CGFloat outerOffset;
    CGFloat outerTranslation;
    CGFloat unconsumedTranslation;
} TLWAIPanSplit;
/// fingerDY 向下为正；内容随手指向下移动 +12，对应 contentOffset 减12。所有范围均为 offset 范围。
NS_INLINE TLWAIPanSplit TLWAISplitPan(CGFloat innerY, CGFloat outerY, CGFloat fingerDY, CGFloat innerMin, CGFloat innerMax, CGFloat outerMin, CGFloat outerMax) {
    innerMax = MAX(innerMin, innerMax); outerMax = MAX(outerMin, outerMax);
    innerY = MIN(innerMax, MAX(innerMin, innerY)); outerY = MIN(outerMax, MAX(outerMin, outerY));
    CGFloat inner = MIN(innerMax, MAX(innerMin, innerY - fingerDY));
    CGFloat leftover = fingerDY - (innerY - inner);
    CGFloat outer = MIN(outerMax, MAX(outerMin, outerY - leftover));
    TLWAIPanSplit result = {inner, outer, outerY - outer, leftover - (outerY - outer)};
    return result;
}
