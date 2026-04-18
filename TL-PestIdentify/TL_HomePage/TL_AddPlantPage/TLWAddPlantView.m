//
//  TLWAddPlantView.m
//  TL-PestIdentify
//
//  Created by xiaoli pop on 2026/4/2.
//

#import "TLWAddPlantView.h"
#import <Masonry/Masonry.h>
#import <SDWebImage/SDWebImage.h>

@interface TLWAddPlantView ()

@property (nonatomic, strong, readwrite) UIButton *backButton;
@property (nonatomic, strong, readwrite) UITextField *plantNameTextField;
@property (nonatomic, strong, readwrite) UIButton *createButton;
@property (nonatomic, strong, readwrite) UIButton *contentCardButton;
@property (nonatomic, strong, readwrite) UIButton *confirmButton;

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *sheetView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UIView *nameCardView;
@property (nonatomic, strong) UIView *plantCardView;
@property (nonatomic, strong) CAGradientLayer *createGradientLayer;
@property (nonatomic, strong) CAGradientLayer *confirmGradientLayer;
@property (nonatomic, strong) UIImageView *selectedPlantImageView;
@property (nonatomic, strong) UIImageView *userAvatarImageView;
@property (nonatomic, strong) UIView *plusHorizontalLine;
@property (nonatomic, strong) UIView *plusVerticalLine;

@end

@implementation TLWAddPlantView

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    [self tl_setupBackground];
    [self tl_setupHeader];
    [self tl_setupScrollContent];
    [self tl_setupNameCard];
    [self tl_setupPlantCard];
    [self tl_setupConfirmButton];
  }
  return self;
}

- (void)layoutSubviews {
  [super layoutSubviews];
  self.createGradientLayer.frame = self.createButton.bounds;
  self.createGradientLayer.cornerRadius = self.createButton.bounds.size.height * 0.5;
  self.confirmGradientLayer.frame = self.confirmButton.bounds;
  self.confirmGradientLayer.cornerRadius = self.confirmButton.bounds.size.height * 0.5;
}

#pragma mark - Setup

- (void)tl_setupBackground {
  UIImage *image = [UIImage imageNamed:@"hp_backView"];
  if (image) {
    self.layer.contents = (__bridge id)image.CGImage;
    self.layer.contentsGravity = kCAGravityResizeAspectFill;
  } else {
    self.backgroundColor = [UIColor colorWithRed:0.26 green:0.76 blue:0.95 alpha:1.0];
  }
}

- (void)tl_setupHeader {
  UILabel *titleLabel = [[UILabel alloc] init];
  titleLabel.text = @"新建种植物管理";
  titleLabel.textColor = [UIColor whiteColor];
  titleLabel.font = [UIFont systemFontOfSize:20 weight:UIFontWeightSemibold];
  [self addSubview:titleLabel];

  UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
  UIImage *backImage = [UIImage imageNamed:@"iconBack"];
  if (backImage) {
    [backButton setImage:backImage forState:UIControlStateNormal];
  } else {
    [backButton setTitle:@"<" forState:UIControlStateNormal];
    [backButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
  }
  backButton.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.24];
  backButton.layer.cornerRadius = 22.0;
  backButton.layer.masksToBounds = YES;
  [self addSubview:backButton];
  self.backButton = backButton;

  [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
    make.centerX.equalTo(self);
    make.top.equalTo(self.mas_safeAreaLayoutGuideTop).offset(12.0);
  }];

  [backButton mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.equalTo(self).offset(16.0);
    make.centerY.equalTo(titleLabel);
    make.width.height.mas_equalTo(40.0);
  }];
}

- (UIView *)tl_cardView {
  UIView *cardView = [[UIView alloc] init];
  cardView.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.72];
  cardView.layer.cornerRadius = 18.0;
  cardView.layer.borderWidth = 1.0;
  cardView.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.45].CGColor;
  cardView.layer.shadowColor = [UIColor colorWithRed:0.12 green:0.35 blue:0.30 alpha:0.16].CGColor;
  cardView.layer.shadowOpacity = 1.0;
  cardView.layer.shadowOffset = CGSizeMake(0, 10);
  cardView.layer.shadowRadius = 20.0;
  return cardView;
}

- (void)tl_setupScrollContent {
  UIView *sheetView = [[UIView alloc] init];
  sheetView.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.88];
  sheetView.layer.cornerRadius = 26.0;
  sheetView.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
  sheetView.layer.masksToBounds = YES;
  [self addSubview:sheetView];
  self.sheetView = sheetView;

  UIScrollView *scrollView = [[UIScrollView alloc] init];
  scrollView.backgroundColor = [UIColor clearColor];
  scrollView.showsVerticalScrollIndicator = NO;
  [sheetView addSubview:scrollView];
  self.scrollView = scrollView;

  UIView *contentView = [[UIView alloc] init];
  contentView.backgroundColor = [UIColor clearColor];
  [scrollView addSubview:contentView];
  self.contentView = contentView;

  [sheetView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(self.mas_safeAreaLayoutGuideTop).offset(68.0);
    make.left.right.bottom.equalTo(self);
  }];

  [scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.edges.equalTo(sheetView);
  }];

  [contentView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.edges.equalTo(scrollView);
    make.width.equalTo(scrollView);
  }];
}

- (void)tl_setupNameCard {
  UILabel *sectionTitleLabel = [[UILabel alloc] init];
  sectionTitleLabel.text = @"请输入种植物的名称";
  sectionTitleLabel.textColor = [UIColor colorWithWhite:0.18 alpha:1.0];
  sectionTitleLabel.font = [UIFont systemFontOfSize:20 weight:UIFontWeightSemibold];
  [self.contentView addSubview:sectionTitleLabel];

  UIView *nameCardView = [self tl_cardView];
  [self.contentView addSubview:nameCardView];
  self.nameCardView = nameCardView;

  UITextField *textField = [[UITextField alloc] init];
  textField.placeholder = @"请输入种植物名称";
  textField.font = [UIFont systemFontOfSize:18 weight:UIFontWeightMedium];
  textField.textColor = [UIColor colorWithWhite:0.22 alpha:1.0];
  textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"请输入种植物名称"
                                                                     attributes:@{
      NSForegroundColorAttributeName : [UIColor colorWithWhite:0.72 alpha:1.0],
      NSFontAttributeName : [UIFont systemFontOfSize:18 weight:UIFontWeightMedium]
  }];
  textField.backgroundColor = [UIColor whiteColor];
  textField.layer.cornerRadius = 14.0;
  UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 16, 1)];
  textField.leftView = paddingView;
  textField.leftViewMode = UITextFieldViewModeAlways;
  [nameCardView addSubview:textField];
  self.plantNameTextField = textField;

  [sectionTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(self.contentView).offset(8.0);
    make.left.equalTo(self.contentView).offset(20.0);
  }];

  [nameCardView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(sectionTitleLabel.mas_bottom).offset(12.0);
    make.left.equalTo(self.contentView).offset(16.0);
    make.right.equalTo(self.contentView).offset(-16.0);
    make.height.mas_equalTo(72.0);
  }];

  [textField mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.equalTo(nameCardView).offset(12.0);
    make.right.equalTo(nameCardView).offset(-12.0);
    make.centerY.equalTo(nameCardView);
    make.height.mas_equalTo(42.0);
  }];
}

- (void)tl_setupPlantCard {
  UILabel *sectionTitleLabel = [[UILabel alloc] init];
  sectionTitleLabel.text = @"请选择种植物图片";
  sectionTitleLabel.textColor = [UIColor colorWithWhite:0.18 alpha:1.0];
  sectionTitleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightSemibold];
  [self.contentView addSubview:sectionTitleLabel];

  UIView *plantCardView = [self tl_cardView];
  [self.contentView addSubview:plantCardView];
  self.plantCardView = plantCardView;

  UIImageView *avatarImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"hp_avatar"]];
  avatarImageView.contentMode = UIViewContentModeScaleAspectFill;
  avatarImageView.clipsToBounds = YES;
  avatarImageView.layer.cornerRadius = 22.0;
  [plantCardView addSubview:avatarImageView];
  self.userAvatarImageView = avatarImageView;

  UILabel *titleLabel = [[UILabel alloc] init];
  titleLabel.text = @"我的种植物";
  titleLabel.textColor = [UIColor colorWithWhite:0.22 alpha:1.0];
  titleLabel.font = [UIFont systemFontOfSize:18.0 weight:UIFontWeightSemibold];
  [plantCardView addSubview:titleLabel];

  UIImageView *locationIconView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"hp_location"]];
  locationIconView.contentMode = UIViewContentModeScaleAspectFit;
  [plantCardView addSubview:locationIconView];

  UILabel *locationLabel = [[UILabel alloc] init];
  locationLabel.text = @"杭州";
  locationLabel.textColor = [UIColor colorWithWhite:0.60 alpha:1.0];
  locationLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightMedium];
  [plantCardView addSubview:locationLabel];

  UIButton *createButton = [UIButton buttonWithType:UIButtonTypeCustom];
  createButton.backgroundColor = [UIColor colorWithRed:0.30 green:0.92 blue:0.76 alpha:1.0];
  createButton.layer.cornerRadius = 18.0;
  createButton.layer.shadowColor = [UIColor colorWithRed:0.17 green:0.86 blue:0.70 alpha:0.34].CGColor;
  createButton.layer.shadowOpacity = 1.0;
  createButton.layer.shadowOffset = CGSizeMake(0, 6);
  createButton.layer.shadowRadius = 12.0;
  [plantCardView addSubview:createButton];
  self.createButton = createButton;

  CAGradientLayer *createGradientLayer = [CAGradientLayer layer];
  createGradientLayer.colors = @[
    (__bridge id)[UIColor colorWithRed:0.43 green:0.95 blue:0.88 alpha:1.0].CGColor,
    (__bridge id)[UIColor colorWithRed:0.33 green:0.87 blue:0.57 alpha:1.0].CGColor
  ];
  createGradientLayer.startPoint = CGPointMake(0.0, 0.5);
  createGradientLayer.endPoint = CGPointMake(1.0, 0.5);
  [createButton.layer insertSublayer:createGradientLayer atIndex:0];
  self.createGradientLayer = createGradientLayer;

  UIImageView *createIconView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"hp_yield_leaf"]];
  createIconView.contentMode = UIViewContentModeScaleAspectFit;
  [createButton addSubview:createIconView];

  UILabel *createLabel = [[UILabel alloc] init];
  createLabel.text = @"新建";
  createLabel.textColor = [UIColor whiteColor];
  createLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
  [createButton addSubview:createLabel];

  UIButton *contentCardButton = [UIButton buttonWithType:UIButtonTypeCustom];
  contentCardButton.backgroundColor = [UIColor colorWithWhite:0.88 alpha:1.0];
  contentCardButton.layer.cornerRadius = 16.0;
  contentCardButton.layer.masksToBounds = YES;
  [plantCardView addSubview:contentCardButton];
  self.contentCardButton = contentCardButton;

  UIView *plusHorizontalLine = [[UIView alloc] init];
  plusHorizontalLine.backgroundColor = [UIColor whiteColor];
  plusHorizontalLine.layer.cornerRadius = 3.0;
  [contentCardButton addSubview:plusHorizontalLine];
  self.plusHorizontalLine = plusHorizontalLine;

  UIView *plusVerticalLine = [[UIView alloc] init];
  plusVerticalLine.backgroundColor = [UIColor whiteColor];
  plusVerticalLine.layer.cornerRadius = 3.0;
  [contentCardButton addSubview:plusVerticalLine];
  self.plusVerticalLine = plusVerticalLine;

  UIImageView *selectedPlantImageView = [[UIImageView alloc] init];
  selectedPlantImageView.contentMode = UIViewContentModeScaleAspectFill;
  selectedPlantImageView.clipsToBounds = YES;
  selectedPlantImageView.hidden = YES;
  [contentCardButton addSubview:selectedPlantImageView];
  self.selectedPlantImageView = selectedPlantImageView;

  [sectionTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(self.nameCardView.mas_bottom).offset(28.0);
    make.left.equalTo(self.contentView).offset(20.0);
  }];

  [plantCardView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(sectionTitleLabel.mas_bottom).offset(12.0);
    make.left.equalTo(self.contentView).offset(16.0);
    make.right.equalTo(self.contentView).offset(-16.0);
    make.height.mas_equalTo(300.0);
  }];

  [avatarImageView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.equalTo(plantCardView).offset(16.0);
    make.top.equalTo(plantCardView).offset(16.0);
    make.width.height.mas_equalTo(44.0);
  }];

  [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.equalTo(avatarImageView.mas_right).offset(12.0);
    make.top.equalTo(avatarImageView).offset(1.0);
    make.right.lessThanOrEqualTo(createButton.mas_left).offset(-10.0);
  }];

  [locationIconView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.equalTo(titleLabel);
    make.top.equalTo(titleLabel.mas_bottom).offset(6.0);
    make.width.height.mas_equalTo(12.0);
  }];

  [locationLabel mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.equalTo(locationIconView.mas_right).offset(4.0);
    make.centerY.equalTo(locationIconView);
  }];

  [createButton mas_makeConstraints:^(MASConstraintMaker *make) {
    make.right.equalTo(plantCardView).offset(-16.0);
    make.centerY.equalTo(avatarImageView);
    make.width.mas_equalTo(92.0);
    make.height.mas_equalTo(36.0);
  }];

  [createIconView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.equalTo(createButton).offset(14.0);
    make.centerY.equalTo(createButton);
    make.width.height.mas_equalTo(16.0);
  }];

  [createLabel mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.equalTo(createIconView.mas_right).offset(8.0);
    make.centerY.equalTo(createButton);
  }];

  [contentCardButton mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.equalTo(plantCardView).offset(6.0);
    make.right.equalTo(plantCardView).offset(-6.0);
    make.top.equalTo(avatarImageView.mas_bottom).offset(14.0);
    make.bottom.equalTo(plantCardView).offset(-10.0);
  }];

  [plusHorizontalLine mas_makeConstraints:^(MASConstraintMaker *make) {
    make.center.equalTo(contentCardButton);
    make.width.mas_equalTo(90.0);
    make.height.mas_equalTo(8.0);
  }];

  [plusVerticalLine mas_makeConstraints:^(MASConstraintMaker *make) {
    make.center.equalTo(contentCardButton);
    make.width.mas_equalTo(8.0);
    make.height.mas_equalTo(90.0);
  }];

  [selectedPlantImageView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.edges.equalTo(contentCardButton);
  }];
}

- (void)tl_setupConfirmButton {
  UIButton *confirmButton = [UIButton buttonWithType:UIButtonTypeCustom];
  [confirmButton setTitle:@"确认" forState:UIControlStateNormal];
  [confirmButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
  confirmButton.titleLabel.font = [UIFont systemFontOfSize:20 weight:UIFontWeightSemibold];
  confirmButton.backgroundColor = [UIColor colorWithRed:1.0 green:0.72 blue:0.24 alpha:1.0];
  confirmButton.layer.cornerRadius = 22.0;
  confirmButton.layer.shadowColor = [UIColor colorWithRed:0.96 green:0.66 blue:0.20 alpha:0.35].CGColor;
  confirmButton.layer.shadowOpacity = 1.0;
  confirmButton.layer.shadowOffset = CGSizeMake(0, 10);
  confirmButton.layer.shadowRadius = 18.0;
  [self.contentView addSubview:confirmButton];
  self.confirmButton = confirmButton;

  CAGradientLayer *confirmGradientLayer = [CAGradientLayer layer];
  confirmGradientLayer.colors = @[
    (__bridge id)[UIColor colorWithRed:1.00 green:0.83 blue:0.28 alpha:1.0].CGColor,
    (__bridge id)[UIColor colorWithRed:0.99 green:0.62 blue:0.20 alpha:1.0].CGColor
  ];
  confirmGradientLayer.startPoint = CGPointMake(0.0, 0.5);
  confirmGradientLayer.endPoint = CGPointMake(1.0, 0.5);
  [confirmButton.layer insertSublayer:confirmGradientLayer atIndex:0];
  self.confirmGradientLayer = confirmGradientLayer;

  [confirmButton mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(self.plantCardView.mas_bottom).offset(120.0);
    make.left.equalTo(self.contentView).offset(20.0);
    make.right.equalTo(self.contentView).offset(-20.0);
    make.height.mas_equalTo(46.0);
    make.bottom.equalTo(self.contentView).offset(-36.0);
  }];
}

- (void)updateSelectedPlantImage:(nullable UIImage *)image {
  BOOL hasImage = (image != nil);
  self.selectedPlantImageView.image = image;
  self.selectedPlantImageView.hidden = !hasImage;
  self.plusHorizontalLine.hidden = hasImage;
  self.plusVerticalLine.hidden = hasImage;
  self.contentCardButton.backgroundColor = hasImage ? [UIColor clearColor] : [UIColor colorWithWhite:0.88 alpha:1.0];
}

- (void)updateUserAvatarWithURLString:(nullable NSString *)avatarURLString {
  UIImage *placeholderImage = [UIImage imageNamed:@"hp_avatar"];
  if (avatarURLString.length > 0) {
    [self.userAvatarImageView sd_setImageWithURL:[NSURL URLWithString:avatarURLString] placeholderImage:placeholderImage];
  } else {
    self.userAvatarImageView.image = placeholderImage;
  }
}

@end
