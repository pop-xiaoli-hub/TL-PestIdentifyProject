//
//  TLWMyFavoriteView.m
//  TL-PestIdentify
//

#import "TLWMyFavoriteView.h"
#import <Masonry/Masonry.h>

static CGFloat const kNavOffset = 8;
static CGFloat const kNavHeight = 48;
static CGFloat const kCardGap   = 22;

@interface TLWMyFavoriteView ()

@property (nonatomic, strong, readwrite) UIButton         *backButton;
@property (nonatomic, strong, readwrite) UIButton         *filterButton;
@property (nonatomic, strong, readwrite) UICollectionView *collectionView;

@property (nonatomic, strong) UIImageView *emptyImageView;
@property (nonatomic, strong) UILabel     *emptyLabel;

@end

@implementation TLWMyFavoriteView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        CGFloat safeTop = [UIApplication sharedApplication].windows.firstObject.safeAreaInsets.top;
        CGFloat navTop  = safeTop + kNavOffset;
        CGFloat cardTop = navTop + kNavHeight + kCardGap;

        [self setupBackground];
        [self setupCardWithTop:cardTop];
        [self setupNavBarWithTop:navTop];
        [self setupCollectionViewWithTop:cardTop];
        [self setupEmptyStateWithTop:cardTop];
    }
    return self;
}

#pragma mark - Background

- (void)setupBackground {
    self.layer.contents = (__bridge id)[UIImage imageNamed:@"hp_backView"].CGImage;
}

#pragma mark - 毛玻璃卡片

- (void)setupCardWithTop:(CGFloat)cardTop {
    UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    UIVisualEffectView *cardView = [[UIVisualEffectView alloc] initWithEffect:blur];
    cardView.layer.cornerRadius  = 20;
    cardView.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
    cardView.layer.masksToBounds = YES;

    UIView *overlay = [UIView new];
    overlay.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.65];
    [cardView.contentView addSubview:overlay];
    [overlay mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(cardView.contentView);
    }];

    [self addSubview:cardView];
    [cardView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self);
        make.top.equalTo(self).offset(cardTop);
    }];
}

#pragma mark - 自定义导航栏

- (void)setupNavBarWithTop:(CGFloat)navTop {
    // 返回按钮
    _backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_backButton setImage:[UIImage imageNamed:@"iconBack"] forState:UIControlStateNormal];
    [self addSubview:_backButton];
    [_backButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self).offset(16);
        make.top.equalTo(self).offset(navTop);
        make.width.height.mas_equalTo(kNavHeight);
    }];

    // 标题容器：文字 + liked 图标
    UIView *titleContainer = [UIView new];
    [self addSubview:titleContainer];

    UILabel *titleLabel = [UILabel new];
    titleLabel.text      = @"我的收藏";
    titleLabel.textColor = UIColor.whiteColor;
    titleLabel.font      = [UIFont systemFontOfSize:20 weight:UIFontWeightSemibold];
    [titleContainer addSubview:titleLabel];

    UIImageView *starIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"liked"]];
    starIcon.contentMode = UIViewContentModeScaleAspectFit;
    [titleContainer addSubview:starIcon];

    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.bottom.equalTo(titleContainer);
    }];
    [starIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(titleLabel.mas_right).offset(5);
        make.right.equalTo(titleContainer);
        make.centerY.equalTo(titleLabel);
        make.width.height.mas_equalTo(20);
    }];
    [titleContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self);
        make.centerY.equalTo(_backButton);
    }];

    // 筛选按钮
    _filterButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_filterButton setTitle:@"筛选" forState:UIControlStateNormal];
    [_filterButton setTitleColor:[UIColor colorWithWhite:1 alpha:0.9] forState:UIControlStateNormal];
    _filterButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    // 图标缩小到 16x16
    UIImage *filterOrigin = [UIImage imageNamed:@"filter"];
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(16, 16), NO, 0);
    [filterOrigin drawInRect:CGRectMake(0, 0, 16, 16)];
    UIImage *filterSmall = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    [_filterButton setImage:filterSmall forState:UIControlStateNormal];
    _filterButton.semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;
    _filterButton.imageEdgeInsets = UIEdgeInsetsMake(0, 6, 0, 0);
    [self addSubview:_filterButton];
    [_filterButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self).offset(-16);
        make.centerY.equalTo(_backButton);
        make.height.mas_equalTo(44);
    }];
}

#pragma mark - CollectionView

- (void)setupCollectionViewWithTop:(CGFloat)cardTop {
    CGFloat gap    = 9;
    CGFloat hInset = 14;
    CGFloat cellWidth = (UIScreen.mainScreen.bounds.size.width - hInset * 2 - gap) / 2;

    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.itemSize                = CGSizeMake(cellWidth, cellWidth + 60);
    layout.minimumInteritemSpacing = gap;
    layout.minimumLineSpacing      = 14;
    layout.sectionInset            = UIEdgeInsetsMake(20, hInset, 20, hInset);

    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    _collectionView.backgroundColor = UIColor.clearColor;
    _collectionView.showsVerticalScrollIndicator = NO;
    [self addSubview:_collectionView];
    [_collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self);
        make.top.equalTo(self).offset(cardTop);
    }];
}

#pragma mark - 空态

- (void)setupEmptyStateWithTop:(CGFloat)cardTop {
    _emptyImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"NoRecord"]];
    _emptyImageView.contentMode = UIViewContentModeScaleAspectFit;
    _emptyImageView.hidden = YES;
    [self addSubview:_emptyImageView];
    [_emptyImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self);
        make.top.equalTo(self).offset(cardTop + 100);
        make.width.height.mas_equalTo(120);
    }];

    _emptyLabel = [UILabel new];
    _emptyLabel.text          = @"暂无收藏记录";
    _emptyLabel.textColor     = [UIColor colorWithWhite:0.6 alpha:1];
    _emptyLabel.font          = [UIFont systemFontOfSize:16];
    _emptyLabel.textAlignment = NSTextAlignmentCenter;
    _emptyLabel.hidden = YES;
    [self addSubview:_emptyLabel];
    [_emptyLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self);
        make.top.equalTo(_emptyImageView.mas_bottom).offset(16);
    }];
}

#pragma mark - Public

- (void)showEmpty:(BOOL)empty {
    _emptyImageView.hidden  = !empty;
    _emptyLabel.hidden      = !empty;
    _collectionView.hidden  = empty;
}

@end
