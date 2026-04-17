//
//  TLWCommunityCell.m
//  TL-PestIdentify
//

#import "TLWCommunityCell.h"
#import "TLWCommunityPost.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import <Masonry/Masonry.h>
#import "TLWLoadingIndicator.h"

@interface TLWCommunityCell ()

@property (nonatomic, strong) UIVisualEffectView *backgroundBlurView;
@property (nonatomic, strong) UIView *backgroundGlassLayer;
@property (nonatomic, strong) UIImageView *photoView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIImageView *avatarView;
@property (nonatomic, strong) UILabel *userLabel;
@property (nonatomic, strong) UIImageView *likeIconView;
@property (nonatomic, strong) UILabel *likeLabel;
/// 本地发布中的毛玻璃遮罩（叠在 photoView 顶部）
@property (nonatomic, strong) UIVisualEffectView *pendingBlurView;
@property (nonatomic, strong) UILabel *pendingLabel;

@end

@implementation TLWCommunityCell

- (NSString *)tl_displayTitleTextForPost:(TLWCommunityPost *)post {
  NSString *rawTitle = post.title.length > 0 ? post.title : post.content;
  if (![rawTitle isKindOfClass:[NSString class]]) {
    return @"";
  }

  NSString *trimmedTitle = [rawTitle stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
  if (trimmedTitle.length <= 20) {//小于直接返回
    return trimmedTitle;
  }
  return [[trimmedTitle substringToIndex:20] stringByAppendingString:@"..."];//过长截取
}

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    [self setUpCellBackView];
    [self setupSubviews];
  }
  return self;
}

- (void)setUpCellBackView {
  // 更强对比的毛玻璃背景
  UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemMaterialLight];
  UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
  blurView.layer.masksToBounds = YES;
  blurView.layer.cornerRadius = 14.0;
  [self.contentView addSubview:blurView];
  self.backgroundBlurView = blurView;
  UIView *contentView = blurView.contentView;
  UIView *glassLayer = [[UIView alloc] init];
  glassLayer.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.32];
  glassLayer.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  [contentView addSubview:glassLayer];
  self.backgroundGlassLayer = glassLayer;
  // 边框
  blurView.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.55].CGColor;
  blurView.layer.borderWidth = 1.0;
  [blurView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.edges.equalTo(self.contentView);
  }];
  [glassLayer mas_makeConstraints:^(MASConstraintMaker *make) {
    make.edges.equalTo(contentView);
  }];
}

- (void)prepareForReuse {
  [super prepareForReuse];
  self.photoView.image = nil;
  self.titleLabel.text = nil;
  self.userLabel.text = nil;
  self.likeLabel.text = nil;
  self.pendingBlurView.hidden = YES;
}

- (void)setupSubviews {
  // 让内容视图透明一些，突出毛玻璃与背景的对比
  self.backgroundColor = [UIColor clearColor];
  self.contentView.backgroundColor = [UIColor clearColor];
  self.contentView.layer.cornerRadius = 14.0;
  self.contentView.layer.masksToBounds = YES;

  // 给 cell 增加轻微阴影，让玻璃板从背景中“浮”起来
  self.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.35].CGColor;
  self.layer.shadowOpacity = 1.0;
  self.layer.shadowOffset = CGSizeMake(0, 8);
  self.layer.shadowRadius = 12.0;
  self.layer.masksToBounds = NO;

  self.photoView = [[UIImageView alloc] init];
  self.photoView.contentMode = UIViewContentModeScaleAspectFill;
  self.photoView.clipsToBounds = YES;

  self.titleLabel = [[UILabel alloc] init];
  self.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
  self.titleLabel.textColor = [UIColor blackColor];
  self.titleLabel.numberOfLines = 2;

  self.avatarView = [[UIImageView alloc] init];
  self.avatarView.contentMode = UIViewContentModeScaleAspectFill;
  self.avatarView.clipsToBounds = YES;
  self.avatarView.layer.cornerRadius = 10.0;
  self.avatarView.image = [UIImage imageNamed:@"hp_avatar"];

  self.userLabel = [[UILabel alloc] init];
  self.userLabel.font = [UIFont systemFontOfSize:11];
  self.userLabel.textColor = [UIColor colorWithWhite:0.2 alpha:1.0];

  self.likeIconView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cp_heart"]];
  self.likeIconView.contentMode = UIViewContentModeScaleAspectFit;

  self.likeLabel = [[UILabel alloc] init];
  self.likeLabel.font = [UIFont systemFontOfSize:11];
  self.likeLabel.textColor = [UIColor colorWithWhite:0.4 alpha:1.0];

  [self.contentView addSubview:self.photoView];
  [self.contentView addSubview:self.titleLabel];
  [self.contentView addSubview:self.avatarView];
  [self.contentView addSubview:self.userLabel];
  [self.contentView addSubview:self.likeIconView];
  [self.contentView addSubview:self.likeLabel];

  [self.photoView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.left.right.equalTo(self.contentView);
    //make.height.greaterThanOrEqualTo(@80);
    make.height.equalTo(self.contentView.mas_height).multipliedBy(0.7);
  }];

  [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(self.photoView.mas_bottom).offset(6);
    make.left.equalTo(self.contentView).offset(8);
    make.right.equalTo(self.contentView).offset(-8);
  }];

  [self.avatarView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.equalTo(self.contentView).offset(8);
    make.bottom.equalTo(self.contentView).offset(-6);
    make.width.height.mas_equalTo(20);
  }];

  [self.userLabel mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.equalTo(self.avatarView.mas_right).offset(6);
    make.centerY.equalTo(self.avatarView);
  }];

  [self.likeIconView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.right.equalTo(self.contentView).offset(-8);
    make.centerY.equalTo(self.avatarView);
    make.width.height.mas_equalTo(14);
  }];

  [self.likeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
    make.right.equalTo(self.likeIconView.mas_left).offset(-4);
    make.centerY.equalTo(self.avatarView);
  }];

  // 本地发布中的毛玻璃遮罩，叠在整个 cell 顶部，默认隐藏
  UIBlurEffect *pendingBlur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterialLight];
  self.pendingBlurView = [[UIVisualEffectView alloc] initWithEffect:pendingBlur];
  self.pendingBlurView.layer.cornerRadius = 14.0;
  self.pendingBlurView.layer.masksToBounds = YES;
  self.pendingBlurView.hidden = YES;
  [self.contentView addSubview:self.pendingBlurView];
  [self.pendingBlurView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.edges.equalTo(self.contentView);
  }];

  // 遮罩上的「发布中」旋转 loading + 文字
  UIImage *loadingImage = [UIImage imageNamed:@"Ip_load"];
  UIImageView *loadingIV = [[UIImageView alloc] initWithImage:loadingImage];
  loadingIV.contentMode = UIViewContentModeScaleAspectFit;
  [self.pendingBlurView.contentView addSubview:loadingIV];

  CABasicAnimation *rotation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
  rotation.fromValue = @(0);
  rotation.toValue = @(M_PI * 2);
  rotation.duration = 1.0;
  rotation.repeatCount = HUGE_VALF;
  rotation.removedOnCompletion = NO;
  [loadingIV.layer addAnimation:rotation forKey:@"tl_loading_rotate"];

  self.pendingLabel = [[UILabel alloc] init];
  self.pendingLabel.text = @"发布中...";
  self.pendingLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
  self.pendingLabel.textColor = [UIColor colorWithWhite:0.15 alpha:1.0];
  [self.pendingBlurView.contentView addSubview:self.pendingLabel];

  [loadingIV mas_makeConstraints:^(MASConstraintMaker *make) {
    make.centerX.equalTo(self.pendingBlurView);
    make.centerY.equalTo(self.pendingBlurView).offset(-10);
    make.width.height.mas_equalTo(30);
  }];
  [self.pendingLabel mas_makeConstraints:^(MASConstraintMaker *make) {
    make.centerX.equalTo(self.pendingBlurView);
    make.top.equalTo(loadingIV.mas_bottom).offset(6);
  }];
}

- (void)setElderModeEnabled:(BOOL)elderModeEnabled {
  _elderModeEnabled = elderModeEnabled;

  self.contentView.layer.cornerRadius = elderModeEnabled ? 22.0 : 14.0;
  self.backgroundBlurView.layer.cornerRadius = elderModeEnabled ? 22.0 : 14.0;
  self.pendingBlurView.layer.cornerRadius = elderModeEnabled ? 22.0 : 14.0;

  self.backgroundBlurView.effect = elderModeEnabled ? nil : [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemMaterialLight];
  self.backgroundBlurView.backgroundColor = elderModeEnabled
    ? [[UIColor whiteColor] colorWithAlphaComponent:0.98]
    : [UIColor clearColor];
  self.backgroundGlassLayer.backgroundColor = elderModeEnabled
    ? [UIColor clearColor]
    : [[UIColor whiteColor] colorWithAlphaComponent:0.32];
  self.backgroundBlurView.layer.borderWidth = elderModeEnabled ? 0.0 : 1.0;

  self.layer.shadowColor = elderModeEnabled
    ? [UIColor colorWithRed:0.56 green:0.62 blue:0.62 alpha:0.24].CGColor
    : [UIColor colorWithWhite:0 alpha:0.35].CGColor;
  self.layer.shadowOffset = elderModeEnabled ? CGSizeMake(0, 6) : CGSizeMake(0, 8);
  self.layer.shadowRadius = elderModeEnabled ? 16.0 : 12.0;

  self.titleLabel.font = [UIFont systemFontOfSize:(elderModeEnabled ? 18.0 : 13.0)
                                           weight:UIFontWeightSemibold];
  self.titleLabel.numberOfLines = elderModeEnabled ? 3 : 2;
  self.userLabel.font = [UIFont systemFontOfSize:(elderModeEnabled ? 16.0 : 11.0)
                                          weight:(elderModeEnabled ? UIFontWeightMedium : UIFontWeightRegular)];
  self.avatarView.layer.cornerRadius = elderModeEnabled ? 18.0 : 10.0;
  self.likeIconView.hidden = elderModeEnabled;
  self.likeLabel.hidden = elderModeEnabled;
  self.pendingLabel.font = [UIFont systemFontOfSize:(elderModeEnabled ? 14.0 : 12.0)
                                             weight:UIFontWeightMedium];

  [self.avatarView mas_updateConstraints:^(MASConstraintMaker *make) {
    make.width.height.mas_equalTo(elderModeEnabled ? 36.0 : 20.0);
  }];
  [self.titleLabel mas_updateConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(self.photoView.mas_bottom).offset(elderModeEnabled ? 10.0 : 6.0);
    make.left.equalTo(self.contentView).offset(elderModeEnabled ? 14.0 : 8.0);
    make.right.equalTo(self.contentView).offset(elderModeEnabled ? -14.0 : -8.0);
  }];
  [self.avatarView mas_updateConstraints:^(MASConstraintMaker *make) {
    make.left.equalTo(self.contentView).offset(elderModeEnabled ? 14.0 : 8.0);
    make.bottom.equalTo(self.contentView).offset(elderModeEnabled ? -12.0 : -6.0);
  }];
  [self.userLabel mas_updateConstraints:^(MASConstraintMaker *make) {
    make.left.equalTo(self.avatarView.mas_right).offset(elderModeEnabled ? 10.0 : 6.0);
  }];
}

//- (void)configureWithPost:(TLWCommunityPost *)post {
//  id first = (post.images.count > 0) ? post.images.firstObject : nil;
//  if (!first || first == [NSNull null]) {
//    self.photoView.image = [UIImage imageNamed:@"cm_placeholder"];
//  } else if ([first isKindOfClass:[UIImage class]]) {
//    UIImage *img = (UIImage *)first;
//    self.photoView.image = img ?: [UIImage imageNamed:@"cm_placeholder"];
//  } else if ([first isKindOfClass:[NSString class]]) {
//    NSString *urlStr = (NSString *)first;
//    if (urlStr.length == 0) {
//      self.photoView.image = [UIImage imageNamed:@"cm_placeholder"];
//    } else {
//      NSURL *url = [NSURL URLWithString:urlStr];
//      // 仅加载展示，不参与瀑布流高度计算
//      [self.photoView sd_setImageWithURL:url placeholderImage:[UIImage imageNamed:@"cm_placeholder"]];
//    }
//  } else {
//    self.photoView.image = [UIImage imageNamed:@"cm_placeholder"];
//  }
//
//  self.titleLabel.text = post.title.length > 0 ? post.title : post.content;
//  self.userLabel.text = post.authorName;
//  self.likeLabel.text = [NSString stringWithFormat:@"%ld", (long)post.likeCount];
//}

- (void)configureWithPost:(TLWCommunityPost *)post {
  id first = (post.images.count > 0) ? post.images.firstObject : nil;
  if (!first || first == [NSNull null]) {
    self.photoView.image = [UIImage imageNamed:@"cp_placeholder"];
  } else if ([first isKindOfClass:[UIImage class]]) {
    UIImage *img = (UIImage *)first;
    self.photoView.image = img ?: [UIImage imageNamed:@"cp_placeholder"];
  } else if ([first isKindOfClass:[NSString class]]) {
    NSString *urlStr = (NSString *)first;
    if (urlStr.length == 0) {
      self.photoView.image = [UIImage imageNamed:@"cp_placeholder"];
    } else {
      NSURL *url = [NSURL URLWithString:urlStr];
      // 仅加载展示，不参与瀑布流高度计算
      [self.photoView sd_setImageWithURL:url placeholderImage:[UIImage imageNamed:@"cp_placeholder"]];
    }
  } else {
    self.photoView.image = [UIImage imageNamed:@"cp_placeholder"];
  }
  [self.avatarView sd_setImageWithURL:[NSURL URLWithString:post.authorAvatar] placeholderImage:[UIImage imageNamed:@"hp_avatar"]];
  self.titleLabel.text = [self tl_displayTitleTextForPost:post];
  self.userLabel.text = post.authorName;
  self.likeLabel.text = [NSString stringWithFormat:@"%@", post.likeCount];
  [self setElderModeEnabled:self.elderModeEnabled];

  // 本地发布中：显示毛玻璃遮罩；上传完成后隐藏
  self.pendingBlurView.hidden = !post.isLocalPending;
}

@end
