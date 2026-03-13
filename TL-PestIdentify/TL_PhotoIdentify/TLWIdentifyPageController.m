//
//  TLWIdentifyPageController.m
//  TL-PestIdentify
//
//  Created by xiaoli pop on 2026/3/11.
//

#import "TLWIdentifyPageController.h"
#import "TLWIdentifyPageView.h"
#import "TLWRecordController.h"
#import <AVFoundation/AVFoundation.h>

@interface TLWIdentifyPageController ()<UIImagePickerControllerDelegate, UINavigationControllerDelegate, AVCapturePhotoCaptureDelegate>
@property (nonatomic, strong) TLWIdentifyPageView *myView;
@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, strong) AVCapturePhotoOutput *photoOutput;
@property (nonatomic, strong) UIImageView *capturedImageView;
@property (nonatomic, strong) UIActivityIndicatorView* indicator;
@end

@implementation TLWIdentifyPageController

- (void)viewDidLoad {
    [super viewDidLoad];
  [self.view addSubview:self.myView];
  [self tl_setupCamera];

  self.capturedImageView = [[UIImageView alloc] initWithFrame:self.myView.bounds];
  self.capturedImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  self.capturedImageView.contentMode = UIViewContentModeScaleAspectFill;
  self.capturedImageView.clipsToBounds = YES;
  self.capturedImageView.hidden = YES;
  [self.myView addSubview:self.capturedImageView];
  [self.myView sendSubviewToBack:self.capturedImageView];
  
  [self.myView.backButton addTarget:self action:@selector(tl_dismissCurrentView:) forControlEvents:UIControlEventTouchUpInside];
  [self.myView.flashButton addTarget:self action:@selector(tl_openFlash:) forControlEvents:UIControlEventTouchUpInside];
  [self.myView.photosButton addTarget:self action:@selector(tl_openPhotoAlbum) forControlEvents:UIControlEventTouchUpInside];
  [self.myView.recordButton addTarget:self action:@selector(tl_openRecord) forControlEvents:UIControlEventTouchUpInside];
  [self.myView.captureButton addTarget:self action:@selector(tl_capturePhoto) forControlEvents:UIControlEventTouchUpInside];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [self tl_setupCamera];//页面出现时启动相机
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  if (self.isMovingFromParentViewController && self.session.isRunning) {
    [self.session stopRunning];
  }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info {
  UIImage* image = info[UIImagePickerControllerEditedImage];
  if (!image) {
    image = info[UIImagePickerControllerOriginalImage];
  }
  __weak typeof(self) weakSelf = self;
  [picker dismissViewControllerAnimated:YES completion:^{
    if (!image) {
      return;
    }
    weakSelf.capturedImageView.image = image;
    weakSelf.capturedImageView.hidden = NO;
    weakSelf.previewLayer.hidden = YES;
    [self tl_identifyFromAI];
  }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
  [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)tl_openPhotoAlbum {
  UIImagePickerController* picker = [[UIImagePickerController alloc] init];
  picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
  picker.allowsEditing = YES;
  picker.delegate = self;
  picker.modalPresentationStyle = UIModalPresentationFullScreen;
  [self presentViewController:picker animated:YES completion:nil];
}

- (void)tl_openFlash: (UIButton* )button {
  button.selected = !button.selected;
  if (button.selected) {
    [self openFlashlight];
  } else {
    [self closeFlashlight];
  }
}

- (void)closeFlashlight {
  AVCaptureDevice* device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
  if ([device hasTorch] && [device isTorchAvailable]) {
    NSError* error = nil;
    [device lockForConfiguration:&error];
    if (!error) {
      device.torchMode = AVCaptureTorchModeOff;
    }
    [device unlockForConfiguration];
  }
}

- (void)openFlashlight {
  AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
  // 判断设备是否支持闪光灯
  if ([device hasTorch] && [device isTorchAvailable]) {
    NSError *error = nil;
    // 锁定设备
    [device lockForConfiguration:&error];
    if (!error) {
      device.torchMode = AVCaptureTorchModeOn;
    }
    // 解锁
    [device unlockForConfiguration];
  }
}

- (void)tl_dismissCurrentView:(UIButton* )button {
  [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)tl_openRecord {
  TLWRecordController *vc = [[TLWRecordController alloc] init];
  vc.hidesBottomBarWhenPushed = YES;
  [self.navigationController pushViewController:vc animated:YES];
}

- (void)tl_setupCamera {
  AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];//进入相机权限检查
  if (status == AVAuthorizationStatusDenied || status == AVAuthorizationStatusRestricted) {//拒绝使用相机
      NSLog(@"相机权限被拒绝");
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:@"相机权限被拒绝" preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"好" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
      return;
  } else if (status == AVAuthorizationStatusNotDetermined) {//用户未授权
    __weak typeof(self) weakSelf = self;
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {//iOS请求相机的核心API，系统支持的设备，回调参数表示用户是否同意权限
      if (granted) {
        dispatch_async(dispatch_get_main_queue(), ^{
          [weakSelf tl_setupCamera];
        });
      } else {
        dispatch_async(dispatch_get_main_queue(), ^{
          UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:@"用户未授权相机权限" preferredStyle:UIAlertControllerStyleAlert];
          [alert addAction:[UIAlertAction actionWithTitle:@"好" style:UIAlertActionStyleDefault handler:nil]];
          [weakSelf presentViewController:alert animated:YES completion:nil];
        });
      }
    }];
    return;
  }

  if (self.session) {
    if (!self.session.isRunning) {
      dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self.session startRunning];
      });
    }
    return;
  }

  self.session = [[AVCaptureSession alloc] init];//创建相机会话
  self.session.sessionPreset = AVCaptureSessionPresetHigh;//AVCaptureSession管理整个相机的数据流
  AVCaptureDevice* device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];//创建相机的输入设备
  if (!device) {
    NSLog(@"没有找到相机设备");
    return;
  }
  NSError* error = nil;
  AVCaptureDeviceInput* input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];//创建输入
  if (error) {
    NSLog(@"相机输入创建失：%@", error);
    return;
  }
  if ([self.session canAddInput:input]) {//加入会话
    [self.session addInput:input];
  }
//流程：摄像头 -> AVCaptureDevice -> AVCaptureDeviceInput -> AVCaptureSession
  self.photoOutput = [[AVCapturePhotoOutput alloc] init];//创建照片输出
  if ([self.session canAddOutput:self.photoOutput]) {
    [self.session addOutput:self.photoOutput];
  }

  self.previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.session];//创建相机预览层
  self.previewLayer.frame = self.view.bounds;
  self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
  [self.myView.layer insertSublayer:self.previewLayer atIndex:0];

  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    [self.session startRunning];
  });
}

//用户点击拍照之行的任务
- (void)tl_capturePhoto {
  if (!self.photoOutput) {
    NSLog(@"相机没有输出");
    return;
  }
  // 再次拍照时，先恢复实时预览
  self.capturedImageView.hidden = YES;
  self.previewLayer.hidden = NO;
  AVCapturePhotoSettings *settings = [AVCapturePhotoSettings photoSettings];//创建拍照设置，拍照参数配置对象
  if (self.photoOutput.supportedFlashModes.count > 0) {//说明设备支持闪光灯模式
    settings.flashMode = self.myView.flashButton.selected ? AVCaptureFlashModeOn : AVCaptureFlashModeOff;
  }
  [self.photoOutput capturePhotoWithSettings:settings delegate:self];
}

- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishProcessingPhoto:(AVCapturePhoto *)photo error:(NSError *)error {
  if (error) {
    NSLog(@"拍照失败：%@", error);
    return;
  }
  NSData *imageData = [photo fileDataRepresentation];
  UIImage *image = [UIImage imageWithData:imageData];
  if (!image) {
    return;
  }
  dispatch_async(dispatch_get_main_queue(), ^{
    self.capturedImageView.image = image;
    self.capturedImageView.hidden = NO;
    self.previewLayer.hidden = YES;
  });
  // TODO: 在这里把 image 传给识别逻辑或结果页
  [self tl_identifyFromAI];
}

- (void)tl_identifyFromAI {
  [self tl_showLoadingIndicator];
  //TODO:调用接口方法，回调跳转，并暂停loading动画
}


- (void)tl_showLoadingIndicator {
  NSLog(@"开始识别");
  dispatch_async(dispatch_get_main_queue(), ^{
    if (!self.indicator) {
      self.indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
      self.indicator.hidesWhenStopped = YES;
      self.indicator.center = self.myView.center;
      [self.myView addSubview:self.indicator];
    }
    [self.myView bringSubviewToFront:self.indicator];
    [self.indicator startAnimating];
  });

}

- (TLWIdentifyPageView *)myView {
  if (!_myView) {
    _myView = [[TLWIdentifyPageView alloc] initWithFrame:[UIScreen mainScreen].bounds];
  }
  return _myView;
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
