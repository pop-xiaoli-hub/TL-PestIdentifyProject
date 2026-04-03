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
    [self applyProfile];
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

    [[TLWSDKManager shared].api uploadFileWithFile:fileURL prefix:@"avatars/" completionHandler:^(AGResultString *output, NSError *error) {
        if (error || output.code.integerValue != 200) {
            if (!error && output.code.integerValue == 401) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[TLWSDKManager shared] handleUnauthorizedWithRetry:^{
                        [[TLWSDKManager shared].api uploadFileWithFile:fileURL prefix:@"avatars/" completionHandler:nil];
                    }];
                });
                return;
            }
            NSLog(@"头像上传失败: %@", error.localizedDescription ?: output.message);
            dispatch_async(dispatch_get_main_queue(), ^{ self.isUploadingAvatar = NO; [TLWToast show:@"头像同步失败，请重试"]; });
            return;
        }
        // 上传成功，直接改缓存 + 发通知
        AGProfileUpdateRequest *req = [[AGProfileUpdateRequest alloc] init];
        req.avatarUrl = output.data;
        [[TLWSDKManager shared].api updateProfileWithProfileUpdateRequest:req completionHandler:^(AGResultUserProfileDto *res, NSError *err) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (err || res.code.integerValue != 200) {
                    if (!err && res.code.integerValue == 401) {
                        [[TLWSDKManager shared] handleUnauthorizedWithRetry:^{
                            [[TLWSDKManager shared].api updateProfileWithProfileUpdateRequest:req completionHandler:nil];
                        }];
                        return;
                    }
                    self.isUploadingAvatar = NO;
                    [TLWToast show:@"头像同步失败，请重试"];
                } else {
                    self.isUploadingAvatar = NO;
                    // 静默更新缓存，不发通知，避免闪烁
                    [TLWSDKManager shared].cachedProfile.avatarUrl = output.data;
                    [TLWToast show:@"头像修改成功"];
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

- (void)onPhoneTap {
    TLWChangePhoneController *vc = [[TLWChangePhoneController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)onPasswordTap {
    NSString *pwd = [TLWSDKManager shared].generatedPassword;
    TLWChangePasswordController *vc = [[TLWChangePasswordController alloc] initWithCurrentPassword:pwd];
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - TLWEditNicknameDelegate

- (void)editNicknameController:(TLWEditNicknameController *)vc didSaveNickname:(NSString *)nickname {
    _nickname = nickname;
    _myView.nicknameValueLabel.text = nickname;
    [TLWToast show:@"昵称修改成功"];
}

@end
