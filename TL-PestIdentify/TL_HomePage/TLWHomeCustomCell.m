//
//  TLWHomeCustomCell.m
//  TL-PestIdentify
//

#import "TLWHomeCustomCell.h"
#import "Models/TLWPlantModel.h"
#import "TLWSDKManager.h"
#import <Masonry.h>
#import <SDWebImage/SDWebImage.h>

@interface TLWHomeCustomCell ()

@property (nonatomic, strong) UIView *cardView;
@property (nonatomic, strong) UIImageView *avatarImageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIImageView *locationIconView;
@property (nonatomic, strong) UILabel *locationLabel;
@property (nonatomic, strong) UIButton *createButton;
@property (nonatomic, strong) UIButton *contentCardButton;
@property (nonatomic, strong) UIImageView *contentImageView;
@property (nonatomic, strong) UIView *plusHorizontalLine;
@property (nonatomic, strong) UIView *plusVerticalLine;
@property (nonatomic, strong) CAGradientLayer *createButtonGradientLayer;
@property (nonatomic, strong) UILabel *plantTagLabel;

@end

@implementation TLWHomeCustomCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (self) {
    [self tl_setupSubviews];
  }
  return self;
}

- (void)prepareForReuse {
  [super prepareForReuse];
  self.clickCreateButton = nil;
  self.clickContentCard = nil;
  self.contentImageView.image = nil;
  self.plantTagLabel.text = nil;
}

- (void)layoutSubviews {
  [super layoutSubviews];
  self.cardView.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.cardView.bounds cornerRadius:self.cardView.layer.cornerRadius].CGPath;
  self.createButtonGradientLayer.frame = self.createButton.bounds;
}

- (void)tl_applyCurrentUserInfo {
  TLWSessionManager *sessionManager = [TLWSDKManager shared].sessionManager;
  AGUserProfileDto *profile = sessionManager.cachedProfile;
  NSString *displayName = profile.fullName ?: profile.username ?: sessionManager.username;
  self.titleLabel.text = displayName.length > 0 ? displayName : @"用户";

  UIImage *placeholderImage = [UIImage imageNamed:@"hp_avatar.png"];
  if (profile.avatarUrl.length > 0) {
    [self.avatarImageView sd_setImageWithURL:[NSURL URLWithString:profile.avatarUrl] placeholderImage:placeholderImage];
  } else {
    self.avatarImageView.image = placeholderImage;
  }
}

- (void)tl_applyLocationName:(nullable NSString *)locationName {
  self.locationLabel.text = locationName.length > 0 ? locationName : @"未定位";
}

- (void)tl_setupSubviews {
  self.selectionStyle = UITableViewCellSelectionStyleNone;
  self.backgroundColor = [UIColor clearColor];
  self.contentView.backgroundColor = [UIColor clearColor];

  UIView *cardView = [[UIView alloc] init];
  cardView.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.96];
  cardView.layer.cornerRadius = 22.0;
  cardView.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.10].CGColor;
  cardView.layer.shadowOpacity = 1.0;
  cardView.layer.shadowOffset = CGSizeMake(0, 8);
  cardView.layer.shadowRadius = 18.0;
  [self.contentView addSubview:cardView];
  self.cardView = cardView;

  [cardView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.equalTo(self.contentView).offset(10.0);
    make.right.equalTo(self.contentView).offset(-10.0);
    make.top.equalTo(self.contentView).offset(8.0);
    make.bottom.equalTo(self.contentView).offset(-8.0);
  }];

  UIImageView *avatarImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"hp_avatar.png"]];
  avatarImageView.contentMode = UIViewContentModeScaleAspectFill;
  avatarImageView.clipsToBounds = YES;
  avatarImageView.layer.cornerRadius = 25.0;
  [cardView addSubview:avatarImageView];
  self.avatarImageView = avatarImageView;

  UILabel *titleLabel = [[UILabel alloc] init];
  titleLabel.text = @"种植物管理";
  titleLabel.textColor = [UIColor colorWithWhite:0.22 alpha:1.0];
  titleLabel.font = [UIFont systemFontOfSize:18.0 weight:UIFontWeightSemibold];
  [cardView addSubview:titleLabel];
  self.titleLabel = titleLabel;

  UIImageView *locationIconView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"hp_location.png"]];
  locationIconView.contentMode = UIViewContentModeScaleAspectFit;
  [cardView addSubview:locationIconView];
  self.locationIconView = locationIconView;

  UILabel *locationLabel = [[UILabel alloc] init];
  locationLabel.text = @"杭州";
  locationLabel.textColor = [UIColor colorWithWhite:0.60 alpha:1.0];
  locationLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightMedium];
  [cardView addSubview:locationLabel];
  self.locationLabel = locationLabel;

  UIButton *createButton = [UIButton buttonWithType:UIButtonTypeCustom];
  createButton.backgroundColor = [UIColor colorWithRed:0.30 green:0.92 blue:0.76 alpha:1.0];
  createButton.layer.cornerRadius = 20.0;
  createButton.layer.masksToBounds = NO;
  createButton.layer.shadowColor = [UIColor colorWithRed:0.15 green:0.90 blue:0.78 alpha:0.45].CGColor;
  createButton.layer.shadowOpacity = 1.0;
  createButton.layer.shadowOffset = CGSizeMake(0, 6);
  createButton.layer.shadowRadius = 14.0;
  [createButton addTarget:self action:@selector(tl_createButtonTapped) forControlEvents:UIControlEventTouchUpInside];
  [cardView addSubview:createButton];
  self.createButton = createButton;

  CAGradientLayer *gradientLayer = [CAGradientLayer layer];
  gradientLayer.colors = @[
    (__bridge id)[UIColor colorWithRed:0.37 green:0.95 blue:0.91 alpha:1.0].CGColor,
    (__bridge id)[UIColor colorWithRed:0.23 green:0.89 blue:0.63 alpha:1.0].CGColor
  ];
  gradientLayer.startPoint = CGPointMake(0.0, 0.5);
  gradientLayer.endPoint = CGPointMake(1.0, 0.5);
  gradientLayer.cornerRadius = 20.0;
  [createButton.layer insertSublayer:gradientLayer atIndex:0];
  self.createButtonGradientLayer = gradientLayer;

  UIImageView *createIconView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"hp_yield_leaf.png"]];
  createIconView.contentMode = UIViewContentModeScaleAspectFit;
  [createButton addSubview:createIconView];

  UILabel *createLabel = [[UILabel alloc] init];
  createLabel.text = @"新建";
  createLabel.textColor = [UIColor whiteColor];
  createLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightSemibold];
  [createButton addSubview:createLabel];

  UILabel *plantTagLabel = [[UILabel alloc] init];
  plantTagLabel.textColor = [UIColor whiteColor];
  plantTagLabel.font = [UIFont systemFontOfSize:16.0 weight:UIFontWeightSemibold];
  plantTagLabel.backgroundColor = [UIColor colorWithRed:0.30 green:0.92 blue:0.76 alpha:1.0];
  plantTagLabel.textAlignment = NSTextAlignmentCenter;
  plantTagLabel.layer.cornerRadius = 20.0;
  plantTagLabel.layer.masksToBounds = YES;
  plantTagLabel.hidden = YES;
  [cardView addSubview:plantTagLabel];
  self.plantTagLabel = plantTagLabel;

  UIButton *contentCardButton = [UIButton buttonWithType:UIButtonTypeCustom];
  contentCardButton.backgroundColor = [UIColor colorWithWhite:0.90 alpha:1.0];
  contentCardButton.layer.cornerRadius = 16.0;
  contentCardButton.layer.masksToBounds = YES;
  [contentCardButton addTarget:self action:@selector(tl_contentCardTapped) forControlEvents:UIControlEventTouchUpInside];
  [cardView addSubview:contentCardButton];
  self.contentCardButton = contentCardButton;

  UIImageView *contentImageView = [[UIImageView alloc] init];
  contentImageView.contentMode = UIViewContentModeScaleAspectFill;
  contentImageView.clipsToBounds = YES;
  contentImageView.hidden = YES;
  [contentCardButton addSubview:contentImageView];
  self.contentImageView = contentImageView;

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

  [avatarImageView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.equalTo(cardView).offset(16.0);
    make.top.equalTo(cardView).offset(16.0);
    make.width.height.mas_equalTo(50.0);
  }];

  [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.equalTo(avatarImageView.mas_right).offset(12.0);
    make.top.equalTo(avatarImageView).offset(2.0);
  }];

  [locationIconView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.equalTo(titleLabel);
    make.top.equalTo(titleLabel.mas_bottom).offset(6.0);
    make.width.height.mas_equalTo(13.0);
  }];

  [locationLabel mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.equalTo(locationIconView.mas_right).offset(4.0);
    make.centerY.equalTo(locationIconView);
  }];

  [createButton mas_makeConstraints:^(MASConstraintMaker *make) {
    make.right.equalTo(cardView).offset(-16.0);
    make.centerY.equalTo(avatarImageView);
    make.width.mas_equalTo(108.0);
    make.height.mas_equalTo(40.0);
  }];

  [createIconView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.equalTo(createButton).offset(14.0);
    make.centerY.equalTo(createButton);
    make.width.height.mas_equalTo(18.0);
  }];

  [createLabel mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.equalTo(createIconView.mas_right).offset(10.0);
    make.centerY.equalTo(createButton);
  }];

  [plantTagLabel mas_makeConstraints:^(MASConstraintMaker *make) {
    make.right.equalTo(cardView).offset(-16.0);
    make.centerY.equalTo(avatarImageView);
    make.width.mas_greaterThanOrEqualTo(86.0);
    make.height.mas_equalTo(40.0);
  }];

  [contentCardButton mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.equalTo(cardView).offset(10.0);
    make.right.equalTo(cardView).offset(-10.0);
    make.top.equalTo(avatarImageView.mas_bottom).offset(16.0);
    make.bottom.equalTo(cardView).offset(-10.0);
  }];

  [contentImageView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.edges.equalTo(contentCardButton);
  }];

  [plusHorizontalLine mas_makeConstraints:^(MASConstraintMaker *make) {
    make.center.equalTo(contentCardButton);
    make.width.mas_equalTo(72.0);
    make.height.mas_equalTo(8.0);
  }];

  [plusVerticalLine mas_makeConstraints:^(MASConstraintMaker *make) {
    make.center.equalTo(contentCardButton);
    make.width.mas_equalTo(8.0);
    make.height.mas_equalTo(72.0);
  }];
}

- (void)configureAsCreateCell {
  [self configureAsCreateCellWithLocationName:nil];
}

- (void)configureAsCreateCellWithLocationName:(nullable NSString *)locationName {
  [self tl_applyCurrentUserInfo];
  [self tl_applyLocationName:locationName];
  self.createButton.hidden = NO;
  self.plantTagLabel.hidden = YES;
  self.contentImageView.hidden = YES;
  self.contentImageView.image = nil;
  self.contentCardButton.backgroundColor = [UIColor colorWithWhite:0.90 alpha:1.0];
  self.plusHorizontalLine.hidden = NO;
  self.plusVerticalLine.hidden = NO;
  self.contentCardButton.userInteractionEnabled = YES;
}

- (void)configureWithPlantModel:(TLWPlantModel *)plantModel locationName:(nullable NSString *)locationName {
  [self tl_applyCurrentUserInfo];
  [self tl_applyLocationName:locationName];
  self.createButton.hidden = YES;
  self.plantTagLabel.hidden = NO;
  self.plantTagLabel.text = [NSString stringWithFormat:@"  %@  ", plantModel.plantName.length > 0 ? plantModel.plantName : @"未命名植物"];
  NSString *imageURLString = plantModel.imageUrl;
  UIImage *placeholderImage = [UIImage imageNamed:@"hp_avatar.png"];
  if (plantModel.localImage) {
    self.contentImageView.image = plantModel.localImage;
  } else if (imageURLString.length > 0) {
    [self.contentImageView sd_setImageWithURL:[NSURL URLWithString:imageURLString] placeholderImage:placeholderImage];
  } else {
    self.contentImageView.image = placeholderImage;
  }
  self.contentImageView.hidden = NO;
  self.contentCardButton.backgroundColor = [UIColor clearColor];
  self.plusHorizontalLine.hidden = YES;
  self.plusVerticalLine.hidden = YES;
  self.contentCardButton.userInteractionEnabled = YES;
}

- (void)tl_createButtonTapped {
  if (self.clickCreateButton) {
    self.clickCreateButton();
  }
}

- (void)tl_contentCardTapped {
  if (self.clickContentCard) {
    self.clickContentCard();
  }
}

@end
