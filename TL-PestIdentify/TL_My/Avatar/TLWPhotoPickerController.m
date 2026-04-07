//
//  TLWPhotoPickerController.m
//  TL-PestIdentify
//

#import "TLWPhotoPickerController.h"
#import "TLWAvatarCropController.h"
#import "TLWPhotoCell.h"
#import <Photos/Photos.h>
#import <Masonry/Masonry.h>

static CGFloat   const kColumnCount   = 4.0;
static CGFloat   const kCellGap       = 1.0;

#pragma mark - Controller

@interface TLWPhotoPickerController () <UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic, strong) UICollectionView          *collectionView;
@property (nonatomic, strong) UICollectionViewFlowLayout *layout;
@property (nonatomic, strong) PHFetchResult<PHAsset *>  *assets;
@property (nonatomic, strong) PHCachingImageManager     *imageManager;
@property (nonatomic, strong) UIView                    *navBar;
@property (nonatomic, strong) CAGradientLayer           *navGradient;
@property (nonatomic, assign) CGSize                     thumbnailSize;
@property (nonatomic, assign) BOOL                       didLayout;

// 多选
@property (nonatomic, strong) NSMutableArray<PHAsset *> *selectedAssets;
@property (nonatomic, strong) UIView                    *bottomBar;
@property (nonatomic, strong) UILabel                   *bottomCountLabel;
@property (nonatomic, strong) UIButton                  *bottomDoneBtn;
@property (nonatomic, strong) UILabel                   *bottomBadge;
@property (nonatomic, strong) PHAsset                   *singleSelectedAsset;

@end

@implementation TLWPhotoPickerController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.hidesBottomBarWhenPushed = YES;
    self.view.backgroundColor = UIColor.clearColor;
    UIImageView *bgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bgGradient"]];
    bgView.contentMode = UIViewContentModeScaleAspectFill;
    [self.view addSubview:bgView];
    [bgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];

    if (_maxCount == 0) _maxCount = 1;
    _selectedAssets = [NSMutableArray array];
    _imageManager = [[PHCachingImageManager alloc] init];

    [self setupNavBar];
    [self setupCollectionView];
    if ([self isMultiSelectMode]) {
        [self setupBottomBar];
    }
    [self requestPhotoAccess];
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
    _navGradient.frame = _navBar.bounds;

    if (_didLayout) return;
    _didLayout = YES;

    CGFloat totalGap = kCellGap * (kColumnCount - 1);
    CGFloat cellW    = floor((self.view.bounds.size.width - totalGap) / kColumnCount);
    _layout.itemSize = CGSizeMake(cellW, cellW);
    _thumbnailSize   = CGSizeMake(cellW * UIScreen.mainScreen.scale,
                                   cellW * UIScreen.mainScreen.scale);
}

- (BOOL)isMultiSelectMode {
    return _maxCount > 1;
}

#pragma mark - Setup

- (void)setupNavBar {
    _navBar = [[UIView alloc] init];
    _navBar.backgroundColor = UIColor.clearColor;
    [self.view addSubview:_navBar];
    [_navBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.view);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(44);
    }];

    _navGradient = [CAGradientLayer layer];
    _navGradient.backgroundColor = UIColor.clearColor.CGColor;
    [_navBar.layer insertSublayer:_navGradient atIndex:0];

    UIButton *backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [backBtn setImage:[UIImage imageNamed:@"iconBack"] forState:UIControlStateNormal];
    [backBtn addTarget:self action:@selector(onBack) forControlEvents:UIControlEventTouchUpInside];
    [_navBar addSubview:backBtn];
    [backBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_navBar).offset(16);
        make.bottom.equalTo(_navBar).offset(-8);
        make.width.height.mas_equalTo(44);
    }];

    UILabel *titleLabel = [UILabel new];
    titleLabel.text      = @"相册";
    titleLabel.font      = [UIFont systemFontOfSize:18 weight:UIFontWeightSemibold];
    titleLabel.textColor = UIColor.whiteColor;
    [_navBar addSubview:titleLabel];
    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(_navBar);
        make.centerY.equalTo(backBtn);
    }];
}

- (void)setupCollectionView {
    // 毛玻璃遮罩：仅覆盖图片区域（navBar 下方）
    UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithEffect:blur];
    [self.view addSubview:blurView];
    [blurView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_navBar.mas_bottom);
        make.left.right.bottom.equalTo(self.view);
    }];

    UIView *overlay = [UIView new];
    overlay.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.65];
    [blurView.contentView addSubview:overlay];
    [overlay mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(blurView.contentView);
    }];

    _layout = [[UICollectionViewFlowLayout alloc] init];
    _layout.minimumInteritemSpacing = kCellGap;
    _layout.minimumLineSpacing      = kCellGap;
    _layout.sectionInset            = UIEdgeInsetsZero;
    _layout.itemSize                = CGSizeMake(1, 1);

    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero
                                         collectionViewLayout:_layout];
    _collectionView.dataSource        = self;
    _collectionView.delegate          = self;
    _collectionView.backgroundColor   = UIColor.clearColor;
    [_collectionView registerClass:[TLWPhotoCell class]
        forCellWithReuseIdentifier:kTLWPhotoCellID];

    [self.view addSubview:_collectionView];
    [_collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_navBar.mas_bottom);
        make.left.right.equalTo(self.view);
        if ([self isMultiSelectMode]) {
            make.bottom.equalTo(self.view).offset(-([self bottomBarHeight]));
        } else {
            make.bottom.equalTo(self.view);
        }
    }];
}

- (CGFloat)bottomBarHeight {
    UIWindow *window = UIApplication.sharedApplication.windows.firstObject;
    CGFloat safeBottom = window.safeAreaInsets.bottom;
    return 60 + safeBottom;
}

- (void)setupBottomBar {
    CGFloat barH = [self bottomBarHeight];

    _bottomBar = [[UIView alloc] init];
    _bottomBar.backgroundColor = [UIColor colorWithWhite:0 alpha:0.75];
    [self.view addSubview:_bottomBar];
    [_bottomBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self.view);
        make.height.mas_equalTo(barH);
    }];

    // "已选0张图片"
    _bottomCountLabel = [UILabel new];
    _bottomCountLabel.text      = @"已选0张图片";
    _bottomCountLabel.font      = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    _bottomCountLabel.textColor = UIColor.whiteColor;
    [_bottomBar addSubview:_bottomCountLabel];
    [_bottomCountLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_bottomBar).offset(24);
        make.top.equalTo(_bottomBar).offset(18);
    }];

    // 完成按钮
    _bottomDoneBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _bottomDoneBtn.layer.cornerRadius = 22;
    _bottomDoneBtn.clipsToBounds = YES;
    _bottomDoneBtn.titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
    [_bottomDoneBtn setTitle:@"完成" forState:UIControlStateNormal];
    [_bottomDoneBtn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    [_bottomDoneBtn addTarget:self action:@selector(onDone) forControlEvents:UIControlEventTouchUpInside];

    // 橙色渐变背景
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.colors = @[
        (id)[UIColor colorWithRed:1.0 green:0.82 blue:0.0 alpha:1.0].CGColor,
        (id)[UIColor colorWithRed:1.0 green:0.56 blue:0.13 alpha:1.0].CGColor
    ];
    gradient.startPoint = CGPointMake(0, 0.5);
    gradient.endPoint   = CGPointMake(1, 0.5);
    gradient.frame      = CGRectMake(0, 0, 88, 44);
    gradient.cornerRadius = 22;
    [_bottomDoneBtn.layer insertSublayer:gradient atIndex:0];

    [_bottomBar addSubview:_bottomDoneBtn];
    [_bottomDoneBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(_bottomBar).offset(-24);
        make.top.equalTo(_bottomBar).offset(8);
        make.width.mas_equalTo(88);
        make.height.mas_equalTo(44);
    }];

    // 角标数字
    _bottomBadge = [UILabel new];
    _bottomBadge.backgroundColor    = [UIColor colorWithRed:0.97 green:0.60 blue:0.15 alpha:1.0];
    _bottomBadge.textColor          = UIColor.whiteColor;
    _bottomBadge.font               = [UIFont systemFontOfSize:12 weight:UIFontWeightBold];
    _bottomBadge.textAlignment      = NSTextAlignmentCenter;
    _bottomBadge.layer.cornerRadius = 10;
    _bottomBadge.clipsToBounds      = YES;
    _bottomBadge.hidden             = YES;
    [_bottomBar addSubview:_bottomBadge];
    [_bottomBadge mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(_bottomDoneBtn.mas_left).offset(-2);
        make.centerY.equalTo(_bottomDoneBtn.mas_top).offset(2);
        make.width.height.mas_equalTo(20);
    }];

    [self updateBottomBar];
}

- (void)updateBottomBar {
    NSUInteger count = _selectedAssets.count;
    _bottomCountLabel.text = [NSString stringWithFormat:@"已选%lu张图片", (unsigned long)count];

    if (count > 0) {
        _bottomBadge.hidden = NO;
        _bottomBadge.text   = [NSString stringWithFormat:@"%lu", (unsigned long)count];
    } else {
        _bottomBadge.hidden = YES;
    }
}

#pragma mark - Photo Access

- (void)requestPhotoAccess {
    void (^handleStatus)(PHAuthorizationStatus) = ^(PHAuthorizationStatus s) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (s == PHAuthorizationStatusAuthorized ||
                s == PHAuthorizationStatusLimited) {
                [self loadPhotos];
            }
        });
    };

    PHAuthorizationStatus current;
    if (@available(iOS 14, *)) {
        current = [PHPhotoLibrary authorizationStatusForAccessLevel:PHAccessLevelReadWrite];
    } else {
        current = [PHPhotoLibrary authorizationStatus];
    }

    if (current == PHAuthorizationStatusAuthorized ||
        current == PHAuthorizationStatusLimited) {
        [self loadPhotos];
    } else if (current == PHAuthorizationStatusNotDetermined) {
        if (@available(iOS 14, *)) {
            [PHPhotoLibrary requestAuthorizationForAccessLevel:PHAccessLevelReadWrite
                                                       handler:handleStatus];
        } else {
            [PHPhotoLibrary requestAuthorization:handleStatus];
        }
    }
}

- (void)loadPhotos {
    PHFetchOptions *options = [[PHFetchOptions alloc] init];
    options.sortDescriptors = @[
        [NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]
    ];
    _assets = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:options];
    [_collectionView reloadData];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section {
    return (NSInteger)_assets.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    TLWPhotoCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kTLWPhotoCellID
                                                                   forIndexPath:indexPath];
    PHAsset *asset = _assets[(NSUInteger)indexPath.item];

    PHImageRequestOptions *opts = [[PHImageRequestOptions alloc] init];
    opts.deliveryMode = PHImageRequestOptionsDeliveryModeOpportunistic;
    opts.resizeMode   = PHImageRequestOptionsResizeModeFast;

    cell.requestID = [_imageManager requestImageForAsset:asset
                                              targetSize:_thumbnailSize
                                             contentMode:PHImageContentModeAspectFill
                                                 options:opts
                                           resultHandler:^(UIImage *result, NSDictionary *info) {
        if (result) cell.imageView.image = result;
    }];

    // 多选模式下显示选中状态
    if ([self isMultiSelectMode]) {
        NSUInteger idx = [_selectedAssets indexOfObject:asset];
        [cell setShowsSelectionIndicator:YES];
        [cell configureWithSelectionIndex:(idx != NSNotFound) ? (NSInteger)(idx + 1) : 0
                        useCheckmarkStyle:NO];
    } else {
        BOOL isSelected = (self.singleSelectedAsset && [self.singleSelectedAsset.localIdentifier isEqualToString:asset.localIdentifier]);
        [cell setShowsSelectionIndicator:YES];
        [cell configureWithSelectionIndex:isSelected ? 1 : 0 useCheckmarkStyle:YES];
    }

    return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView
didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    PHAsset *asset = _assets[(NSUInteger)indexPath.item];

    // 单选模式：点击直接回调
    if (![self isMultiSelectMode]) {
        self.singleSelectedAsset = asset;
        [collectionView reloadItemsAtIndexPaths:@[indexPath]];
        [self loadFullImageForAsset:asset completion:^(UIImage *image) {
            if (self.onSelectImage) {
                self.onSelectImage(image);
                [self.navigationController popViewControllerAnimated:YES];
            } else {
                TLWAvatarCropController *cropVC = [[TLWAvatarCropController alloc] initWithImage:image];
                cropVC.delegate = self.cropDelegate;
                [self.navigationController pushViewController:cropVC animated:YES];
            }
        }];
        return;
    }

    // 多选模式：切换选中状态
    NSUInteger idx = [_selectedAssets indexOfObject:asset];
    if (idx != NSNotFound) {
        // 取消选中
        [_selectedAssets removeObjectAtIndex:idx];
    } else {
        // 选中（检查上限）
        if (_selectedAssets.count >= _maxCount) return;
        [_selectedAssets addObject:asset];
    }

    [self updateBottomBar];
    [_collectionView reloadData];
}

#pragma mark - Load Full Image

- (void)loadFullImageForAsset:(PHAsset *)asset completion:(void (^)(UIImage *image))completion {
    PHImageRequestOptions *opts = [[PHImageRequestOptions alloc] init];
    opts.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    opts.synchronous  = NO;

    [_imageManager requestImageForAsset:asset
                             targetSize:PHImageManagerMaximumSize
                            contentMode:PHImageContentModeDefault
                                options:opts
                          resultHandler:^(UIImage *result, NSDictionary *info) {
        BOOL isDegraded = [info[PHImageResultIsDegradedKey] boolValue];
        if (isDegraded) return;
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) completion(result);
        });
    }];
}

#pragma mark - Actions

- (void)onBack {
    if (self.navigationController.viewControllers.firstObject == self &&
        self.navigationController.presentingViewController) {
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)onDone {
    if (_selectedAssets.count == 0) return;

    // 批量加载原图
    dispatch_group_t group = dispatch_group_create();
    NSMutableDictionary<NSNumber *, UIImage *> *imageMap = [NSMutableDictionary dictionary];

    for (NSUInteger i = 0; i < _selectedAssets.count; i++) {
        PHAsset *asset = _selectedAssets[i];
        dispatch_group_enter(group);
        [self loadFullImageForAsset:asset completion:^(UIImage *image) {
            if (image) {
                @synchronized (imageMap) {
                    imageMap[@(i)] = image;
                }
            }
            dispatch_group_leave(group);
        }];
    }

    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        // 按选中顺序排列
        NSMutableArray<UIImage *> *images = [NSMutableArray array];
        for (NSUInteger i = 0; i < self->_selectedAssets.count; i++) {
            UIImage *img = imageMap[@(i)];
            if (img) [images addObject:img];
        }

        if (self.onSelectImages) {
            self.onSelectImages([images copy]);
        }
        if (self.navigationController.viewControllers.firstObject == self &&
            self.navigationController.presentingViewController) {
            [self.navigationController dismissViewControllerAnimated:YES completion:nil];
        } else {
            [self.navigationController popViewControllerAnimated:YES];
        }
    });
}

@end
