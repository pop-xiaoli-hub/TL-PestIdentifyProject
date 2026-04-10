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
#import "TL_SearchResult/TLWSearchResultController.h"
#import "TLWSDKManager.h"
#import "TLWToast.h"
#import <Masonry/Masonry.h>
#import "TLWDBManager.h"
#import "TLWCommunitySuggestionCell.h"
#import "TLWLoadingIndicator.h"
static NSString *const kCommunityCellID = @"TLWCommunityCell";
static NSString *const kCommunitySuggestionCellID = @"TLWCommunitySuggestionCell";
static NSInteger const kCommunityFeedPageSize = 20;
static NSTimeInterval const kCommunityRefreshTimeout = 8.0;

@interface TLWCommunityController () <UICollectionViewDataSource, UICollectionViewDelegate, TLWCommunityWaterfallLayoutDelegate, UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) TLWCommunityView *myView;
@property (nonatomic, strong) NSMutableArray *posts;
@property (nonatomic, assign) BOOL elderModeEnabled;
@property (nonatomic, assign) BOOL tl_isFetchingFeed;
@property (nonatomic, assign) NSInteger currentFeedPage;
@property (nonatomic, assign) BOOL hasMoreFeed;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, assign) NSInteger feedRequestToken;
@property (nonatomic, strong) NSMutableArray* collectePosts;
@property (nonatomic, strong) NSMutableArray<NSString *> *searchSuggestions;
@property (nonatomic, strong, nullable) NSURLSessionTask *suggestionTask;
@property (nonatomic, copy) NSString *pendingSuggestionQuery;
@property (nonatomic, assign) NSInteger suggestionRequestToken;
@property (nonatomic, copy) NSString *activeSearchQuery;
@property (nonatomic, strong) NSArray<TLWCommunityPost *> *searchRecommendations;
@property (nonatomic, strong) NSArray<NSString *> *searchKeywordSuggestions;
@property (nonatomic, assign) BOOL isSearchingPosts;
@end

@implementation TLWCommunityController

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [self tl_applyCommunityLayoutStyle];//进行适老化设置判断
  [self tl_resetSearchStateIfNeeded];
}

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
  UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
  refreshControl.tintColor = [UIColor clearColor]; // 隐藏系统菊花
  [refreshControl addTarget:self action:@selector(tl_handlePullToRefresh) forControlEvents:UIControlEventValueChanged];
  self.myView.collectionView.refreshControl = refreshControl;
  self.refreshControl = refreshControl;
  self.posts = [NSMutableArray array];
  self.searchSuggestions = [NSMutableArray array];
  self.pendingSuggestionQuery = @"";
  self.activeSearchQuery = @"";
  self.searchRecommendations = @[];
  self.searchKeywordSuggestions = @[];
  self.tl_isFetchingFeed = NO;
  self.currentFeedPage = -1;
  self.hasMoreFeed = YES;
  self.feedRequestToken = 0;
  [self tl_applyCommunityLayoutStyle];
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
  self.currentFeedPage = -1;
  self.hasMoreFeed = YES;
  [self tl_fetchNextCommunityPage];
}

- (void)tl_fetchNextCommunityPage {
  if (self.tl_isFetchingFeed) {
    return;
  }
  if (!self.hasMoreFeed) {
    return;
  }
  self.tl_isFetchingFeed = YES;
  if (self.posts.count == 0 && !self.refreshControl.refreshing) {
    [TLWLoadingIndicator showInView:self.myView.collectionView];
  }

  TLWSDKManager *sdk = [TLWSDKManager shared];
  NSInteger nextPage = self.currentFeedPage + 1;
  self.feedRequestToken += 1;
  NSInteger requestToken = self.feedRequestToken;
  __weak typeof(self) weakSelf = self;
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kCommunityRefreshTimeout * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    __strong typeof(weakSelf) strongSelf = weakSelf;
    if (!strongSelf) return;
    if (requestToken != strongSelf.feedRequestToken) return;
    if (!strongSelf.tl_isFetchingFeed) return;

    strongSelf.feedRequestToken += 1;
    strongSelf.tl_isFetchingFeed = NO;
    [strongSelf.refreshControl endRefreshing];
    [TLWLoadingIndicator hideInView:strongSelf.myView.collectionView];
    NSLog(@"[Community] page=%ld 请求超时，保持当前帖子列表不变", (long)nextPage);
  });
  [sdk getAllPostsWithTag:nil
                        q:nil
                     page:@(nextPage)
                     size:@(kCommunityFeedPageSize)
        completionHandler:^(AGResultPageResultPostResponseDto *output, NSError *error) {
    __strong typeof(weakSelf) strongSelf = weakSelf;
    if (!strongSelf) return;

    dispatch_async(dispatch_get_main_queue(), ^{
      if (requestToken != strongSelf.feedRequestToken) {
        return;
      }
      strongSelf.tl_isFetchingFeed = NO;
      [strongSelf.refreshControl endRefreshing];
    [TLWLoadingIndicator hideInView:strongSelf.myView.collectionView];

      NSLog(@"[Community] page=%ld error=%@ code=%@ message=%@ listCount=%lu",
            (long)nextPage, error, output.code, output.message,
            (unsigned long)output.data.list.count);

      if (error || !output || !output.data.list) {
        NSLog(@"[Community] 拉取失败: error=%@, output=%@", error, output);
        return;
      }

      NSArray<TLWCommunityPost *> *newPosts = [strongSelf tl_postsFromDtoList:output.data.list];
      NSMutableArray<TLWCommunityPost *> *localPendingPosts = [NSMutableArray array];
      for (TLWCommunityPost *post in strongSelf.posts) {
        if (post.isLocalPending) {
          [localPendingPosts addObject:post];
        }
      }

      if (nextPage == 0) {
        strongSelf.posts = [NSMutableArray arrayWithArray:localPendingPosts];
      }
      [strongSelf.posts addObjectsFromArray:newPosts];
      strongSelf.currentFeedPage = nextPage;
      strongSelf.hasMoreFeed = output.data.hasNext.boolValue;
      [strongSelf.myView.collectionView reloadData];
    });
  }];
}

- (void)tl_handlePullToRefresh {
  if (self.activeSearchQuery.length > 0 || self.tl_isFetchingFeed) {
    [self.refreshControl endRefreshing];
    return;
  }
  [TLWLoadingIndicator showPullToRefreshInScrollView:self.myView.collectionView size:40];
  [self tl_fetchCommunityFeed];
}

- (TLWCommunityPost *)tl_postFromDto:(AGPostResponseDto *)dto {
  if (!dto) {
    return nil;
  }

  TLWCommunityPost *post = [TLWCommunityPost new];
  post._id = dto._id;
  post.title = dto.title ?: @"";
  post.content = dto.content ?: @"";
  post.images = dto.images ?: @[];
  post.tags = dto.tags ?: @[];
  post.authorName = dto.authorName ?: @"";
  post.authorAvatar = dto.authorAvatar ?: @"";
  post.likeCount = dto.likeCount ?: @0;
  post.isLiked = dto.isLiked.boolValue;
  post.isCollected = dto.isFavorited.boolValue;
  post.favoriteCount = dto.favoriteCount ?: @0;
  return post;
}

- (NSArray<TLWCommunityPost *> *)tl_postsFromDtoList:(NSArray<AGPostResponseDto *> *)dtoList {
  NSMutableArray<TLWCommunityPost *> *posts = [NSMutableArray array];
  for (AGPostResponseDto *dto in dtoList ?: @[]) {
    TLWCommunityPost *post = [self tl_postFromDto:dto];
    if (post) {
      [posts addObject:post];
    }
  }
  return [posts copy];
}

- (void)tl_resetSearchStateIfNeeded {
  if (self.myView.searchTextField.text.length == 0 &&
      self.activeSearchQuery.length == 0 &&
      self.pendingSuggestionQuery.length == 0 &&
      self.searchSuggestions.count == 0) {
    return;
  }

  self.myView.searchTextField.text = @"";
  self.activeSearchQuery = @"";
  self.pendingSuggestionQuery = @"";
  [self.suggestionTask cancel];
  self.suggestionTask = nil;
  [self.myView.searchTextField resignFirstResponder];
  [self.myView tl_hideSearchOverlay];
  [self tl_clearSuggestionList];
}

- (BOOL)tl_isElderModeEnabled {
  NSInteger currentUserId = [TLWSDKManager shared].sessionManager.userId;
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSString *elderModeKey = [NSString stringWithFormat:@"TLW_elder_mode_%ld", (long)currentUserId];
  if ([defaults objectForKey:elderModeKey] != nil) {//优先读取用户的专属key
    return [defaults boolForKey:elderModeKey];
  }
  if ([defaults objectForKey:@"TLW_elder_mode"] != nil) {//如果客户级没有再兼容全局key
    return [defaults boolForKey:@"TLW_elder_mode"];
  }
  return NO;//默认不开启
}

- (void)tl_applyCommunityLayoutStyle {
  self.elderModeEnabled = [self tl_isElderModeEnabled];//获取当前适老化数据      
  [self.myView applyElderModeEnabled:self.elderModeEnabled];

  TLWCommunityWaterfallLayout *layout = (TLWCommunityWaterfallLayout *)self.myView.collectionView.collectionViewLayout;
  layout.numberOfColumns = self.elderModeEnabled ? 1 : 2;
  layout.columnSpacing = self.elderModeEnabled ? 0.0 : 10.0;
  layout.rowSpacing = self.elderModeEnabled ? 14.0 : 10.0;
  layout.sectionInset = self.elderModeEnabled ? UIEdgeInsetsMake(14, 12, 20, 12) : UIEdgeInsetsMake(12, 12, 20, 12);
  [layout invalidateLayout];

  if (self.isViewLoaded) {
    [self.myView.collectionView reloadData];
  }
}

- (void)tl_reloadPostWithId:(NSNumber *)postId {
  if (postId == nil) {
    return;
  }

  __weak typeof(self) weakSelf = self;
  [[TLWSDKManager shared] getPostDetailWithId:postId completionHandler:^(AGResultPostResponseDto *output, NSError *error) {
    dispatch_async(dispatch_get_main_queue(), ^{
      __strong typeof(weakSelf) strongSelf = weakSelf;
      if (!strongSelf) return;

      if (error || !output || output.code.integerValue != 200 || !output.data) {
        if (!error && output.code.integerValue == 401) {
          [[TLWSDKManager shared].sessionManager handleUnauthorizedWithRetry:^{
            [strongSelf tl_reloadPostWithId:postId];
          }];
          return;
        }
        NSLog(@"[Community] 回刷帖子失败: %@", error.localizedDescription ?: output.message);
        return;
      }

      NSInteger targetIndex = NSNotFound;
      for (NSInteger i = 0; i < strongSelf.posts.count; i++) {
        TLWCommunityPost *post = strongSelf.posts[i];
        if ([post._id isEqualToNumber:postId]) {
          targetIndex = i;
          break;
        }
      }

      if (targetIndex == NSNotFound) {
        return;
      }

      TLWCommunityPost *updatedPost = [strongSelf tl_postFromDto:output.data];
      TLWCommunityPost *oldPost = strongSelf.posts[targetIndex];
      updatedPost.imageAspectRatio = oldPost.imageAspectRatio;
      updatedPost.isLocalPending = oldPost.isLocalPending;
      strongSelf.posts[targetIndex] = updatedPost;

      NSIndexPath *indexPath = [NSIndexPath indexPathForItem:targetIndex inSection:0];
      if ([[strongSelf.myView.collectionView indexPathsForVisibleItems] containsObject:indexPath]) {
        [strongSelf.myView.collectionView reloadItemsAtIndexPaths:@[ indexPath ]];
      } else {
        [strongSelf.myView.collectionView reloadData];
      }
    });
  }];
}

- (void)tl_executeSearchWithQuery:(NSString *)query {
  NSString *trimmedQuery = [query stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];//取出输入前后的空格、换行
  self.myView.searchTextField.text = trimmedQuery;//将清理后的值重新写回输入框

  if (trimmedQuery.length == 0) {//用户没有输入有效的词汇，推出搜索态
    self.activeSearchQuery = @"";
    self.searchRecommendations = @[];
    self.searchKeywordSuggestions = @[];
    [self tl_clearSuggestionList];
    [self.myView.searchTextField resignFirstResponder];
    [self.myView tl_hideSearchOverlay];
    [self tl_fetchCommunityFeed];
    return;
  }

  //防止重复的进行请求搜索
  if (self.isSearchingPosts) {
    return;
  }

  self.isSearchingPosts = YES;//进入请求态
  self.activeSearchQuery = trimmedQuery;
  [self.suggestionTask cancel];
  self.suggestionTask = nil;
  [self tl_clearSuggestionList];

  __weak typeof(self) weakSelf = self;
  [[TLWSDKManager shared] searchPostsWithQ:trimmedQuery page:@0 size:@20 completionHandler:^(AGResultSearchResultResponse *output, NSError *error) {
    dispatch_async(dispatch_get_main_queue(), ^{
      __strong typeof(weakSelf) strongSelf = weakSelf;
      if (!strongSelf) return;
      strongSelf.isSearchingPosts = NO;

      if (error || !output || output.code.integerValue != 200 || !output.data) {
        if (!error && output.code.integerValue == 401) {
          //鉴权过期失败重试
          [[TLWSDKManager shared].sessionManager handleUnauthorizedWithRetry:^{
            [strongSelf tl_executeSearchWithQuery:trimmedQuery];
          }];
          return;
        }
        NSLog(@"[Community] 搜索失败: %@", error.localizedDescription ?: output.message);
        [TLWToast show:(output.message.length > 0 ? output.message : @"搜索失败，请稍后重试")];
        return;
      }

      //如果发现用户当前搜索框的keyword与网申返回结果的keyword不同的话，判断无效，异步结果防干扰
      NSString *currentQuery = [strongSelf.myView.searchTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
      if (![currentQuery isEqualToString:trimmedQuery]) {
        return;
      }

      strongSelf.activeSearchQuery = trimmedQuery;
      strongSelf.searchRecommendations = [strongSelf tl_postsFromDtoList:output.data.recommendations];
      strongSelf.searchKeywordSuggestions = output.data.suggestions ?: @[];

      NSArray<TLWCommunityPost *> *matchedPosts = [strongSelf tl_postsFromDtoList:output.data.matches.list];
      [strongSelf.myView.searchTextField resignFirstResponder];
      [strongSelf.myView tl_hideSearchOverlay];

      TLWSearchResultController *resultVC = [[TLWSearchResultController alloc] init];
      resultVC.queryText = trimmedQuery;
      resultVC.posts = [matchedPosts mutableCopy];
      resultVC.recommendations = strongSelf.searchRecommendations;
      resultVC.keywordSuggestions = strongSelf.searchKeywordSuggestions;
      resultVC.hasCollectedPosts = strongSelf.collectePosts;

      UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:resultVC];
      nav.modalPresentationStyle = UIModalPresentationFullScreen;
      nav.navigationBarHidden = YES;
      [strongSelf presentViewController:nav animated:YES completion:nil];
    });
  }];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
  return self.posts.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
  TLWCommunityCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kCommunityCellID forIndexPath:indexPath];
  TLWCommunityPost *post = self.posts[indexPath.item];

  if (self.elderModeEnabled) {
    post.imageAspectRatio = 0.62;
  } else if (indexPath.row == 0) {
    post.imageAspectRatio = 0.60;
  } else {
    post.imageAspectRatio = 0.75;
  }
  NSLog(@"点赞数-1 : %@", post.likeCount);
  cell.elderModeEnabled = self.elderModeEnabled;
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
  detailVC.post = post;
  __weak typeof(self) weakSelf = self;
  detailVC.reloadPosts = ^(NSNumber * _Nonnull postId) {
    __strong typeof(weakSelf) strongSelf = weakSelf;
    if (!strongSelf) return;
    NSLog(@"重新拉取帖子详情并刷新社区页: %@", postId);
    [strongSelf tl_reloadPostWithId:postId];
  };
  detailVC.hasCollectedPosts = self.collectePosts;
  detailVC.hidesBottomBarWhenPushed = YES;
  [self.navigationController pushViewController:detailVC animated:YES];
}

#pragma mark - TLWCommunityWaterfallLayoutDelegate

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)layout heightForItemAtIndexPath:(NSIndexPath *)indexPath itemWidth:(CGFloat)width {
  TLWCommunityPost *post = self.posts[indexPath.item];
  // 瀑布流高度计算使用的纵横比规则应与 cell 展示保持一致
  if (self.elderModeEnabled) {
    post.imageAspectRatio = 0.62;
  } else if (indexPath.row == 0) {
    post.imageAspectRatio = 0.60;
  } else {
    post.imageAspectRatio = 0.75;
  }
  CGFloat cellHeight = [post cellHeightForWidth:width];
  return self.elderModeEnabled ? (cellHeight + 28.0) : cellHeight;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
  if (scrollView != self.myView.collectionView) {
    return;
  }
  if (self.activeSearchQuery.length > 0) {
    return;
  }

  CGFloat contentHeight = scrollView.contentSize.height;
  CGFloat visibleHeight = CGRectGetHeight(scrollView.bounds);
  CGFloat offsetY = scrollView.contentOffset.y;
  if (contentHeight <= 0 || visibleHeight <= 0) {
    return;
  }

  if (offsetY > contentHeight - visibleHeight - 120.0) {
    [self tl_fetchNextCommunityPage];
  }
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
  [self tl_executeSearchWithQuery:textField.text ?: @""];
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
  NSLog(@"执行词条搜索");

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
          [[TLWSDKManager shared].sessionManager handleUnauthorizedWithRetry:^{
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

/*
 TLWCommunityPost *post = self.posts[indexPath.item];
 TLWPostDetailController *detailVC = [[TLWPostDetailController alloc] init];
 NSLog(@"post:%@", post.content);
 NSLog(@"post.favcount = %@", post.favoriteCount);
 detailVC._id = post._id;
 detailVC.post = post;
 __weak typeof(self) weakSelf = self;
 detailVC.reloadPosts = ^(NSNumber * _Nonnull postId) {
   __strong typeof(weakSelf) strongSelf = weakSelf;
   if (!strongSelf) return;
   NSLog(@"重新拉取帖子详情并刷新社区页: %@", postId);
   [strongSelf tl_reloadPostWithId:postId];
 };
 detailVC.hasCollectedPosts = self.collectePosts;
 detailVC.hidesBottomBarWhenPushed = YES;
 [self.navigationController pushViewController:detailVC animated:YES];

 */

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  if (indexPath.row >= self.searchSuggestions.count) {
    return;
  }
  NSString *text = self.searchSuggestions[indexPath.row];
  [self tl_executeSearchWithQuery:text];
}

- (void)tl_updatePost:(NSNotification* )notification {
  __weak typeof(self) weakSelf = self;
  TLWSDKManager* manager = [TLWSDKManager shared];
  NSDictionary* dict = notification.userInfo;
  NSString* title = dict[@"title"];
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
    request.title = [title copy];
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
            [[TLWSDKManager shared].sessionManager handleUnauthorizedWithRetry:^{
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
