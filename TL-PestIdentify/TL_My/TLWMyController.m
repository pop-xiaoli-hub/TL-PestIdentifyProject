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
#import <Masonry/Masonry.h>
#import <SDWebImage/SDWebImage.h>

extern NSString * const TLWAvatarDidUpdateNotification;
extern NSString * const TLWProfileDidUpdateNotification;

@interface TLWMyController ()

@property (nonatomic, strong) TLWMyView *myView;

@end

@implementation TLWMyController

- (void)viewDidLoad {
    [super viewDidLoad];
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
    [self fetchMyPosts];

    __weak typeof(self) weakSelf = self;
    self.myView.onPostTapped = ^(NSNumber *postId) {
        TLWPostDetailController *vc = [[TLWPostDetailController alloc] init];
        vc._id = postId;
        vc.hidesBottomBarWhenPushed = YES;
        [weakSelf.navigationController pushViewController:vc animated:YES];
    };
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    __weak typeof(self) weakSelf = self;
    [[TLWSDKManager shared] fetchProfileWithCompletion:^(AGUserProfileDto *profile) {
        // TLWProfileDidUpdateNotification 会自动触发 applyProfile，无需额外处理
        (void)weakSelf;
    }];
    [self fetchMyPosts];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)onProfileUpdated {
    [self applyProfile];
}

- (void)applyProfile {
    AGUserProfileDto *profile = [TLWSDKManager shared].cachedProfile;
    if (!profile) return;
    NSString *displayName = profile.fullName ?: profile.username ?: @"未设置昵称";
    _myView.userNameLabel.text = displayName;
    _myView.postNameLabel.text = displayName;
    if (profile.avatarUrl.length > 0) {
        NSURL *avatarURL = [NSURL URLWithString:profile.avatarUrl];
        [_myView.avatarImageView sd_setImageWithURL:avatarURL];
        [_myView.postAvatarImageView sd_setImageWithURL:avatarURL];
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

#pragma mark - Actions

- (void)onEditProfile {
    TLWEditProfileController *vc = [[TLWEditProfileController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}
- (void)onSetting {
    TLWSettingViewController *vc = [[TLWSettingViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}
- (void)onShare { /* TODO: 分享 */ }
- (void)onRecord {
    TLWRecordController *vc = [[TLWRecordController alloc] init];
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)fetchMyPosts {
    __weak typeof(self) weakSelf = self;
    [[TLWSDKManager shared] getMyPostsWithPage:@(0) size:@(20) completionHandler:^(AGResultPageResultPostResponseDto *output, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        if (error || !output) return;
        if (output.code.integerValue == 401) {
            [[TLWSDKManager shared] handleUnauthorizedWithRetry:^{
                [strongSelf fetchMyPosts];
            }];
            return;
        }
        if (output.code.integerValue != 200) return;
        NSArray<AGPostResponseDto *> *posts = output.data.list ?: @[];
        dispatch_async(dispatch_get_main_queue(), ^{
            [strongSelf.myView reloadPosts:posts];
        });
    }];
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
