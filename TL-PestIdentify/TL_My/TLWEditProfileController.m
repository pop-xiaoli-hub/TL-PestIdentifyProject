//
//  TLWEditProfileController.m
//  TL-PestIdentify
//

#import "TLWEditProfileController.h"
#import "TLWEditProfileView.h"
#import "TLWEditNicknameController.h"
#import <Masonry/Masonry.h>

@interface TLWEditProfileController () <TLWEditNicknameDelegate>
@property (nonatomic, strong) TLWEditProfileView *myView;
@property (nonatomic, copy)   NSString           *nickname;
@end

@implementation TLWEditProfileController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.hidesBottomBarWhenPushed = YES;
    [self.view addSubview:self.myView];
    [self.myView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    [self setupMockData];
    [self setupActions];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    self.navigationController.interactivePopGestureRecognizer.enabled  = YES;
    self.navigationController.interactivePopGestureRecognizer.delegate = nil;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}

#pragma mark - Setup

- (void)setupMockData {
    // TODO: 替换为真实接口 GET /user/profile
    _nickname = @"王建军";
    _myView.nicknameValueLabel.text = _nickname;
    _myView.phoneValueLabel.text    = @"18888888888";
    _myView.cropValueLabel.text     = @"水稻";
    _myView.avatarImageView.image   = [UIImage imageNamed:@"avatar"];
}

- (void)setupActions {
    [_myView.backButton       addTarget:self action:@selector(onBack)            forControlEvents:UIControlEventTouchUpInside];
    [_myView.avatarRowButton  addTarget:self action:@selector(onAvatarTap)       forControlEvents:UIControlEventTouchUpInside];
    [_myView.nicknameRowButton addTarget:self action:@selector(onNicknameTap)    forControlEvents:UIControlEventTouchUpInside];
    [_myView.backgroundRowButton addTarget:self action:@selector(onBackgroundTap) forControlEvents:UIControlEventTouchUpInside];
}

- (TLWEditProfileView *)myView {
    if (!_myView) _myView = [[TLWEditProfileView alloc] initWithFrame:CGRectZero];
    return _myView;
}

#pragma mark - Actions

- (void)onBack {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)onAvatarTap {
    // TODO: 调用 POST /user/avatar 上传头像（选图 / 拍照后上传）
}

- (void)onNicknameTap {
    TLWEditNicknameController *vc = [[TLWEditNicknameController alloc] initWithCurrentNickname:_nickname];
    vc.delegate = self;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)onBackgroundTap {
    // TODO: 跳转背景图选择页，调用 POST /user/background
}

#pragma mark - TLWEditNicknameDelegate

- (void)editNicknameController:(TLWEditNicknameController *)vc didSaveNickname:(NSString *)nickname {
    _nickname = nickname;
    _myView.nicknameValueLabel.text = nickname;
    [self showToast:@"修改成功"];
}

#pragma mark - Toast

- (void)showToast:(NSString *)text {
    UILabel *toast = [UILabel new];
    toast.text            = text;
    toast.font            = [UIFont systemFontOfSize:15];
    toast.textColor       = [UIColor colorWithRed:0.20 green:0.20 blue:0.20 alpha:1];
    toast.textAlignment   = NSTextAlignmentCenter;
    toast.backgroundColor = UIColor.whiteColor;
    toast.layer.cornerRadius  = 8;
    toast.layer.masksToBounds = NO;
    toast.layer.shadowColor   = [UIColor colorWithWhite:0 alpha:0.15].CGColor;
    toast.layer.shadowOpacity = 1;
    toast.layer.shadowRadius  = 6;
    toast.layer.shadowOffset  = CGSizeMake(0, 2);
    [self.view addSubview:toast];
    [toast mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view).offset(50);
        make.centerY.equalTo(self.view).multipliedBy(0.72);
        make.width.mas_equalTo(108);
        make.height.mas_equalTo(38);
    }];

    toast.alpha = 0;
    [UIView animateWithDuration:0.25 animations:^{ toast.alpha = 1; } completion:^(BOOL f) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.25 animations:^{ toast.alpha = 0; } completion:^(BOOL done) {
                [toast removeFromSuperview];
            }];
        });
    }];
}

@end
