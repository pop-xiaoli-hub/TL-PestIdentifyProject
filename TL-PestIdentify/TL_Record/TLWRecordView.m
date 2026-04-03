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
