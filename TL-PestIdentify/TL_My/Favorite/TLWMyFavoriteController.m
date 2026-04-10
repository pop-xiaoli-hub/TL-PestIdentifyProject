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

static NSString * const kFavoriteCellID = @"TLWFavoriteCell";
static NSInteger  const kPageSize       = 20;

@interface TLWMyFavoriteController () <UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic, strong) TLWMyFavoriteView *favoriteView;
@property (nonatomic, strong) NSMutableArray<AGPostResponseDto *> *favorites;
@property (nonatomic, assign) NSInteger currentPage;
@property (nonatomic, assign) BOOL hasMore;
@property (nonatomic, assign) BOOL isLoading;
@property (nonatomic, assign) BOOL hasAppearedOnce;

@end

@implementation TLWMyFavoriteController

- (instancetype)init {
    self = [super init];
    if (self) {
        self.hidesBottomBarWhenPushed = YES;
        _favorites   = [NSMutableArray array];
        _currentPage = 0;
        _hasMore     = YES;
    }
    return self;
}

- (NSString *)navTitle { return @"我的收藏"; }
- (NSString *)navTitleIconName { return @"liked"; }

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.navBar setRightButtonTitle:@"筛选" iconName:@"filter"];

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
    [rc addTarget:self action:@selector(onRefresh) forControlEvents:UIControlEventValueChanged];
    self.favoriteView.collectionView.refreshControl = rc;

    [self loadFirstPage];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.hasAppearedOnce) {
        [self onRefresh];
    }
    self.hasAppearedOnce = YES;
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
    _currentPage = 0;
    _hasMore     = YES;
    [_favorites removeAllObjects];
    [self.favoriteView.collectionView reloadData];
    [self fetchPage:0];
}

- (void)onRefresh {
    _currentPage = 0;
    _hasMore     = YES;
    [_favorites removeAllObjects];
    [self.favoriteView.collectionView reloadData];
    [self fetchPage:0];
}

- (void)fetchPage:(NSInteger)page {
    if (_isLoading) return;
    _isLoading = YES;

    __weak typeof(self) weakSelf = self;
    [[TLWSDKManager shared].api getFavoritedPostsWithPage:@(page)
                                                     size:@(kPageSize)
                                        completionHandler:^(AGResultPageResultPostResponseDto *output, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) self = weakSelf;
            if (!self) return;
            self.isLoading = NO;
            [self.favoriteView.collectionView.refreshControl endRefreshing];

            if (error || output.code.integerValue != 200) {
                if (output.code.integerValue == 401) {
                    [[TLWSDKManager shared].sessionManager handleUnauthorizedWithRetry:^{
                        [self fetchPage:page];
                    }];
                    return;
                }
                NSLog(@"[Favorite] 加载失败: %@", error ?: output.message);
                [self.favoriteView showEmpty:(self.favorites.count == 0)];
                return;
            }

            AGPageResultPostResponseDto *pageData = output.data;
            NSArray<AGPostResponseDto *> *list = pageData.list ?: @[];

            if (page == 0) {
                [self.favorites removeAllObjects];
            }
            [self.favorites addObjectsFromArray:list];

            self.currentPage = page;
            self.hasMore     = pageData.hasNext.boolValue;

            [self.favoriteView showEmpty:(self.favorites.count == 0)];
            [self.favoriteView.collectionView reloadData];
        });
    }];
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
        [self fetchPage:_currentPage + 1];
    }
}

@end
