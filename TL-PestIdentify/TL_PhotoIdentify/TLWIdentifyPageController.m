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
#import "TLWIdentifyResultController.h"
#import "TLWSDKManager.h"
#import <AgriPestClient/AGApiClient.h>
#import <AgriPestClient/AGChatRequest.h>
#import <AgriPestClient/AGDiagnosisItem.h>
#import <AgriPestClient/AGResultChatProfileResponse.h>
#import <AgriPestClient/AGResultListDiagnosisItem.h>
#import <AgriPestClient/AGDefaultConfiguration.h>
#import "TLWPhotoPickerController.h"
#import "TLWLocalIdentifyManager.h"
#import "TLWLocationManager.h"
#import "TLWToast.h"

static CGFloat const TLWIdentifyCloudJPEGQuality = 0.78f;
static CGFloat const TLWIdentifyCloudMaxEdge = 1280.0f;
static CGFloat const TLWIdentifyMinLocalFallbackConfidence = 0.60f;
static NSInteger const TLWIdentifyDisplayResultCount = 3;
static NSTimeInterval const TLWIdentifyCloudTimeout = 240.0f;
static BOOL const TLWIdentifyEnableProfileProbe = YES;

@interface TLWIdentifyPageController ()<AVCapturePhotoCaptureDelegate>
//  主视图
@property (nonatomic, strong) TLWIdentifyPageView *myView;
//  相机会话
@property (nonatomic, strong) AVCaptureSession *session;
//  相机预览层
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
//  拍照输出对象，由他输出对象
@property (nonatomic, strong) AVCapturePhotoOutput *photoOutput;
@property (nonatomic, strong) UIImageView *capturedImageView;
@property (nonatomic, strong) UIImageView *loadingImageView;
@property (nonatomic, strong) UIImage *capturedImage; // 待识别的图片，接口调用时从此属性读取
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
  [[TLWLocationManager shared] requestLocationPermission];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [self.navigationController setNavigationBarHidden:YES animated:NO];
  [self tl_setupCamera];//页面出现时启动相机
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  if (self.isMovingFromParentViewController && self.session.isRunning) {
    [self.session stopRunning];
  }
}

- (void)prepareForRetakeCapture {
  self.capturedImage = nil;
  self.capturedImageView.image = nil;
  self.capturedImageView.hidden = YES;
  self.previewLayer.hidden = NO;
  [self tl_stopLoadingIndicator];

  if (self.session && !self.session.isRunning) {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      [self.session startRunning];
    });
  }
}

- (void)tl_openPhotoAlbum {
  TLWPhotoPickerController *pickerVC = [[TLWPhotoPickerController alloc] init];
  pickerVC.maxCount = 1;
  __weak typeof(self) weakSelf = self;
  pickerVC.onSelectImage = ^(UIImage *image) {
    __strong typeof(weakSelf) strongSelf = weakSelf;
    if (!strongSelf || !image) return;
    UIImage *preparedImage = [strongSelf tl_preparedAlbumImageForIdentify:image];
    strongSelf.capturedImage = preparedImage;
    strongSelf.capturedImageView.image = preparedImage;
    strongSelf.capturedImageView.hidden = NO;
    strongSelf.previewLayer.hidden = YES;
    [strongSelf tl_identifyFromAI];
  };
  pickerVC.hidesBottomBarWhenPushed = YES;
  [self.navigationController pushViewController:pickerVC animated:YES];
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
  if ([self.session canSetSessionPreset:AVCaptureSessionPresetPhoto]) {
    self.session.sessionPreset = AVCaptureSessionPresetPhoto;
  } else {
    self.session.sessionPreset = AVCaptureSessionPresetHigh;
  }
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
  if (@available(iOS 13.0, *)) {
    AVCapturePhotoQualityPrioritization desired = AVCapturePhotoQualityPrioritizationQuality;
    AVCapturePhotoQualityPrioritization maxSupported = self.photoOutput.maxPhotoQualityPrioritization;
    settings.photoQualityPrioritization = MIN(desired, maxSupported);
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
  UIImage *processedImage = [self tl_croppedCameraImageToPreview:image];
  dispatch_async(dispatch_get_main_queue(), ^{
    self.capturedImage = processedImage;
    self.capturedImageView.image = processedImage;
    self.capturedImageView.hidden = NO;
    self.previewLayer.hidden = YES;
    [self tl_identifyFromAI];
  });
}

- (void)tl_identifyFromAI {
  [self tl_showLoadingIndicator];
  UIImage *image = self.capturedImage;
  if (![image isKindOfClass:[UIImage class]]) {
    [self tl_stopLoadingIndicator];
    return;
  }

  __weak typeof(self) weakSelf = self;
  __block NSArray<NSDictionary *> *localResults = @[];
  __block BOOL localFinished = NO;
  __block BOOL waitingForLocalFallback = NO;

  void (^presentLocalFallbackIfNeeded)(void) = ^{
    __strong typeof(weakSelf) strongSelf = weakSelf;
    if (!strongSelf || !waitingForLocalFallback || !localFinished) {
      return;
    }
    waitingForLocalFallback = NO;
    [strongSelf tl_stopLoadingIndicator];
    [strongSelf tl_fallbackToLocalResults:localResults];
  };

  // ---- 1. 本地 CoreML 并行识别（作为云端失败的兜底） ----
  [[TLWLocalIdentifyManager shared] identifyImage:image completion:^(NSArray<TLWLocalIdentifyResult *> *results, NSError *error) {
    __strong typeof(weakSelf) strongSelf = weakSelf;
    if (!strongSelf) {
      return;
    }

    if (!error && results.count > 0) {
      NSLog(@"========== [CoreML] 本地识别结果 ==========");
      for (NSInteger i = 0; i < results.count; i++) {
        TLWLocalIdentifyResult *r = results[i];
        NSLog(@"[CoreML] Top%ld: %@ | 标签: %@ | 作物: %@ | 置信度: %.2f%%", (long)(i + 1), r.name, r.label, r.crop, r.confidence * 100);
      }
      NSLog(@"============================================");
      localResults = [strongSelf tl_buildLocalFallbackResultsFromIdentifyResults:results];
      if (localResults.count == 0) {
        NSLog(@"[CoreML] 本地结果未通过兜底阈值，跳过展示");
      }
    } else {
      NSLog(@"[CoreML] 本地识别失败: %@", error.localizedDescription);
    }

    localFinished = YES;
    presentLocalFallbackIfNeeded();
  }];

  // ---- 2. 云端 SDK 识别（主路径） ----
  NSData *imageData = [self tl_cloudImageDataForIdentify:image];
  if (imageData.length == 0) {
    waitingForLocalFallback = YES;
    presentLocalFallbackIfNeeded();
    return;
  }

  TLWSDKManager *manager = [TLWSDKManager shared];
  NSTimeInterval previousTimeout = manager.api.apiClient.timeoutInterval;
  manager.api.apiClient.timeoutInterval = TLWIdentifyCloudTimeout;

  [self tl_uploadIdentifyImageData:imageData completion:^(NSString *imageURL, NSError *uploadError) {
    dispatch_async(dispatch_get_main_queue(), ^{
      if (uploadError || imageURL.length == 0) {
        manager.api.apiClient.timeoutInterval = previousTimeout;
        NSLog(@"[云端] 图片上传失败 error=%@", uploadError.localizedDescription ?: @"<nil>");
        waitingForLocalFallback = YES;
        presentLocalFallbackIfNeeded();
        return;
      }

      AGChatRequest *request = [[AGChatRequest alloc] init];
      request.text = [self tl_identifyPrompt];
      request.imageUrl = imageURL;
      request.useSingleModel = @(YES);
      request.saveHistory = @(YES);

      NSString *currentToken = [AGDefaultConfiguration sharedConfig].accessToken;
      NSLog(@"AI识别：开始识别，uploadURL=%@ token=%@",
            imageURL,
            currentToken.length > 0 ? @"有" : @"无（未登录？）");
      NSLog(@"[云端] SDK timeoutInterval=%.0fs, saveHistory=%@, useSingleModel=%@, profileProbe=%@",
            manager.api.apiClient.timeoutInterval,
            request.saveHistory.boolValue ? @"YES" : @"NO",
            request.useSingleModel.boolValue ? @"YES" : @"NO",
            TLWIdentifyEnableProfileProbe ? @"YES" : @"NO");

      __block void (^performCloudIdentify)(BOOL);
      performCloudIdentify = ^(BOOL didRetryAuth) {
        [manager.api chatWithChatRequest:request completionHandler:^(AGResultListDiagnosisItem *chatOutput, NSError *chatError) {
      dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        manager.api.apiClient.timeoutInterval = previousTimeout;
        if (!strongSelf) {
          return;
        }

        if (!didRetryAuth
            && [manager.sessionManager handleAuthFailureForCode:chatOutput.code
                                                       message:chatOutput.message
                                                    retryBlock:^{
          manager.api.apiClient.timeoutInterval = TLWIdentifyCloudTimeout;
          performCloudIdentify(YES);
        }]) {
          return;
        }

        if (chatError || !chatOutput || chatOutput.code.integerValue != 200 || chatOutput.data.count == 0) {
          NSLog(@"========== [云端] AI识别失败 ==========");
          if (chatError) {
            NSLog(@"[云端] NSError domain=%@ code=%ld msg=%@",
                  chatError.domain, (long)chatError.code, chatError.localizedDescription);
            NSLog(@"[云端] NSError userInfo=%@", chatError.userInfo);
          } else {
            NSLog(@"[云端] NSError=nil");
          }
          if (!chatOutput) {
            NSLog(@"[云端] chatOutput=nil（响应体解析失败或无响应）");
          } else {
            NSLog(@"[云端] code=%@, message=%@", chatOutput.code, chatOutput.message);
            NSLog(@"[云端] diagnosisCount=%lu", (unsigned long)chatOutput.data.count);
          }
          NSLog(@"============================================");
          if (TLWIdentifyEnableProfileProbe) {
            [strongSelf tl_probeCloudIdentifyProfileWithRequest:request manager:manager];
          }
          waitingForLocalFallback = YES;
          presentLocalFallbackIfNeeded();
          return;
        }

        NSLog(@"========== [云端] AI识别成功 ==========");
        NSArray<NSDictionary *> *parsedResults = [strongSelf tl_normalizedIdentifyResultsForDisplay:
                                                  [strongSelf tl_resultsFromDiagnosisItems:chatOutput.data]];
        if (parsedResults.count == 0) {
          NSLog(@"[云端] 结构化结果解析失败，回退本地识别");
          if (TLWIdentifyEnableProfileProbe) {
            [strongSelf tl_probeCloudIdentifyProfileWithRequest:request manager:manager];
          }
          waitingForLocalFallback = YES;
          presentLocalFallbackIfNeeded();
          return;
        }

        for (NSInteger i = 0; i < parsedResults.count; i++) {
          AGDiagnosisItem *rawItem = i < chatOutput.data.count ? chatOutput.data[i] : nil;
          if ([rawItem isKindOfClass:[AGDiagnosisItem class]]) {
            NSLog(@"[云端] 原始 DiagnosisItem Top%ld -> diseaseName=%@, confidence=%@, controlPlan=%@",
                  (long)(i + 1),
                  rawItem.diseaseName ?: @"<nil>",
                  rawItem.confidence ?: @"<nil>",
                  rawItem.controlPlan ?: @"<nil>");
          }
          NSDictionary *r = parsedResults[i];
          NSLog(@"[云端] Top%ld: %@ | 置信度: %@ | 依据: %@", (long)(i + 1), r[@"name"], r[@"confidence"], r[@"reason"]);
        }
        NSLog(@"============================================");
        if (TLWIdentifyEnableProfileProbe) {
          [strongSelf tl_probeCloudIdentifyProfileWithRequest:request manager:manager];
        }

    if (parsedResults.count == 0) {
      waitingForLocalFallback = YES;
      presentLocalFallbackIfNeeded();
      return;
    }

    [strongSelf tl_stopLoadingIndicator];
    TLWIdentifyResultController *vc = [[TLWIdentifyResultController alloc] init];
    vc.image = strongSelf.capturedImage;
    vc.identifyResults = parsedResults;
    vc.hidesBottomBarWhenPushed = YES;
        [strongSelf.navigationController pushViewController:vc animated:YES];
      });
        }];
      };
      performCloudIdentify(NO);
    });
  }];
}

#pragma mark - 本地识别兜底

- (void)tl_fallbackToLocalResults:(NSArray<NSDictionary *> *)localResults {
  if (localResults.count > 0) {
    NSLog(@"========== [兜底] 使用本地 CoreML 结果 ==========");
    for (NSInteger i = 0; i < localResults.count; i++) {
      NSDictionary *r = localResults[i];
      NSLog(@"[兜底] Top%ld: %@ | 置信度: %@", (long)(i + 1), r[@"name"], r[@"confidence"]);
    }
    NSLog(@"=================================================");
    [TLWToast show:@"云端识别失败，已使用本地识别结果"];
    TLWIdentifyResultController *vc = [[TLWIdentifyResultController alloc] init];
    vc.image = self.capturedImage;
    vc.identifyResults = localResults;
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
  } else {
    NSLog(@"[兜底] 本地 CoreML 也无结果，双路均失败");
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:@"识别失败，请检查网络后重试" preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"好" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
  }
}


- (NSData *)tl_cloudImageDataForIdentify:(UIImage *)image {
  if (![image isKindOfClass:[UIImage class]]) {
    return nil;
  }

  CGFloat width = image.size.width;
  CGFloat height = image.size.height;
  UIImage *workingImage = image;
  if (width > TLWIdentifyCloudMaxEdge || height > TLWIdentifyCloudMaxEdge) {
    CGFloat scale = (width > height) ? (TLWIdentifyCloudMaxEdge / width) : (TLWIdentifyCloudMaxEdge / height);
    CGSize newSize = CGSizeMake(MAX(1.0, floor(width * scale)),
                                MAX(1.0, floor(height * scale)));
    UIGraphicsBeginImageContextWithOptions(newSize, YES, 1.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *resized = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    if (resized) {
      workingImage = resized;
    }
  }

  return UIImageJPEGRepresentation(workingImage, TLWIdentifyCloudJPEGQuality);
}

- (void)tl_uploadIdentifyImageData:(NSData *)imageData
                        completion:(void (^)(NSString *imageURL, NSError *error))completion {
  if (imageData.length == 0) {
    if (completion) {
      completion(nil, [NSError errorWithDomain:@"TLWIdentifyUpload"
                                          code:-1
                                      userInfo:@{NSLocalizedDescriptionKey: @"图片数据为空"}]);
    }
    return;
  }

  NSString *fileName = [NSString stringWithFormat:@"identify_%@.jpg", NSUUID.UUID.UUIDString];
  NSString *filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];
  BOOL wrote = [imageData writeToFile:filePath atomically:YES];
  if (!wrote) {
    if (completion) {
      completion(nil, [NSError errorWithDomain:@"TLWIdentifyUpload"
                                          code:-2
                                      userInfo:@{NSLocalizedDescriptionKey: @"图片临时文件写入失败"}]);
    }
    return;
  }

  NSURL *fileURL = [NSURL fileURLWithPath:filePath];
  [[TLWSDKManager shared] uploadFileWithFile:fileURL
                                      prefix:@"identify/"
                           completionHandler:^(AGResultString *output, NSError *error) {
    [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
    dispatch_async(dispatch_get_main_queue(), ^{
      if (error || !output || output.code.integerValue != 200 || output.data.length == 0) {
        NSError *finalError = error;
        if (!finalError) {
          NSString *message = output.message ?: @"图片上传失败";
          finalError = [NSError errorWithDomain:@"TLWIdentifyUpload"
                                           code:output.code.integerValue ?: -3
                                       userInfo:@{NSLocalizedDescriptionKey: message}];
        }
        if (completion) {
          completion(nil, finalError);
        }
        return;
      }

      if (completion) {
        completion(output.data, nil);
      }
    });
  }];
}

- (UIImage *)tl_preparedAlbumImageForIdentify:(UIImage *)image {
  UIImage *normalizedImage = [self tl_normalizedImageForProcessing:image];
  if (!normalizedImage) {
    return image;
  }

  CGSize targetSize = self.previewLayer ? self.previewLayer.bounds.size : CGSizeZero;
  if (targetSize.width <= 0 || targetSize.height <= 0) {
    return normalizedImage;
  }

  CGFloat targetAspect = targetSize.width / targetSize.height;
  CGFloat imageAspect = normalizedImage.size.width / normalizedImage.size.height;
  CGRect cropRect = CGRectMake(0, 0, normalizedImage.size.width, normalizedImage.size.height);

  if (fabs(imageAspect - targetAspect) < 0.01) {
    return normalizedImage;
  }

  if (imageAspect > targetAspect) {
    CGFloat cropWidth = normalizedImage.size.height * targetAspect;
    cropRect.origin.x = floor((normalizedImage.size.width - cropWidth) * 0.5);
    cropRect.size.width = floor(cropWidth);
  } else {
    CGFloat cropHeight = normalizedImage.size.width / targetAspect;
    cropRect.origin.y = floor((normalizedImage.size.height - cropHeight) * 0.5);
    cropRect.size.height = floor(cropHeight);
  }

  CGImageRef croppedCGImage = CGImageCreateWithImageInRect(normalizedImage.CGImage, CGRectIntegral(cropRect));
  if (!croppedCGImage) {
    return normalizedImage;
  }

  UIImage *croppedImage = [UIImage imageWithCGImage:croppedCGImage scale:normalizedImage.scale orientation:UIImageOrientationUp];
  CGImageRelease(croppedCGImage);
  return croppedImage ?: normalizedImage;
}

- (UIImage *)tl_croppedCameraImageToPreview:(UIImage *)image {
  UIImage *normalizedImage = [self tl_normalizedImageForProcessing:image];
  if (!normalizedImage || !self.previewLayer) {
    return normalizedImage ?: image;
  }

  CGRect visibleRect = [self.previewLayer metadataOutputRectOfInterestForRect:self.previewLayer.bounds];
  if (CGRectIsEmpty(visibleRect) || CGRectIsNull(visibleRect)) {
    return normalizedImage;
  }

  CGFloat imageWidth = normalizedImage.size.width;
  CGFloat imageHeight = normalizedImage.size.height;
  CGRect cropRect = CGRectMake(CGRectGetMinX(visibleRect) * imageWidth,
                               CGRectGetMinY(visibleRect) * imageHeight,
                               CGRectGetWidth(visibleRect) * imageWidth,
                               CGRectGetHeight(visibleRect) * imageHeight);
  CGRect imageBounds = CGRectMake(0, 0, imageWidth, imageHeight);
  cropRect = CGRectIntersection(CGRectIntegral(cropRect), imageBounds);
  if (CGRectIsEmpty(cropRect) || CGRectIsNull(cropRect)) {
    return normalizedImage;
  }

  CGImageRef croppedCGImage = CGImageCreateWithImageInRect(normalizedImage.CGImage, cropRect);
  if (!croppedCGImage) {
    return normalizedImage;
  }

  UIImage *croppedImage = [UIImage imageWithCGImage:croppedCGImage scale:normalizedImage.scale orientation:UIImageOrientationUp];
  CGImageRelease(croppedCGImage);
  return croppedImage ?: normalizedImage;
}

- (UIImage *)tl_normalizedImageForProcessing:(UIImage *)image {
  if (![image isKindOfClass:[UIImage class]]) {
    return nil;
  }
  if (image.imageOrientation == UIImageOrientationUp) {
    return image;
  }

  UIGraphicsBeginImageContextWithOptions(image.size, YES, image.scale);
  [image drawInRect:CGRectMake(0, 0, image.size.width, image.size.height)];
  UIImage *normalizedImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return normalizedImage ?: image;
}

- (NSString *)tl_identifyPrompt {
  return @"请识别图片中农作物最可能的病害或虫害，并给出清晰、克制的诊断结论。"
         "请仅根据图片中可见症状判断，不要凭空猜测；如果证据明显不足、图像模糊或主体不明确，再返回待确认。"
         "如果能够判断，请优先给出最可能的病虫害名称，并提供简明、防治导向的建议。";
}

- (NSArray<NSDictionary *> *)tl_resultsFromDiagnosisItems:(NSArray<AGDiagnosisItem *> *)items {
  if (![items isKindOfClass:[NSArray class]] || items.count == 0) {
    return @[];
  }

  NSMutableArray<NSDictionary *> *results = [NSMutableArray array];
  NSArray<NSString *> *titles = @[@"结果一", @"结果二", @"结果三"];
  for (NSUInteger idx = 0; idx < MIN(items.count, TLWIdentifyDisplayResultCount); idx++) {
    AGDiagnosisItem *item = items[idx];
    if (![item isKindOfClass:[AGDiagnosisItem class]]) {
      continue;
    }

    NSString *name = item.diseaseName.length > 0 ? item.diseaseName : @"待确认";
    NSString *confidence = item.confidence ? [NSString stringWithFormat:@"%@%%", item.confidence] : @"--";
    NSString *advice = item.controlPlan.length > 0 ? item.controlPlan : @"";
    NSString *title = idx < titles.count ? titles[idx] : [NSString stringWithFormat:@"结果%lu", (unsigned long)(idx + 1)];
    [results addObject:@{
      @"title": title,
      @"name": name,
      @"names": @[name],
      @"confidence": confidence,
      @"reason": @"",
      @"advice": advice
    }];
  }
  return results.copy;
}

- (void)tl_probeCloudIdentifyProfileWithRequest:(AGChatRequest *)request manager:(TLWSDKManager *)manager {
  AGChatRequest *probeRequest = [[AGChatRequest alloc] init];
  probeRequest.text = request.text;
  probeRequest.imageUrl = request.imageUrl;
  probeRequest.useSingleModel = request.useSingleModel;
  probeRequest.extraInfo = request.extraInfo;
  probeRequest.saveHistory = @(NO);

  NSTimeInterval previousTimeout = manager.api.apiClient.timeoutInterval;
  manager.api.apiClient.timeoutInterval = TLWIdentifyCloudTimeout;
  [manager.api chatProfileWithChatRequest:probeRequest completionHandler:^(AGResultChatProfileResponse *output, NSError *error) {
    dispatch_async(dispatch_get_main_queue(), ^{
      manager.api.apiClient.timeoutInterval = previousTimeout;
      if (error || !output || output.code.integerValue != 200 || !output.data.profile) {
        NSLog(@"[云端][profile] 探针失败 error=%@ code=%@ message=%@",
              error.localizedDescription ?: @"<nil>",
              output.code ?: @"<nil>",
              output.message ?: @"<nil>");
        return;
      }

      NSLog(@"[云端][profile] requestId=%@ requestBytes=%@ imageType=%@ imageLength=%@ singleModel=%@ totalMs=%@ visionMs=%@ agentMs=%@ saveHistoryMs=%@",
            output.data.profile.requestId ?: @"<nil>",
            output.data.profile.requestBytes ?: @"<nil>",
            output.data.profile.imageUrlType ?: @"<nil>",
            output.data.profile.imageUrlLength ?: @"<nil>",
            output.data.profile.singleModel ?: @"<nil>",
            output.data.profile.totalMs ?: @"<nil>",
            output.data.profile.visionMs ?: @"<nil>",
            output.data.profile.agentMs ?: @"<nil>",
            output.data.profile.saveHistoryMs ?: @"<nil>");
    });
  }];
}

- (NSString *)tl_diagnosisPrompt {
  return @"图中发生了什么病害";
}

- (void)tl_requestDiagnosisResultsWithImageData:(NSData *)imageData
                                     completion:(void (^)(NSArray<NSDictionary *> *results))completion {
  TLWLocationManager *locationManager = [TLWLocationManager shared];
  void (^sendDiagnosisRequest)(NSDictionary * _Nullable) = ^(NSDictionary * _Nullable weatherInfo) {
    AGChatRequest *request = [self tl_diagnosisRequestWithImageData:imageData
                                                      locationInfo:locationManager
                                                        weatherInfo:weatherInfo];
    [[TLWSDKManager shared] chatWithChatRequest:request completionHandler:^(AGResultListDiagnosisItem *output, NSError *error) {
      dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"11%ld", output.data.count);
        if (error || !output || output.code.integerValue != 200 || output.data.count == 0) {
          NSLog(@"========== [云端] 诊断失败 ==========");
          if (error) {
            NSLog(@"[云端] NSError domain=%@ code=%ld msg=%@",
                  error.domain, (long)error.code, error.localizedDescription);
            NSLog(@"[云端] NSError userInfo=%@", error.userInfo);
          } else if (output) {
            NSLog(@"[云端] code=%@, message=%@", output.code, output.message);
          } else {
            NSLog(@"[云端] output=nil");
          }
          NSLog(@"============================================");
          if (completion) {
            completion(@[]);
          }
          return;
        }

        NSLog(@"========== [云端] 诊断成功 ==========");
        NSArray<NSDictionary *> *results = [self tl_normalizedIdentifyResultsForDisplay:
                                            [self tl_identifyResultsFromDiagnosisItems:output.data]];
        for (NSInteger i = 0; i < results.count; i++) {
          NSDictionary *result = results[i];
          NSLog(@"[云端] Top%ld: %@ | 置信度: %@ | 方案: %@",
                (long)(i + 1),
                result[@"name"],
                result[@"confidence"],
                result[@"advice"]);
        }
        NSLog(@"============================================");

        if (completion) {
          completion(results);
        }
      });
    }];
  };

  if (locationManager.hasLocation) {
    [[TLWSDKManager shared] getCurrentWeatherWithLatitude:locationManager.latitude
                                                longitude:locationManager.longitude
                                               completion:^(NSDictionary * _Nullable weatherInfo, NSError * _Nullable error) {
      if (error) {
        NSLog(@"[云端] 天气信息获取失败，继续发起诊断: %@", error.localizedDescription);
      }
      sendDiagnosisRequest(weatherInfo);
    }];
    return;
  }

  sendDiagnosisRequest(nil);
}

- (AGChatRequest *)tl_diagnosisRequestWithImageData:(NSData *)imageData
                                      locationInfo:(TLWLocationManager *)locationManager
                                        weatherInfo:(NSDictionary * _Nullable)weatherInfo {
  AGChatRequest *request = [[AGChatRequest alloc] init];
  request.text = [self tl_diagnosisPrompt];
  request.imageUrl = [NSString stringWithFormat:@"data:image/jpeg;base64,%@",
                      [imageData base64EncodedStringWithOptions:0]];
  request.useSingleModel = @(YES);
  request.extraInfo = [self tl_diagnosisExtraInfoWithLocationInfo:locationManager weatherInfo:weatherInfo];
  return request;
}

- (NSString *)tl_diagnosisExtraInfoWithLocationInfo:(TLWLocationManager *)locationManager
                                        weatherInfo:(NSDictionary * _Nullable)weatherInfo {
  NSMutableArray<NSString *> *parts = [NSMutableArray array];
  if (locationManager.hasLocation) {
    NSString *city = locationManager.cityName.length > 0 ? locationManager.cityName : @"未知位置";
    [parts addObject:[NSString stringWithFormat:@"定位城市：%@", city]];
    [parts addObject:[NSString stringWithFormat:@"定位坐标：%.6f, %.6f",
                      locationManager.latitude,
                      locationManager.longitude]];
  }

  NSString *weatherText = [weatherInfo[@"weatherText"] isKindOfClass:[NSString class]] ? weatherInfo[@"weatherText"] : nil;
  NSString *temperature = [weatherInfo[@"temperature"] isKindOfClass:[NSString class]] ? weatherInfo[@"temperature"] : nil;
  if (weatherText.length > 0 || temperature.length > 0) {
    [parts addObject:[NSString stringWithFormat:@"天气：%@，温度：%@°C",
                      weatherText.length > 0 ? weatherText : @"未知",
                      temperature.length > 0 ? temperature : @"--"]];
  }

  return parts.count > 0 ? [parts componentsJoinedByString:@"；"] : nil;
}

- (NSArray<NSDictionary *> *)tl_identifyResultsFromDiagnosisItems:(NSArray<AGDiagnosisItem *> *)items {
  if (items.count == 0) {
    return @[];
  }

  NSMutableArray<NSDictionary *> *results = [NSMutableArray array];
  NSInteger count = MIN(items.count, TLWIdentifyDisplayResultCount);
  for (NSInteger idx = 0; idx < count; idx++) {
    AGDiagnosisItem *item = items[idx];
    NSString *name = item.diseaseName.length > 0 ? item.diseaseName : @"待确认";
    NSString *confidence = [self tl_confidenceTextFromNumber:item.confidence];
    NSString *advice = item.controlPlan.length > 0
        ? item.controlPlan
        : @"建议补拍叶片近景、病斑局部、叶背或虫体细节后再次识别。";
    NSString *reason = @"综合图片、定位与天气信息生成的诊断结果。";
    [results addObject:@{
      @"title": [self tl_identifyTitleForIndex:idx],
      @"name": name,
      @"names": @[name],
      @"confidence": confidence,
      @"reason": reason,
      @"advice": advice
    }];
  }
  return results.copy;
}

- (NSString *)tl_confidenceTextFromNumber:(NSNumber *)confidenceNumber {
  if (![confidenceNumber isKindOfClass:[NSNumber class]]) {
    return @"--";
  }

  double value = confidenceNumber.doubleValue;
  if (fabs(value - round(value)) < 0.01) {
    return [NSString stringWithFormat:@"%.0f%%", value];
  }
  return [NSString stringWithFormat:@"%.1f%%", value];
}

- (NSArray<NSDictionary *> *)tl_parseIdentifyResultsFromJSONString:(NSString *)jsonString {
  if (![jsonString isKindOfClass:[NSString class]] || jsonString.length == 0) {
    return @[];
  }

  NSString *normalized = [jsonString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
  NSRange firstBraceRange = [normalized rangeOfString:@"{"];
  NSRange lastBraceRange = [normalized rangeOfString:@"}" options:NSBackwardsSearch];
  if (firstBraceRange.location != NSNotFound &&
      lastBraceRange.location != NSNotFound &&
      lastBraceRange.location > firstBraceRange.location) {
    normalized = [normalized substringWithRange:NSMakeRange(firstBraceRange.location,
                                                            lastBraceRange.location - firstBraceRange.location + 1)];
  }

  NSData *data = [normalized dataUsingEncoding:NSUTF8StringEncoding];
  if (!data) {
    return @[];
  }

  NSError *jsonError = nil;
  id jsonObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
  if (jsonError || ![jsonObject isKindOfClass:[NSDictionary class]]) {
    NSLog(@"AI识别：JSON解析失败 %@", jsonError.localizedDescription);
    return @[];
  }

  id resultsObject = ((NSDictionary *)jsonObject)[@"results"];
  if (![resultsObject isKindOfClass:[NSArray class]]) {
    return @[];
  }

  NSMutableArray<NSDictionary *> *parsedResults = [NSMutableArray array];
  NSArray *rawResults = (NSArray *)resultsObject;
  for (NSUInteger idx = 0; idx < rawResults.count; idx++) {
    id item = rawResults[idx];
    if (![item isKindOfClass:[NSDictionary class]]) {
      continue;
    }

    NSDictionary *result = (NSDictionary *)item;
    NSString *title = [result[@"title"] isKindOfClass:[NSString class]] ? result[@"title"] : [NSString stringWithFormat:@"结果%lu", (unsigned long)(idx + 1)];

    NSString *name = nil;
    if ([result[@"name"] isKindOfClass:[NSString class]] && [result[@"name"] length] > 0) {
      name = result[@"name"];
    } else if ([result[@"names"] isKindOfClass:[NSArray class]]) {
      for (id nameItem in result[@"names"]) {
        if ([nameItem isKindOfClass:[NSString class]] && [((NSString *)nameItem) length] > 0) {
          name = nameItem;
          break;
        }
      }
    }

    NSString *confidence = nil;
    if ([result[@"confidence"] isKindOfClass:[NSString class]]) {
      confidence = result[@"confidence"];
    } else if ([result[@"confidence"] isKindOfClass:[NSNumber class]]) {
      confidence = [NSString stringWithFormat:@"%.1f%%", [result[@"confidence"] floatValue]];
    }
    NSString *advice = [result[@"advice"] isKindOfClass:[NSString class]] ? result[@"advice"] : @"";
    NSString *reason = [result[@"reason"] isKindOfClass:[NSString class]] ? result[@"reason"] : @"";
    if (advice.length == 0 && reason.length > 0) {
      advice = reason;
    }

    [parsedResults addObject:@{
      @"title": title ?: @"",
      @"name": name ?: @"",
      @"names": name.length > 0 ? @[name] : @[],
      @"confidence": confidence ?: @"--",
      @"reason": reason ?: @"",
      @"advice": advice ?: @""
    }];
  }

  return [parsedResults copy];
}

- (NSArray<NSDictionary *> *)tl_buildLocalFallbackResultsFromIdentifyResults:(NSArray<TLWLocalIdentifyResult *> *)results {
  if (results.count == 0) {
    return @[];
  }

  TLWLocalIdentifyResult *topResult = results.firstObject;
  if (![topResult isKindOfClass:[TLWLocalIdentifyResult class]]) {
    return @[];
  }
  if ([topResult.label isEqualToString:@"Background_without_leaves"] ||
      topResult.confidence < TLWIdentifyMinLocalFallbackConfidence) {
    return @[];
  }

  NSMutableArray<NSDictionary *> *parsed = [NSMutableArray array];
  NSInteger count = MIN(results.count, TLWIdentifyDisplayResultCount);
  for (NSInteger i = 0; i < count; i++) {
    TLWLocalIdentifyResult *result = results[i];
    NSString *reason = result.crop.length > 0
        ? [NSString stringWithFormat:@"本地离线模型预判（作物：%@）", result.crop]
        : @"本地离线模型预判";
    [parsed addObject:@{
      @"title": [self tl_identifyTitleForIndex:i],
      @"name": result.name ?: @"待确认",
      @"names": result.name.length > 0 ? @[result.name] : @[],
      @"confidence": [NSString stringWithFormat:@"%.1f%%", result.confidence * 100.0f],
      @"reason": reason,
      @"advice": @"当前为离线兜底结果，建议补拍叶片近景、病斑细节或联网后再次识别。"
    }];
  }
  return parsed.copy;
}

- (NSArray<NSDictionary *> *)tl_normalizedIdentifyResultsForDisplay:(NSArray<NSDictionary *> *)results {
  if (results.count == 0) {
    return @[];
  }

  NSMutableArray<NSDictionary *> *normalized = [NSMutableArray array];
  NSInteger count = MIN(results.count, TLWIdentifyDisplayResultCount);
  for (NSInteger idx = 0; idx < count; idx++) {
    NSDictionary *result = results[idx];
    NSString *title = [result[@"title"] isKindOfClass:[NSString class]] && [result[@"title"] length] > 0
        ? result[@"title"]
        : [self tl_identifyTitleForIndex:idx];
    NSString *name = [result[@"name"] isKindOfClass:[NSString class]] && [result[@"name"] length] > 0
        ? result[@"name"]
        : @"待确认";
    NSString *confidence = [result[@"confidence"] isKindOfClass:[NSString class]] && [result[@"confidence"] length] > 0
        ? result[@"confidence"]
        : @"--";
    NSString *reason = [result[@"reason"] isKindOfClass:[NSString class]] ? result[@"reason"] : @"";
    NSString *advice = [result[@"advice"] isKindOfClass:[NSString class]] ? result[@"advice"] : @"";
    if (advice.length == 0) {
      advice = reason.length > 0 ? reason : @"建议补拍叶片近景、叶背或虫体细节后再次识别。";
    }

    [normalized addObject:@{
      @"title": title,
      @"name": name,
      @"names": @[name],
      @"confidence": confidence,
      @"reason": reason ?: @"",
      @"advice": advice
    }];
  }

  return normalized.copy;
}

- (NSString *)tl_identifyTitleForIndex:(NSInteger)index {
  NSArray<NSString *> *titles = @[@"结果一", @"结果二", @"结果三"];
  if (index >= 0 && index < titles.count) {
    return titles[index];
  }
  return [NSString stringWithFormat:@"结果%ld", (long)index + 1];
}


- (void)tl_showLoadingIndicator {
  dispatch_async(dispatch_get_main_queue(), ^{
    if (!self.loadingImageView) {
      UIImage *loadingImage = [UIImage imageNamed:@"Ip_load.png"];
      self.loadingImageView = [[UIImageView alloc] initWithImage:loadingImage];
      self.loadingImageView.bounds = CGRectMake(0, 0, 130, 130);
      self.loadingImageView.center = self.myView.center;
      self.loadingImageView.contentMode = UIViewContentModeScaleAspectFit;
      self.loadingImageView.hidden = YES;
      self.loadingImageView.userInteractionEnabled = NO;
      [self.myView addSubview:self.loadingImageView];
    }
    self.loadingImageView.center = self.myView.center;
    self.loadingImageView.hidden = NO;
    [self.loadingImageView.layer removeAnimationForKey:@"tl_identify_rotate"];

    CABasicAnimation *rotation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotation.fromValue = @(0);
    rotation.toValue = @(M_PI * 2);
    rotation.duration = 1.0;
    rotation.repeatCount = HUGE_VALF;
    rotation.removedOnCompletion = NO;
    [self.loadingImageView.layer addAnimation:rotation forKey:@"tl_identify_rotate"];
    [self.myView bringSubviewToFront:self.loadingImageView];
  });
}

- (void)tl_stopLoadingIndicator {
  dispatch_async(dispatch_get_main_queue(), ^{
    [self.loadingImageView.layer removeAnimationForKey:@"tl_identify_rotate"]; self.loadingImageView.hidden = YES;
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
