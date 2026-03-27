//
//  TLWEditProfileController.m
//  TL-PestIdentify
//

#import "TLWEditProfileController.h"
#import "TLWEditProfileView.h"
#import "TLWEditNicknameController.h"
#import "TLWAvatarCropController.h"
#import "TLWImagePickerManager.h"
#import "TLWSDKManager.h"
#import <Masonry/Masonry.h>
#import <SDWebImage/SDWebImage.h>

NSString * const TLWAvatarDidUpdateNotification = @"TLWAvatarDidUpdateNotification";
extern NSString * const TLWProfileDidUpdateNotification;

@interface TLWEditProfileController () <TLWEditNicknameDelegate, TLWAvatarCropDelegate, TLWImagePickerDelegate>
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
    [self setupActions];
    [self loadAvatar];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onProfileUpdated)
                                                 name:TLWProfileDidUpdateNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onAvatarUpdated:)
                                                 name:TLWAvatarDidUpdateNotification
                                               object:nil];
}

- (void)loadAvatar {
    AGUserProfileDto *profile = [TLWSDKManager shared].cachedProfile;
    if (profile.avatarUrl.length > 0) {
        [_myView.avatarImageView sd_setImageWithURL:[NSURL URLWithString:profile.avatarUrl]];
    }
}

- (void)onAvatarUpdated:(NSNotification *)noti {
    UIImage *avatar = noti.userInfo[@"avatar"];
    if (avatar) _myView.avatarImageView.image = avatar;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)onProfileUpdated {
    [self applyProfile];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    self.navigationController.interactivePopGestureRecognizer.enabled  = YES;
    self.navigationController.interactivePopGestureRecognizer.delegate = nil;
    [self applyProfile];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}

#pragma mark - Setup

- (void)applyProfile {
    AGUserProfileDto *profile = [TLWSDKManager shared].cachedProfile;
    if (!profile) return;
    _nickname = profile.fullName ?: profile.username ?: @"";
    _myView.nicknameValueLabel.text = _nickname.length > 0 ? _nickname : @"未设置";
    _myView.phoneValueLabel.text    = profile.phone ?: @"未绑定";
    _myView.cropValueLabel.text     = profile.followedCrops.count > 0 ? [profile.followedCrops componentsJoinedByString:@"、"] : @"未设置";
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
    TLWImagePickerManager *picker = [[TLWImagePickerManager alloc] init];
    picker.delegate = self;
    [picker openAlbumFrom:self];
}

#pragma mark - TLWImagePickerDelegate

- (void)imagePicker:(TLWImagePickerManager *)picker didSelectImage:(UIImage *)image {
    TLWAvatarCropController *cropVC = [[TLWAvatarCropController alloc] initWithImage:image];
    cropVC.delegate = self;
    [self.navigationController pushViewController:cropVC animated:YES];
}

#pragma mark - TLWAvatarCropDelegate

- (void)avatarCropController:(TLWAvatarCropController *)vc didConfirmImage:(UIImage *)image {
    // 乐观更新：立刻通知所有页面用本地图片刷新头像
    [[NSNotificationCenter defaultCenter] postNotificationName:TLWAvatarDidUpdateNotification
                                                        object:nil
                                                      userInfo:@{@"avatar": image}];
    [self.navigationController popToViewController:self animated:YES];

    // 后台静默上传，失败才提示
    NSData *imageData = UIImageJPEGRepresentation(image, 0.8);
    NSString *tmpPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"avatar_upload.jpg"];
    [imageData writeToFile:tmpPath atomically:YES];
    NSURL *fileURL = [NSURL fileURLWithPath:tmpPath];

    [[TLWSDKManager shared].api uploadFileWithFile:fileURL prefix:@"avatars/" completionHandler:^(AGResultString *output, NSError *error) {
        if (error || output.code.integerValue != 200) {
            NSLog(@"头像上传失败: %@", error.localizedDescription ?: output.message);
            dispatch_async(dispatch_get_main_queue(), ^{ [self showToast:@"头像同步失败，请重试"]; });
            return;
        }
        // 上传成功，直接改缓存 + 发通知
        AGProfileUpdateRequest *req = [[AGProfileUpdateRequest alloc] init];
        req.avatarUrl = output.data;
        [[TLWSDKManager shared].api updateProfileWithProfileUpdateRequest:req completionHandler:^(AGResultUserProfileDto *res, NSError *err) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (err || res.code.integerValue != 200) {
                    [self showToast:@"头像同步失败，请重试"];
                } else {
                    // 静默更新缓存，不发通知，避免闪烁
                    [TLWSDKManager shared].cachedProfile.avatarUrl = output.data;
                    [self showToast:@"修改成功"];
                }
            });
        }];
    }];
}

- (void)onNicknameTap {
    TLWEditNicknameController *vc = [[TLWEditNicknameController alloc] initWithCurrentNickname:_nickname];
    vc.delegate = self;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)onBackgroundTap {
    // TODO: push 背景图选择页（待建），用户选图后回调
    //   成功回调：POST /user/background，参数为所选图片；更新 myView.backgroundImageView
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
