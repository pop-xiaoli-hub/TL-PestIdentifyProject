//
//  TLWToast.m
//  TL-PestIdentify
//

#import "TLWToast.h"
#import <Masonry/Masonry.h>

static NSInteger const kOverlayTag = 9526;
static NSInteger const kToastTag   = 9527;

@implementation TLWToast

+ (void)show:(NSString *)text {
    if (text.length == 0) return;

    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *window = [self _keyWindow];
        if (!window) return;

        // 移除已有的
        UIView *oldOverlay = [window viewWithTag:kOverlayTag];
        if (oldOverlay) [oldOverlay removeFromSuperview];

        // 半透明遮罩
        UIView *overlay = [UIView new];
        overlay.tag             = kOverlayTag;
        overlay.backgroundColor = [UIColor colorWithWhite:0 alpha:0.25];
        overlay.userInteractionEnabled = NO;
        [window addSubview:overlay];
        [overlay mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(window);
        }];

        // Toast 主体 — 居中、更大
        UILabel *toast = [UILabel new];
        toast.tag             = kToastTag;
        toast.text            = text;
        toast.font            = [UIFont systemFontOfSize:17 weight:UIFontWeightMedium];
        toast.textColor       = [UIColor colorWithRed:0.20 green:0.20 blue:0.20 alpha:1];
        toast.textAlignment   = NSTextAlignmentCenter;
        toast.backgroundColor = UIColor.whiteColor;
        toast.numberOfLines   = 0;
        toast.layer.cornerRadius  = 16;
        toast.layer.masksToBounds = YES;
        [overlay addSubview:toast];

        // 文字宽度自适应，最小 160，最大屏宽 - 80
        CGFloat textWidth = [text sizeWithAttributes:@{NSFontAttributeName: toast.font}].width;
        CGFloat toastWidth = MIN(MAX(textWidth + 56, 160), UIScreen.mainScreen.bounds.size.width - 80);

        [toast mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(overlay);
            make.width.mas_equalTo(toastWidth);
            make.height.mas_equalTo(52);
        }];

        // 动画
        overlay.alpha = 0;
        [UIView animateWithDuration:0.2 animations:^{
            overlay.alpha = 1;
        } completion:^(BOOL finished) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [UIView animateWithDuration:0.25 animations:^{
                    overlay.alpha = 0;
                } completion:^(BOOL done) {
                    [overlay removeFromSuperview];
                }];
            });
        }];
    });
}

+ (UIWindow *)_keyWindow {
    if (@available(iOS 13.0, *)) {
        for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
            if (scene.activationState != UISceneActivationStateForegroundActive) continue;
            if (![scene isKindOfClass:[UIWindowScene class]]) continue;
            for (UIWindow *w in ((UIWindowScene *)scene).windows) {
                if (w.isKeyWindow) return w;
            }
        }
    }
    return UIApplication.sharedApplication.windows.firstObject;
}

@end
