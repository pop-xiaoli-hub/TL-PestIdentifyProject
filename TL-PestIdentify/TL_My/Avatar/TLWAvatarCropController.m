//
//  TLWAvatarCropController.m
//  TL-PestIdentify
//

#import "TLWAvatarCropController.h"
#import <Masonry/Masonry.h>

static CGFloat const kCropNavHeight    = 44.0;
static CGFloat const kCropBottomHeight = 88.0;

#pragma mark - Overlay View

@interface TLWCropOverlayView : UIView
@property (nonatomic, assign) CGRect circleRect;
@end

@implementation TLWCropOverlayView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) self.backgroundColor = UIColor.clearColor;
    return self;
}

- (void)drawRect:(CGRect)rect {
    CGContextRef ctx = UIGraphicsGetCurrentContext();

    // Dark overlay
    [[UIColor colorWithWhite:0 alpha:0.48] setFill];
    UIRectFill(rect);

    // Clear the circle area
    CGContextSetBlendMode(ctx, kCGBlendModeClear);
    UIBezierPath *circle = [UIBezierPath bezierPathWithOvalInRect:_circleRect];
    [circle fill];

    // White border ring
    CGContextSetBlendMode(ctx, kCGBlendModeNormal);
    circle.lineWidth = 1.5;
    [[UIColor colorWithWhite:1 alpha:0.75] setStroke];
    [circle stroke];
}

@end

#pragma mark - Crop Controller

@interface TLWAvatarCropController () <UIScrollViewDelegate>

@property (nonatomic, strong) UIImage            *originalImage;
@property (nonatomic, strong) UIScrollView       *scrollView;
@property (nonatomic, strong) UIImageView        *imageView;
@property (nonatomic, strong) TLWCropOverlayView *overlayView;
@property (nonatomic, strong) UIView             *navBar;
@property (nonatomic, strong) CAGradientLayer    *navGradient;
@property (nonatomic, strong) UIButton           *backButton;
@property (nonatomic, assign) CGFloat             circleRadius;
@property (nonatomic, assign) CGFloat             circleCenterY;
@property (nonatomic, assign) BOOL                didInitialLayout;
@property (nonatomic, strong) UIButton           *cancelButton;
@property (nonatomic, strong) UIButton           *confirmButton;

@end

@implementation TLWAvatarCropController

#pragma mark - Init

- (instancetype)initWithImage:(UIImage *)image {
    self = [super init];
    if (self) {
        _originalImage = [TLWAvatarCropController fixOrientation:image];
    }
    return self;
}

+ (UIImage *)fixOrientation:(UIImage *)image {
    if (image.imageOrientation == UIImageOrientationUp) return image;
    UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
    [image drawInRect:CGRectMake(0, 0, image.size.width, image.size.height)];
    UIImage *normalized = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return normalized;
}

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.hidesBottomBarWhenPushed = YES;
    self.view.backgroundColor = UIColor.blackColor;

    // 背景图（和 app 整体风格一致）
    UIImageView *bgImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"hp_backView.png"]];
    bgImageView.contentMode = UIViewContentModeScaleAspectFill;
    [self.view addSubview:bgImageView];
    [bgImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];

    // 半透明黑色蒙版
    UIView *dimView = [[UIView alloc] init];
    dimView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    [self.view addSubview:dimView];
    [dimView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];

    [self setupScrollView];
    [self setupOverlay];
    [self setupNavBar];
    [self setupBottomBar];
    [self setActionButtonsEnabled:NO];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    self.navigationController.interactivePopGestureRecognizer.enabled  = YES;
    self.navigationController.interactivePopGestureRecognizer.delegate = nil;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    // Update gradient frame every layout (handles rotation / first appearance)
    _navGradient.frame = _navBar.bounds;

    if (_didInitialLayout) return;
    _didInitialLayout = YES;
    [self setupInitialZoom];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    // 防止从相册点击进入时，上一页触摸事件残留触发“取消/确定”导致秒退。
    [self setActionButtonsEnabled:NO];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self setActionButtonsEnabled:YES];
    });
}

#pragma mark - Setup

- (void)setupScrollView {
    _scrollView = [[UIScrollView alloc] init];
    _scrollView.delegate = self;
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.showsVerticalScrollIndicator   = NO;
    _scrollView.bouncesZoom = YES;
    _scrollView.clipsToBounds = YES;
    if (@available(iOS 11.0, *)) {
        _scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    [self.view addSubview:_scrollView];
    [_scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];

    _imageView = [[UIImageView alloc] initWithImage:_originalImage];
    _imageView.contentMode = UIViewContentModeScaleAspectFill;
    [_scrollView addSubview:_imageView];
}

- (void)setupOverlay {
    _overlayView = [[TLWCropOverlayView alloc] init];
    _overlayView.userInteractionEnabled = NO;
    [self.view addSubview:_overlayView];
    [_overlayView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
}

- (void)setupNavBar {
    _navBar = [[UIView alloc] init];
    _navBar.backgroundColor = UIColor.clearColor;
    [self.view addSubview:_navBar];
    [_navBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.view);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(kCropNavHeight);
    }];

    // Gradient: dark teal → transparent
    _navGradient = [CAGradientLayer layer];
    _navGradient.colors = @[
        (id)[UIColor colorWithRed:0.07 green:0.22 blue:0.20 alpha:0.90].CGColor,
        (id)[UIColor colorWithRed:0.07 green:0.22 blue:0.20 alpha:0.00].CGColor
    ];
    _navGradient.startPoint = CGPointMake(0.5, 0);
    _navGradient.endPoint   = CGPointMake(0.5, 1);
    [_navBar.layer insertSublayer:_navGradient atIndex:0];

    _backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_backButton setImage:[UIImage imageNamed:@"iconBack"] forState:UIControlStateNormal];
    [_backButton addTarget:self action:@selector(onBack) forControlEvents:UIControlEventTouchUpInside];
    [_navBar addSubview:_backButton];
    [_backButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_navBar).offset(16);
        make.bottom.equalTo(_navBar).offset(-8);
        make.width.height.mas_equalTo(44);
    }];

    UILabel *title = [UILabel new];
    title.text      = @"更换头像";
    title.font      = [UIFont systemFontOfSize:18 weight:UIFontWeightSemibold];
    title.textColor = UIColor.whiteColor;
    [_navBar addSubview:title];
    [title mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(_navBar);
        make.centerY.equalTo(_backButton);
    }];
}

- (void)setupBottomBar {
    UIView *bottomBar = [[UIView alloc] init];
    bottomBar.backgroundColor = [UIColor colorWithRed:0.07 green:0.16 blue:0.15 alpha:1.0];
    [self.view addSubview:bottomBar];
    [bottomBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self.view);
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-kCropBottomHeight);
    }];

    // Cancel
    _cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_cancelButton setTitle:@"取消" forState:UIControlStateNormal];
    [_cancelButton setTitleColor:[UIColor colorWithWhite:0.75 alpha:1] forState:UIControlStateNormal];
    _cancelButton.titleLabel.font = [UIFont systemFontOfSize:16];
    [_cancelButton addTarget:self action:@selector(onCancel) forControlEvents:UIControlEventTouchUpInside];
    [bottomBar addSubview:_cancelButton];
    [_cancelButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(bottomBar).offset(40);
        make.top.equalTo(bottomBar).offset(22);
        make.width.mas_equalTo(80);
        make.height.mas_equalTo(44);
    }];

    // Confirm
    _confirmButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_confirmButton setTitle:@"确定" forState:UIControlStateNormal];
    [_confirmButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    _confirmButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    _confirmButton.backgroundColor    = [UIColor colorWithRed:0.97 green:0.60 blue:0.15 alpha:1.0];
    _confirmButton.layer.cornerRadius = 22;
    [_confirmButton addTarget:self action:@selector(onConfirm) forControlEvents:UIControlEventTouchUpInside];
    [bottomBar addSubview:_confirmButton];
    [_confirmButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(bottomBar).offset(-40);
        make.top.equalTo(bottomBar).offset(22);
        make.width.mas_equalTo(100);
        make.height.mas_equalTo(44);
    }];
}

- (void)setActionButtonsEnabled:(BOOL)enabled {
    _backButton.userInteractionEnabled = enabled;
    _cancelButton.userInteractionEnabled = enabled;
    _confirmButton.userInteractionEnabled = enabled;
}

- (void)setupInitialZoom {
    CGFloat screenW = self.view.bounds.size.width;
    CGFloat screenH = self.view.bounds.size.height;
    CGFloat navH    = self.view.safeAreaInsets.top + kCropNavHeight;
    CGFloat botH    = kCropBottomHeight + self.view.safeAreaInsets.bottom;
    CGFloat imageAreaH = screenH - navH - botH;

    // Circle: fills screen width with small padding, centered in the image area
    _circleRadius  = (screenW - 32.0) / 2.0;
    _circleCenterY = navH + imageAreaH / 2.0;

    // Update overlay
    CGRect circleRect = CGRectMake(screenW / 2.0 - _circleRadius,
                                   _circleCenterY - _circleRadius,
                                   _circleRadius * 2,
                                   _circleRadius * 2);
    _overlayView.circleRect = circleRect;
    [_overlayView setNeedsDisplay];

    // Set imageView to fill screen width maintaining aspect ratio
    CGFloat aspect      = _originalImage.size.height / _originalImage.size.width;
    CGFloat imageViewW  = screenW;
    CGFloat imageViewH  = screenW * aspect;

    // Ensure imageView is at least as tall as the visible area
    if (imageViewH < imageAreaH) {
        imageViewH = imageAreaH;
        imageViewW = imageAreaH / aspect;
    }

    _imageView.frame           = CGRectMake(0, 0, imageViewW, imageViewH);
    _scrollView.contentSize    = _imageView.frame.size;

    // Min zoom: image must fill the circle
    CGFloat minZoom = MAX((_circleRadius * 2) / imageViewW,
                          (_circleRadius * 2) / imageViewH);
    _scrollView.minimumZoomScale = minZoom;
    _scrollView.maximumZoomScale = MAX(minZoom * 4.0, 4.0);
    _scrollView.zoomScale        = minZoom;

    // Center: put the image center at the circle center
    CGFloat scaledW = _scrollView.contentSize.width;
    CGFloat scaledH = _scrollView.contentSize.height;
    CGFloat offsetX = MAX(0, (scaledW - screenW) / 2.0);
    CGFloat offsetY = MAX(0, scaledH / 2.0 - _circleCenterY);
    offsetY = MIN(offsetY, MAX(0, scaledH - screenH));
    _scrollView.contentOffset = CGPointMake(offsetX, offsetY);
}

#pragma mark - UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return _imageView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    // Keep imageView centered when content is smaller than the scroll view bounds
    CGFloat boundsW = scrollView.bounds.size.width;
    CGFloat boundsH = scrollView.bounds.size.height;
    CGFloat contentW = scrollView.contentSize.width;
    CGFloat contentH = scrollView.contentSize.height;
    CGFloat offsetX = MAX(0, (boundsW - contentW) / 2.0);
    CGFloat offsetY = MAX(0, (boundsH - contentH) / 2.0);
    _imageView.center = CGPointMake(contentW / 2.0 + offsetX,
                                    contentH / 2.0 + offsetY);
}

#pragma mark - Actions

- (void)onBack {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)onCancel {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)onConfirm {
    UIImage *cropped = [self croppedImage];
    [self.delegate avatarCropController:self didConfirmImage:cropped];
    // 导航由 delegate (TLWEditProfileController) 统一处理
}

#pragma mark - Crop

- (UIImage *)croppedImage {
    CGFloat screenW = self.view.bounds.size.width;

    // Circle rect in the scroll view's bounds coordinate space
    CGRect circleRectInView = CGRectMake(screenW / 2.0 - _circleRadius,
                                         _circleCenterY - _circleRadius,
                                         _circleRadius * 2,
                                         _circleRadius * 2);

    CGFloat zoomScale     = _scrollView.zoomScale;
    CGPoint contentOffset = _scrollView.contentOffset;

    // Convert to imageView bounds coordinate space
    // (use bounds, not frame, to get the unscaled size)
    CGFloat ivX = (circleRectInView.origin.x    + contentOffset.x) / zoomScale;
    CGFloat ivY = (circleRectInView.origin.y    + contentOffset.y) / zoomScale;
    CGFloat ivW =  circleRectInView.size.width  / zoomScale;
    CGFloat ivH =  circleRectInView.size.height / zoomScale;
    CGRect cropInImageView = CGRectMake(ivX, ivY, ivW, ivH);

    // Scale from imageView points → image pixels
    CGFloat scaleX   = _originalImage.size.width  / _imageView.bounds.size.width;
    CGFloat scaleY   = _originalImage.size.height / _imageView.bounds.size.height;
    CGFloat imgScale = _originalImage.scale;

    CGRect cropInPixels = CGRectMake(cropInImageView.origin.x    * scaleX * imgScale,
                                     cropInImageView.origin.y    * scaleY * imgScale,
                                     cropInImageView.size.width  * scaleX * imgScale,
                                     cropInImageView.size.height * scaleY * imgScale);

    // Clamp to image bounds
    CGRect imageBounds = CGRectMake(0, 0,
                                    _originalImage.size.width  * imgScale,
                                    _originalImage.size.height * imgScale);
    cropInPixels = CGRectIntersection(cropInPixels, imageBounds);

    CGImageRef cgCropped = CGImageCreateWithImageInRect(_originalImage.CGImage, cropInPixels);
    UIImage *result = [UIImage imageWithCGImage:cgCropped
                                          scale:imgScale
                                    orientation:UIImageOrientationUp];
    CGImageRelease(cgCropped);
    return result;
}

@end
