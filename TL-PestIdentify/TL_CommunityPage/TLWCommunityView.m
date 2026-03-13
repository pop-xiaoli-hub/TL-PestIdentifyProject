//
//  TLWCommunityView.m
//  TL-PestIdentify
//
//  Created by xiaoli pop on 2026/3/13.
//

#import "TLWCommunityView.h"
#import "TLWCommunityWaterfallLayout.h"
#import <Masonry/Masonry.h>

/// 顶部搜索区域高度
static CGFloat const kSearchBarHeight = 64.0;
/// 搜索区域与安全区顶部的间距
static CGFloat const kSearchBarTopInset = 12.0;
/// 瀑布流左右内边距
static CGFloat const kHorizontalInset = 12.0;
/// 瀑布流 item 间距
static CGFloat const kItemGap = 10.0;

@interface TLWCommunityView ()

@property (nonatomic, strong, readwrite) UICollectionView *collectionView;
@property (nonatomic, strong, readwrite) UITextField *searchTextField;
@property (nonatomic, strong, readwrite) UIButton *uploadButton;

@property (nonatomic, strong) UIView *searchContainer;

@end

@implementation TLWCommunityView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self tl_setupBackground];
        [self tl_setupSearchBar];
        [self tl_setupCollectionView];
    }
    return self;
}

#pragma mark - Setup UI

- (void)tl_setupBackground {
  UIImage* image = [UIImage imageNamed:@"hp_backView.png"];
  self.layer.contents = (__bridge id)image.CGImage;
}

- (void)tl_setupSearchBar {
    UIView *container = [[UIView alloc] init];
    container.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.22];
    container.layer.cornerRadius = 24.0;
    container.layer.masksToBounds = YES;
    [self addSubview:container];
    self.searchContainer = container;

    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = @"社区";
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.font = [UIFont systemFontOfSize:20 weight:UIFontWeightSemibold];
    [self addSubview:titleLabel];

    UIView *searchFieldBackground = [[UIView alloc] init];
    searchFieldBackground.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.95];
    searchFieldBackground.layer.cornerRadius = 22.0;
    searchFieldBackground.layer.masksToBounds = YES;
    [container addSubview:searchFieldBackground];

    UIImageView *searchIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cm_search"]];
    searchIcon.contentMode = UIViewContentModeScaleAspectFit;
    [searchFieldBackground addSubview:searchIcon];

    UITextField *textField = [[UITextField alloc] init];
    textField.placeholder = @"请输入关键词";
    textField.font = [UIFont systemFontOfSize:14];
    textField.textColor = [UIColor darkTextColor];
    [searchFieldBackground addSubview:textField];
    self.searchTextField = textField;

    UIImageView *voiceIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cm_voice"]];
    voiceIcon.contentMode = UIViewContentModeScaleAspectFit;
    [searchFieldBackground addSubview:voiceIcon];

    UIButton *uploadButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [uploadButton setImage:[UIImage imageNamed:@"cm_upload"] forState:UIControlStateNormal];
    uploadButton.adjustsImageWhenHighlighted = YES;
    [container addSubview:uploadButton];
    self.uploadButton = uploadButton;

    [container mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self).offset(12);
        make.right.equalTo(self).offset(-12);
        make.top.equalTo(self.mas_safeAreaLayoutGuideTop).offset(kSearchBarTopInset);
        make.height.mas_equalTo(kSearchBarHeight);
    }];

    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self);
        make.bottom.equalTo(container.mas_top).offset(-8);
    }];

    [searchFieldBackground mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(container).offset(12);
        make.top.equalTo(container).offset(10);
        make.bottom.equalTo(container).offset(-10);
        make.right.equalTo(container).offset(-64);
    }];

    [searchIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(searchFieldBackground).offset(12);
        make.centerY.equalTo(searchFieldBackground);
        make.width.height.mas_equalTo(18);
    }];

    [voiceIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(searchFieldBackground).offset(-12);
        make.centerY.equalTo(searchFieldBackground);
        make.width.height.mas_equalTo(18);
    }];

    [textField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(searchIcon.mas_right).offset(8);
        make.right.equalTo(voiceIcon.mas_left).offset(-8);
        make.centerY.equalTo(searchFieldBackground);
        make.height.mas_equalTo(32);
    }];

    [uploadButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(container).offset(-10);
        make.centerY.equalTo(container);
        make.width.height.mas_equalTo(44);
    }];
}

- (void)tl_setupCollectionView {
    TLWCommunityWaterfallLayout *layout = [[TLWCommunityWaterfallLayout alloc] init];
    layout.columnSpacing = kItemGap;
    layout.rowSpacing = kItemGap;
    layout.sectionInset = UIEdgeInsetsMake(12, kHorizontalInset, 20, kHorizontalInset);
    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero
                                                           collectionViewLayout:layout];
    collectionView.backgroundColor = [UIColor clearColor];
    collectionView.showsVerticalScrollIndicator = NO;
    [self addSubview:collectionView];
    self.collectionView = collectionView;

    [collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self);
        make.top.equalTo(self.searchContainer.mas_bottom).offset(10);
    }];
}

@end
