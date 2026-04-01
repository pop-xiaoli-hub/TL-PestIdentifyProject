//
//  TLWMyFavoriteController.m
//  TL-PestIdentify
//

#import "TLWMyFavoriteController.h"
#import "TLWMyFavoriteView.h"
#import "TLWFavoriteCell.h"
#import "TLWSDKManager.h"
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

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBarHidden = YES;

    [self.view addSubview:self.favoriteView];
    [self.favoriteView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];

    [self.favoriteView.collectionView registerClass:[TLWFavoriteCell class]
                         forCellWithReuseIdentifier:kFavoriteCellID];
    self.favoriteView.collectionView.dataSource = self;
    self.favoriteView.collectionView.delegate   = self;

    [self.favoriteView.backButton addTarget:self
                                     action:@selector(onBack)
                           forControlEvents:UIControlEventTouchUpInside];

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

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.navigationController.interactivePopGestureRecognizer.enabled  = YES;
    self.navigationController.interactivePopGestureRecognizer.delegate = nil;
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
                    [[TLWSDKManager shared] handleUnauthorizedWithRetry:^{
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

- (void)onBack {
    [self.navigationController popViewControllerAnimated:YES];
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
