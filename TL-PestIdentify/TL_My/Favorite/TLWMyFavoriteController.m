//
//  TLWMyFavoriteController.m
//  TL-PestIdentify
//

#import "TLWMyFavoriteController.h"
#import "TLWMyFavoriteView.h"
#import "TLWFavoriteCell.h"
#import "TLWPostDetailController.h"
#import "TLWCommunityPost.h"
#import "TLWSDKManager.h"
#import <AgriPestClient/AGPostResponseDto.h>
#import <Masonry/Masonry.h>
#import "TLWDBCollectedModel.h"
#import "TLWDBManager.h"

#import "TLWLoadingIndicator.h"

/*
本地数据库优先+网络分页同步
 */

static NSString * const kFavoriteCellID = @"TLWFavoriteCell";
static NSInteger  const kFavoritePageSize = 30;
static NSTimeInterval const kFavoriteSyncInterval = 5 * 60;

@interface TLWMyFavoriteController () <UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic, strong) TLWMyFavoriteView *favoriteView;
@property (nonatomic, strong) NSMutableArray<AGPostResponseDto *> *favorites;
@property (nonatomic, assign) NSInteger currentPage;
@property (nonatomic, assign) BOOL hasMore;
@property (nonatomic, assign) BOOL isLoading;
@property (nonatomic, assign) BOOL hasAppearedOnce;
@property (nonatomic, strong) NSDate *lastRemoteSyncDate;
@property (nonatomic, strong) NSURLSessionTask *favoriteFetchTask;
@property (nonatomic, strong) NSMutableSet<NSNumber *> *remoteSyncedPostIds;

@end

@implementation TLWMyFavoriteController

- (instancetype)init {
    self = [super init];
    if (self) {
        self.hidesBottomBarWhenPushed = YES;
        _favorites   = [NSMutableArray array];
        _currentPage = -1;
        _hasMore     = YES;
        _remoteSyncedPostIds = [NSMutableSet set];
    }
    return self;
}

- (NSString *)navTitle { return @"我的收藏"; }
- (NSString *)navTitleIconName { return @"liked"; }

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.navBar setRightButtonTitle:@"筛选" iconName:nil];
    UIImageSymbolConfiguration *filterConfig =
        [UIImageSymbolConfiguration configurationWithPointSize:18.0 weight:UIImageSymbolWeightBold];
    UIImage *filterImage = [UIImage systemImageNamed:@"line.3.horizontal.decrease.circle.fill"
                                   withConfiguration:filterConfig];
    UIColor *buttonColor = [UIColor colorWithWhite:0.96 alpha:0.92];
    UIButtonConfiguration *buttonConfig = self.navBar.rightButton.configuration ?: [UIButtonConfiguration plainButtonConfiguration];
    buttonConfig.title = @"筛选";
    buttonConfig.image = filterImage;
    buttonConfig.imagePlacement = NSDirectionalRectEdgeTrailing;
    buttonConfig.imagePadding = 6.0;
    buttonConfig.baseForegroundColor = buttonColor;
    buttonConfig.contentInsets = NSDirectionalEdgeInsetsZero;
    buttonConfig.titleTextAttributesTransformer = ^NSDictionary<NSAttributedStringKey,id> * _Nonnull(NSDictionary<NSAttributedStringKey,id> * _Nonnull incoming) {
        NSMutableDictionary<NSAttributedStringKey, id> *attrs = [incoming mutableCopy];
        attrs[NSFontAttributeName] = [UIFont systemFontOfSize:22 weight:UIFontWeightBold];
        return attrs;
    };
    self.navBar.rightButton.configuration = buttonConfig;
    self.navBar.rightButton.tintColor = buttonColor;

    [self.view addSubview:self.favoriteView];
    [self.favoriteView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    [self.view bringSubviewToFront:self.navBar];

    [self.favoriteView.collectionView registerClass:[TLWFavoriteCell class]
                         forCellWithReuseIdentifier:kFavoriteCellID];
    self.favoriteView.collectionView.dataSource = self;
    self.favoriteView.collectionView.delegate   = self;

    // 下拉刷新
    UIRefreshControl *rc = [UIRefreshControl new];
    rc.tintColor = [UIColor clearColor]; // 隐藏系统菊花
    [rc addTarget:self action:@selector(onRefresh) forControlEvents:UIControlEventValueChanged];
    self.favoriteView.collectionView.refreshControl = rc;

    [self loadFirstPage];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reloadFavoritesFromDatabase];
    if (self.hasAppearedOnce) {
        [self syncFirstRemotePageIfNeeded];
    }
    self.hasAppearedOnce = YES;
}

- (void)dealloc {
    [self.favoriteFetchTask cancel];
}

#pragma mark - Lazy

- (TLWMyFavoriteView *)favoriteView {
    if (!_favoriteView) {
        _favoriteView = [[TLWMyFavoriteView alloc] initWithFrame:CGRectZero];
    }
    return _favoriteView;
}

#pragma mark - Data Loading

- (void)loadFirstPage {
    [self reloadFavoritesFromDatabase];
    [self syncFirstRemotePageIfNeeded];
}

- (void)onRefresh {
    if (self.isLoading) {
        return;
    }
    [TLWLoadingIndicator showPullToRefreshInScrollView:self.favoriteView.collectionView size:40];
    [self fetchRemotePage:0 force:YES];
}

- (void)reloadFavoritesFromDatabase {
    NSArray<TLWDBCollectedModel *> *storedPosts = [[TLWDBManager shared] fetchAllCollectedPosts];
    NSMutableArray<AGPostResponseDto *> *posts = [NSMutableArray arrayWithCapacity:storedPosts.count];
    for (TLWDBCollectedModel *storedPost in storedPosts) {
        AGPostResponseDto *dto = [self tl_postDtoFromCollectedModel:storedPost];
        if (dto) {
            [posts addObject:dto];
        }
    }

    [self.favorites removeAllObjects];
    [self.favorites addObjectsFromArray:posts];
    [self.favoriteView showEmpty:(self.favorites.count == 0)];
    [self.favoriteView.collectionView reloadData];
}

//网络同步加载
- (void)syncFirstRemotePageIfNeeded {
    if (![TLWSDKManager shared].sessionManager.isLoggedIn || self.isLoading) {
        return;
    }

    BOOL hasNoLocalData = self.favorites.count == 0;
    BOOL syncExpired = !self.lastRemoteSyncDate || [[NSDate date] timeIntervalSinceDate:self.lastRemoteSyncDate] > kFavoriteSyncInterval;
    if (hasNoLocalData || syncExpired) {
        [self fetchRemotePage:0 force:NO];
    }
}

- (void)fetchRemotePage:(NSInteger)page force:(BOOL)force {
    if (self.isLoading) return;
    if (![TLWSDKManager shared].sessionManager.isLoggedIn) {
        [self finishRemoteLoading];
        return;
    }
    if (!force && page == 0 && self.lastRemoteSyncDate && [[NSDate date] timeIntervalSinceDate:self.lastRemoteSyncDate] <= kFavoriteSyncInterval && self.favorites.count > 0) {
        return;
    }

    self.isLoading = YES;
    if (page == 0) {
        self.hasMore = YES;
    }

    __weak typeof(self) weakSelf = self;
    self.favoriteFetchTask = [[TLWSDKManager shared] getFavoritedPostsWithPage:@(page)
                                                                          size:@(kFavoritePageSize)
                                                             completionHandler:^(AGResultPageResultPostResponseDto *output, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) self = weakSelf;
            if (!self) return;
            self.favoriteFetchTask = nil;
            [self finishRemoteLoading];

            if (error || !output || output.code.integerValue != 200) {
                if (!error && [[TLWSDKManager shared].sessionManager shouldAttemptTokenRefreshForCode:output.code]) {
                    [[TLWSDKManager shared].sessionManager handleUnauthorizedWithRetry:^{
                        [self fetchRemotePage:page force:YES];
                    }];
                    return;
                }
                NSLog(@"[Favorite] 网络同步失败，保留本地收藏: %@", error ?: output.message);
                [self.favoriteView showEmpty:(self.favorites.count == 0)];
                return;
            }

            AGPageResultPostResponseDto *pageData = output.data;
            if (!pageData) {
                NSLog(@"[Favorite] 网络同步失败，返回数据为空，保留本地收藏");
                [self.favoriteView showEmpty:(self.favorites.count == 0)];
                return;
            }

            NSArray<AGPostResponseDto *> *list = pageData.list ?: @[];
            [[TLWDBManager shared] upsertCollectedPostsFromDtos:list];

            if (page == 0) {
                [self.remoteSyncedPostIds removeAllObjects];
            }
            [self addRemoteSyncedPostIdsFromDtos:list];

            self.currentPage = page;
            self.hasMore     = pageData.hasNext.boolValue;
            self.lastRemoteSyncDate = [NSDate date];

            if (!self.hasMore) {
                [self deleteLocalFavoritesMissingFromRemoteIds:self.remoteSyncedPostIds];
            }
            [self reloadFavoritesFromDatabase];
        });
    }];
}

- (void)finishRemoteLoading {
    self.isLoading = NO;
    [self.favoriteView.collectionView.refreshControl endRefreshing];
    [TLWLoadingIndicator hideInView:self.favoriteView.collectionView];
}

- (nullable AGPostResponseDto *)tl_postDtoFromCollectedModel:(TLWDBCollectedModel *)model {
    if (!model.postId) return nil;

    AGPostResponseDto *dto = [[AGPostResponseDto alloc] init];
    dto._id = model.postId;
    dto.title = model.title ?: @"";
    dto.content = model.title ?: @"";
    dto.images = model.images ?: @[];
    dto.authorName = model.authorName ?: @"";
    dto.authorAvatar = model.authorAvatar ?: @"";
    dto.favoriteCount = model.favoriteCount ?: @0;
    dto.isFavorited = @YES;
    return dto;
}

- (void)addRemoteSyncedPostIdsFromDtos:(NSArray<AGPostResponseDto *> *)dtos {
    for (AGPostResponseDto *dto in dtos) {
        if (dto._id) {
            [self.remoteSyncedPostIds addObject:dto._id];
        }
    }
}

- (void)deleteLocalFavoritesMissingFromRemoteIds:(NSSet<NSNumber *> *)remoteIds {
    NSArray<TLWDBCollectedModel *> *localPosts = [[TLWDBManager shared] fetchAllCollectedPosts];
    for (TLWDBCollectedModel *model in localPosts) {
        if (model.postId && ![remoteIds containsObject:model.postId]) {
            [[TLWDBManager shared] deleteCollectedPostByPostId:model.postId];
        }
    }
}

#pragma mark - Actions

- (void)tl_openPostDetailAtIndex:(NSInteger)index {
    if (index < 0 || index >= self.favorites.count) return;

    AGPostResponseDto *postDto = self.favorites[index];
    NSNumber *postId = postDto._id;
    if (!postId) return;

    TLWPostDetailController *detailVC = [[TLWPostDetailController alloc] init];
    detailVC._id = postId;
    detailVC.post = [self tl_communityPostFromDto:postDto];
    detailVC.hasCollectedPosts = self.favorites;
    detailVC.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:detailVC animated:YES];
}

- (TLWCommunityPost *)tl_communityPostFromDto:(AGPostResponseDto *)dto {
    if (!dto) return nil;

    TLWCommunityPost *post = [[TLWCommunityPost alloc] init];
    post._id = dto._id;
    post.title = dto.title ?: @"";
    post.content = dto.content ?: @"";
    post.images = dto.images ?: @[];
    post.tags = dto.tags ?: @[];
    post.authorName = dto.authorName ?: @"";
    post.authorAvatar = dto.authorAvatar ?: @"";
    post.likeCount = dto.likeCount ?: @0;
    post.isLiked = dto.isLiked.boolValue;
    post.isCollected = YES;
    post.favoriteCount = dto.favoriteCount ?: @0;
    post.imageAspectRatio = 4.0 / 3.0;
    return post;
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _favorites.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                           cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    TLWFavoriteCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kFavoriteCellID
                                                                     forIndexPath:indexPath];
    [cell configureWithPostDto:_favorites[indexPath.item]];
    return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [self tl_openPostDetailAtIndex:indexPath.item];
}

#pragma mark - UIScrollViewDelegate (上拉加载更多)

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (!_hasMore || _isLoading) return;
    CGFloat offsetY    = scrollView.contentOffset.y;
    CGFloat contentH   = scrollView.contentSize.height;
    CGFloat frameH     = scrollView.frame.size.height;
    if (offsetY > contentH - frameH - 100 && contentH > 0) {
        [self fetchRemotePage:_currentPage + 1 force:YES];
    }
}
@end
