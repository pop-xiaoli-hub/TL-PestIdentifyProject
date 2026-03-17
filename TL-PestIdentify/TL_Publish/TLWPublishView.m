//
//  TLWPublishView.m
//  TL-PestIdentify
//

#import "TLWPublishView.h"
#import <Masonry/Masonry.h>

static CGFloat const kCardCornerRadius = 14.0;

@interface TLWPublishView ()

@property (nonatomic, strong, readwrite) UIButton *backButton;
@property (nonatomic, strong, readwrite) UIButton *cropSelectButton;
@property (nonatomic, strong, readwrite) UICollectionView *cropsCollectionView;
@property (nonatomic, strong, readwrite) UITextView *contentTextView;
@property (nonatomic, strong, readwrite) UIButton *addImageButton;
@property (nonatomic, strong, readwrite) UIButton *confirmPublishButton;
@property (nonatomic, strong, readwrite) UICollectionView *imagesCollectionView;

@property (nonatomic, strong) UIView *topCardView;
@property (nonatomic, strong) UILabel *cropPlaceholderLabel;
@property (nonatomic, strong) UIButton *cropArrowButton;

@end

@implementation TLWPublishView

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    [self tl_setupBackground];
    [self tl_setupHeader];
    [self tl_setupCards];
    [self tl_setupConfirmButton];
  }
  return self;
}

- (void)layoutSubviews {
  [super layoutSubviews];
  // 在这里可根据需要更新渐变等
}

#pragma mark - Setup

- (void)tl_setupBackground {
  UIImage *image = [UIImage imageNamed:@"hp_backView.png"];
  if (image) {
    self.layer.contents = (__bridge id)image.CGImage;
  } else {
    self.backgroundColor = [UIColor colorWithRed:0.22 green:0.75 blue:0.96 alpha:1.0];
  }
}

- (void)tl_setupHeader {
  UILabel *titleLabel = [[UILabel alloc] init];
  titleLabel.text = @"我要发布";
  titleLabel.textColor = [UIColor whiteColor];
  titleLabel.font = [UIFont systemFontOfSize:20 weight:UIFontWeightSemibold];
  [self addSubview:titleLabel];

  UIButton *backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
  UIImage *backImage = [UIImage imageNamed:@"iconBack"];
  if (backImage) {
    [backBtn setImage:backImage forState:UIControlStateNormal];
  } else {
    [backBtn setTitle:@"<" forState:UIControlStateNormal];
  }
  backBtn.layer.cornerRadius = 22.0;
  backBtn.layer.masksToBounds = YES;
  backBtn.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.06];
  [self addSubview:backBtn];
  self.backButton = backBtn;

  [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
    make.centerX.equalTo(self);
    make.top.equalTo(self.mas_safeAreaLayoutGuideTop).offset(12);
  }];

  [backBtn mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.equalTo(self).offset(16);
    make.centerY.equalTo(titleLabel);
    make.width.height.mas_equalTo(44);
  }];
}

- (UIView *)tl_cardContainer {
  UIView *card = [[UIView alloc] init];
  card.backgroundColor = [UIColor colorWithWhite:1 alpha:0.96];
  card.layer.cornerRadius = kCardCornerRadius;
  card.layer.masksToBounds = YES;
  card.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.1].CGColor;
  card.layer.shadowOpacity = 0.6;
  card.layer.shadowRadius = 8.0;
  card.layer.shadowOffset = CGSizeMake(0, 4);
  return card;
}

- (void)tl_setupCards {
  UIView *topCard = [self tl_cardContainer];
  UIView *middleCard = [self tl_cardContainer];
  [self addSubview:topCard];
  [self addSubview:middleCard];
  self.topCardView = topCard;
  self.middleCardView = middleCard;

  [topCard mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(self.mas_safeAreaLayoutGuideTop).offset(80);
    make.left.equalTo(self).offset(16);
    make.right.equalTo(self).offset(-16);
    make.height.mas_equalTo(72);
  }];

  [middleCard mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(topCard.mas_bottom).offset(16);
    make.left.right.equalTo(topCard);
    make.height.mas_equalTo(500);
  }];

  // 顶部卡片：选择农作物
  UILabel *cropTitle = [[UILabel alloc] init];
  cropTitle.text = @"请选择您要发布的农作物";
  cropTitle.font = [UIFont systemFontOfSize:20];
  cropTitle.textColor = [UIColor darkTextColor];
  [topCard addSubview:cropTitle];
  self.cropPlaceholderLabel = cropTitle;

  UIButton *arrowButton = [UIButton buttonWithType:UIButtonTypeSystem];
  [arrowButton setTitle:@">" forState:UIControlStateNormal];
  [arrowButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
  arrowButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
  [topCard addSubview:arrowButton];
  self.cropArrowButton = arrowButton;

  // 顶部整卡点击区域（仅在无选中作物时可见）
  UIButton *cropButton = [UIButton buttonWithType:UIButtonTypeCustom];
  cropButton.backgroundColor = [UIColor clearColor];
  [topCard addSubview:cropButton];
  self.cropSelectButton = cropButton;

  [cropButton mas_makeConstraints:^(MASConstraintMaker *make) {
    make.edges.equalTo(topCard);
  }];
  [cropTitle mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.equalTo(topCard).offset(12);
    make.centerY.equalTo(topCard);
  }];
  [arrowButton mas_makeConstraints:^(MASConstraintMaker *make) {
    make.right.equalTo(topCard).offset(-12);
    make.centerY.equalTo(topCard);
  }];

  // 顶部横向已选作物标签列表，初始隐藏
  UICollectionViewFlowLayout *cropFlow = [[UICollectionViewFlowLayout alloc] init];
  cropFlow.scrollDirection = UICollectionViewScrollDirectionHorizontal;
  cropFlow.minimumLineSpacing = 10;
  cropFlow.minimumInteritemSpacing = 10;
  cropFlow.sectionInset = UIEdgeInsetsMake(0, 12, 0, 12);
  cropFlow.itemSize = CGSizeMake(110, 40);

  UICollectionView *cropsCollectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:cropFlow];
  cropsCollectionView.backgroundColor = [UIColor clearColor];
  cropsCollectionView.showsHorizontalScrollIndicator = NO;
  cropsCollectionView.hidden = YES;
  [topCard addSubview:cropsCollectionView];
  self.cropsCollectionView = cropsCollectionView;

  [cropsCollectionView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.edges.equalTo(topCard);
  }];

  // 中间卡片：发布内容 + 上传图片（统一悬浮在一个卡片上）
  UILabel *contentTitle = [[UILabel alloc] init];
  contentTitle.text = @"请描述您要发布的内容";
  contentTitle.font = [UIFont systemFontOfSize:20];
  contentTitle.textColor = [UIColor darkTextColor];
  [middleCard addSubview:contentTitle];

  UITextView *textView = [[UITextView alloc] init];
  textView.backgroundColor = [UIColor clearColor];
  textView.font = [UIFont systemFontOfSize:18];
  textView.textColor = [UIColor darkTextColor];
  textView.text = @"点击输入您要发布的内容";
  textView.textColor = [UIColor lightGrayColor];
  textView.backgroundColor = [[UIColor lightGrayColor] colorWithAlphaComponent:0.4];
  textView.layer.masksToBounds = YES;
  textView.layer.cornerRadius = 10;
  [middleCard addSubview:textView];
  self.contentTextView = textView;

  [contentTitle mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(middleCard).offset(25);
    make.left.equalTo(middleCard).offset(12);
  }];

  [textView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(contentTitle.mas_bottom).offset(25);
    make.left.equalTo(middleCard).offset(12);
    make.right.equalTo(middleCard).offset(-12);
    make.height.mas_equalTo(230);
  }];

  // 上传图片标题
  UILabel *uploadTitle = [[UILabel alloc] init];
  uploadTitle.text = @"上传图片";
  uploadTitle.font = [UIFont systemFontOfSize:18];
  uploadTitle.textColor = [UIColor darkTextColor];
  [middleCard addSubview:uploadTitle];

  [uploadTitle mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(textView.mas_bottom).offset(20);
    make.left.equalTo(middleCard).offset(12);
  }];

  // 横向图片列表（第一项为添加图片按钮）
  UICollectionViewFlowLayout *flow = [[UICollectionViewFlowLayout alloc] init];
  flow.scrollDirection = UICollectionViewScrollDirectionHorizontal;
  flow.minimumLineSpacing = 12;
  flow.minimumInteritemSpacing = 12;
  flow.sectionInset = UIEdgeInsetsMake(0, 12, 0, 12);
  flow.itemSize = CGSizeMake(90, 90);

  UICollectionView *imagesCollectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:flow];
  imagesCollectionView.backgroundColor = [UIColor clearColor];
  imagesCollectionView.showsHorizontalScrollIndicator = NO;
  [middleCard addSubview:imagesCollectionView];
  self.imagesCollectionView = imagesCollectionView;

  [imagesCollectionView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(uploadTitle.mas_bottom).offset(16);
    make.left.right.equalTo(middleCard);
    make.height.mas_equalTo(100);
    make.bottom.lessThanOrEqualTo(middleCard).offset(-20);
  }];

  // 额外提供一个“添加图片”按钮，方便 VC 直接绑定点击事件
  UIButton *addImageButton = [UIButton buttonWithType:UIButtonTypeCustom];
  [addImageButton setImage:[UIImage imageNamed:@"addPhoto"] forState:UIControlStateNormal];
  self.addImageButton = addImageButton;

}

- (void)tl_updateCropSelectionVisible:(BOOL)hasSelection {
  self.cropsCollectionView.hidden = !hasSelection;
  self.cropPlaceholderLabel.hidden = hasSelection;
  self.cropArrowButton.hidden = hasSelection;
  self.cropSelectButton.hidden = hasSelection;
}

- (void)tl_setupConfirmButton {
  UIButton *confirmButton = [UIButton buttonWithType:UIButtonTypeCustom];
  [confirmButton setTitle:@"确认发布" forState:UIControlStateNormal];
  [confirmButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
  confirmButton.titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightSemibold];
  confirmButton.layer.cornerRadius = 25.0;
  confirmButton.layer.masksToBounds = YES;

  CAGradientLayer *gradient = [CAGradientLayer layer];
  gradient.colors = @[
    (__bridge id)[UIColor colorWithRed:1.0 green:0.77 blue:0.2 alpha:1.0].CGColor,
    (__bridge id)[UIColor colorWithRed:1.0 green:0.6 blue:0.0 alpha:1.0].CGColor
  ];
  gradient.startPoint = CGPointMake(0, 0.5);
  gradient.endPoint = CGPointMake(1, 0.5);
  gradient.frame = CGRectMake(0, 0, 340, 50);
  [confirmButton.layer insertSublayer:gradient atIndex:0];

  [self addSubview:confirmButton];
  self.confirmPublishButton = confirmButton;

  [confirmButton mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.equalTo(self).offset(32);
    make.right.equalTo(self).offset(-32);
    make.bottom.equalTo(self.mas_safeAreaLayoutGuideBottom).offset(-28);
    make.height.mas_equalTo(50);
  }];

  // 让渐变在 AutoLayout 后尺寸正确
  dispatch_async(dispatch_get_main_queue(), ^{
    gradient.frame = confirmButton.bounds;
  });
}

@end

