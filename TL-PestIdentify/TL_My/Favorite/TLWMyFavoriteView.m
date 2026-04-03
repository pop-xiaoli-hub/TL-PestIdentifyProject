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
