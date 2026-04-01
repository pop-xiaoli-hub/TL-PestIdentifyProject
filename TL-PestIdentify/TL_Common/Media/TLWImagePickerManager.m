//
//  TLWImagePickerManager.m
//  TL-PestIdentify
//
//  Created by 吴桐 on 2026/3/26.
//

#import "TLWImagePickerManager.h"
#import "TLWPhotoPickerController.h"
#import <Photos/Photos.h>
#import <PhotosUI/PhotosUI.h>
#import <objc/runtime.h>

static const void *kImagePickerManagerKey = &kImagePickerManagerKey;

@interface TLWImagePickerManager () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic, weak) UIViewController *hostVC;

@end

@implementation TLWImagePickerManager

- (instancetype)init {
    self = [super init];
    if (self) _maxCount = 1;
    return self;
}

#pragma mark - Public

- (void)openAlbumFrom:(UIViewController *)vc {
    self.hostVC = vc;
    [self retainSelf];
    [self requestPhotoAccessWithCompletion:^(BOOL granted) {
        if (!granted) {
            [self showAlert:@"请在设置中开启相册权限" inVC:vc];
            [self releaseSelf];
            return;
        }
        if (self.maxCount <= 1) {
            [self openSingleAlbumFrom:vc];
        } else {
            [self openMultiAlbumFrom:vc];
        }
    }];
}

- (void)openCameraFrom:(UIViewController *)vc {
    self.hostVC = vc;
    [self retainSelf];
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        [self showAlert:@"当前设备不支持拍照" inVC:vc];
        [self releaseSelf];
        return;
    }
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (status == AVAuthorizationStatusDenied || status == AVAuthorizationStatusRestricted) {
        [self showAlert:@"请在设置中开启相机权限" inVC:vc];
        [self releaseSelf];
        return;
    }
    if (status == AVAuthorizationStatusNotDetermined) {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (granted) {
                    [self presentCameraIn:vc];
                } else {
                    [self showAlert:@"用户未授权相机权限" inVC:vc];
                    [self releaseSelf];
                }
            });
        }];
        return;
    }
    [self presentCameraIn:vc];
}

#pragma mark - 单选相册（push 自写相册页）

- (void)openSingleAlbumFrom:(UIViewController *)vc {
    TLWPhotoPickerController *picker = [[TLWPhotoPickerController alloc] init];
    __weak typeof(self) weakSelf = self;
    picker.onSelectImage = ^(UIImage *image) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        if ([strongSelf.delegate respondsToSelector:@selector(imagePicker:didSelectImage:)]) {
            [strongSelf.delegate imagePicker:strongSelf didSelectImage:image];
        }
        [strongSelf releaseSelf];
    };
    if (vc.navigationController) {
        [vc.navigationController pushViewController:picker animated:YES];
    } else {
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:picker];
        nav.modalPresentationStyle = UIModalPresentationFullScreen;
        [vc presentViewController:nav animated:YES completion:nil];
    }
}

#pragma mark - 多选相册（自定义 PhotoPicker）

- (void)openMultiAlbumFrom:(UIViewController *)vc {
    TLWPhotoPickerController *picker = [[TLWPhotoPickerController alloc] init];
    picker.maxCount = self.maxCount;
    __weak typeof(self) weakSelf = self;
    picker.onSelectImages = ^(NSArray<UIImage *> *images) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        if ([strongSelf.delegate respondsToSelector:@selector(imagePicker:didSelectImages:)]) {
            [strongSelf.delegate imagePicker:strongSelf didSelectImages:images];
        }
        [strongSelf releaseSelf];
    };
    if (vc.navigationController) {
        [vc.navigationController pushViewController:picker animated:YES];
    } else {
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:picker];
        nav.modalPresentationStyle = UIModalPresentationFullScreen;
        [vc presentViewController:nav animated:YES completion:nil];
    }
}

#pragma mark - 相机

- (void)presentCameraIn:(UIViewController *)vc {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    picker.delegate = self;
    picker.modalPresentationStyle = UIModalPresentationFullScreen;
    [vc presentViewController:picker animated:YES completion:nil];
}

#pragma mark - PHPickerViewControllerDelegate (iOS 14+)

- (void)picker:(PHPickerViewController *)picker
    didFinishPicking:(NSArray<PHPickerResult *> *)results API_AVAILABLE(ios(14.0)) {
    [picker dismissViewControllerAnimated:YES completion:nil];

    if (results.count == 0) {
        if ([self.delegate respondsToSelector:@selector(imagePickerDidCancel:)]) {
            [self.delegate imagePickerDidCancel:self];
        }
        [self releaseSelf];
        return;
    }

    // 单选快速路径
    if (self.maxCount <= 1) {
        NSItemProvider *provider = results.firstObject.itemProvider;
        if ([provider canLoadObjectOfClass:[UIImage class]]) {
            [provider loadObjectOfClass:[UIImage class] completionHandler:^(id<NSItemProviderReading> obj, NSError *err) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if ([obj isKindOfClass:[UIImage class]] &&
                        [self.delegate respondsToSelector:@selector(imagePicker:didSelectImage:)]) {
                        [self.delegate imagePicker:self didSelectImage:(UIImage *)obj];
                    }
                    [self releaseSelf];
                });
            }];
        }
        return;
    }

    // 多选
    dispatch_group_t group = dispatch_group_create();
    NSMutableArray<UIImage *> *images = [NSMutableArray array];
    for (PHPickerResult *result in results) {
        NSItemProvider *provider = result.itemProvider;
        if (![provider canLoadObjectOfClass:[UIImage class]]) continue;
        dispatch_group_enter(group);
        [provider loadObjectOfClass:[UIImage class] completionHandler:^(id<NSItemProviderReading> obj, NSError *err) {
            if (!err && [obj isKindOfClass:[UIImage class]]) {
                @synchronized (images) { [images addObject:(UIImage *)obj]; }
            }
            dispatch_group_leave(group);
        }];
    }
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        if (images.count > 0 && [self.delegate respondsToSelector:@selector(imagePicker:didSelectImages:)]) {
            [self.delegate imagePicker:self didSelectImages:[images copy]];
        }
        [self releaseSelf];
    });
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker
didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info {
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    [picker dismissViewControllerAnimated:YES completion:^{
        if (image && [self.delegate respondsToSelector:@selector(imagePicker:didSelectImage:)]) {
            [self.delegate imagePicker:self didSelectImage:image];
        }
        [self releaseSelf];
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:^{
        if ([self.delegate respondsToSelector:@selector(imagePickerDidCancel:)]) {
            [self.delegate imagePickerDidCancel:self];
        }
        [self releaseSelf];
    }];
}

#pragma mark - 权限

- (void)requestPhotoAccessWithCompletion:(void (^)(BOOL granted))completion {
    PHAuthorizationStatus status;
    if (@available(iOS 14, *)) {
        status = [PHPhotoLibrary authorizationStatusForAccessLevel:PHAccessLevelReadWrite];
    } else {
        status = [PHPhotoLibrary authorizationStatus];
    }
    if (status == PHAuthorizationStatusAuthorized || status == PHAuthorizationStatusLimited) {
        completion(YES);
        return;
    }
    if (status == PHAuthorizationStatusNotDetermined) {
        void (^handler)(PHAuthorizationStatus) = ^(PHAuthorizationStatus s) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(s == PHAuthorizationStatusAuthorized || s == PHAuthorizationStatusLimited);
            });
        };
        if (@available(iOS 14, *)) {
            [PHPhotoLibrary requestAuthorizationForAccessLevel:PHAccessLevelReadWrite handler:handler];
        } else {
            [PHPhotoLibrary requestAuthorization:handler];
        }
        return;
    }
    completion(NO);
}

#pragma mark - 生命周期（防止 Manager 被提前释放）

- (void)retainSelf {
    objc_setAssociatedObject(self.hostVC, kImagePickerManagerKey, self, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)releaseSelf {
    objc_setAssociatedObject(self.hostVC, kImagePickerManagerKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - Alert

- (void)showAlert:(NSString *)msg inVC:(UIViewController *)vc {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:msg preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [vc presentViewController:alert animated:YES completion:nil];
}

@end
