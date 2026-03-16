//
//  TLWMyController.m
//  TL-PestIdentify
//

#import "TLWMyController.h"
#import "TLWMyView.h"
#import "TLWEditProfileController.h"
#import "TLWSettingViewController.h"
#import <Masonry/Masonry.h>

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
    [self setupMockData];
    [self setupActions];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onAvatarUpdated:)
                                                 name:TLWAvatarDidUpdateNotification
                                               object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setupMockData {
    _myView.userNameLabel.text   = @"用户2759";
    _myView.favCountLabel.text   = @"8";
    _myView.recordCountLabel.text = @"16";
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
    if (avatar) _myView.avatarImageView.image = avatar;
}

@end
