//
//  TLWEditProfileController.m
//  TL-PestIdentify
//

#import "TLWEditProfileController.h"
#import "TLWEditProfileView.h"
#import "TLWEditNicknameController.h"
#import "TLWAvatarCropController.h"
#import "TLWChangePhoneController.h"
#import "TLWChangePasswordController.h"
#import "TLWImagePickerManager.h"
#import "TLWSDKManager.h"
#import "TLWToast.h"
#import <Masonry/Masonry.h>
#import <SDWebImage/SDWebImage.h>

NSString * const TLWAvatarDidUpdateNotification = @"TLWAvatarDidUpdateNotification";
extern NSString * const TLWProfileDidUpdateNotification;

@interface TLWEditProfileController () <TLWEditNicknameDelegate, TLWAvatarCropDelegate, TLWImagePickerDelegate>
@property (nonatomic, strong) TLWEditProfileView *myView;
@property (nonatomic, copy)   NSString           *nickname;
@property (nonatomic, assign) BOOL isUploadingAvatar;
@property (nonatomic, strong) NSURLSessionTask   *avatarUploadTask;
@property (nonatomic, strong) NSURLSessionTask   *avatarProfileUpdateTask;
@end

@implementation TLWEditProfileController

- (NSString *)navTitle { return @"编辑资料"; }

- (void)viewDidLoad {
    self.hidesBottomBarWhenPushed = YES;
    [super viewDidLoad];
    [self.view addSubview:self.myView];
    [self.myView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    [self.view bringSubviewToFront:self.navBar];
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
    AGUserProfileDto *profile = [TLWSDKManager shared].sessionManager.cachedProfile;
    if (profile.avatarUrl.length > 0) {
        [_myView.avatarImageView sd_setImageWithURL:[NSURL URLWithString:profile.avatarUrl]];
    }
}

- (void)onAvatarUpdated:(NSNotification *)noti {
    UIImage *avatar = noti.userInfo[@"avatar"];
    if (avatar) _myView.avatarImageView.image = avatar;
}

- (void)dealloc {
    [self.avatarUploadTask cancel];
    [self.avatarProfileUpdateTask cancel];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)onProfileUpdated {
    [self applyProfile];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self applyProfile];
}

#pragma mark - Setup

- (void)applyProfile {
    AGUserProfileDto *profile = [TLWSDKManager shared].sessionManager.cachedProfile;
    if (!profile) return;
    _nickname = profile.fullName ?: profile.username ?: @"";
    _myView.nicknameValueLabel.text = _nickname.length > 0 ? _nickname : @"未设置";
    _myView.phoneValueLabel.text    = profile.phone ?: @"未绑定";
    _myView.cropValueLabel.text     = profile.followedCrops.count > 0 ? [profile.followedCrops componentsJoinedByString:@"、"] : @"未设置";
}

- (void)setupActions {
    [_myView.avatarRowButton   addTarget:self action:@selector(onAvatarTap)    forControlEvents:UIControlEventTouchUpInside];
    [_myView.nicknameRowButton addTarget:self action:@selector(onNicknameTap)  forControlEvents:UIControlEventTouchUpInside];
    [_myView.phoneRowButton    addTarget:self action:@selector(onPhoneTap)     forControlEvents:UIControlEventTouchUpInside];
    [_myView.passwordRowButton addTarget:self action:@selector(onPasswordTap)  forControlEvents:UIControlEventTouchUpInside];
}

- (TLWEditProfileView *)myView {
    if (!_myView) _myView = [[TLWEditProfileView alloc] initWithFrame:CGRectZero];
    return _myView;
}

#pragma mark - Actions

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
    if (self.isUploadingAvatar) return;
    self.isUploadingAvatar = YES;
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
    [self tl_uploadAvatarFile:fileURL didRetryAuth:NO];
}

- (void)onNicknameTap {
    TLWEditNicknameController *vc = [[TLWEditNicknameController alloc] initWithCurrentNickname:_nickname];
    vc.delegate = self;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)onPhoneTap {
    TLWChangePhoneController *vc = [[TLWChangePhoneController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)onPasswordTap {
    NSString *pwd = [TLWSDKManager shared].sessionManager.generatedPassword;
    TLWChangePasswordController *vc = [[TLWChangePasswordController alloc] initWithCurrentPassword:pwd];
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - TLWEditNicknameDelegate

- (void)editNicknameController:(TLWEditNicknameController *)vc didSaveNickname:(NSString *)nickname {
    _nickname = nickname;
    _myView.nicknameValueLabel.text = nickname;
    [TLWToast show:@"昵称修改成功"];
}

- (void)tl_uploadAvatarFile:(NSURL *)fileURL didRetryAuth:(BOOL)didRetryAuth {
    __weak typeof(self) weakSelf = self;
    self.avatarUploadTask = [[TLWSDKManager shared].api uploadFileWithFile:fileURL prefix:@"avatars/" completionHandler:^(AGResultString *output, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) return;
            strongSelf.avatarUploadTask = nil;

            if (error || output.code.integerValue != 200 || output.data.length == 0) {
                if (!error && !didRetryAuth && [[TLWSDKManager shared].sessionManager shouldAttemptTokenRefreshForCode:output.code]) {
                    [[TLWSDKManager shared].sessionManager handleUnauthorizedWithRetry:^{
                        [strongSelf tl_uploadAvatarFile:fileURL didRetryAuth:YES];
                    }];
                    return;
                }
                NSLog(@"头像上传失败: %@", error.localizedDescription ?: output.message);
                [strongSelf tl_finishAvatarUploadWithSuccess:NO avatarURL:nil];
                return;
            }

            [strongSelf tl_updateAvatarProfileURL:output.data didRetryAuth:NO];
        });
    }];
}

- (void)tl_updateAvatarProfileURL:(NSString *)avatarURL didRetryAuth:(BOOL)didRetryAuth {
    AGProfileUpdateRequest *req = [[AGProfileUpdateRequest alloc] init];
    req.avatarUrl = avatarURL;

    __weak typeof(self) weakSelf = self;
    self.avatarProfileUpdateTask = [[TLWSDKManager shared].api updateProfileWithProfileUpdateRequest:req completionHandler:^(AGResultUserProfileDto *res, NSError *err) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) return;
            strongSelf.avatarProfileUpdateTask = nil;

            if (err || res.code.integerValue != 200) {
                if (!err && !didRetryAuth && [[TLWSDKManager shared].sessionManager shouldAttemptTokenRefreshForCode:res.code]) {
                    [[TLWSDKManager shared].sessionManager handleUnauthorizedWithRetry:^{
                        [strongSelf tl_updateAvatarProfileURL:avatarURL didRetryAuth:YES];
                    }];
                    return;
                }
                [strongSelf tl_finishAvatarUploadWithSuccess:NO avatarURL:nil];
                return;
            }

            [strongSelf tl_finishAvatarUploadWithSuccess:YES avatarURL:avatarURL];
        });
    }];
}

- (void)tl_finishAvatarUploadWithSuccess:(BOOL)success avatarURL:(NSString *)avatarURL {
    self.isUploadingAvatar = NO;
    if (!success) {
        [TLWToast show:@"头像同步失败，请重试"];
        return;
    }

    if ([TLWSDKManager shared].sessionManager.cachedProfile && avatarURL.length > 0) {
        [TLWSDKManager shared].sessionManager.cachedProfile.avatarUrl = avatarURL;
    }
    [TLWToast show:@"头像修改成功"];
}

@end
