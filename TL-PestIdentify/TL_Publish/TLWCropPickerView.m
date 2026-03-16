//
//  TLWCropPickerView.m
//  TL-PestIdentify
//

#import "TLWCropPickerView.h"
#import <Masonry/Masonry.h>

@interface TLWCropPickerView ()

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong, readwrite) UICollectionView *collectionView;
@property (nonatomic, strong, readwrite) UIButton *confirmButton;

@end

@implementation TLWCropPickerView

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    [self tl_setupView];
  }
  return self;
}

- (void)tl_setupView {
  [self tl_setupBackground];
  [self tl_setupHeader];
  [self tl_setupCollectionView];
  [self tl_setupConfirmButton];
}

- (void)tl_setupBackground {
  UIImageView *bg = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bgGradient"]];
  bg.contentMode = UIViewContentModeScaleAspectFill;
  bg.clipsToBounds = YES;
  [self addSubview:bg];
  [bg mas_makeConstraints:^(MASConstraintMaker *make) {
    make.edges.equalTo(self);
  }];

  UIImageView *card = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bgCard"]];
  card.contentMode = UIViewContentModeScaleToFill;
  [self addSubview:card];
  [card mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.right.bottom.equalTo(self);
    make.height.mas_equalTo(792);
  }];
}

- (void)tl_setupHeader {
  UILabel *title = [[UILabel alloc] init];
  title.text = @"选择作物";
  title.font = [UIFont systemFontOfSize:20 weight:UIFontWeightSemibold];
  title.textColor = UIColor.whiteColor;
  [self addSubview:title];
  self.titleLabel = title;

  [title mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(self.mas_safeAreaLayoutGuideTop).offset(12);
    make.centerX.equalTo(self);
  }];

  UILabel *subtitle = [[UILabel alloc] init];
  subtitle.text = @"请选择您要发布的农作物";
  subtitle.font = [UIFont systemFontOfSize:22 weight:UIFontWeightMedium];
  subtitle.textColor = [UIColor colorWithWhite:1.0 alpha:0.8];
  [self addSubview:subtitle];
  self.subtitleLabel = subtitle;

  [subtitle mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(title.mas_bottom).offset(18);
    make.left.equalTo(self).offset(22);
  }];
}

- (void)tl_setupCollectionView {
  UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
  layout.scrollDirection = UICollectionViewScrollDirectionVertical;
  layout.minimumInteritemSpacing = 10;
  layout.minimumLineSpacing = 10;
  layout.sectionInset = UIEdgeInsetsMake(8, 22, 20, 22);
  layout.headerReferenceSize = CGSizeMake(0, 36);

  UICollectionView *cv = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
  cv.backgroundColor = UIColor.clearColor;
  cv.showsVerticalScrollIndicator = NO;
  cv.contentInset = UIEdgeInsetsMake(0, 0, 120, 0);
  [self addSubview:cv];
  self.collectionView = cv;

  [cv mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(self.subtitleLabel.mas_bottom).offset(12);
    make.left.equalTo(self).offset(10);
    make.right.bottom.equalTo(self);
  }];
}

- (void)tl_setupConfirmButton {
  UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
  button.layer.cornerRadius = 14;
  button.clipsToBounds = YES;
  UIImage *commitBg = [[UIImage imageNamed:@"commitRectangle"]
                       resizableImageWithCapInsets:UIEdgeInsetsMake(0, 40, 0, 40)
                       resizingMode:UIImageResizingModeStretch];
  [button setBackgroundImage:commitBg forState:UIControlStateNormal];
  NSMutableAttributedString *btnTitle = [[NSMutableAttributedString alloc] initWithString:@"确认" attributes:@{
    NSFontAttributeName: [UIFont systemFontOfSize:21 weight:UIFontWeightSemibold],
    NSForegroundColorAttributeName: UIColor.whiteColor,
    NSKernAttributeName: @(1.05),
  }];
  [button setAttributedTitle:btnTitle forState:UIControlStateNormal];
  [self addSubview:button];
  self.confirmButton = button;

  [button mas_makeConstraints:^(MASConstraintMaker *make) {
    make.bottom.equalTo(self.mas_safeAreaLayoutGuideBottom).offset(-30);
    make.left.equalTo(self.mas_safeAreaLayoutGuideLeft).offset(22);
    make.right.equalTo(self.mas_safeAreaLayoutGuideRight).offset(-22);
    make.height.mas_equalTo(54);
  }];
}

@end

