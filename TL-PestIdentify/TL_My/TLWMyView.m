//
//  TLWMyView.m
//  TL-PestIdentify
//

#import "TLWMyView.h"
#import <Masonry/Masonry.h>
#import <SDWebImage/SDWebImage.h>
#import "TLWLoadingIndicator.h"
#import "TLWSDKManager.h"
#import <objc/runtime.h>

static const void *kTLWMyViewBaseFontKey = &kTLWMyViewBaseFontKey;

@interface TLWMyView () <UIScrollViewDelegate>

@property (nonatomic, strong, readwrite) UIImageView *avatarImageView;
@property (nonatomic, strong, readwrite) UILabel     *userNameLabel;
@property (nonatomic, strong, readwrite) UILabel     *favCountLabel;
@property (nonatomic, strong, readwrite) UIView      *favStatView;
@property (nonatomic, strong, readwrite) UILabel     *recordCountLabel;
@property (nonatomic, strong, readwrite) UIView      *recordStatView;
@property (nonatomic, strong, readwrite) UIButton    *editProfileButton;
@property (nonatomic, strong, readwrite) UIButton    *settingButton;
@property (nonatomic, strong, readwrite) UIButton    *shareButton;
@property (nonatomic, strong, readwrite) UIImageView *postAvatarImageView;
@property (nonatomic, strong, readwrite) UILabel     *_postNameLabelLabel;
@property (nonatomic, strong) UIScrollView                    *postsScrollView;
@property (nonatomic, strong) UIRefreshControl                *postsRefreshControl;
@property (nonatomic, strong) UIView                          *postListContent;
@property (nonatomic, strong) NSArray<AGPostResponseDto *>    *cachedPosts;
@property (nonatomic, strong) UILabel                         *postsStatusLabel;
@property (nonatomic, assign) BOOL                            elderModeEnabled;
@property (nonatomic, strong) MASConstraint                   *statsRowHeightConstraint;
@property (nonatomic, strong) MASConstraint                   *editProfileButtonHeightConstraint;

@end

@implementation TLWMyView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) [self setupUI];
    return self;
}

- (void)setupUI {
    // 与识别记录页相同的背景
    self.layer.contents = (__bridge id)[UIImage imageNamed:@"hp_backView"].CGImage;

    [self setupIcons];
    UIView *statsRow = [self setupHeader];
    [self setupCardBelowStatsRow:statsRow];
}

#pragma mark - 顶部图标

- (void)setupIcons {
    _settingButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_settingButton setImage:[UIImage imageNamed:@"iconSetting"] forState:UIControlStateNormal];
    _settingButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self addSubview:_settingButton];
    [_settingButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.mas_safeAreaLayoutGuideTop).offset(12);
        make.right.equalTo(self).offset(-58);
        make.width.height.mas_equalTo(28);
    }];

    _shareButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_shareButton setImage:[UIImage imageNamed:@"iconTransmit"] forState:UIControlStateNormal];
    _shareButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self addSubview:_shareButton];
    [_shareButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(_settingButton);
        make.right.equalTo(self).offset(-16);
        make.width.height.mas_equalTo(28);
    }];
}

#pragma mark - 头像 / 昵称 / 统计行

- (UIView *)setupHeader {
    _avatarImageView = [[UIImageView alloc] init];
    _avatarImageView.contentMode      = UIViewContentModeScaleAspectFill;
    _avatarImageView.clipsToBounds    = YES;
    _avatarImageView.layer.cornerRadius = 42;
    _avatarImageView.layer.borderWidth  = 3;
    _avatarImageView.layer.borderColor  = [UIColor colorWithWhite:1.0 alpha:0.9].CGColor;
    [self addSubview:_avatarImageView];
    [_avatarImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.mas_safeAreaLayoutGuideTop).offset(20);
        make.centerX.equalTo(self);
        make.width.height.mas_equalTo(84);
    }];

    _userNameLabel = [UILabel new];
    _userNameLabel.font      = [UIFont systemFontOfSize:22 weight:UIFontWeightSemibold];
    _userNameLabel.textColor = UIColor.whiteColor;
    [self addSubview:_userNameLabel];
    [_userNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_avatarImageView.mas_bottom).offset(12);
        make.centerX.equalTo(self);
    }];

    UIView *statsRow = [UIView new];
    [self addSubview:statsRow];
    [statsRow mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_userNameLabel.mas_bottom).offset(16);
        make.left.equalTo(self).offset(16);
        make.right.equalTo(self).offset(-16);
        self.statsRowHeightConstraint = make.height.mas_equalTo(50);
    }];

    UILabel *l1, *l2;
    UIView *stat1 = [self statViewWithDesc:@"我的收藏" countLabel:&l1];
    UIView *stat2 = [self statViewWithDesc:@"识别记录"  countLabel:&l2];
    _favCountLabel    = l1;
    _favStatView      = stat1;
    _recordCountLabel = l2;
    _recordStatView   = stat2;

    stat1.userInteractionEnabled = YES;
    stat2.userInteractionEnabled = YES;
    [statsRow addSubview:stat1];
    [statsRow addSubview:stat2];
    [stat1 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.bottom.equalTo(statsRow);
        make.width.mas_equalTo(100);
    }];
    [stat2 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(stat1.mas_right).offset(24);
        make.top.bottom.equalTo(statsRow);
        make.width.mas_equalTo(100);
    }];

    _editProfileButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_editProfileButton setImage:[UIImage imageNamed:@"editProfile"] forState:UIControlStateNormal];
    _editProfileButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [statsRow addSubview:_editProfileButton];
    [_editProfileButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(statsRow);
        make.centerY.equalTo(statsRow);
        make.width.mas_equalTo(93);
        self.editProfileButtonHeightConstraint = make.height.mas_equalTo(50);
    }];

    return statsRow;
}

- (UIView *)statViewWithDesc:(NSString *)desc countLabel:(UILabel *__autoreleasing *)outLabel {
    UIView *view = [UIView new];

    UILabel *countLabel = [UILabel new];
    countLabel.font          = [UIFont systemFontOfSize:26 weight:UIFontWeightBold];
    countLabel.textColor     = UIColor.whiteColor;
    countLabel.textAlignment = NSTextAlignmentCenter;
    [view addSubview:countLabel];
    [countLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(view);
        make.centerX.equalTo(view);
    }];

    UILabel *descLabel = [UILabel new];
    descLabel.text          = desc;
    descLabel.font          = [UIFont systemFontOfSize:12];
    descLabel.textColor     = [UIColor colorWithWhite:1.0 alpha:0.88];
    descLabel.textAlignment = NSTextAlignmentCenter;
    [view addSubview:descLabel];
    [descLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(countLabel.mas_bottom).offset(4);
        make.centerX.equalTo(view);
        make.bottom.lessThanOrEqualTo(view);
    }];

    if (outLabel) *outLabel = countLabel;
    return view;
}

#pragma mark - 毛玻璃卡片（同 RecordView 风格）

- (void)setupCardBelowStatsRow:(UIView *)statsRow {
    UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    UIVisualEffectView *card = [[UIVisualEffectView alloc] initWithEffect:blur];
    card.layer.cornerRadius  = 22;
    card.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
    card.layer.masksToBounds = YES;

    // 白色半透明叠层，同 RecordView 的磨砂玻璃效果
    UIView *overlay = [UIView new];
    overlay.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.65];
    [card.contentView addSubview:overlay];
    [overlay mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(card.contentView);
    }];

    [self addSubview:card];
    [card mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(statsRow.mas_bottom).offset(22);
        make.left.right.bottom.equalTo(self);
    }];

    // 标题
    UILabel *titleLabel = [UILabel new];
    titleLabel.text      = @"我的帖子";
    titleLabel.font      = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
    titleLabel.textColor = [UIColor colorWithRed:0.13 green:0.13 blue:0.13 alpha:1.0];
    [card.contentView addSubview:titleLabel];
    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(card.contentView).offset(24);
        make.left.equalTo(card.contentView).offset(16);
    }];

    // 可滚动的帖子列表
    UIScrollView *sv = [UIScrollView new];
    sv.showsVerticalScrollIndicator = NO;
    sv.delegate = self;
    _postsScrollView = sv;

    _postsRefreshControl = [[UIRefreshControl alloc] init];
    _postsRefreshControl.tintColor = [UIColor clearColor];
    [_postsRefreshControl addTarget:self action:@selector(tl_handleRefresh:) forControlEvents:UIControlEventValueChanged];
    sv.refreshControl = _postsRefreshControl;

    [card.contentView addSubview:sv];
    [sv mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(titleLabel.mas_bottom).offset(12);
        make.left.right.bottom.equalTo(card.contentView);
    }];

    _postListContent = [UIView new];
    [sv addSubview:_postListContent];
    [_postListContent mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(sv);
        make.width.equalTo(sv);
        make.height.mas_greaterThanOrEqualTo(1);
    }];
}

#pragma mark - 我的帖子（真实数据）

- (void)showPostsLoading {
    _cachedPosts = nil;
    [self tl_resetPostListContent];

    if (!_postsStatusLabel) {
        _postsStatusLabel = [UILabel new];
        _postsStatusLabel.font = [UIFont systemFontOfSize:14];
        _postsStatusLabel.textColor = [UIColor colorWithRed:0.60 green:0.60 blue:0.60 alpha:1.0];
        _postsStatusLabel.textAlignment = NSTextAlignmentCenter;
    }

    _postsStatusLabel.text = @"加载中...";
    [_postListContent addSubview:_postsStatusLabel];

    [TLWLoadingIndicator showAtTopOfView:_postListContent topOffset:24 size:40];

    [_postsStatusLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_postListContent).offset(74); // 24 top + 40 size + 10 gap
        make.centerX.equalTo(_postListContent);
        make.bottom.equalTo(_postListContent).offset(-20);
    }];
    [self tl_applyFontScaleToView:_postsStatusLabel];
}

- (void)showPostsStatusText:(NSString *)text {
    _cachedPosts = nil;
    [self tl_resetPostListContent];

    if (!_postsStatusLabel) {
        _postsStatusLabel = [UILabel new];
        _postsStatusLabel.font = [UIFont systemFontOfSize:14];
        _postsStatusLabel.textColor = [UIColor colorWithRed:0.60 green:0.60 blue:0.60 alpha:1.0];
        _postsStatusLabel.textAlignment = NSTextAlignmentCenter;
    }

    _postsStatusLabel.text = [text copy];
    [_postListContent addSubview:_postsStatusLabel];
    [_postsStatusLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(40);
        make.centerX.equalTo(_postListContent);
        make.bottom.equalTo(_postListContent).offset(-40);
    }];
    [self tl_applyFontScaleToView:_postsStatusLabel];
}

- (void)reloadPosts:(NSArray<AGPostResponseDto *> *)posts {
    _cachedPosts = posts;
    [self tl_resetPostListContent];

    if (posts.count == 0) {
        UILabel *empty = [UILabel new];
        empty.text      = @"还没有发布过帖子";
        empty.font      = [UIFont systemFontOfSize:14];
        empty.textColor = [UIColor colorWithRed:0.60 green:0.60 blue:0.60 alpha:1.0];
        empty.textAlignment = NSTextAlignmentCenter;
        [_postListContent addSubview:empty];
        [empty mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(40);
            make.centerX.equalTo(_postListContent);
            make.bottom.equalTo(_postListContent).offset(-40);
        }];
        [self tl_applyFontScaleToView:empty];
        return;
    }

    UIView *prev = nil;
    for (NSUInteger i = 0; i < posts.count; i++) {
        AGPostResponseDto *post = posts[i];
        UIView *item = [self buildPostItemWithPost:post isFirst:(i == 0)];
        item.tag = (NSInteger)i;
        item.userInteractionEnabled = YES;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tl_postItemTapped:)];
        [item addGestureRecognizer:tap];
        // 非首个帖子前插入浅灰分割线
        if (prev) {
            UIView *sep = [UIView new];
            sep.backgroundColor = [UIColor colorWithWhite:0.88 alpha:1.0];
            [_postListContent addSubview:sep];
            [sep mas_makeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(prev.mas_bottom).offset(10);
                make.left.equalTo(_postListContent).offset(16);
                make.right.equalTo(_postListContent).offset(-16);
                make.height.mas_equalTo(0.5);
            }];
            prev = sep;
        }

        [_postListContent addSubview:item];
        [item mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(_postListContent).offset(16);
            make.right.equalTo(_postListContent).offset(-16);
            if (prev) {
                make.top.equalTo(prev.mas_bottom).offset(10);
            } else {
                make.top.equalTo(_postListContent).offset(4);
            }
            if (i == posts.count - 1) {
                make.bottom.equalTo(_postListContent).offset(-80);
            }
        }];
        prev = item;
    }
    [self tl_applyFontScaleRecursivelyInView:_postListContent];
}

- (void)tl_resetPostListContent {
    [TLWLoadingIndicator hideInView:_postListContent];
    [_postListContent.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [_postListContent mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(_postListContent.superview);
        make.width.equalTo(_postListContent.superview);
        make.height.mas_greaterThanOrEqualTo(1);
    }];
}

- (void)tl_handleRefresh:(UIRefreshControl *)sender {
    [TLWLoadingIndicator showPullToRefreshInScrollView:_postsScrollView size:40];
    if (self.onRefreshPosts) {
        self.onRefreshPosts();
    }
}

- (void)endRefreshingPosts {
    [_postsRefreshControl endRefreshing];
    [TLWLoadingIndicator hideInView:_postsScrollView];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView != _postsScrollView || !self.onLoadMorePosts) {
        return;
    }

    CGFloat offsetY = scrollView.contentOffset.y;
    CGFloat contentH = scrollView.contentSize.height;
    CGFloat frameH = scrollView.bounds.size.height;
    if (contentH > 0 && offsetY > contentH - frameH - 100) {
        self.onLoadMorePosts();
    }
}

- (void)tl_postItemTapped:(UITapGestureRecognizer *)tap {
    NSUInteger index = (NSUInteger)tap.view.tag;
    if (index >= _cachedPosts.count) return;
    AGPostResponseDto *post = _cachedPosts[index];
    if (self.onPostTapped) {
        self.onPostTapped(post._id);
    }
}

- (UIView *)buildPostItemWithPost:(AGPostResponseDto *)post isFirst:(BOOL)isFirst {
    UIView *item = [UIView new];
    AGUserProfileDto *profile = [TLWSDKManager shared].sessionManager.cachedProfile;
    NSString *followedCropsText = profile.followedCrops.count > 0 ? [profile.followedCrops componentsJoinedByString:@"、"] : @"未设置";

    // 头像（第一个帖子同步到 postAvatarImageView）
    UIImageView *avatarView = [[UIImageView alloc] init];
    avatarView.contentMode      = UIViewContentModeScaleAspectFill;
    avatarView.clipsToBounds    = YES;
    avatarView.layer.cornerRadius = 20;
    avatarView.image = [UIImage imageNamed:@"avatar"];
    if (post.authorAvatar.length > 0) {
        [avatarView sd_setImageWithURL:[NSURL URLWithString:post.authorAvatar]
                      placeholderImage:[UIImage imageNamed:@"avatar"]];
    }
    if (isFirst) {
        _postAvatarImageView = avatarView;
    }
    [item addSubview:avatarView];
    [avatarView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.equalTo(item);
        make.width.height.mas_equalTo(40);
    }];

    // 昵称
    UILabel *nameLabel = [UILabel new];
    nameLabel.text      = post.authorName ?: post.authorUsername ?: @"";
    nameLabel.font      = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    nameLabel.textColor = [UIColor colorWithRed:0.13 green:0.13 blue:0.13 alpha:1.0];
    if (isFirst) {
        _postNameLabel = nameLabel;
    }
    [item addSubview:nameLabel];
    [nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(avatarView).offset(2);
        make.left.equalTo(avatarView.mas_right).offset(10);
    }];

    UILabel *cropsLabel = [UILabel new];
    cropsLabel.text = [NSString stringWithFormat:@"关注作物：%@", followedCropsText];
    cropsLabel.font = [UIFont systemFontOfSize:12];
    cropsLabel.textColor = [UIColor colorWithRed:0.55 green:0.58 blue:0.58 alpha:1.0];
    cropsLabel.numberOfLines = 1;
    [item addSubview:cropsLabel];
    [cropsLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(nameLabel);
        make.top.equalTo(nameLabel.mas_bottom).offset(4);
        make.right.lessThanOrEqualTo(item).offset(-70);
    }];

    // 时间（头像行右侧）
    UILabel *timeLabel = [UILabel new];
    timeLabel.font      = [UIFont systemFontOfSize:12];
    timeLabel.textColor = [UIColor colorWithRed:0.60 green:0.60 blue:0.60 alpha:1.0];
    timeLabel.text = [self tl_relativeTimeString:post.createdAt];
    [item addSubview:timeLabel];
    [timeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(nameLabel);
        make.right.equalTo(item);
    }];

    // 正文
    UILabel *bodyLabel = [UILabel new];
    bodyLabel.text          = post.content ?: @"";
    bodyLabel.font          = [UIFont systemFontOfSize:15];
    bodyLabel.textColor     = [UIColor colorWithRed:0.20 green:0.20 blue:0.20 alpha:1.0];
    bodyLabel.numberOfLines = 3;
    [item addSubview:bodyLabel];
    [bodyLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(avatarView.mas_bottom).offset(16);
        make.left.right.equalTo(item);
    }];

    // 图片（最多2张）
    NSArray<NSString *> *images = post.images ?: @[];
    UIView *lastContentView = bodyLabel;
    if (images.count > 0) {
        NSUInteger showCount = MIN(images.count, 2);
        UIImageView *iv0 = [[UIImageView alloc] init];
        iv0.contentMode = UIViewContentModeScaleAspectFill;
        iv0.clipsToBounds = YES;
        iv0.layer.cornerRadius = 8;
        iv0.backgroundColor = [UIColor colorWithRed:0.90 green:0.90 blue:0.90 alpha:1.0];
        [iv0 sd_setImageWithURL:[NSURL URLWithString:images[0]]];
        [item addSubview:iv0];
        [iv0 mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(bodyLabel.mas_bottom).offset(10);
            make.left.equalTo(item);
            if (showCount == 1) {
                make.right.equalTo(item);
            } else {
                make.right.equalTo(item.mas_centerX).offset(-4);
            }
            make.height.mas_equalTo(120);
        }];
        if (showCount == 2) {
            UIImageView *iv1 = [[UIImageView alloc] init];
            iv1.contentMode = UIViewContentModeScaleAspectFill;
            iv1.clipsToBounds = YES;
            iv1.layer.cornerRadius = 8;
            iv1.backgroundColor = [UIColor colorWithRed:0.90 green:0.90 blue:0.90 alpha:1.0];
            [iv1 sd_setImageWithURL:[NSURL URLWithString:images[1]]];
            [item addSubview:iv1];
            [iv1 mas_makeConstraints:^(MASConstraintMaker *make) {
                make.top.height.equalTo(iv0);
                make.left.equalTo(item.mas_centerX).offset(4);
                make.right.equalTo(item);
            }];
        }
        lastContentView = iv0;
    }

    // 底部：收藏数
    UILabel *favCountLabel = [UILabel new];
    favCountLabel.text      = [NSString stringWithFormat:@"收藏 %@", post.favoriteCount ?: @(0)];
    favCountLabel.font      = [UIFont systemFontOfSize:12];
    favCountLabel.textColor = [UIColor colorWithRed:0.50 green:0.50 blue:0.50 alpha:1.0];
    [item addSubview:favCountLabel];
    [favCountLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(lastContentView.mas_bottom).offset(10);
        make.left.equalTo(item);
        make.bottom.equalTo(item);
    }];

    UILabel *commentLabel = [UILabel new];
    commentLabel.text      = [NSString stringWithFormat:@"评论 %@", post.commentCount ?: @(0)];
    commentLabel.font      = [UIFont systemFontOfSize:12];
    commentLabel.textColor = [UIColor colorWithRed:0.50 green:0.50 blue:0.50 alpha:1.0];
    [item addSubview:commentLabel];
    [commentLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(favCountLabel);
        make.left.equalTo(favCountLabel.mas_right).offset(16);
    }];

    return item;
}

- (NSString *)tl_relativeTimeString:(NSDate *)date {
    if (!date) return @"";
    NSTimeInterval diff = -[date timeIntervalSinceNow];
    if (diff < 60) return @"刚刚";
    if (diff < 3600) return [NSString stringWithFormat:@"%d分钟前", (int)(diff / 60)];
    if (diff < 86400) return [NSString stringWithFormat:@"%d小时前", (int)(diff / 3600)];
    if (diff < 86400 * 30) return [NSString stringWithFormat:@"%d天前", (int)(diff / 86400)];
    NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
    fmt.dateFormat = @"MM-dd";
    return [fmt stringFromDate:date];
}

- (void)configureElderModeEnabled:(BOOL)enabled {
    self.elderModeEnabled = enabled;
    [self.statsRowHeightConstraint setOffset:(enabled ? 58.0 : 50.0)];
    [self.editProfileButtonHeightConstraint setOffset:(enabled ? 58.0 : 50.0)];
    [self tl_applyFontScaleRecursivelyInView:self];
}

- (void)tl_applyFontScaleRecursivelyInView:(UIView *)view {
    [self tl_applyFontScaleToView:view];
    for (UIView *subview in view.subviews) {
        [self tl_applyFontScaleRecursivelyInView:subview];
    }
}

- (void)tl_applyFontScaleToView:(UIView *)view {
    if ([view isKindOfClass:[UILabel class]]) {
        UILabel *label = (UILabel *)view;
        UIFont *baseFont = objc_getAssociatedObject(label, kTLWMyViewBaseFontKey);
        if (!baseFont) {
            baseFont = label.font;
            objc_setAssociatedObject(label, kTLWMyViewBaseFontKey, baseFont, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        label.font = [UIFont fontWithDescriptor:baseFont.fontDescriptor
                                           size:(baseFont.pointSize + (self.elderModeEnabled ? 3.0 : 0.0))];
    } else if ([view isKindOfClass:[UIButton class]]) {
        UIButton *button = (UIButton *)view;
        UIFont *baseFont = objc_getAssociatedObject(button.titleLabel, kTLWMyViewBaseFontKey);
        if (!baseFont && button.titleLabel.font) {
            baseFont = button.titleLabel.font;
            objc_setAssociatedObject(button.titleLabel, kTLWMyViewBaseFontKey, baseFont, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        if (baseFont) {
            button.titleLabel.font = [UIFont fontWithDescriptor:baseFont.fontDescriptor size:(baseFont.pointSize + (self.elderModeEnabled ? 3.0 : 0.0))];
        }
    }
}

@end
