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
#import "TLWToast.h"

/*
本地数据库优先+网络分页同步
 */

static NSString * const kFavoriteCellID = @"TLWFavoriteCell";
static NSInteger  const kFavoritePageSize = 30;
static NSTimeInterval const kFavoriteSyncInterval = 5 * 60;

@interface TLWMyFavoriteController () <UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic, strong) TLWMyFavoriteView *favoriteView;
@property (nonatomic, strong) NSMutableArray<AGPostResponseDto *> *favorites;
@property (nonatomic, strong) NSArray<AGPostResponseDto *> *allFavorites;
@property (nonatomic, assign) NSInteger currentPage;
@property (nonatomic, assign) BOOL hasMore;
@property (nonatomic, assign) BOOL isLoading;
@property (nonatomic, assign) BOOL hasAppearedOnce;
@property (nonatomic, strong) NSDate *lastRemoteSyncDate;
@property (nonatomic, strong) NSURLSessionTask *favoriteFetchTask;
@property (nonatomic, strong) NSMutableSet<NSNumber *> *remoteSyncedPostIds;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSNumber *> *favoriteCollectedAtMap;
@property (nonatomic, strong) UIView *filterMaskView;
@property (nonatomic, strong) UIView *filterPanelView;
@property (nonatomic, strong) UILabel *filterYearLabel;
@property (nonatomic, strong) NSArray<UIButton *> *monthButtons;
@property (nonatomic, assign) NSInteger selectedFilterYear;
@property (nonatomic, assign) NSInteger selectedFilterMonth;
@property (nonatomic, assign) NSInteger pendingFilterYear;
@property (nonatomic, assign) NSInteger pendingFilterMonth;

@end

@implementation TLWMyFavoriteController

- (instancetype)init {
    self = [super init];
    if (self) {
        self.hidesBottomBarWhenPushed = YES;
        _favorites   = [NSMutableArray array];
        _allFavorites = @[];
        _currentPage = -1;
        _hasMore     = YES;
        _remoteSyncedPostIds = [NSMutableSet set];
        _favoriteCollectedAtMap = [NSMutableDictionary dictionary];
    }
    return self;
}

- (NSString *)navTitle { return @"我的收藏"; }
- (NSString *)navTitleIconName { return @"liked"; }

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.navBar setRightButtonTitle:@"筛选" iconName:@"筛选"];

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

    [self.navBar.rightButton addTarget:self
                                action:@selector(tl_filter)
                      forControlEvents:UIControlEventTouchUpInside];

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
    [self.favoriteCollectedAtMap removeAllObjects];
    for (TLWDBCollectedModel *storedPost in storedPosts) {
        AGPostResponseDto *dto = [self tl_postDtoFromCollectedModel:storedPost];
        if (dto) {
            [posts addObject:dto];
            if (storedPost.postId) {
                self.favoriteCollectedAtMap[storedPost.postId] = @(storedPost.collectedAt);
            }
        }
    }
    self.allFavorites = [posts copy];
    [self tl_prepareDefaultFilterIfNeededWithFavorites:self.allFavorites];
    [self tl_applyFavoriteFilterAndReload];
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

- (void)tl_filter {
    [self tl_preparePendingFilter];
    [self tl_updateFilterPanelSelection];
    [self tl_showFilterPanel];
}

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

#pragma mark - Filter

- (NSArray<AGPostResponseDto *> *)tl_filteredFavoritesFromFavorites:(NSArray<AGPostResponseDto *> *)favorites {
    if (self.selectedFilterYear <= 0 || self.selectedFilterMonth <= 0) {
        return favorites ?: @[];
    }

    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSMutableArray<AGPostResponseDto *> *filtered = [NSMutableArray array];
    for (AGPostResponseDto *dto in favorites) {
        NSNumber *collectedAtNumber = dto._id ? self.favoriteCollectedAtMap[dto._id] : nil;
        if (collectedAtNumber.longLongValue <= 0) {
            continue;
        }
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:collectedAtNumber.longLongValue / 1000.0];
        NSDateComponents *components = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth fromDate:date];
        if (components.year == self.selectedFilterYear && components.month == self.selectedFilterMonth) {
            [filtered addObject:dto];
        }
    }
    return [filtered copy];
}

- (void)tl_applyFavoriteFilterAndReload {
    NSArray<AGPostResponseDto *> *filteredFavorites = [self tl_filteredFavoritesFromFavorites:self.allFavorites];
    [self.favorites removeAllObjects];
    [self.favorites addObjectsFromArray:filteredFavorites];
    [self.favoriteView showEmpty:(self.favorites.count == 0)];
    [self.favoriteView.collectionView reloadData];
}

- (void)tl_prepareDefaultFilterIfNeededWithFavorites:(NSArray<AGPostResponseDto *> *)favorites {
    if (self.selectedFilterYear > 0 && self.selectedFilterMonth > 0) {
        return;
    }

    NSDate *referenceDate = nil;
    for (AGPostResponseDto *dto in favorites) {
        NSNumber *collectedAtNumber = dto._id ? self.favoriteCollectedAtMap[dto._id] : nil;
        if (collectedAtNumber.longLongValue > 0) {
            referenceDate = [NSDate dateWithTimeIntervalSince1970:collectedAtNumber.longLongValue / 1000.0];
            break;
        }
    }
    if (!referenceDate) {
        referenceDate = [NSDate date];
    }

    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitYear | NSCalendarUnitMonth fromDate:referenceDate];
    self.selectedFilterYear = components.year;
    self.selectedFilterMonth = components.month;
}

- (void)tl_preparePendingFilter {
    if (self.selectedFilterYear <= 0 || self.selectedFilterMonth <= 0) {
        [self tl_prepareDefaultFilterIfNeededWithFavorites:self.allFavorites];
    }
    self.pendingFilterYear = self.selectedFilterYear;
    self.pendingFilterMonth = self.selectedFilterMonth;
}

- (void)tl_showFilterPanel {
    if (!self.filterMaskView) {
        [self tl_buildFilterPanelIfNeeded];
    }
    self.filterMaskView.hidden = NO;
    self.filterMaskView.alpha = 0.0;
    self.filterPanelView.transform = CGAffineTransformMakeScale(0.96, 0.96);
    [UIView animateWithDuration:0.22 animations:^{
        self.filterMaskView.alpha = 1.0;
        self.filterPanelView.transform = CGAffineTransformIdentity;
    }];
}

- (void)tl_hideFilterPanel {
    if (!self.filterMaskView || self.filterMaskView.hidden) {
        return;
    }
    [UIView animateWithDuration:0.2 animations:^{
        self.filterMaskView.alpha = 0.0;
        self.filterPanelView.transform = CGAffineTransformMakeScale(0.96, 0.96);
    } completion:^(BOOL finished) {
        self.filterMaskView.hidden = YES;
        self.filterPanelView.transform = CGAffineTransformIdentity;
    }];
}

- (void)tl_buildFilterPanelIfNeeded {
    UIView *maskView = [[UIView alloc] init];
    maskView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.16];
    maskView.hidden = YES;
    [self.view addSubview:maskView];
    [maskView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    self.filterMaskView = maskView;

    UIButton *dismissButton = [UIButton buttonWithType:UIButtonTypeCustom];
    dismissButton.backgroundColor = [UIColor clearColor];
    [dismissButton addTarget:self action:@selector(tl_hideFilterPanel) forControlEvents:UIControlEventTouchUpInside];
    [maskView addSubview:dismissButton];
    [dismissButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(maskView);
    }];

    UIView *panel = [[UIView alloc] init];
    panel.backgroundColor = [UIColor whiteColor];
    panel.layer.cornerRadius = 20.0;
    panel.layer.masksToBounds = YES;
    [maskView addSubview:panel];
    self.filterPanelView = panel;
    [panel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(maskView).offset(28);
        make.right.equalTo(maskView).offset(-28);
        make.top.equalTo(maskView).offset(92);
    }];

    UIButton *prevButton = [self tl_filterArrowButtonWithTitle:@"←"];
    prevButton.tag = -1;
    [prevButton addTarget:self action:@selector(tl_changeFilterYear:) forControlEvents:UIControlEventTouchUpInside];
    [panel addSubview:prevButton];

    UIButton *nextButton = [self tl_filterArrowButtonWithTitle:@"→"];
    nextButton.tag = 1;
    [nextButton addTarget:self action:@selector(tl_changeFilterYear:) forControlEvents:UIControlEventTouchUpInside];
    [panel addSubview:nextButton];

    UILabel *yearLabel = [[UILabel alloc] init];
    yearLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightSemibold];
    yearLabel.textColor = [UIColor colorWithWhite:0.25 alpha:1.0];
    yearLabel.textAlignment = NSTextAlignmentCenter;
    [panel addSubview:yearLabel];
    self.filterYearLabel = yearLabel;

    [prevButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(panel).offset(26);
        make.top.equalTo(panel).offset(20);
        make.width.height.mas_equalTo(40);
    }];
    [nextButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(panel).offset(-26);
        make.centerY.equalTo(prevButton);
        make.width.height.mas_equalTo(40);
    }];
    [yearLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(prevButton);
        make.centerX.equalTo(panel);
    }];

    NSArray<NSString *> *months = @[@"一月", @"二月", @"三月", @"四月", @"五月",
                                    @"六月", @"七月", @"八月", @"九月", @"十月",
                                    @"十一月", @"十二月"];
    NSMutableArray<UIButton *> *buttons = [NSMutableArray array];
    NSInteger columnCount = 5;
    CGFloat horizontalInset = 18.0;
    CGFloat buttonWidth = (UIScreen.mainScreen.bounds.size.width - 56.0 - horizontalInset * 2) / 5.0;
    CGFloat buttonHeight = 40.0;
    CGFloat topStart = 88.0;
    CGFloat rowSpacing = 22.0;

    for (NSInteger index = 0; index < months.count; index++) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button setTitle:months[index] forState:UIControlStateNormal];
        [button setTitleColor:[UIColor colorWithWhite:0.65 alpha:1.0] forState:UIControlStateNormal];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
        button.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
        button.layer.cornerRadius = 6.0;
        button.tag = index + 1;
        [button addTarget:self action:@selector(tl_monthButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [panel addSubview:button];
        [buttons addObject:button];

        NSInteger row = index / columnCount;
        NSInteger column = index % columnCount;
        CGFloat left = horizontalInset + column * buttonWidth;
        CGFloat top = topStart + row * (buttonHeight + rowSpacing);
        [button mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(panel).offset(left);
            make.top.equalTo(panel).offset(top);
            make.width.mas_equalTo(buttonWidth);
            make.height.mas_equalTo(buttonHeight);
        }];
    }
    self.monthButtons = [buttons copy];

    UIView *line = [[UIView alloc] init];
    line.backgroundColor = [UIColor colorWithWhite:0.93 alpha:1.0];
    [panel addSubview:line];
    [line mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(panel);
        make.top.equalTo(panel).offset(280);
        make.height.mas_equalTo(1.0);
    }];

    UIButton *confirmButton = [self tl_filterActionButtonWithTitle:@"确认" filled:YES];
    [confirmButton addTarget:self action:@selector(tl_confirmFilterSelection) forControlEvents:UIControlEventTouchUpInside];
    [panel addSubview:confirmButton];

    UIButton *cancelButton = [self tl_filterActionButtonWithTitle:@"取消" filled:NO];
    [cancelButton addTarget:self action:@selector(tl_hideFilterPanel) forControlEvents:UIControlEventTouchUpInside];
    [panel addSubview:cancelButton];

    [confirmButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(line.mas_bottom).offset(12);
        make.right.equalTo(panel.mas_centerX).offset(-10);
        make.width.mas_equalTo(88);
        make.height.mas_equalTo(38);
        make.bottom.equalTo(panel).offset(-14);
    }];
    [cancelButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(confirmButton);
        make.left.equalTo(panel.mas_centerX).offset(10);
        make.width.height.equalTo(confirmButton);
    }];
}

- (UIButton *)tl_filterArrowButtonWithTitle:(NSString *)title {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:[UIColor colorWithRed:1.0 green:0.69 blue:0.12 alpha:1.0] forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:24 weight:UIFontWeightSemibold];
    button.layer.cornerRadius = 20.0;
    button.layer.borderWidth = 1.0;
    button.layer.borderColor = [UIColor colorWithWhite:0.9 alpha:1.0].CGColor;
    button.backgroundColor = [UIColor whiteColor];
    return button;
}

- (UIButton *)tl_filterActionButtonWithTitle:(NSString *)title filled:(BOOL)filled {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setTitle:title forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    button.layer.cornerRadius = 6.0;
    button.layer.borderWidth = filled ? 0.0 : 1.0;
    if (filled) {
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        button.backgroundColor = [UIColor colorWithRed:1.0 green:0.69 blue:0.12 alpha:1.0];
    } else {
        [button setTitleColor:[UIColor colorWithRed:1.0 green:0.69 blue:0.12 alpha:1.0] forState:UIControlStateNormal];
        button.backgroundColor = [UIColor whiteColor];
        button.layer.borderColor = [UIColor colorWithRed:1.0 green:0.69 blue:0.12 alpha:1.0].CGColor;
    }
    return button;
}

- (void)tl_changeFilterYear:(UIButton *)sender {
    self.pendingFilterYear += sender.tag;
    [self tl_updateFilterPanelSelection];
}

- (void)tl_monthButtonTapped:(UIButton *)sender {
    self.pendingFilterMonth = sender.tag;
    [self tl_updateFilterPanelSelection];
}

- (void)tl_updateFilterPanelSelection {
    self.filterYearLabel.text = [NSString stringWithFormat:@"%ld年", (long)self.pendingFilterYear];
    for (UIButton *button in self.monthButtons) {
        BOOL selected = (button.tag == self.pendingFilterMonth);
        button.selected = selected;
        button.backgroundColor = selected ? [UIColor colorWithRed:1.0 green:0.69 blue:0.12 alpha:1.0] : [UIColor clearColor];
    }
}

- (void)tl_confirmFilterSelection {
    self.selectedFilterYear = self.pendingFilterYear;
    self.selectedFilterMonth = self.pendingFilterMonth;
    [self tl_applyFavoriteFilterAndReload];
    [self tl_hideFilterPanel];
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
