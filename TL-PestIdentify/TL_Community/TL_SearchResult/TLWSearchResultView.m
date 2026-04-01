//
//  TLWSearchResultView.m
//  TL-PestIdentify
//

#import "TLWSearchResultView.h"
#import "TLWCommunityWaterfallLayout.h"
#import <Masonry/Masonry.h>

@interface TLWSearchResultView ()

@property (nonatomic, strong, readwrite) UIButton *closeButton;
@property (nonatomic, strong, readwrite) UILabel *titleLabel;
@property (nonatomic, strong, readwrite) UILabel *subtitleLabel;
@property (nonatomic, strong, readwrite) UICollectionView *collectionView;
@property (nonatomic, strong, readwrite) UILabel *emptyLabel;

@end

@implementation TLWSearchResultView

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    [self tl_setupBackground];
    [self tl_setupHeader];
    [self tl_setupCollectionView];
    [self tl_setupEmptyState];
  }
  return self;
}

- (void)tl_setupBackground {
  self.backgroundColor = [UIColor whiteColor];
  UIImage *image = [UIImage imageNamed:@"hp_backView.png"];
  self.layer.contents = (__bridge id)image.CGImage;
}

- (void)tl_setupHeader {
  UIView *headerPanel = [[UIView alloc] init];
  headerPanel.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.16];
  headerPanel.layer.cornerRadius = 22.0;
  headerPanel.layer.borderWidth = 1.0;
  headerPanel.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.34].CGColor;
  headerPanel.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.18].CGColor;
  headerPanel.layer.shadowOpacity = 1.0;
  headerPanel.layer.shadowOffset = CGSizeMake(0, 10);
  headerPanel.layer.shadowRadius = 24.0;
  [self addSubview:headerPanel];

  UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
  [closeButton setImage:[UIImage imageNamed:@"iconBack"] forState:UIControlStateNormal];
  closeButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
  [headerPanel addSubview:closeButton];
  self.closeButton = closeButton;

  UILabel *titleLabel = [[UILabel alloc] init];
  titleLabel.text = @"搜索结果";
  titleLabel.font = [UIFont systemFontOfSize:20 weight:UIFontWeightSemibold];
  titleLabel.textColor = [UIColor whiteColor];
  [headerPanel addSubview:titleLabel];
  self.titleLabel = titleLabel;

  UILabel *subtitleLabel = [[UILabel alloc] init];
  subtitleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
  subtitleLabel.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.88];
  subtitleLabel.numberOfLines = 2;
  [headerPanel addSubview:subtitleLabel];
  self.subtitleLabel = subtitleLabel;

  [headerPanel mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(self.mas_safeAreaLayoutGuideTop).offset(12);
    make.left.equalTo(self).offset(12);
    make.right.equalTo(self).offset(-12);
    make.height.mas_equalTo(92);
  }];

  [closeButton mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.equalTo(headerPanel).offset(12);
    make.top.equalTo(headerPanel).offset(12);
    make.width.height.mas_equalTo(36);
  }];

  [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.equalTo(closeButton.mas_right).offset(8);
    make.top.equalTo(headerPanel).offset(14);
    make.right.equalTo(headerPanel).offset(-16);
  }];

  [subtitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.equalTo(titleLabel);
    make.top.equalTo(titleLabel.mas_bottom).offset(6);
    make.right.equalTo(headerPanel).offset(-16);
  }];
}

- (void)tl_setupCollectionView {
  TLWCommunityWaterfallLayout *layout = [[TLWCommunityWaterfallLayout alloc] init];
  layout.sectionInset = UIEdgeInsetsMake(14, 12, 30, 12);

  UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
  collectionView.backgroundColor = [UIColor clearColor];
  collectionView.alwaysBounceVertical = YES;
  [self addSubview:collectionView];
  self.collectionView = collectionView;

  [collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(self.mas_safeAreaLayoutGuideTop).offset(118);
    make.left.right.bottom.equalTo(self);
  }];
}

- (void)tl_setupEmptyState {
  UILabel *emptyLabel = [[UILabel alloc] init];
  emptyLabel.text = @"暂时没有匹配到帖子";
  emptyLabel.textAlignment = NSTextAlignmentCenter;
  emptyLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
  emptyLabel.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.94];
  emptyLabel.hidden = YES;
  [self addSubview:emptyLabel];
  self.emptyLabel = emptyLabel;

  [emptyLabel mas_makeConstraints:^(MASConstraintMaker *make) {
    make.center.equalTo(self.collectionView);
    make.left.equalTo(self).offset(32);
    make.right.equalTo(self).offset(-32);
  }];
}

- (void)tl_updateQueryText:(NSString *)query {
  NSString *trimmedQuery = [query stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
  self.subtitleLabel.text = trimmedQuery.length > 0 ? [NSString stringWithFormat:@"“%@” 的相关帖子", trimmedQuery] : @"搜索到的相关帖子";
}

- (void)tl_setEmptyHidden:(BOOL)hidden {
  self.emptyLabel.hidden = hidden;
}

@end
