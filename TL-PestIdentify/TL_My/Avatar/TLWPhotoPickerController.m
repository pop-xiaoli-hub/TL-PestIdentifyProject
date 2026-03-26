//
//  TLWPhotoPickerController.m
//  TL-PestIdentify
//

#import "TLWPhotoPickerController.h"
#import "TLWAvatarCropController.h"
#import <Photos/Photos.h>
#import <Masonry/Masonry.h>

static NSString * const kPhotoCellID  = @"TLWPhotoCell";
static CGFloat   const kColumnCount   = 4.0;
static CGFloat   const kCellGap       = 1.0;

#pragma mark - Cell

@interface TLWPhotoCell : UICollectionViewCell
@property (nonatomic, strong) UIImageView        *imageView;
@property (nonatomic, assign) PHImageRequestID    requestID;
@end

@implementation TLWPhotoCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _requestID = PHInvalidImageRequestID;
        _imageView = [[UIImageView alloc] initWithFrame:self.bounds];
        _imageView.contentMode         = UIViewContentModeScaleAspectFill;
        _imageView.clipsToBounds       = YES;
        _imageView.autoresizingMask    = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.contentView addSubview:_imageView];
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    if (_requestID != PHInvalidImageRequestID) {
        [[PHImageManager defaultManager] cancelImageRequest:_requestID];
        _requestID = PHInvalidImageRequestID;
    }
    _imageView.image = nil;
}

@end

@interface TLWPhotoPickerController () <UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic, strong) UICollectionView          *collectionView;
@property (nonatomic, strong) UICollectionViewFlowLayout *layout;
@property (nonatomic, strong) PHFetchResult<PHAsset *>  *assets;
@property (nonatomic, strong) PHCachingImageManager     *imageManager;
@property (nonatomic, strong) UIView                    *navBar;
@property (nonatomic, strong) CAGradientLayer           *navGradient;
@property (nonatomic, assign) CGSize                     thumbnailSize;
@property (nonatomic, assign) BOOL                       didLayout;

@end

@implementation TLWPhotoPickerController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.hidesBottomBarWhenPushed = YES;
    self.view.backgroundColor = UIColor.whiteColor;
    self.view.layer.contents = (__bridge id)[UIImage imageNamed:@"hp_backView"].CGImage;

    _imageManager = [[PHCachingImageManager alloc] init];

    [self setupNavBar];
    [self setupCollectionView];
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
        forCellWithReuseIdentifier:kPhotoCellID];

    [self.view addSubview:_collectionView];
    [_collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_navBar.mas_bottom);
        make.left.right.bottom.equalTo(self.view);
    }];
}

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
    TLWPhotoCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kPhotoCellID
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

    return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView
didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    PHAsset *asset = _assets[(NSUInteger)indexPath.item];

    PHImageRequestOptions *opts = [[PHImageRequestOptions alloc] init];
    opts.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    opts.synchronous  = NO;

    [_imageManager requestImageForAsset:asset
                             targetSize:PHImageManagerMaximumSize
                            contentMode:PHImageContentModeDefault
                                options:opts
                          resultHandler:^(UIImage *result, NSDictionary *info) {
        if (!result) return;
        BOOL isDegraded = [info[PHImageResultIsDegradedKey] boolValue];
        if (isDegraded) return;

        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.onSelectImage) {
                self.onSelectImage(result);
            } else {
                TLWAvatarCropController *cropVC = [[TLWAvatarCropController alloc] initWithImage:result];
                cropVC.delegate = self.cropDelegate;
                [self.navigationController pushViewController:cropVC animated:YES];
            }
        });
    }];
}

#pragma mark - Actions

- (void)onBack {
    [self.navigationController popViewControllerAnimated:YES];
}

@end
