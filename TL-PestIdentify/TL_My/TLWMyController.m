//
//  TLWMyController.m
//  TL-PestIdentify
//

#import "TLWMyController.h"
#import "TLWMyView.h"
#import "TLWEditProfileController.h"
#import "TLWSettingViewController.h"
#import "TLWSDKManager.h"
#import <Masonry/Masonry.h>
#import <SDWebImage/SDWebImage.h>

extern NSString * const TLWAvatarDidUpdateNotification;

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
                                             selector:@selector(onAvatarUpdated:)
                                                 name:TLWAvatarDidUpdateNotification
                                               object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self fetchUserProfile];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)fetchUserProfile {
    [[TLWSDKManager shared].api getCurrentUserProfileWithCompletionHandler:^(AGResultUserProfileDto *output, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error || output.code.integerValue != 200) {
                NSLog(@"获取用户资料失败: %@", error.localizedDescription ?: output.message);
                return;
            }
            AGUserProfileDto *profile = output.data;
            NSString *displayName = profile.fullName ?: profile.username ?: @"未设置昵称";
            self->_myView.userNameLabel.text = displayName;
            self->_myView.postNameLabel.text = displayName;
            if (profile.avatarUrl.length > 0) {
                NSURL *avatarURL = [NSURL URLWithString:profile.avatarUrl];
                [self->_myView.avatarImageView sd_setImageWithURL:avatarURL];
                [self->_myView.postAvatarImageView sd_setImageWithURL:avatarURL];
            }
            // 收藏数、记录数后端暂无接口，先保留默认值
            self->_myView.favCountLabel.text    = @"0";
            self->_myView.recordCountLabel.text = @"0";
        });
    }];
}

- (void)setupActions {
    [_myView.editProfileButton addTarget:self action:@selector(onEditProfile) forControlEvents:UIControlEventTouchUpInside];
    [_myView.settingButton     addTarget:self action:@selector(onSetting)     forControlEvents:UIControlEventTouchUpInside];
    [_myView.shareButton       addTarget:self action:@selector(onShare)       forControlEvents:UIControlEventTouchUpInside];
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

- (void)onAvatarUpdated:(NSNotification *)noti {
    UIImage *avatar = noti.userInfo[@"avatar"];
    if (avatar) {
        _myView.avatarImageView.image = avatar;
        _myView.postAvatarImageView.image = avatar;
    }
}

@end
