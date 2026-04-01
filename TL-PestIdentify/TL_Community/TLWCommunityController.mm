//
//  TLWCommunityController.m
//  TL-PestIdentify
//

#import "TLWCommunityController.h"
#import "TLWCommunityView.h"
#import "TLWCommunityCell.h"
#import "TLWCommunityPost.h"
#import "TLWCommunityWaterfallLayout.h"
#import "TLWVoiceInputViewController.h"
#import "TLWPublishController.h"
#import "TLWPostDetailController.h"
#import "TLWSDKManager.h"
#import "TLWToast.h"
#import <Masonry/Masonry.h>
#import "TLWDBManager.h"
static NSString *const kCommunityCellID = @"TLWCommunityCell";
static NSString *const kCommunitySuggestionCellID = @"TLWCommunitySuggestionCell";

@interface TLWCommunitySuggestionCell : UITableViewCell

- (void)tl_configureWithText:(NSString *)text showsDivider:(BOOL)showsDivider;

@end

@implementation TLWCommunitySuggestionCell {
  UIView *_cardView;
  UIView *_highlightView;
  UIView *_dividerView;
  UIImageView *_iconView;
  UILabel *_titleLabel;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (self) {
    self.backgroundColor = [UIColor clearColor];
    self.selectionStyle = UITableViewCellSelectionStyleNone;

    UIView *selectedBackground = [[UIView alloc] init];
    selectedBackground.backgroundColor = [UIColor clearColor];
    self.selectedBackgroundView = selectedBackground;

    UIView *cardView = [[UIView alloc] init];
    cardView.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.18];
    cardView.layer.cornerRadius = 16.0;
    cardView.layer.borderWidth = 1.0;
    cardView.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.36].CGColor;
    cardView.layer.shadowColor = [UIColor colorWithRed:0.12 green:0.18 blue:0.31 alpha:0.14].CGColor;
    cardView.layer.shadowOpacity = 1.0;
    cardView.layer.shadowRadius = 12.0;
    cardView.layer.shadowOffset = CGSizeMake(0, 6);
    [self.contentView addSubview:cardView];
    _cardView = cardView;

    UIView *highlightView = [[UIView alloc] init];
    highlightView.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.12];
    highlightView.userInteractionEnabled = NO;
    highlightView.layer.cornerRadius = 16.0;
    [cardView addSubview:highlightView];
    _highlightView = highlightView;

    UIImage *iconImage = nil;
    if (@available(iOS 13.0, *)) {
      UIImageSymbolConfiguration *symbolConfig = [UIImageSymbolConfiguration configurationWithPointSize:14 weight:UIImageSymbolWeightSemibold];
      iconImage = [UIImage systemImageNamed:@"magnifyingglass" withConfiguration:symbolConfig];
    }
    UIImageView *iconView = [[UIImageView alloc] initWithImage:iconImage];
    iconView.tintColor = [UIColor colorWithRed:0.20 green:0.42 blue:0.94 alpha:0.95];
    iconView.contentMode = UIViewContentModeScaleAspectFit;
    [cardView addSubview:iconView];
    _iconView = iconView;

    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    titleLabel.textColor = [UIColor colorWithWhite:0.12 alpha:1.0];
    [cardView addSubview:titleLabel];
    _titleLabel = titleLabel;

    UIView *dividerView = [[UIView alloc] init];
    dividerView.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.26];
    [cardView addSubview:dividerView];
    _dividerView = dividerView;

    [_cardView mas_makeConstraints:^(MASConstraintMaker *make) {
      make.top.equalTo(self.contentView).offset(4);
      make.bottom.equalTo(self.contentView).offset(-4);
      make.left.right.equalTo(self.contentView);
    }];

    [_highlightView mas_makeConstraints:^(MASConstraintMaker *make) {
      make.top.left.right.equalTo(_cardView);
      make.height.mas_equalTo(24);
    }];

    [_iconView mas_makeConstraints:^(MASConstraintMaker *make) {
      make.left.equalTo(_cardView).offset(14);
      make.centerY.equalTo(_cardView);
      make.width.height.mas_equalTo(16);
    }];

    [_titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
      make.left.equalTo(_iconView.mas_right).offset(10);
      make.centerY.equalTo(_cardView);
      make.right.equalTo(_cardView).offset(-14);
    }];

    [_dividerView mas_makeConstraints:^(MASConstraintMaker *make) {
      make.left.equalTo(_titleLabel);
      make.right.equalTo(_cardView).offset(-14);
      make.bottom.equalTo(_cardView);
      make.height.mas_equalTo(1);
    }];
  }
  return self;
}

- (void)tl_configureWithText:(NSString *)text showsDivider:(BOOL)showsDivider {
  _titleLabel.text = text;
  _dividerView.hidden = !showsDivider;
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
  [super setHighlighted:highlighted animated:animated];

  CGFloat targetAlpha = highlighted ? 0.30 : 0.18;
  UIColor *targetBorderColor = [UIColor colorWithWhite:1 alpha:(highlighted ? 0.52 : 0.36)];
  [UIView animateWithDuration:(animated ? 0.18 : 0.0) animations:^{
    _cardView.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:targetAlpha];
    _cardView.layer.borderColor = targetBorderColor.CGColor;
  }];
}

@end

@interface TLWCommunityController () <UICollectionViewDataSource, UICollectionViewDelegate, TLWCommunityWaterfallLayoutDelegate, UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) TLWCommunityView *myView;
@property (nonatomic, strong) NSMutableArray *posts;
@property (nonatomic, assign) BOOL tl_isFetchingFeed;
@property (nonatomic, strong) NSMutableArray* collectePosts;
@property (nonatomic, strong) NSMutableArray<NSString *> *searchSuggestions;
@property (nonatomic, strong, nullable) NSURLSessionTask *suggestionTask;
@property (nonatomic, copy) NSString *pendingSuggestionQuery;
@property (nonatomic, assign) NSInteger suggestionRequestToken;
@end

@implementation TLWCommunityController



- (void)viewDidLoad {
  [super viewDidLoad];
  self.view.backgroundColor = [UIColor clearColor];
  [self.view addSubview:self.myView];
  [self.myView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.edges.equalTo(self.view);
  }];

  UICollectionView *collectionView = self.myView.collectionView;
  collectionView.dataSource = self;
  collectionView.delegate = self;
  TLWCommunityWaterfallLayout *layout = (TLWCommunityWaterfallLayout *)collectionView.collectionViewLayout;
  layout.delegate = self;
  [collectionView registerClass:[TLWCommunityCell class] forCellWithReuseIdentifier:kCommunityCellID];
  UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panAction:)];
  [self.myView.publishButton addGestureRecognizer:pan];
  [self.myView.publishButton addTarget:self action:@selector(tl_publishButtonTapped) forControlEvents:UIControlEventTouchUpInside];

  [self.myView bringSubviewToFront:self.myView.publishButton];
  self.myView.searchTextField.delegate = self;
  [self.myView.searchTextField addTarget:self action:@selector(tl_searchTextChanged:) forControlEvents:UIControlEventEditingChanged];
  self.myView.suggestionTableView.dataSource = self;
  self.myView.suggestionTableView.delegate = self;
  [self.myView.suggestionTableView registerClass:[TLWCommunitySuggestionCell class] forCellReuseIdentifier:kCommunitySuggestionCellID];
  [self.myView.voiceButton addTarget:self action:@selector(tl_voiceButtonTapped) forControlEvents:UIControlEventTouchUpInside];
  self.posts = [NSMutableArray array];
  self.searchSuggestions = [NSMutableArray array];
  self.pendingSuggestionQuery = @"";
  self.tl_isFetchingFeed = NO;
  [self tl_fetchCommunityFeed];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tl_updatePost:) name:@"updatePost" object:nil];
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(tl_fetchSuggestionsNow:) object:nil];
  [self.suggestionTask cancel];
}



- (void)loadCollectedPosts {
  TLWSDKManager* manager = [TLWSDKManager shared];
  __weak typeof(self) weakSelf = self;
  [manager fetchAllFavoritedPostsWithCompletion:^(NSArray<AGPostResponseDto *> * _Nullable posts, NSError * _Nullable error) {
    if (error) {
      NSLog(@"用户收藏帖子列表获取失败, code = ");
    } else {
      NSLog(@"获取到所有收藏的帖子数位：%ld", posts.count);
      weakSelf.collectePosts = [NSMutableArray arrayWithArray:posts];
    }
  }];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  [self loadCollectedPosts];
}


- (void)panAction:(UIPanGestureRecognizer *)pan {
  CGPoint translation = [pan translationInView:self.myView];
  self.myView.publishButton.center = CGPointMake(self.myView.publishButton.center.x + translation.x, self.myView.publishButton.center.y + translation.y);
  [pan setTranslation:CGPointZero inView:self.myView];
  if (pan.state == UIGestureRecognizerStateEnded) {
    [self moveToEdge];
  }
}

- (void)moveToEdge {
  CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
  CGFloat targetX;
  if (self.myView.publishButton.center.x <= screenWidth / 2) {
    targetX = self.myView.publishButton.bounds.size.width / 2 + 10;
  } else {
    targetX = screenWidth - self.myView.publishButton.bounds.size.width / 2 - 10;
  }
  [UIView animateWithDuration:0.3 animations:^{
    self.myView.publishButton.center = CGPointMake(targetX, self.myView.publishButton.center.y);
  }];
}

#pragma mark - Data

/// TODO: 接口接入后替换内部实现，保持方法签名不变，方便全局调用
- (void)tl_fetchCommunityFeed {
  if (self.tl_isFetchingFeed) {
    return;
  }
  self.tl_isFetchingFeed = YES;

  // 先清空，让用户立刻看到刷新反馈
  self.posts = [NSMutableArray array];
  dispatch_async(dispatch_get_main_queue(), ^{
    [self.myView.collectionView reloadData];
  });

  TLWSDKManager *sdk = [TLWSDKManager shared];
  NSInteger pageSize = 20; // 一次拉取多少条
  NSInteger maxPages = 50; // 安全兜底：避免 hasNext 异常导致无限请求

  NSMutableArray<TLWCommunityPost *> *accumulator = [NSMutableArray array];
  __weak typeof(self) weakSelf = self;

  __block void (^fetchPageBlock)(NSInteger pageIndex);
  fetchPageBlock = ^(NSInteger pageIndex) {
    __strong typeof(weakSelf) strongSelf = weakSelf;
    if (!strongSelf) return;

    [sdk getAllPostsWithTag:nil
                           q:nil
                         page:@(pageIndex)
                         size:@(pageSize)
            completionHandler:^(AGResultPageResultPostResponseDto *output, NSError *error) {
      __strong typeof(weakSelf) s = weakSelf;
      if (!s) return;

      NSLog(@"[Community] page=%ld error=%@ code=%@ message=%@ listCount=%lu",
            (long)pageIndex, error, output.code, output.message,
            (unsigned long)output.data.list.count);

      if (error || !output || !output.data.list) {
        NSLog(@"[Community] 拉取失败: error=%@, output=%@", error, output);
        fetchPageBlock = nil; // 打破 block 循环引用
        dispatch_async(dispatch_get_main_queue(), ^{
          s.tl_isFetchingFeed = NO;
          // 合并本地发布的 item，避免分页完成时覆盖掉刚发布的帖子
          NSMutableArray<TLWCommunityPost *> *merged = [accumulator mutableCopy];
          for (TLWCommunityPost *localPost in s.posts) {
            if (![accumulator containsObject:localPost]) {
              [merged addObject:localPost];
            }
          }
          s.posts = merged;
          [s.myView.collectionView reloadData];
        });
        return;
      }

      for (AGPostResponseDto *dto in output.data.list) {
        TLWCommunityPost *post = [TLWCommunityPost new];
        post._id = dto._id;
        post.title = dto.title ?: @"";
        post.content = dto.content ?: @"";
        post.images = dto.images ?: @[];
        post.tags = dto.tags ?: @[];
        post.authorName = dto.authorName ?: @"";
        post.authorAvatar = dto.authorAvatar ?: @"";
        post.likeCount = dto.likeCount ?: @0;
        post.favoriteCount = dto.favoriteCount ?: @0;
        post.isLiked = dto.isLiked;
        post.isFavorited = dto.isFavorited;
        NSLog(@"点赞数 : %@", post.likeCount);
        NSLog(@"收藏数 : %@", post.likeCount);
        // imageAspectRatio 由瀑布流代理方法按行规则统一设置
        [accumulator addObject:post];
      }

      // 逐页渲染，减少“空白等待”感
      dispatch_async(dispatch_get_main_queue(), ^{
        // 合并本地发布的 item，避免分页刷新覆盖掉刚发布的帖子
        NSMutableArray<TLWCommunityPost *> *merged = [accumulator mutableCopy];
        for (TLWCommunityPost *localPost in s.posts) {
          if (![accumulator containsObject:localPost]) {
            [merged addObject:localPost];
          }
        }
        s.posts = merged;
        [s.myView.collectionView reloadData];
      });

      BOOL hasNext = output.data.hasNext.boolValue;
      if (hasNext && pageIndex + 1 < maxPages) {
        fetchPageBlock(pageIndex + 1);
      } else {
        fetchPageBlock = nil; // 打破 block 循环引用
        dispatch_async(dispatch_get_main_queue(), ^{
          s.tl_isFetchingFeed = NO;
          // 合并本地发布的 item，避免最终结果覆盖掉刚发布的帖子
          NSMutableArray<TLWCommunityPost *> *merged = [accumulator mutableCopy];
          for (TLWCommunityPost *localPost in s.posts) {
            if (![accumulator containsObject:localPost]) {
              [merged addObject:localPost];
            }
          }
          s.posts = merged;
          [s.myView.collectionView reloadData];
        });
      }
    }];
  };

  fetchPageBlock(0);
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
  return self.posts.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
  TLWCommunityCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kCommunityCellID forIndexPath:indexPath];
  TLWCommunityPost *post = self.posts[indexPath.item];

  if (indexPath.row == 0) {
    post.imageAspectRatio = 0.60;
  } else {
    post.imageAspectRatio = 0.75;
  }
  NSLog(@"点赞数-1 : %@", post.likeCount);
  [cell configureWithPost:post];
  return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
  if (indexPath.item >= self.posts.count) return;
  TLWCommunityPost *post = self.posts[indexPath.item];
  // 本地发布中的帖子禁止点击进入详情
  if (post.isLocalPending) return;
  TLWPostDetailController *detailVC = [[TLWPostDetailController alloc] init];
  NSLog(@"post:%@", post.content);
  NSLog(@"post.favcount = %@", post.favoriteCount);
  detailVC._id = post._id;
  detailVC.hasCollectedPosts = self.collectePosts;
  detailVC.hidesBottomBarWhenPushed = YES;
  [self.navigationController pushViewController:detailVC animated:YES];
}

#pragma mark - TLWCommunityWaterfallLayoutDelegate

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)layout heightForItemAtIndexPath:(NSIndexPath *)indexPath itemWidth:(CGFloat)width {
  TLWCommunityPost *post = self.posts[indexPath.item];
  // 瀑布流高度计算使用的纵横比规则应与 cell 展示保持一致
  if (indexPath.row == 0) {
    post.imageAspectRatio = 0.60;
  } else {
    post.imageAspectRatio = 0.75;
  }
  return [post cellHeightForWidth:width];
}

#pragma mark - Lazy

- (TLWCommunityView *)myView {
  if (!_myView) {
    _myView = [[TLWCommunityView alloc] initWithFrame:CGRectZero];
  }
  return _myView;
}

- (void)tl_voiceButtonTapped {
  TLWVoiceInputViewController *vc = [[TLWVoiceInputViewController alloc] init];
  vc.initialSearchText = self.myView.searchTextField.text;
  __weak typeof(self) weakSelf = self;
  vc.onSearchTextChanged = ^(NSString *text) {
    __strong typeof(weakSelf) strongSelf = weakSelf;
    if (!strongSelf) return;
    strongSelf.myView.searchTextField.text = text;
    [strongSelf.myView.searchTextField sendActionsForControlEvents:UIControlEventEditingChanged];
  };
  vc.modalPresentationStyle = UIModalPresentationFullScreen;
  [self presentViewController:vc animated:YES completion:nil];
}

- (void)tl_publishButtonTapped {
  TLWPublishController *vc = [[TLWPublishController alloc] init];
  vc.modalPresentationStyle = UIModalPresentationFullScreen;
  __weak typeof(self) weakSelf = self;
  // 本地发布直接把 TLWCommunityPost 存入瀑布流数据源
  vc.clickPublish = ^(TLWCommunityPost * _Nonnull post) {
    __strong typeof(weakSelf) strongSelf = weakSelf;
    if (!strongSelf) {
      return;
    }
    // 本地发布帖子的高度固定，不做真实宽高比计算
    if (post.imageAspectRatio <= 0.0) {
      post.imageAspectRatio = 0.65;
    }
    // 标记为本地发布中，cell 顶部会显示毛玻璃遮罩
    post.isLocalPending = YES;
    // 插入到数组最前面，让新帖子显示在最上方
    [strongSelf.posts insertObject:post atIndex:0];
    NSLog(@"post.content: %@", post.content);
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:0];

    // 如果正在分页拉取，分页回调会触发 reloadData；为避免数据源/插入操作冲突，此处兜底全量刷新
    if (strongSelf.tl_isFetchingFeed) {
      [strongSelf.myView.collectionView reloadData];
      return;
    }

    // 只插入新增的 1 个 item，并滚动到顶部
    [strongSelf.myView.collectionView performBatchUpdates:^{
      [strongSelf.myView.collectionView insertItemsAtIndexPaths:@[indexPath]];
    } completion:^(BOOL finished) {
      [strongSelf.myView.collectionView scrollToItemAtIndexPath:indexPath
                                              atScrollPosition:UICollectionViewScrollPositionTop
                                                      animated:YES];
    }];
  };
  [self presentViewController:vc animated:YES completion:nil];
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
  // 直接点击输入框时，同样展示毛玻璃搜索面板
  [self.myView tl_showSearchOverlay];
  [self tl_requestSuggestionsForQuery:textField.text ?: @""];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  // 这里可以触发真正的搜索事件，暂时只收起页面
  [textField resignFirstResponder];
  [self tl_clearSuggestionList];
  [self.myView tl_hideSearchOverlay];
  return YES;
}

#pragma mark - Search Suggestions

- (void)tl_searchTextChanged:(UITextField *)textField {
  [self tl_requestSuggestionsForQuery:textField.text ?: @""];
}

- (void)tl_requestSuggestionsForQuery:(NSString *)query {
  NSString *trimmedQuery = [query stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
  self.pendingSuggestionQuery = trimmedQuery ?: @"";
  [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(tl_fetchSuggestionsNow:) object:nil];

  if (self.pendingSuggestionQuery.length == 0) {
    [self.suggestionTask cancel];
    self.suggestionTask = nil;
    [self tl_clearSuggestionList];
    return;
  }

  [self performSelector:@selector(tl_fetchSuggestionsNow:) withObject:self.pendingSuggestionQuery afterDelay:0.2];
}

- (void)tl_fetchSuggestionsNow:(NSString *)query {
  NSLog(@"之行词条搜索");

  if (query.length == 0) {
    [self tl_clearSuggestionList];
    return;
  }

  self.suggestionRequestToken += 1;
  NSInteger requestToken = self.suggestionRequestToken;
  [self.suggestionTask cancel];

  __weak typeof(self) weakSelf = self;
  self.suggestionTask = [[TLWSDKManager shared] getSuggestionsWithQ:query completionHandler:^(AGResultListString *output, NSError *error) {
    dispatch_async(dispatch_get_main_queue(), ^{
      __strong typeof(weakSelf) strongSelf = weakSelf;
      if (!strongSelf || requestToken != strongSelf.suggestionRequestToken) {
        return;
      }

      if ([error.domain isEqualToString:NSURLErrorDomain] && error.code == NSURLErrorCancelled) {
        return;
      }

      if (error || !output || output.code.integerValue != 200) {
        if (!error && output.code.integerValue == 401) {
          [[TLWSDKManager shared] handleUnauthorizedWithRetry:^{
            [strongSelf tl_requestSuggestionsForQuery:query];
          }];
          return;
        }
        [strongSelf tl_clearSuggestionList];
        return;
      }

      NSString *currentQuery = [strongSelf.myView.searchTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
      if (![currentQuery isEqualToString:query]) {
        return;
      }

      NSArray<NSString *> *rawItems = output.data ?: @[];
      NSMutableOrderedSet<NSString *> *dedupedItems = [NSMutableOrderedSet orderedSet];
      for (NSString *item in rawItems) {
        if (![item isKindOfClass:[NSString class]]) {
          continue;
        }
        NSString *trimmedItem = [item stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (trimmedItem.length > 0) {
          [dedupedItems addObject:trimmedItem];
        }
      }

      strongSelf.searchSuggestions = [[dedupedItems array] mutableCopy];
      [strongSelf.myView.suggestionTableView reloadData];
      [strongSelf.myView tl_setSuggestionListHidden:(strongSelf.searchSuggestions.count == 0) itemCount:strongSelf.searchSuggestions.count];
    });
  }];
}

- (void)tl_clearSuggestionList {
  [self.searchSuggestions removeAllObjects];
  [self.myView.suggestionTableView reloadData];
  [self.myView tl_setSuggestionListHidden:YES itemCount:0];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return self.searchSuggestions.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  TLWCommunitySuggestionCell *cell = [tableView dequeueReusableCellWithIdentifier:kCommunitySuggestionCellID forIndexPath:indexPath];
  BOOL showsDivider = indexPath.row < self.searchSuggestions.count - 1;
  [cell tl_configureWithText:self.searchSuggestions[indexPath.row] showsDivider:showsDivider];
  return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  if (indexPath.row >= self.searchSuggestions.count) {
    return;
  }
  NSString *text = self.searchSuggestions[indexPath.row];
  self.myView.searchTextField.text = text;
  [self tl_clearSuggestionList];
  [self.myView.searchTextField resignFirstResponder];
  [self.myView tl_hideSearchOverlay];
}

- (void)tl_updatePost:(NSNotification* )notification {
  __weak typeof(self) weakSelf = self;
  TLWSDKManager* manager = [TLWSDKManager shared];
  NSDictionary* dict = notification.userInfo;
  NSString* content = dict[@"content"];
  [manager uploadImages:dict[@"images"] prefix:@"post" completion:^(NSArray<NSString *> * _Nullable urls, NSError * _Nullable error) {
    __strong typeof(weakSelf) strongSelf = weakSelf;
    NSLog(@"1");
      if (!strongSelf) {
        NSLog(@"2");
        return;
      }
      if (error) {
        NSLog(@"3");
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"上传图片失败" message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
        [strongSelf presentViewController:alert animated:YES completion:nil];
        return;
      }
    NSLog(@"4");
      AGPostCreateRequest* request = [[AGPostCreateRequest alloc] init];
      request.title = content.length > 12 ? [content substringToIndex:12] : content;
      request.content = [content copy];
      request.images = urls ?: @[];
      request.tags = [dict[@"crops"] copy] ?: @[];
      NSLog(@"图片url已获取");
    NSLog(@"strongSelf: %@", strongSelf);
    [manager.api createPostWithPostCreateRequest:request completionHandler:^(AGResultPostResponseDto *output, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
              NSLog(@"5");
              if (output.code.integerValue != 200) {
                if (output.code.integerValue == 401) {
                    [[TLWSDKManager shared] handleUnauthorizedWithRetry:^{
                        [manager.api createPostWithPostCreateRequest:request completionHandler:^(AGResultPostResponseDto *r, NSError *e) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [TLWToast show:(r.code.integerValue == 200) ? @"帖子发布成功" : @"帖子发送失败"];
                            });
                        }];
                    }];
                    return;
                }
                NSLog(@"6");
                [TLWToast show:@"帖子发送失败"];
                NSLog(@"帖子发布失败");
                return;
              }
              NSLog(@"7");
              NSLog(@"帖子发布成功");
              NSLog(@"strongSelf:%@", strongSelf);
              [strongSelf tl_showTopToast:@"帖子发布成功"];
              // 上传成功：找到本地发布中的帖子，清除 pending 标记并刷新对应 cell
              NSInteger pendingIndex = NSNotFound;
              AGPostResponseDto* dto = output.data;
              for (NSInteger i = 0; i < (NSInteger)strongSelf.posts.count; i++) {
                TLWCommunityPost *p = strongSelf.posts[i];
                if (p.isLocalPending) {
                  p.isLocalPending = NO;
                  p._id = dto._id;
                  p.images = urls;
                  p.likeCount = @0;
                  p.favoriteCount = @0;
                  pendingIndex = i;
                  break;
                }
              }
              if (pendingIndex != NSNotFound) {
                NSIndexPath *ip = [NSIndexPath indexPathForItem:pendingIndex inSection:0];
                [strongSelf.myView.collectionView reloadItemsAtIndexPaths:@[ip]];
              }
            });
    }];
  }];
  NSLog(@"8");
}

- (void)tl_showTopToast:(NSString *)text {
  if (text.length == 0) return;

  // 挂到“全局 window”，保证在任何页面都能看到
  UIWindow *hostWindow = nil;
  if (@available(iOS 13.0, *)) {
    // 仅使用前台激活的 Scene，避免取到后台/其他窗口的 keyWindow
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
      if (scene.activationState != UISceneActivationStateForegroundActive) continue;
      if (![scene isKindOfClass:[UIWindowScene class]]) continue;
      UIWindowScene *windowScene = (UIWindowScene *)scene;

      // 优先取 key window（当前场景正在接收事件的窗口）
      for (UIWindow *w in windowScene.windows) {
        if (w.isKeyWindow) {
          hostWindow = w;
          break;
        }
      }
      if (!hostWindow) {
        hostWindow = windowScene.windows.firstObject;
      }
      if (hostWindow) break;
    }
  } else {
    // iOS 12 及以下：直接用当前控制器关联的 window 即可（避免使用废弃的 UIApplication.windows）
    hostWindow = self.view.window;
  }
  if (!hostWindow) return;

  UIView *old = [hostWindow viewWithTag:1107];
  if (old) [old removeFromSuperview];

  UILabel *toast = [UILabel new];
  toast.tag = 1107;
  toast.text = text;
  toast.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
  toast.textColor = [UIColor colorWithRed:0.20 green:0.20 blue:0.20 alpha:1];
  toast.textAlignment = NSTextAlignmentCenter;
  toast.backgroundColor = UIColor.whiteColor;
  toast.layer.cornerRadius = 19;
  toast.layer.masksToBounds = YES;
  toast.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.15].CGColor;
  toast.layer.shadowOpacity = 1;
  toast.layer.shadowRadius = 6;
  toast.layer.shadowOffset = CGSizeMake(0, 2);
  [hostWindow addSubview:toast];

  [toast mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(hostWindow.mas_safeAreaLayoutGuideTop).offset(10);
    make.centerX.equalTo(hostWindow);
    make.width.mas_equalTo(190);
    make.height.mas_equalTo(38);
  }];

  toast.alpha = 0;
  [UIView animateWithDuration:0.25 animations:^{
    toast.alpha = 1;
  } completion:^(BOOL finished) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
      [UIView animateWithDuration:0.25 animations:^{
        toast.alpha = 0;
      } completion:^(BOOL done) {
        [toast removeFromSuperview];
      }];
    });
  }];
}

@end
