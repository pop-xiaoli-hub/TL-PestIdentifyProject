//
//  TLWMyController.m
//  TL-PestIdentify
//

#import "TLWMyController.h"
#import "TLWMyView.h"
#import "TLWEditProfileController.h"
#import "TLWSettingViewController.h"
#import "TLWMyFavoriteController.h"
#import "TLWRecordController.h"
#import "TLWPostDetailController.h"
#import "TLWSDKManager.h"
#import "TLWToast.h"
#import <Masonry/Masonry.h>
#import <SDWebImage/SDWebImage.h>
#import "TLWDBManager.h"
#import "TLWDBMyPublishedModel.h"

extern NSString * const TLWAvatarDidUpdateNotification;
extern NSString * const TLWProfileDidUpdateNotification;

static NSInteger const kMyPublishedPageSize = 30;
static NSTimeInterval const kMyPublishedSyncInterval = 5 * 60;

@interface TLWMyController ()

@property (nonatomic, strong) TLWMyView *myView;
@property (nonatomic, assign) BOOL hasLoadedMyPostsOnce;
@property (nonatomic, assign) NSInteger currentMyPostsPage;
@property (nonatomic, assign) BOOL hasMoreMyPosts;
@property (nonatomic, assign) BOOL isLoadingMyPosts;
@property (nonatomic, strong) NSDate *lastMyPostsSyncDate;
@property (nonatomic, strong) NSURLSessionTask *myPostsTask;
@property (nonatomic, strong) NSMutableSet<NSNumber *> *remoteSyncedMyPostIds;
@property (nonatomic, assign) BOOL elderModeEnabled;

@end

@implementation TLWMyController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.currentMyPostsPage = -1;
    self.hasMoreMyPosts = YES;
    self.remoteSyncedMyPostIds = [NSMutableSet set];

    [self.view addSubview:self.myView];
    [self.myView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    [self setupActions];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onProfileUpdated)
                                                 name:TLWProfileDidUpdateNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onAvatarUpdated:)
                                                 name:TLWAvatarDidUpdateNotification
                                               object:nil];
    [self applyProfile];

    __weak typeof(self) weakSelf = self;
    self.myView.onPostTapped = ^(NSNumber *postId) {
        TLWPostDetailController *vc = [[TLWPostDetailController alloc] init];
        vc._id = postId;
        vc.hidesBottomBarWhenPushed = YES;
        [weakSelf.navigationController pushViewController:vc animated:YES];
    };
    self.myView.onRefreshPosts = ^{
        [weakSelf tl_fetchMyPostsForRefresh];
    };
    self.myView.onLoadMorePosts = ^{
        [weakSelf tl_loadMoreMyPostsIfNeeded];
    };
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self tl_applyElderModeState];
    if (![TLWSDKManager shared].sessionManager.isLoggedIn) {
        return;
    }
    [[TLWDBManager shared] printFormattedCollectedPosts];
    __weak typeof(self) weakSelf = self;
    [[TLWSDKManager shared].sessionManager fetchProfileWithCompletion:^(AGUserProfileDto *profile) {
        // TLWProfileDidUpdateNotification 会自动触发 applyProfile，无需额外处理
        (void)weakSelf;
    }];
    [self reloadMyPostsFromDatabase];
    [self syncFirstMyPostsIfNeeded];
}

- (void)dealloc {
    [self.myPostsTask cancel];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)onProfileUpdated {
    [self applyProfile];
}

- (void)applyProfile {
    AGUserProfileDto *profile = [TLWSDKManager shared].sessionManager.cachedProfile;
    if (!profile) return;
    NSString *displayName = profile.fullName ?: profile.username ?: @"未设置昵称";
    _myView.userNameLabel.text = displayName;
    _myView.postNameLabel.text = displayName;
    if (profile.avatarUrl.length > 0) {
        NSURL *avatarURL = [NSURL URLWithString:profile.avatarUrl];
        [_myView.avatarImageView sd_setImageWithURL:avatarURL];
        [_myView.postAvatarImageView sd_setImageWithURL:avatarURL];
    } else {
        _myView.avatarImageView.image = nil;
        _myView.postAvatarImageView.image = nil;
    }
    _myView.favCountLabel.text    = [NSString stringWithFormat:@"%@", profile.favoriteCount ?: @(0)];
    _myView.recordCountLabel.text = [NSString stringWithFormat:@"%@", profile.historyRecognitionCount ?: @(0)];
}

- (void)setupActions {
    [_myView.editProfileButton addTarget:self action:@selector(onEditProfile) forControlEvents:UIControlEventTouchUpInside];
    [_myView.settingButton     addTarget:self action:@selector(onSetting)     forControlEvents:UIControlEventTouchUpInside];
    [_myView.shareButton       addTarget:self action:@selector(onShare)       forControlEvents:UIControlEventTouchUpInside];

    UITapGestureRecognizer *favTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onFavorite)];
    [_myView.favStatView addGestureRecognizer:favTap];

    UITapGestureRecognizer *recordTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onRecord)];
    [_myView.recordStatView addGestureRecognizer:recordTap];
}

- (TLWMyView *)myView {
    if (!_myView) {
        _myView = [[TLWMyView alloc] initWithFrame:CGRectZero];
    }
    return _myView;
}

- (BOOL)tl_isElderModeEnabled {
    NSInteger currentUserId = [TLWSDKManager shared].sessionManager.userId;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *elderModeKey = [NSString stringWithFormat:@"TLW_elder_mode_%ld", (long)currentUserId];
    if ([defaults objectForKey:elderModeKey] != nil) {
        return [defaults boolForKey:elderModeKey];
    }
    if ([defaults objectForKey:@"TLW_elder_mode"] != nil) {
        return [defaults boolForKey:@"TLW_elder_mode"];
    }
    return NO;
}

- (void)tl_applyElderModeState {
    self.elderModeEnabled = [self tl_isElderModeEnabled];
    [self.myView configureElderModeEnabled:self.elderModeEnabled];
}

#pragma mark - Actions

- (void)onEditProfile {
    TLWEditProfileController *vc = [[TLWEditProfileController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}
- (void)onSetting {
    TLWSettingViewController *vc = [[TLWSettingViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}
- (void)onShare {
    [TLWToast show:@"开发中..."];
}
- (void)onRecord {
    TLWRecordController *vc = [[TLWRecordController alloc] init];
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)fetchMyPosts {
    [self reloadMyPostsFromDatabase];
    [self syncFirstMyPostsIfNeeded];
}

- (void)tl_fetchMyPostsForRefresh {
    if (self.isLoadingMyPosts) {
        [self.myView endRefreshingPosts];
        return;
    }
    [self fetchMyPostsRemotePage:0 force:YES];
}

- (void)reloadMyPostsFromDatabase {
    NSArray<TLWDBMyPublishedModel *> *storedPosts = [[TLWDBManager shared] fetchAllMyPublishedPosts];
    NSMutableArray<AGPostResponseDto *> *posts = [NSMutableArray arrayWithCapacity:storedPosts.count];
    for (TLWDBMyPublishedModel *storedPost in storedPosts) {
        AGPostResponseDto *dto = [self tl_postDtoFromMyPublishedModel:storedPost];
        if (dto) {
            [posts addObject:dto];
        }
    }

    self.hasLoadedMyPostsOnce = YES;
    [self.myView reloadPosts:posts];
}

- (void)syncFirstMyPostsIfNeeded {
    if (![TLWSDKManager shared].sessionManager.isLoggedIn || self.isLoadingMyPosts) {
        return;
    }

    BOOL hasNoLocalData = !self.hasLoadedMyPostsOnce;
    BOOL syncExpired = !self.lastMyPostsSyncDate || [[NSDate date] timeIntervalSinceDate:self.lastMyPostsSyncDate] > kMyPublishedSyncInterval;
    if (hasNoLocalData || syncExpired) {
        [self fetchMyPostsRemotePage:0 force:NO];
    }
}

- (void)tl_loadMoreMyPostsIfNeeded {
    if (!self.hasMoreMyPosts || self.isLoadingMyPosts) {
        return;
    }
    [self fetchMyPostsRemotePage:self.currentMyPostsPage + 1 force:YES];
}

- (void)fetchMyPostsRemotePage:(NSInteger)page force:(BOOL)force {
    if (self.isLoadingMyPosts) return;
    if (![TLWSDKManager shared].sessionManager.isLoggedIn) {
        [self finishMyPostsLoading];
        return;
    }
    if (!force && page == 0 && self.lastMyPostsSyncDate && [[NSDate date] timeIntervalSinceDate:self.lastMyPostsSyncDate] <= kMyPublishedSyncInterval && self.hasLoadedMyPostsOnce) {
        return;
    }

    self.isLoadingMyPosts = YES;
    if (page == 0) {
        self.hasMoreMyPosts = YES;
    }
    if (!self.hasLoadedMyPostsOnce) {
        [self.myView showPostsLoading];
    }

    __weak typeof(self) weakSelf = self;
    self.myPostsTask = [[TLWSDKManager shared] getMyPostsWithPage:@(page) size:@(kMyPublishedPageSize) completionHandler:^(AGResultPageResultPostResponseDto *output, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        dispatch_async(dispatch_get_main_queue(), ^{
            strongSelf.myPostsTask = nil;
            [strongSelf finishMyPostsLoading];

            if (error || !output) {
                if (!strongSelf.hasLoadedMyPostsOnce) {
                    [strongSelf.myView showPostsStatusText:@"帖子加载失败，请稍后重试"];
                }
                return;
            }
            if ([[TLWSDKManager shared].sessionManager shouldAttemptTokenRefreshForCode:output.code]) {
                [[TLWSDKManager shared].sessionManager handleUnauthorizedWithRetry:^{
                    [strongSelf fetchMyPostsRemotePage:page force:YES];
                }];
                return;
            }
            if (output.code.integerValue != 200 || !output.data) {
                if (!strongSelf.hasLoadedMyPostsOnce) {
                    [strongSelf.myView showPostsStatusText:@"帖子加载失败，请稍后重试"];
                }
                return;
            }

            NSArray<AGPostResponseDto *> *posts = output.data.list ?: @[];
            [[TLWDBManager shared] upsertMyPublishedPostsFromDtos:posts];

            if (page == 0) {
                [strongSelf.remoteSyncedMyPostIds removeAllObjects];
            }
            [strongSelf addRemoteSyncedMyPostIdsFromDtos:posts];

            strongSelf.currentMyPostsPage = page;
            strongSelf.hasMoreMyPosts = output.data.hasNext.boolValue;
            strongSelf.lastMyPostsSyncDate = [NSDate date];

            if (!strongSelf.hasMoreMyPosts) {
                [strongSelf deleteLocalMyPostsMissingFromRemoteIds:strongSelf.remoteSyncedMyPostIds];
            }
            [strongSelf reloadMyPostsFromDatabase];
        });
    }];
}

- (void)finishMyPostsLoading {
    self.isLoadingMyPosts = NO;
    [self.myView endRefreshingPosts];
}

- (nullable AGPostResponseDto *)tl_postDtoFromMyPublishedModel:(TLWDBMyPublishedModel *)model {
    if (!model.postId) return nil;

    AGPostResponseDto *dto = [[AGPostResponseDto alloc] init];
    dto._id = model.postId;
    dto.title = model.title ?: @"";
    dto.content = model.content ?: @"";
    dto.images = model.images ?: @[];
    dto.tags = model.tags ?: @[];
    dto.authorName = model.authorName ?: @"";
    dto.authorAvatar = model.authorAvatar ?: @"";
    dto.likeCount = model.likeCount ?: @0;
    dto.favoriteCount = model.favoriteCount ?: @0;
    dto.isLiked = @(model.isLiked);
    dto.isFavorited = @(model.isFavorited);
    if (model.publishedAt > 0) {
        dto.createdAt = [NSDate dateWithTimeIntervalSince1970:model.publishedAt / 1000.0];
    }
    return dto;
}

- (void)addRemoteSyncedMyPostIdsFromDtos:(NSArray<AGPostResponseDto *> *)dtos {
    for (AGPostResponseDto *dto in dtos) {
        if (dto._id) {
            [self.remoteSyncedMyPostIds addObject:dto._id];
        }
    }
}

- (void)deleteLocalMyPostsMissingFromRemoteIds:(NSSet<NSNumber *> *)remoteIds {
    NSArray<TLWDBMyPublishedModel *> *localPosts = [[TLWDBManager shared] fetchAllMyPublishedPosts];
    for (TLWDBMyPublishedModel *model in localPosts) {
        if (model.postId && ![remoteIds containsObject:model.postId]) {
            [[TLWDBManager shared] deleteMyPublishedPostByPostId:model.postId];
        }
    }
}

- (void)onFavorite {
    TLWMyFavoriteController *vc = [[TLWMyFavoriteController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)onAvatarUpdated:(NSNotification *)noti {
    UIImage *avatar = noti.userInfo[@"avatar"];
    if (avatar) {
        _myView.avatarImageView.image = avatar;
        _myView.postAvatarImageView.image = avatar;
    }
}



@end
