//
//  TLWHomeCardCell.m
//  TL-PestIdentify
//
//  Created by xiaoli pop on 2026/3/9.
//

#import "TLWHomeCardCell.h"
#import "TLWWarningModel.h"
#import <Masonry.h>

@interface TLWHomeCardCell ()

@property (nonatomic, strong) UIView *cardShadowView;
@property (nonatomic, strong) UIView *cardContainerView;
@property (nonatomic, strong) UIVisualEffectView *blurView;
@property (nonatomic, strong) UIView *tintOverlayView;
@property (nonatomic, strong) UIImageView *leadingIconView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *detailLabel;
@property (nonatomic, strong) CAGradientLayer *shineGradientLayer;
@property (nonatomic, strong) CAGradientLayer *topShineGradientLayer;
@property (nonatomic, assign) BOOL warningExpanded;

@end

@implementation TLWHomeCardCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {

  if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
    if ([reuseIdentifier isEqualToString:@"kTLWHomeCardCellIdentifier1"]) {
      [self tl_setupWarningCardSubviews];
    } else {
      [self tl_setupFeatureCardSubviews];
    }
  }
  return self;
}

- (void)tl_configureWithWarning:(TLWWarningModel* )model {
  self.bodyLabel.text = [model.string copy];
  if (model.shouldExpand) {
    self.detailLabel.hidden = NO;
  } else {
    self.detailLabel.hidden = YES;
  }
}

- (void)tl_configureWarningExpanded:(BOOL)expanded {
  self.warningExpanded = expanded;
  self.bodyLabel.numberOfLines = expanded ? 0 : 3;
  self.bodyLabel.lineBreakMode = NSLineBreakByTruncatingTail;
  self.detailLabel.text = expanded ? @"点击收起" : @"查看详细>";
}

- (void)tl_setupWarningCardSubviews {
  self.selectionStyle = UITableViewCellSelectionStyleNone;
  self.backgroundColor = [UIColor clearColor];
  self.contentView.backgroundColor = [UIColor clearColor];
  self.selectedBackgroundView = [UIView new];
  self.selectedBackgroundView.backgroundColor = [UIColor clearColor];

  self.cardShadowView = [[UIView alloc] init];
  self.cardShadowView.backgroundColor = [UIColor clearColor];
  self.cardShadowView.layer.shadowColor = [UIColor blackColor].CGColor;
  self.cardShadowView.layer.shadowOpacity = 0.20;
  self.cardShadowView.layer.shadowRadius = 22.0;
  self.cardShadowView.layer.shadowOffset = CGSizeMake(0, 4);
  [self.contentView addSubview:self.cardShadowView];

  [self.cardShadowView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.equalTo(self.contentView).offset(16.0);
    make.right.equalTo(self.contentView).offset(-16.0);
    make.top.equalTo(self.contentView).offset(8.0);
    make.bottom.equalTo(self.contentView).offset(-8.0);
  }];

  _cardContainerView = [[UIView alloc] init];
  _cardContainerView.backgroundColor = [UIColor clearColor];
  _cardContainerView.layer.cornerRadius = 16.0;
  _cardContainerView.layer.masksToBounds = YES;

  [self.cardShadowView addSubview:_cardContainerView];

  [_cardContainerView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.edges.equalTo(self.cardShadowView);
  }];

  UIBlurEffectStyle blurStyle = UIBlurEffectStyleLight;
  if (@available(iOS 13.0, *)) {
    blurStyle = UIBlurEffectStyleSystemThinMaterialLight;
  }
  self.blurView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:blurStyle]];
  self.blurView.userInteractionEnabled = NO;
  self.blurView.alpha = 0.70;
  self.blurView.layer.cornerRadius = 16.0;
  self.blurView.layer.masksToBounds = YES;
  [self.cardContainerView addSubview:self.blurView];
  [self.blurView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.edges.equalTo(self.cardContainerView);
  }];

  self.tintOverlayView = [[UIView alloc] init];
  self.tintOverlayView.userInteractionEnabled = NO;
  self.tintOverlayView.backgroundColor = [UIColor colorWithRed:0.55 green:0.92 blue:0.90 alpha:0.12];
  [self.cardContainerView addSubview:self.tintOverlayView];
  [self.tintOverlayView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.edges.equalTo(self.cardContainerView);
  }];

  self.shineGradientLayer = [CAGradientLayer layer];
  self.shineGradientLayer.startPoint = CGPointMake(0.0, 0.0);
  self.shineGradientLayer.endPoint = CGPointMake(1.0, 1.0);
  self.shineGradientLayer.colors = @[
    (__bridge id)[UIColor colorWithWhite:1.0 alpha:0.80].CGColor,
    (__bridge id)[UIColor colorWithWhite:1.0 alpha:0.34].CGColor,
    (__bridge id)[UIColor colorWithWhite:1.0 alpha:0.0].CGColor
  ];
  self.shineGradientLayer.locations = @[@0.0, @0.60, @1.0];
  [self.cardContainerView.layer addSublayer:self.shineGradientLayer];

  self.topShineGradientLayer = [CAGradientLayer layer];
  self.topShineGradientLayer.startPoint = CGPointMake(0.2, 0.0);
  self.topShineGradientLayer.endPoint = CGPointMake(0.8, 1.0);
  self.topShineGradientLayer.colors = @[
    (__bridge id)[UIColor colorWithWhite:1.0 alpha:0.55].CGColor,
    (__bridge id)[UIColor colorWithWhite:1.0 alpha:0.18].CGColor,
    (__bridge id)[UIColor colorWithWhite:1.0 alpha:0.0].CGColor
  ];
  self.topShineGradientLayer.locations = @[@0.0, @0.35, @1.0];
  [self.cardContainerView.layer addSublayer:self.topShineGradientLayer];

  self.cardContainerView.layer.borderWidth = 1.0;
  self.cardContainerView.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.45].CGColor;

  self.leadingIconView = [[UIImageView alloc] init];
  self.leadingIconView.tintColor = [UIColor colorWithRed:1.0 green:0.55 blue:0.0 alpha:1.0];
  if (@available(iOS 13.0, *)) {
    UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:20.0 weight:UIImageSymbolWeightSemibold];
    self.leadingIconView.image = [[UIImage systemImageNamed:@"exclamationmark.warninglight.fill"] imageWithConfiguration:config];
  }
  [_cardContainerView addSubview:self.leadingIconView];

  self.titleLabel = [[UILabel alloc] init];
  self.titleLabel.text = @"【占位预警卡片】";
  self.titleLabel.textColor = [UIColor colorWithWhite:0.1 alpha:1.0];
  self.titleLabel.font = [UIFont systemFontOfSize:20.0 weight:UIFontWeightHeavy];
  [_cardContainerView addSubview:self.titleLabel];

  self.bodyLabel = [[UILabel alloc] init];
  self.bodyLabel.textColor = [UIColor colorWithWhite:0.15 alpha:0.9];
  self.bodyLabel.font = [UIFont systemFontOfSize:16.0 weight:UIFontWeightRegular];
  self.bodyLabel.numberOfLines = 3; // 默认最多 3 行
  self.bodyLabel.lineBreakMode = NSLineBreakByTruncatingTail;
  [_cardContainerView addSubview:self.bodyLabel];

  self.detailLabel = [[UILabel alloc] init];
  self.detailLabel.text = @"查看详细>";
  self.detailLabel.textColor = [UIColor colorWithWhite:0.25 alpha:1.0];
  self.detailLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightMedium];
  self.detailLabel.userInteractionEnabled = YES;
  [_cardContainerView addSubview:self.detailLabel];
  UITapGestureRecognizer *detailTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tl_didTapWarningDetail)];
  [self.detailLabel addGestureRecognizer:detailTap];

  [self.leadingIconView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.equalTo(self.cardContainerView).offset(16.0);
    make.top.equalTo(self.cardContainerView).offset(14.0);
    make.width.height.mas_equalTo(22.0);
  }];

  [self.detailLabel mas_makeConstraints:^(MASConstraintMaker *make) {
    make.right.equalTo(self.cardContainerView).offset(-5.0);
    make.bottom.equalTo(self.cardContainerView).offset(-10.0);
    make.width.mas_equalTo(70);
  }];

  [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.equalTo(self.leadingIconView.mas_right).offset(10.0);
    make.right.lessThanOrEqualTo(self.cardContainerView).offset(-30.0);
    make.centerY.equalTo(self.leadingIconView);
  }];

  [self.bodyLabel mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.equalTo(self.cardContainerView).offset(16.0);
    make.right.equalTo(self.cardContainerView).offset(-10);
    make.top.equalTo(self.leadingIconView.mas_bottom).offset(10.0);
    make.bottom.equalTo(self.detailLabel.mas_top).offset(-10);
  }];
}

- (void)tl_setupFeatureCardSubviews {
  self.selectionStyle = UITableViewCellSelectionStyleNone;
  self.backgroundColor = [UIColor clearColor];
  self.contentView.backgroundColor = [UIColor clearColor];
  self.selectedBackgroundView = [UIView new];
  self.selectedBackgroundView.backgroundColor = [UIColor clearColor];

  UIView *container = [[UIView alloc] init];
  container.backgroundColor = [UIColor clearColor];
  [self.contentView addSubview:container];
  [container mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.equalTo(self.contentView).offset(16.0);
    make.right.equalTo(self.contentView).offset(-16.0);
    make.top.equalTo(self.contentView).offset(2.0);
    make.bottom.equalTo(self.contentView).offset(-2.0);
  }];

  // 左侧垂直两个小卡片
  UIView *leftStack = [[UIView alloc] init];
  leftStack.backgroundColor = [UIColor clearColor];
  [container addSubview:leftStack];

  // 右侧大卡片（正方形）
  UIView *rightCardShadow = [[UIView alloc] init];
  rightCardShadow.backgroundColor = [UIColor clearColor];
  rightCardShadow.layer.shadowColor = [UIColor colorWithRed:0.0 green:0.6 blue:0.45 alpha:1.0].CGColor;
  rightCardShadow.layer.shadowOpacity = 0.32;
  rightCardShadow.layer.shadowRadius = 24.0;
  rightCardShadow.layer.shadowOffset = CGSizeMake(0, 8);
  [container addSubview:rightCardShadow];

  // 左右等宽 + 中间 12pt，右侧为正方形：width = height = (container.width - 12) / 2，避免与 contentView 固定高度冲突
  [rightCardShadow mas_makeConstraints:^(MASConstraintMaker *make) {
    make.centerY.equalTo(container);
    make.right.equalTo(container);
    make.width.equalTo(container.mas_width).multipliedBy(0.5).offset(-6.0); // (width - 12) / 2
    make.height.equalTo(rightCardShadow.mas_width); // 正方形
  }];

  [leftStack mas_makeConstraints:^(MASConstraintMaker *make) {
    make.centerY.equalTo(container);
    make.left.equalTo(container);
    make.height.equalTo(rightCardShadow);
    make.right.equalTo(rightCardShadow.mas_left).offset(-12.0);
    make.width.equalTo(rightCardShadow); // 左右等宽
  }];

  // 左侧两个小卡片
  UIView *recordCard = [self tl_createFeatureRecordCardInStack:leftStack];
  UIView *assistantCard = [self tl_createFeatureAssistantCardBelowRecordCardInStack:leftStack recordCard:recordCard];

  // 右侧拍照识别大卡片
  [self tl_createFeatureRightPhotoCardInShadow:rightCardShadow];
}

- (UIView *)tl_createFeatureRecordCardInStack:(UIView *)leftStack {
  UIView *recordCard = [[UIView alloc] init];
  recordCard.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.96];
  recordCard.layer.cornerRadius = 16.0;
  recordCard.layer.masksToBounds = YES;
    recordCard.userInteractionEnabled = YES;
  [leftStack addSubview:recordCard];

    UITapGestureRecognizer *recordTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tl_didTapRecordCard)];
    [recordCard addGestureRecognizer:recordTap];

  [recordCard mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.right.top.equalTo(leftStack);
    make.height.equalTo(leftStack.mas_height).multipliedBy(0.48);
  }];

  UIImageView *recordOuterIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"hp_identification_1.png"]];
  recordOuterIcon.contentMode = UIViewContentModeScaleAspectFill;
  recordOuterIcon.clipsToBounds = YES;
  recordOuterIcon.layer.cornerRadius = 18.0;

  UILabel *recordTitle = [[UILabel alloc] init];
  recordTitle.text = @"识别记录";
  recordTitle.textColor = [UIColor colorWithWhite:0.15 alpha:1.0];
  recordTitle.font = [UIFont systemFontOfSize:18.0 weight:UIFontWeightSemibold];

  UILabel *recordSub = [[UILabel alloc] init];
  recordSub.text = @"共5次识别记录";
  recordSub.textColor = [UIColor colorWithWhite:0.45 alpha:1.0];
  recordSub.font = [UIFont systemFontOfSize:13.0];

  [recordCard addSubview:recordOuterIcon];
  [recordCard addSubview:recordTitle];
  [recordCard addSubview:recordSub];

  [recordOuterIcon mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.equalTo(recordCard).offset(10);
    make.centerY.equalTo(recordCard);
    make.width.mas_equalTo(70.0);
    make.height.mas_equalTo(70.0);
  }];
  [recordTitle mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.equalTo(recordOuterIcon.mas_right).offset(5.0);
    make.top.equalTo(recordOuterIcon.mas_top).offset(10);
  }];
  [recordSub mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.equalTo(recordTitle);
    make.top.equalTo(recordTitle.mas_bottom).offset(6.0);
  }];

  return recordCard;
}

- (UIView *)tl_createFeatureAssistantCardBelowRecordCardInStack:(UIView *)leftStack recordCard:(UIView *)recordCard {
  UIView *assistantCard = [[UIView alloc] init];
  assistantCard.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.96];
  assistantCard.layer.cornerRadius = 16.0;
  assistantCard.layer.masksToBounds = YES;
    assistantCard.userInteractionEnabled = YES;
  [leftStack addSubview:assistantCard];

    UITapGestureRecognizer *assistantTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tl_didTapAssistantCard)];
    [assistantCard addGestureRecognizer:assistantTap];

  [assistantCard mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.right.bottom.equalTo(leftStack);
    make.height.equalTo(leftStack.mas_height).multipliedBy(0.48);
  }];

  UIImageView *assistantOuterIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"hp_smartAssistant_1.png"]];
  assistantOuterIcon.contentMode = UIViewContentModeScaleAspectFill;
  assistantOuterIcon.clipsToBounds = YES;
  assistantOuterIcon.layer.cornerRadius = 18.0;

  UILabel *assistantTitle = [[UILabel alloc] init];
  assistantTitle.text = @"AI助手";
  assistantTitle.textColor = [UIColor colorWithWhite:0.15 alpha:1.0];
  assistantTitle.font = [UIFont systemFontOfSize:18.0 weight:UIFontWeightSemibold];

  UILabel *assistantSub = [[UILabel alloc] init];
  assistantSub.text = @"询问病虫害难题";
  assistantSub.textColor =  [UIColor colorWithWhite:0.45 alpha:1.0];
  assistantSub.font = [UIFont systemFontOfSize:13.0];

  [assistantCard addSubview:assistantOuterIcon];
  [assistantCard addSubview:assistantTitle];
  [assistantCard addSubview:assistantSub];

  [assistantOuterIcon mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.equalTo(assistantCard).offset(3.0);
    make.top.equalTo(assistantCard.mas_top).offset(8);
    make.width.mas_equalTo(83.0);
    make.height.mas_equalTo(83.0);
  }];


  [assistantTitle mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.equalTo(assistantOuterIcon.mas_right).offset(-3);
    make.top.equalTo(assistantOuterIcon.mas_top).offset(13);
  }];
  [assistantSub mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.equalTo(assistantTitle);
    make.top.equalTo(assistantTitle.mas_bottom).offset(6.0);
  }];

  return assistantCard;
}

- (void)tl_createFeatureRightPhotoCardInShadow:(UIView *)rightCardShadow {
  UIView *rightCard = [[UIView alloc] init];
  rightCard.layer.cornerRadius = 24.0;
  rightCard.layer.masksToBounds = YES;
    rightCard.userInteractionEnabled = YES;
  [rightCardShadow addSubview:rightCard];
  [rightCard mas_makeConstraints:^(MASConstraintMaker *make) {
    make.edges.equalTo(rightCardShadow);
  }];
  UITapGestureRecognizer *assistantTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tl_didTapPhotoCard)];
  [rightCardShadow addGestureRecognizer:assistantTap];
  CAGradientLayer *rightGradient = [CAGradientLayer layer];
  rightGradient.startPoint = CGPointMake(0.0, 0.0);
  rightGradient.endPoint = CGPointMake(1.0, 1.0);
  rightGradient.colors = @[
    (__bridge id)[UIColor colorWithRed:0.20 green:0.92 blue:0.74 alpha:1.0].CGColor,
    (__bridge id)[UIColor colorWithRed:0.00 green:0.71 blue:0.89 alpha:1.0].CGColor
  ];
  rightGradient.locations = @[@0.0, @1.0];
  rightGradient.cornerRadius = 24.0;
  [rightCard.layer insertSublayer:rightGradient atIndex:0];

  UIImageView* imageView1 = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"hp_identify_4.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
  [rightCardShadow addSubview:imageView1];
  [imageView1 mas_makeConstraints:^(MASConstraintMaker *make) {
      make.left.equalTo(rightCardShadow.mas_left).offset(40);
      make.top.equalTo(rightCardShadow.mas_top).offset(40);
  }];
  UIImageView* imageView2 = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"hp_identify_1.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
  [rightCardShadow addSubview:imageView2];
  [imageView2 mas_makeConstraints:^(MASConstraintMaker *make) {
      make.center.equalTo(rightCardShadow);
    make.width.mas_equalTo(112.24);
    make.height.mas_equalTo(99.98);
  }];

  UIImageView* imageView3 = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"hp_identify_2.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
  [rightCardShadow addSubview:imageView3];
  [imageView3 mas_makeConstraints:^(MASConstraintMaker *make) {
    make.center.equalTo(imageView2);
    make.height.width.mas_equalTo(35);
  }];

  UIImageView* imageView4 = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"hp_identify_3.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
  [rightCardShadow addSubview:imageView4];
  [imageView4 mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.equalTo(imageView3.mas_right).offset(2);
    make.top.equalTo(imageView3).offset(-2);
    make.height.width.mas_equalTo(10);
  }];

  UIImageView* imageView5 = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"hp_identify_5.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
  [rightCardShadow addSubview:imageView5];
  [imageView5 mas_makeConstraints:^(MASConstraintMaker *make) {
    make.bottom.equalTo(imageView2.mas_top).offset(18);
    make.right.equalTo(imageView2.mas_right).offset(-14);
  }]; 
  UILabel *photoTitle = [[UILabel alloc] init];
  photoTitle.text = @"拍照识别";
  photoTitle.textColor = [UIColor whiteColor];
  photoTitle.font = [UIFont systemFontOfSize:20.0 weight:UIFontWeightBold];

  UILabel *photoSub = [[UILabel alloc] init];
  photoSub.text = @"识别病虫害";
  photoSub.textColor = [UIColor colorWithWhite:1.0 alpha:0.9];
  photoSub.font = [UIFont systemFontOfSize:14.0];

  [rightCard addSubview:photoTitle];
  [rightCard addSubview:photoSub];

  [photoTitle mas_makeConstraints:^(MASConstraintMaker *make) {
    make.centerX.equalTo(rightCard);
    make.top.equalTo(imageView2.mas_bottom).offset(-10);
  }];
  [photoSub mas_makeConstraints:^(MASConstraintMaker *make) {
    make.centerX.equalTo(photoTitle);
    make.top.equalTo(photoTitle.mas_bottom);
  }];

  // 让右侧渐变层在布局后正确填充
  dispatch_async(dispatch_get_main_queue(), ^{
    rightGradient.frame = rightCard.bounds;
  });
}

- (void)tl_didTapRecordCard {
    if (self.clickRecordCard) {
        self.clickRecordCard();
    }
}

- (void)tl_didTapAssistantCard {
    NSLog(@"点击按钮-助手");
}

- (void)tl_didTapPhotoCard {
  if (self.clickPhotoIdentification) {
    NSLog(@"点击按钮-拍照");
    self.clickPhotoIdentification();
  }
}

- (void)tl_didTapWarningClose {
    NSLog(@"点击预警关闭");
}

- (void)tl_didTapWarningDetail {
  if (self.clickWarningDetail) {
    self.clickWarningDetail();
  }
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
  // 避免系统高亮态把自定义渐变卡片“压暗/变色”
  [super setHighlighted:NO animated:animated];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
  // 避免系统选中态把自定义渐变卡片“压暗/变色”
  [super setSelected:NO animated:animated];
}

- (void)layoutSubviews {
  [super layoutSubviews];
  self.shineGradientLayer.frame = self.cardContainerView.bounds;
  self.topShineGradientLayer.frame = CGRectMake(0, 0, self.cardContainerView.bounds.size.width, self.cardContainerView.bounds.size.height * 0.72);
  self.cardShadowView.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.cardShadowView.bounds cornerRadius:16.0].CGPath;
}

@end

