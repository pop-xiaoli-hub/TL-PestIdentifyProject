//
//  TLWCommunityCell.m
//  TL-PestIdentify
//

#import "TLWCommunityCell.h"
#import "TLWCommunityPost.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import <Masonry/Masonry.h>

@interface TLWCommunityCell ()

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
  UIView *contentView = blurView.contentView;
  UIView *glassLayer = [[UIView alloc] init];
  glassLayer.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.32];
  glassLayer.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  [contentView addSubview:glassLayer];
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
  self.avatarView.image = [UIImage imageNamed:@"hp_avatar.png"];

  self.userLabel = [[UILabel alloc] init];
  self.userLabel.font = [UIFont systemFontOfSize:11];
  self.userLabel.textColor = [UIColor colorWithWhite:0.2 alpha:1.0];

  self.likeIconView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cp_heart.png"]];
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

  // 遮罩上的「发布中」文字 + 菊花
  UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
  spinner.color = [UIColor colorWithWhite:0.15 alpha:1.0];
  [spinner startAnimating];
  [self.pendingBlurView.contentView addSubview:spinner];

  self.pendingLabel = [[UILabel alloc] init];
  self.pendingLabel.text = @"发布中...";
  self.pendingLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
  self.pendingLabel.textColor = [UIColor colorWithWhite:0.15 alpha:1.0];
  [self.pendingBlurView.contentView addSubview:self.pendingLabel];

  [spinner mas_makeConstraints:^(MASConstraintMaker *make) {
    make.centerX.equalTo(self.pendingBlurView);
    make.centerY.equalTo(self.pendingBlurView).offset(-10);
  }];
  [self.pendingLabel mas_makeConstraints:^(MASConstraintMaker *make) {
    make.centerX.equalTo(self.pendingBlurView);
    make.top.equalTo(spinner.mas_bottom).offset(6);
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
    self.photoView.image = [UIImage imageNamed:@"cm_placeholder"];
  } else if ([first isKindOfClass:[UIImage class]]) {
    UIImage *img = (UIImage *)first;
    self.photoView.image = img ?: [UIImage imageNamed:@"cm_placeholder"];
  } else if ([first isKindOfClass:[NSString class]]) {
    NSString *urlStr = (NSString *)first;
    if (urlStr.length == 0) {
      self.photoView.image = [UIImage imageNamed:@"cm_placeholder"];
    } else {
      NSURL *url = [NSURL URLWithString:urlStr];
      // 仅加载展示，不参与瀑布流高度计算
      [self.photoView sd_setImageWithURL:url placeholderImage:[UIImage imageNamed:@"cm_placeholder"]];
    }
  } else {
    self.photoView.image = [UIImage imageNamed:@"cm_placeholder"];
  }
  [self.avatarView sd_setImageWithURL:[NSURL URLWithString:post.authorAvatar] placeholderImage:[UIImage imageNamed:@"hp_avatar.png"]];
  self.titleLabel.text = post.title.length > 0 ? post.title : post.content;
  self.userLabel.text = post.authorName;
  self.likeLabel.text = [NSString stringWithFormat:@"%@", post.likeCount];
  

  // 本地发布中：显示毛玻璃遮罩；上传完成后隐藏
  self.pendingBlurView.hidden = !post.isLocalPending;
}

@end
