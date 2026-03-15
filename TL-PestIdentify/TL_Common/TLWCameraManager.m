//
//  TLWCameraManager.m
//  TL-PestIdentify
//

#import "TLWCameraManager.h"

    //  分别用于拍照回调、相册选图回调和一个其他
@interface TLWCameraManager () <AVCapturePhotoCaptureDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property (nonatomic, weak)   UIViewController *hostVC;
@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCapturePhotoOutput *photoOutput;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, assign) BOOL flashEnabled;

@end

@implementation TLWCameraManager

- (instancetype)initWithHostViewController:(UIViewController *)viewController {
    self = [super init];
    if (self) {
        _hostVC = viewController;
    }
    return self;
}

#pragma mark - Public

- (void)setupCamera {
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (status == AVAuthorizationStatusDenied || status == AVAuthorizationStatusRestricted) {
        [self showAlertWithMessage:@"相机权限被拒绝，请在设置中开启"];
        return;
    }
    if (status == AVAuthorizationStatusNotDetermined) {
        __weak typeof(self) weakSelf = self;
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (granted) {
                    [weakSelf setupCamera];
                } else {
                    [weakSelf showAlertWithMessage:@"用户未授权相机权限"];
                }
            });
        }];
        return;
    }
    // 已有 session 则直接启动
    if (self.session) {
        [self startRunning];
        return;
    }
    [self setupSession];
}

- (void)startRunning {
    if (!self.session.isRunning) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self.session startRunning];
        });
    }
}

- (void)stopRunning {
    if (self.session.isRunning) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self.session stopRunning];
        });
    }
}

- (void)capturePhoto {
    if (!self.photoOutput) {
        NSLog(@"[TLWCameraManager] 相机未初始化");
        return;
    }
    AVCapturePhotoSettings *settings = [AVCapturePhotoSettings photoSettings];
    if (self.photoOutput.supportedFlashModes.count > 0) {
        settings.flashMode = self.flashEnabled ? AVCaptureFlashModeOn : AVCaptureFlashModeOff;
    }
    [self.photoOutput capturePhotoWithSettings:settings delegate:self];
}

- (void)setFlashEnabled:(BOOL)enabled {
    _flashEnabled = enabled;
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (![device hasTorch] || ![device isTorchAvailable]) return;
    NSError *error = nil;
    [device lockForConfiguration:&error];
    if (!error) {
        device.torchMode = enabled ? AVCaptureTorchModeOn : AVCaptureTorchModeOff;
    }
    [device unlockForConfiguration];
}

- (void)openPhotoAlbum {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.allowsEditing = YES;
    picker.delegate = self;
    picker.modalPresentationStyle = UIModalPresentationFullScreen;
    [self.hostVC presentViewController:picker animated:YES completion:nil];
}

#pragma mark - Private

- (void)setupSession {
    //  获取相机设备
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (!device) {
        NSLog(@"[TLWCameraManager] 未找到相机设备");
        return;
    }

    NSError *error = nil;
    //  创建输入
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    if (error) {
        NSLog(@"[TLWCameraManager] 相机输入创建失败：%@", error);
        return;
    }
    //  创建Session，调整清晰度
    self.session = [[AVCaptureSession alloc] init];
    self.session.sessionPreset = AVCaptureSessionPresetHigh;
    if ([self.session canAddInput:input]) {
        [self.session addInput:input];
    }
    self.photoOutput = [[AVCapturePhotoOutput alloc] init];
    if ([self.session canAddOutput:self.photoOutput]) {
        [self.session addOutput:self.photoOutput];
    }
    self.previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self startRunning];
}

- (void)showAlertWithMessage:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"好" style:UIAlertActionStyleDefault handler:nil]];
    [self.hostVC presentViewController:alert animated:YES completion:nil];
}

#pragma mark - AVCapturePhotoCaptureDelegate

- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishProcessingPhoto:(AVCapturePhoto *)photo error:(NSError *)error {
    if (error) {
        NSLog(@"[TLWCameraManager] 拍照失败：%@", error);
        return;
    }
    NSData *data = [photo fileDataRepresentation];
    UIImage *image = [UIImage imageWithData:data];
    if (!image) return;

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate cameraManager:self didCapturePhoto:image];
    });
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker
didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey, id> *)info {
    UIImage *image = info[UIImagePickerControllerEditedImage] ?: info[UIImagePickerControllerOriginalImage];
    [picker dismissViewControllerAnimated:YES completion:^{
        if (image) {
            [self.delegate cameraManager:self didCapturePhoto:image];
        }
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

@end
