//
//  TLWToast.m
//  TL-PestIdentify
//

#import "TLWToast.h"
#import <Masonry/Masonry.h>

static NSInteger const kToastTag = 9527;

@implementation TLWToast

+ (void)show:(NSString *)text {
    if (text.length == 0) return;

    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *window = [self _keyWindow];
        if (!window) return;

        // 移除已有 Toast，避免叠加
        UIView *old = [window viewWithTag:kToastTag];
        if (old) [old removeFromSuperview];

        UILabel *toast = [UILabel new];
        toast.tag             = kToastTag;
        toast.text            = text;
        toast.font            = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
        toast.textColor       = [UIColor colorWithRed:0.20 green:0.20 blue:0.20 alpha:1];
        toast.textAlignment   = NSTextAlignmentCenter;
        toast.backgroundColor = UIColor.whiteColor;
        toast.numberOfLines   = 1;
        toast.layer.cornerRadius  = 19;
        toast.layer.masksToBounds = NO;
        toast.layer.shadowColor   = [UIColor colorWithWhite:0 alpha:0.12].CGColor;
        toast.layer.shadowOpacity = 1;
        toast.layer.shadowRadius  = 8;
        toast.layer.shadowOffset  = CGSizeMake(0, 2);
        [window addSubview:toast];

        // 文字宽度自适应，最小 120，最大屏宽 - 80
        CGFloat textWidth = [text sizeWithAttributes:@{NSFontAttributeName: toast.font}].width;
        CGFloat toastWidth = MIN(MAX(textWidth + 40, 120), UIScreen.mainScreen.bounds.size.width - 80);

        [toast mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(window);
            make.centerY.equalTo(window).multipliedBy(1.25);
            make.width.mas_equalTo(toastWidth);
            make.height.mas_equalTo(38);
        }];

        toast.alpha = 0;
        [UIView animateWithDuration:0.25 animations:^{
            toast.alpha = 1;
        } completion:^(BOOL finished) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [UIView animateWithDuration:0.25 animations:^{
                    toast.alpha = 0;
                } completion:^(BOOL done) {
                    [toast removeFromSuperview];
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
