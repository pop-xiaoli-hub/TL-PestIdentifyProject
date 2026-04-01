//
//  TLWPostDetailHeaderView.m
//  TL-PestIdentify
//

#import "TLWPostDetailHeaderView.h"
#import "TLWCommunityPost.h"
#import <Masonry/Masonry.h>
#import <SDWebImage/UIImageView+WebCache.h>

static CGFloat const kBannerHeight  = 500.0;
static CGFloat const kHorizontalPad = 16.0;

@interface TLWPostDetailHeaderView () <UIScrollViewDelegate>
@property (nonatomic, strong) UIScrollView  *bannerScrollView;
@property (nonatomic, strong) UIPageControl *pageControl;
@property (nonatomic, strong) NSTimer       *autoScrollTimer;
@property (nonatomic, assign) NSInteger      currentPage;
@property (nonatomic, strong) NSArray       *images;
@property (nonatomic, strong) UIImageView   *avatarView;
@property (nonatomic, strong) UILabel       *nameLabel;
@property (nonatomic, strong) UILabel       *dateLabel;
@property (nonatomic, strong) UILabel       *titleLabel;
@property (nonatomic, strong) UILabel       *contentLabel;
@property (nonatomic, strong) UIScrollView  *tagScrollView;
@property (nonatomic, strong) UIView        *divider;
@property (nonatomic, strong) UILabel       *commentSectionLabel;
@end

@implementation TLWPostDetailHeaderView

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    self.backgroundColor = [UIColor whiteColor];
    [self buildBanner];
    [self buildAuthorBar];
    [self buildContent];
    [self buildTagRow];
    [self buildCommentDivider];
  }
  return self;
}

- (void)dealloc {
  [self.autoScrollTimer invalidate];
  self.autoScrollTimer = nil;
}

- (void)didMoveToWindow {
  [super didMoveToWindow];
  if (!self.window) {
    [self.autoScrollTimer invalidate];
    self.autoScrollTimer = nil;
  }
}

- (void)buildBanner {
  self.bannerScrollView = [[UIScrollView alloc] init];
  self.bannerScrollView.pagingEnabled = YES;
  self.bannerScrollView.showsHorizontalScrollIndicator = NO;
  self.bannerScrollView.showsVerticalScrollIndicator = NO;
  self.bannerScrollView.delegate = self;
  self.bannerScrollView.backgroundColor = [UIColor colorWithWhite:0.93 alpha:1.0];
  [self addSubview:self.bannerScrollView];

  self.pageControl = [[UIPageControl alloc] init];
  self.pageControl.currentPageIndicatorTintColor = [UIColor colorWithRed:0.18 green:0.72 blue:0.45 alpha:1.0];
  self.pageControl.pageIndicatorTintColor = [UIColor colorWithWhite:0.75 alpha:1.0];
  self.pageControl.hidesForSinglePage = YES;
  [self addSubview:self.pageControl];

  [self.bannerScrollView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.left.right.equalTo(self);
    make.height.mas_equalTo(kBannerHeight);
  }];
  [self.pageControl mas_makeConstraints:^(MASConstraintMaker *make) {
    make.bottom.equalTo(self.bannerScrollView).offset(-10);
    make.centerX.equalTo(self);
    make.height.mas_equalTo(20);
  }];
}

- (void)buildAuthorBar {
  self.avatarView = [[UIImageView alloc] init];
  self.avatarView.contentMode = UIViewContentModeScaleAspectFill;
  self.avatarView.clipsToBounds = YES;
  self.avatarView.layer.cornerRadius = 23.0;
  self.avatarView.backgroundColor = [UIColor colorWithWhite:0.88 alpha:1.0];
  self.avatarView.image = [UIImage imageNamed:@"hp_avatar.png"];
  [self addSubview:self.avatarView];

  self.nameLabel = [[UILabel alloc] init];
  self.nameLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
  self.nameLabel.textColor = [UIColor colorWithWhite:0.1 alpha:1.0];
  [self addSubview:self.nameLabel];

  self.dateLabel = [[UILabel alloc] init];
  self.dateLabel.font = [UIFont systemFontOfSize:12];
  self.dateLabel.textColor = [UIColor colorWithWhite:0.55 alpha:1.0];
  self.dateLabel.text = @"刚刚";
  [self addSubview:self.dateLabel];

  // ---- 点赞组：图标 + 数量 ----
  self.likeButton = [UIButton buttonWithType:UIButtonTypeCustom];
  [self.likeButton setImage:[UIImage imageNamed:@"cp_isLiked-1.png"] forState:UIControlStateNormal];
  self.likeButton.imageView.contentMode = UIViewContentModeScaleAspectFit;

  [self addSubview:self.likeButton];

  self.likedCountLabel = [[UILabel alloc] init];
  self.likedCountLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
  self.likedCountLabel.text = @"0";
  self.likedCountLabel.textColor = [UIColor colorWithWhite:0.45 alpha:1.0];
  self.likedCountLabel.textAlignment = NSTextAlignmentLeft;
  [self addSubview:self.likedCountLabel];

  // ---- 收藏组：图标 + 数量 ----
  self.collectButton = [UIButton buttonWithType:UIButtonTypeCustom];
  [self.collectButton setImage:[UIImage imageNamed:@"cp_collected-1.png"] forState:UIControlStateNormal];
  self.collectButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
  [self addSubview:self.collectButton];

  self.collectedCountLabel = [[UILabel alloc] init];
  self.collectedCountLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
  self.collectedCountLabel.text = @"0";
  self.collectedCountLabel.textColor = [UIColor colorWithWhite:0.45 alpha:1.0];
  self.collectedCountLabel.textAlignment = NSTextAlignmentLeft;
  [self addSubview:self.collectedCountLabel];

  // 头像
  [self.avatarView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.equalTo(self).offset(kHorizontalPad);
    make.top.equalTo(self.bannerScrollView.mas_bottom).offset(14);
    make.width.height.mas_equalTo(46);
  }];
  // 用户名
  [self.nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.equalTo(self.avatarView.mas_right).offset(10);
    make.top.equalTo(self.avatarView).offset(3);
  }];
  // 时间
  [self.dateLabel mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.equalTo(self.nameLabel);
    make.top.equalTo(self.nameLabel.mas_bottom).offset(4);
  }];

  // 点赞数字（最右）
  [self.likedCountLabel mas_makeConstraints:^(MASConstraintMaker *make) {
    make.centerY.equalTo(self.avatarView);
    make.right.equalTo(self).offset(-kHorizontalPad);
  }];
  // 点赞图标
  [self.likeButton mas_makeConstraints:^(MASConstraintMaker *make) {
    make.centerY.equalTo(self.avatarView);
    make.right.equalTo(self.likedCountLabel.mas_left).offset(-4);
    make.width.height.mas_equalTo(28);
  }];
  // 收藏数字
  [self.collectedCountLabel mas_makeConstraints:^(MASConstraintMaker *make) {
    make.centerY.equalTo(self.avatarView);
    make.right.equalTo(self.likeButton.mas_left).offset(-14);
  }];
  // 收藏图标
  [self.collectButton mas_makeConstraints:^(MASConstraintMaker *make) {
    make.centerY.equalTo(self.avatarView);
    make.right.equalTo(self.collectedCountLabel.mas_left).offset(-4);
    make.width.height.mas_equalTo(28);
  }];
}

- (void)buildContent {
  self.titleLabel = [[UILabel alloc] init];
  self.titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
  self.titleLabel.textColor = [UIColor colorWithWhite:0.08 alpha:1.0];
  self.titleLabel.numberOfLines = 0;
  [self addSubview:self.titleLabel];

  self.contentLabel = [[UILabel alloc] init];
  self.contentLabel.font = [UIFont systemFontOfSize:15];
  self.contentLabel.textColor = [UIColor colorWithWhite:0.25 alpha:1.0];
  self.contentLabel.numberOfLines = 0;
  self.contentLabel.lineBreakMode = NSLineBreakByWordWrapping;
  [self addSubview:self.contentLabel];

  [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(self.avatarView.mas_bottom).offset(14);
    make.left.equalTo(self).offset(kHorizontalPad);
    make.right.equalTo(self).offset(-kHorizontalPad);
  }];
  [self.contentLabel mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(self.titleLabel.mas_bottom).offset(10);
    make.left.equalTo(self).offset(kHorizontalPad);
    make.right.equalTo(self).offset(-kHorizontalPad);
  }];
}

- (void)buildTagRow {
  self.tagScrollView = [[UIScrollView alloc] init];
  self.tagScrollView.showsHorizontalScrollIndicator = NO;
  self.tagScrollView.showsVerticalScrollIndicator = NO;
  self.tagScrollView.contentInset = UIEdgeInsetsMake(0, kHorizontalPad, 0, kHorizontalPad);
  [self addSubview:self.tagScrollView];
  [self.tagScrollView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(self.contentLabel.mas_bottom).offset(12);
    make.left.right.equalTo(self);
    make.height.mas_equalTo(32);
  }];
}

- (void)buildCommentDivider {
  self.divider = [[UIView alloc] init];
  self.divider.backgroundColor = [UIColor colorWithWhite:0.93 alpha:1.0];
  [self addSubview:self.divider];

  self.commentSectionLabel = [[UILabel alloc] init];
  self.commentSectionLabel.text = @"全部评论";
  self.commentSectionLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
  self.commentSectionLabel.textColor = [UIColor colorWithWhite:0.1 alpha:1.0];
  [self addSubview:self.commentSectionLabel];

  [self.divider mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(self.tagScrollView.mas_bottom).offset(16);
    make.left.right.equalTo(self);
    make.height.mas_equalTo(8);
  }];
  [self.commentSectionLabel mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(self.divider.mas_bottom).offset(14);
    make.left.equalTo(self).offset(kHorizontalPad);
    make.bottom.equalTo(self).offset(-14);
  }];
}

#pragma mark - Configure

- (void)configureWithPost:(TLWCommunityPost *)post {
  self.nameLabel.text = post.authorName.length > 0 ? post.authorName : @"匿名用户";
  if (post.authorAvatar.length > 0) {
    [self.avatarView sd_setImageWithURL:[NSURL URLWithString:post.authorAvatar]
                       placeholderImage:[UIImage imageNamed:@"hp_avatar.png"]];
  }
  self.titleLabel.text = post.title.length > 0 ? post.title : @"";
  self.contentLabel.text = post.content.length > 0 ? post.content : @"";
  // 同步点赞数 / 收藏数（收藏数暂用点赞数占位，后端接入后替换）
  NSInteger likeCount = post.likeCount ? post.likeCount.integerValue : 0;
  NSInteger favCount = post.favoriteCount ? post.favoriteCount.unsignedIntValue : 0;
  self.likedCountLabel.text = [NSString stringWithFormat:@"%ld", (long)likeCount];
  self.collectedCountLabel.text = [NSString stringWithFormat:@"%ld", (long)favCount];
  self.images = post.images ?: @[];
  [self reloadBannerImages];
  [self reloadTags:post.tags];
  [self setNeedsLayout];
  [self layoutIfNeeded];
}

- (void)reloadBannerImages {
  for (UIView *sub in self.bannerScrollView.subviews) { [sub removeFromSuperview]; }
  [self.autoScrollTimer invalidate];
  self.autoScrollTimer = nil;
  self.currentPage = 0;

  NSArray *imgs = self.images;
  NSInteger count = imgs.count;
  if (count == 0) {
    UIImageView *ph = [[UIImageView alloc] init];
    ph.contentMode = UIViewContentModeScaleAspectFill;
    ph.clipsToBounds = YES;
    ph.backgroundColor = [UIColor colorWithWhite:0.90 alpha:1.0];
    [self.bannerScrollView addSubview:ph];
    [ph mas_makeConstraints:^(MASConstraintMaker *make) {
      make.edges.equalTo(self.bannerScrollView);
      make.width.equalTo(self.bannerScrollView);
      make.height.mas_equalTo(kBannerHeight);
    }];
    self.pageControl.numberOfPages = 0;
    return;
  }

  self.pageControl.numberOfPages = count;
  self.pageControl.currentPage = 0;

  UIView *prev = nil;
  for (NSInteger i = 0; i < count; i++) {
    UIImageView *iv = [[UIImageView alloc] init];
    iv.contentMode = UIViewContentModeScaleAspectFill;
    iv.clipsToBounds = YES;
    iv.backgroundColor = [UIColor colorWithWhite:0.90 alpha:1.0];
    [self.bannerScrollView addSubview:iv];
    id img = imgs[i];
    if ([img isKindOfClass:[UIImage class]]) {
      iv.image = (UIImage *)img;
    } else if ([img isKindOfClass:[NSString class]] && [(NSString *)img length] > 0) {
      [iv sd_setImageWithURL:[NSURL URLWithString:(NSString *)img] placeholderImage:nil];
    }
    UIView *prevRef = prev;
    [iv mas_makeConstraints:^(MASConstraintMaker *make) {
      make.top.bottom.equalTo(self.bannerScrollView);
      make.width.equalTo(self.bannerScrollView);
      make.height.mas_equalTo(kBannerHeight);
      if (prevRef) { make.left.equalTo(prevRef.mas_right); }
      else { make.left.equalTo(self.bannerScrollView); }
    }];
    prev = iv;
  }
  if (prev) {
    [prev mas_makeConstraints:^(MASConstraintMaker *make) {
      make.right.equalTo(self.bannerScrollView);
    }];
  }
  if (count > 1) {
    __weak typeof(self) weakSelf = self;
    self.autoScrollTimer = [NSTimer scheduledTimerWithTimeInterval:3.0 repeats:YES block:^(NSTimer * _Nonnull timer) {
      __strong typeof(weakSelf) strongSelf = weakSelf;
      if (!strongSelf) {
        [timer invalidate];
        return;
      }
      [strongSelf autoScrollBanner];
    }];
  }
}

- (void)autoScrollBanner {
  NSInteger count = self.images.count;
  if (count <= 1) return;
  NSInteger next = (self.currentPage + 1) % count;
  CGFloat w = self.bannerScrollView.bounds.size.width;
  if (w <= 0) w = [UIScreen mainScreen].bounds.size.width;
  [self.bannerScrollView setContentOffset:CGPointMake(next * w, 0) animated:YES];
}

- (void)reloadTags:(NSArray<NSString *> *)tags {
  for (UIView *sub in self.tagScrollView.subviews) { [sub removeFromSuperview]; }
  if (tags.count == 0) return;
  CGFloat x = 0, tagH = 24.0;
  for (NSString *tag in tags) {
    UILabel *pill = [[UILabel alloc] init];
    pill.text = [NSString stringWithFormat:@"# %@", tag];
    pill.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
    pill.textColor = [UIColor colorWithRed:0.10 green:0.58 blue:0.38 alpha:1.0];
    pill.backgroundColor = [UIColor colorWithRed:0.10 green:0.58 blue:0.38 alpha:0.10];
    pill.layer.cornerRadius = tagH / 2.0;
    pill.layer.masksToBounds = YES;
    pill.textAlignment = NSTextAlignmentCenter;
    [pill sizeToFit];
    CGFloat w = pill.bounds.size.width + 20.0;
    pill.frame = CGRectMake(x, (32.0 - tagH) / 2.0, w, tagH);
    [self.tagScrollView addSubview:pill];
    x += w + 8.0;
  }
  self.tagScrollView.contentSize = CGSizeMake(x, 32.0);
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
  if (scrollView != self.bannerScrollView) return;
  CGFloat w = scrollView.bounds.size.width;
  if (w <= 0) return;
  NSInteger page = (NSInteger)((scrollView.contentOffset.x + w / 2.0) / w);
  self.currentPage = page;
  self.pageControl.currentPage = page;
}

#pragma mark - Height calculation

+ (CGFloat)heightForPost:(TLWCommunityPost *)post {
  CGFloat screenW = [UIScreen mainScreen].bounds.size.width;
  CGFloat availW = screenW - kHorizontalPad * 2;
  CGFloat h = kBannerHeight;   // banner
  h += 14 + 36 + 14;           // author bar
  if (post.title.length > 0) {
    CGSize ts = [post.title boundingRectWithSize:CGSizeMake(availW, CGFLOAT_MAX)
                                         options:NSStringDrawingUsesLineFragmentOrigin
                                      attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:18 weight:UIFontWeightBold]}
                                         context:nil].size;
    h += ceil(ts.height) + 10;
  }
  if (post.content.length > 0) {
    CGSize cs = [post.content boundingRectWithSize:CGSizeMake(availW, CGFLOAT_MAX)
                                           options:NSStringDrawingUsesLineFragmentOrigin
                                        attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:15]}
                                           context:nil].size;
    h += ceil(cs.height);
  }
  h += 12 + 32;          // tag row
  h += 16 + 8 + 14 + 22 + 14; // divider + "全部评论"
  return h;
}

@end
