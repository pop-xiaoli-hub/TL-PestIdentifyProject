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
@interface TLWIdentifyPageController ()<UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property (nonatomic, strong)TLWIdentifyPageView* myView;
@property (nonatomic, strong)AVCaptureSession* session;
@property (nonatomic, strong)AVCaptureVideoPreviewLayer* previewLayer;

@end

@implementation TLWIdentifyPageController

- (void)viewDidLoad {
    [super viewDidLoad];
  [self.view addSubview:self.myView];
  [self tl_setupCamera];
  [self.myView.backButton addTarget:self action:@selector(tl_dismissCurrentView:) forControlEvents:UIControlEventTouchUpInside];
  [self.myView.flashButton addTarget:self action:@selector(tl_openFlash:) forControlEvents:UIControlEventTouchUpInside];
  [self.myView.photosButton addTarget:self action:@selector(tl_openPhotoAlbum) forControlEvents:UIControlEventTouchUpInside];
  [self.myView.recordButton addTarget:self action:@selector(tl_openRecord) forControlEvents:UIControlEventTouchUpInside];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info {
  UIImage* image = info[UIImagePickerControllerEditedImage];
  if (!image) {
    image = info[UIImagePickerControllerOriginalImage];
  }
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
  [self.navigationController pushViewController:vc animated:YES];
}

- (void)tl_setupCamera {
  AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
  if (status == AVAuthorizationStatusDenied || status == AVAuthorizationStatusRestricted) {
      NSLog(@"相机权限被拒绝");
      return;
  }
  self.session = [[AVCaptureSession alloc] init];
  self.session.sessionPreset = AVCaptureSessionPresetHigh;
  AVCaptureDevice* device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
  if (!device) {
    NSLog(@"没有找到相机设备");
    return;
  }
  NSError* error = nil;
  AVCaptureDeviceInput* input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
  if (error) {
    NSLog(@"相机输入创建失：%@", error);
    return;
  }
  if ([self.session canAddInput:input]) {
    [self.session addInput:input];
  }
  self.previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
  self.previewLayer.frame = self.view.bounds;
  self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
  [self.myView.layer addSublayer:self.previewLayer];
  [self.myView.layer insertSublayer:self.previewLayer atIndex:0];
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    [self.session startRunning];
  });
}

- (TLWIdentifyPageView *)myView {
  if (!_myView) {
    _myView = [[TLWIdentifyPageView alloc] initWithFrame:[UIScreen mainScreen].bounds];
  }
  return _myView;
}

- (void)viewWillAppear:(BOOL)animated {
  [self.navigationController setNavigationBarHidden:YES animated:NO];
}

- (void)viewDidDisappear:(BOOL)animated {
  [self.navigationController setNavigationBarHidden:NO animated:NO];
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
