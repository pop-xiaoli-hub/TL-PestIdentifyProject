#import "TLWLoadingIndicator.h"
#import <Masonry/Masonry.h>

static const NSInteger kTLWLoadingIndicatorTag = 88881;
static const NSInteger kTLWLoadingSpinnerTag = 88882;
static NSString * const kTLWRotationAnimationKey = @"tl_loading_rotate";

@implementation TLWLoadingIndicator

+ (void)showInView:(UIView *)view {
    [self showInView:view size:50 offset:CGPointZero];
}

+ (void)showInView:(UIView *)view size:(CGFloat)size offset:(CGPoint)offset {
    if (!view) return;

    // 避免重复添加
    UIView *existing = [self _loadingIndicatorInView:view];
    if (existing) {
        existing.hidden = NO;
        [existing.superview bringSubviewToFront:existing];
        [self _addRotationToLayer:[self _spinnerLayerInIndicator:existing]];
        return;
    }

    CGFloat containerSize = MAX(size + 56.0, 112.0);
    UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, containerSize, containerSize)];
    container.tag = kTLWLoadingIndicatorTag;
    container.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.97];
    container.layer.cornerRadius = 24.0;
    container.layer.shadowColor = [UIColor colorWithRed:0.58 green:0.73 blue:0.74 alpha:0.35].CGColor;
    container.layer.shadowOpacity = 1.0;
    container.layer.shadowOffset = CGSizeMake(0, 12);
    container.layer.shadowRadius = 22.0;
    container.userInteractionEnabled = NO;
    container.center = CGPointMake(view.bounds.size.width / 2.0 + offset.x,
                                   view.bounds.size.height / 2.0 + offset.y);
    container.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin |
                                 UIViewAutoresizingFlexibleRightMargin |
                                 UIViewAutoresizingFlexibleTopMargin |
                                 UIViewAutoresizingFlexibleBottomMargin;

    UIImage *loadingImage = [UIImage imageNamed:@"Ip_load.png"];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:loadingImage];
    imageView.tag = kTLWLoadingSpinnerTag;
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.bounds = CGRectMake(0, 0, size, size);
    imageView.center = CGPointMake(containerSize / 2.0, containerSize / 2.0);
    imageView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin |
                                 UIViewAutoresizingFlexibleRightMargin |
                                 UIViewAutoresizingFlexibleTopMargin |
                                 UIViewAutoresizingFlexibleBottomMargin;
    [container addSubview:imageView];
    [view addSubview:container];
    [view bringSubviewToFront:container];

    [self _addRotationToLayer:imageView.layer];
}

+ (void)showPullToRefreshInScrollView:(UIScrollView *)scrollView size:(CGFloat)size {
    if (!scrollView) return;

    UIRefreshControl *refreshControl = scrollView.refreshControl;
    if (!refreshControl || !refreshControl.refreshing) {
        [self showInView:scrollView
                    size:size
                  offset:CGPointMake(0, -scrollView.bounds.size.height / 2.0 + size)];
        return;
    }

    UIView *existing = [self _loadingIndicatorInView:scrollView];
    if (existing && existing.superview != refreshControl) {
        [existing.layer removeAnimationForKey:kTLWRotationAnimationKey];
        [existing removeFromSuperview];
        existing = nil;
    }
    if (existing) {
        existing.hidden = NO;
        [refreshControl bringSubviewToFront:existing];
        [self _addRotationToLayer:existing.layer];
        return;
    }

    UIImage *loadingImage = [UIImage imageNamed:@"Ip_load.png"];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:loadingImage];
    imageView.tag = kTLWLoadingIndicatorTag;
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.userInteractionEnabled = NO;
    [refreshControl addSubview:imageView];
    [imageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(refreshControl);
        make.bottom.equalTo(refreshControl.mas_bottom).offset(-6);
        make.width.height.mas_equalTo(size);
    }];
    [refreshControl bringSubviewToFront:imageView];

    [self _addRotationToLayer:imageView.layer];
}

+ (void)hideInView:(UIView *)view {
    if (!view) return;
    UIView *existing = [self _loadingIndicatorInView:view];
    if (existing) {
        [[self _spinnerLayerInIndicator:existing] removeAnimationForKey:kTLWRotationAnimationKey];
        [existing removeFromSuperview];
    }
}

+ (UIView *)footerLoadingViewWithWidth:(CGFloat)width height:(CGFloat)height {
    UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
    container.backgroundColor = [UIColor clearColor];

    CGFloat size = 30;
    UIImage *loadingImage = [UIImage imageNamed:@"Ip_load.png"];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:loadingImage];
    imageView.tag = kTLWLoadingIndicatorTag;
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.bounds = CGRectMake(0, 0, size, size);
    imageView.center = CGPointMake(width / 2.0, height / 2.0);
    imageView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin |
                                 UIViewAutoresizingFlexibleRightMargin |
                                 UIViewAutoresizingFlexibleTopMargin |
                                 UIViewAutoresizingFlexibleBottomMargin;
    [container addSubview:imageView];

    [self _addRotationToLayer:imageView.layer];

    return container;
}

+ (void)showAtTopOfView:(UIView *)view topOffset:(CGFloat)topOffset size:(CGFloat)size {
    if (!view) return;
    UIView *existing = [view viewWithTag:kTLWLoadingIndicatorTag];
    if (existing) {
        existing.hidden = NO;
        [view bringSubviewToFront:existing];
        [self _addRotationToLayer:existing.layer];
        return;
    }
    UIImage *loadingImage = [UIImage imageNamed:@"Ip_load.png"];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:loadingImage];
    imageView.tag = kTLWLoadingIndicatorTag;
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    [view addSubview:imageView];
    [imageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(view).offset(topOffset);
        make.centerX.equalTo(view);
        make.width.height.mas_equalTo(size);
    }];
    [self _addRotationToLayer:imageView.layer];
}

+ (void)stopFooterLoadingView:(UIView *)view {
    if (!view) return;
    UIView *imageView = [view viewWithTag:kTLWLoadingIndicatorTag];
    if (imageView) {
        [imageView.layer removeAnimationForKey:kTLWRotationAnimationKey];
    }
}

#pragma mark - Private

+ (UIView *)_loadingIndicatorInView:(UIView *)view {
    if (!view) return nil;

    UIView *existing = [view viewWithTag:kTLWLoadingIndicatorTag];
    if (existing) {
        return existing;
    }

    if ([view isKindOfClass:[UIScrollView class]]) {
        UIRefreshControl *refreshControl = ((UIScrollView *)view).refreshControl;
        if (refreshControl) {
            return [refreshControl viewWithTag:kTLWLoadingIndicatorTag];
        }
    }

    return nil;
}

+ (void)_addRotationToLayer:(CALayer *)layer {
    if (!layer) return;
    [layer removeAnimationForKey:kTLWRotationAnimationKey];
    CABasicAnimation *rotation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotation.fromValue = @(0);
    rotation.toValue = @(M_PI * 2);
    rotation.duration = 1.0;
    rotation.repeatCount = HUGE_VALF;
    rotation.removedOnCompletion = NO;
    [layer addAnimation:rotation forKey:kTLWRotationAnimationKey];
}

+ (CALayer *)_spinnerLayerInIndicator:(UIView *)indicator {
    if (!indicator) return nil;
    if ([indicator isKindOfClass:[UIImageView class]]) {
        return indicator.layer;
    }
    UIView *spinnerView = [indicator viewWithTag:kTLWLoadingSpinnerTag];
    return spinnerView.layer ?: indicator.layer;
}

@end
