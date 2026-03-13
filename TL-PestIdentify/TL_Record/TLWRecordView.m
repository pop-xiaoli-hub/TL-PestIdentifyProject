//
//  TLWRecordView.m
//  TL-PestIdentify
//
//  Created by Tommy on 2026/3/13.
//

#import "TLWRecordView.h"
#import <Masonry/Masonry.h>

/// 导航按钮距状态栏底部的间距
static CGFloat const kNavOffset  = 8;
/// 导航按钮高度
static CGFloat const kNavHeight  = 48;
/// 导航底部到毛玻璃卡片顶部的间距
static CGFloat const kCardGap    = 22;

@interface TLWRecordView ()
@property (nonatomic, strong) UIButton *backButton;
@property (nonatomic, strong) UIButton *filterButton;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UILabel *emptyLabel;
@end

@implementation TLWRecordView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // 安全区高度需从 window 动态取，避免刘海屏/灵动岛硬编码错位
        CGFloat safeTop  = [UIApplication sharedApplication].windows.firstObject.safeAreaInsets.top;
        CGFloat navTop   = safeTop + kNavOffset;
        CGFloat cardTop  = navTop + kNavHeight + kCardGap;

        [self tl_setupBackground];
        [self tl_setupCardWithTop:cardTop];
        [self tl_setupNavBarWithTop:navTop];
        [self tl_setupCollectionViewWithTop:cardTop];
        [self tl_setupEmptyLabelWithTop:cardTop];
    }
    return self;
}

#pragma mark - Setup

- (void)tl_setupBackground {
    UIImage *bg = [UIImage imageNamed:@"hp_backView.png"];
    self.layer.contents = (__bridge id)bg.CGImage;
}

- (void)tl_setupCardWithTop:(CGFloat)cardTop {
    UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    UIVisualEffectView *cardView = [[UIVisualEffectView alloc] initWithEffect:blur];
    cardView.layer.cornerRadius = 20;
    cardView.layer.masksToBounds = YES;

    // 叠加白色半透明层，配合 blur 实现设计稿的磨砂玻璃效果
    UIView *overlay = [[UIView alloc] init];
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

- (void)tl_setupNavBarWithTop:(CGFloat)navTop {
    // 返回按钮
    _backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_backButton setImage:[UIImage imageNamed:@"iconBack"] forState:UIControlStateNormal];
    [self addSubview:_backButton];
    [_backButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self).offset(16);
        make.top.equalTo(self).offset(navTop);
        make.width.height.mas_equalTo(kNavHeight);
    }];

    // 标题容器：文字 + 时钟图标水平排列，整体居中
    UIView *titleContainer = [[UIView alloc] init];
    [self addSubview:titleContainer];

    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = @"识别记录";
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.font = [UIFont systemFontOfSize:20 weight:UIFontWeightSemibold];
    [titleContainer addSubview:titleLabel];

    UIImageView *clockIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"records"]];
    clockIcon.contentMode = UIViewContentModeScaleAspectFit;
    [titleContainer addSubview:clockIcon];

    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.bottom.equalTo(titleContainer);
    }];
    [clockIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(titleLabel.mas_right).offset(5);
        make.right.equalTo(titleContainer);
        make.centerY.equalTo(titleLabel);
        make.width.height.mas_equalTo(20);
    }];
    [titleContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self);
        make.centerY.equalTo(_backButton);
    }];

    // 筛选按钮：图标在文字右侧
    _filterButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_filterButton setTitle:@"筛选" forState:UIControlStateNormal];
    [_filterButton setTitleColor:[UIColor colorWithWhite:1 alpha:0.9] forState:UIControlStateNormal];
    _filterButton.titleLabel.font = [UIFont systemFontOfSize:20 weight:UIFontWeightBold];
    [_filterButton setImage:[UIImage imageNamed:@"筛选"] forState:UIControlStateNormal];
    // ForceRightToLeft 让图标出现在文字右侧
    _filterButton.semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;
    _filterButton.imageEdgeInsets = UIEdgeInsetsMake(0, 6, 0, 0);
    [self addSubview:_filterButton];
    [_filterButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self).offset(-16);
        make.centerY.equalTo(_backButton);
        make.height.mas_equalTo(44);
    }];
}

- (void)tl_setupCollectionViewWithTop:(CGFloat)cardTop {
    CGFloat gap    = 9;
    CGFloat hInset = 14;
    CGFloat cellWidth = (UIScreen.mainScreen.bounds.size.width - hInset * 2 - gap) / 2;

    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.itemSize                = CGSizeMake(cellWidth, cellWidth);
    layout.minimumInteritemSpacing = gap;
    layout.minimumLineSpacing      = 14;
    layout.sectionInset            = UIEdgeInsetsMake(12, hInset, 20, hInset);
    layout.headerReferenceSize     = CGSizeMake(UIScreen.mainScreen.bounds.size.width, 44);

    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    _collectionView.backgroundColor = [UIColor clearColor];
    _collectionView.showsVerticalScrollIndicator = NO;
    [self addSubview:_collectionView];
    [_collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self);
        make.top.equalTo(self).offset(cardTop);
    }];
}

- (void)tl_setupEmptyLabelWithTop:(CGFloat)cardTop {
    _emptyLabel = [[UILabel alloc] init];
    _emptyLabel.text = @"暂无识别记录";
    _emptyLabel.textColor = [UIColor colorWithWhite:0.6 alpha:1];
    _emptyLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightRegular];
    _emptyLabel.textAlignment = NSTextAlignmentCenter;
    _emptyLabel.hidden = YES; // 默认隐藏，有数据时不显示
    [self addSubview:_emptyLabel];
    [_emptyLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self);
        make.top.equalTo(self).offset(cardTop + 80);
    }];
}

@end
