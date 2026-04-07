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
#import <AgriPestClient/AGChatRequest.h>
#import "TLWPhotoPickerController.h"

@interface TLWIdentifyPageController ()<AVCapturePhotoCaptureDelegate>
@property (nonatomic, strong) TLWIdentifyPageView *myView;
@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, strong) AVCapturePhotoOutput *photoOutput;
@property (nonatomic, strong) UIImageView *capturedImageView;
@property (nonatomic, strong) UIActivityIndicatorView* indicator;
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

- (void)tl_openPhotoAlbum {
  TLWPhotoPickerController *pickerVC = [[TLWPhotoPickerController alloc] init];
  pickerVC.maxCount = 1;
  __weak typeof(self) weakSelf = self;
  pickerVC.onSelectImage = ^(UIImage *image) {
    __strong typeof(weakSelf) strongSelf = weakSelf;
    if (!strongSelf || !image) return;
    strongSelf.capturedImage = image;
    strongSelf.capturedImageView.image = image;
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
    self.capturedImage = image;
    self.capturedImageView.image = image;
    self.capturedImageView.hidden = NO;
    self.previewLayer.hidden = YES;
    [self tl_identifyFromAI];
  });
}

- (void)tl_identifyFromAI {
  [self tl_showLoadingIndicator];//展示加载动画
  UIImage *image = self.capturedImage;
  if (![image isKindOfClass:[UIImage class]]) {
    [self tl_stopLoadingIndicator];
    return;
  }

  NSData *imageData = UIImageJPEGRepresentation(image, 0.9);//压缩
  if (imageData.length == 0) {
    [self tl_stopLoadingIndicator];
    return;
  }

  NSString *fileName = [NSString stringWithFormat:@"identify_%@.jpg", [[NSUUID UUID] UUIDString]];//生成一个全局唯一的标识符，避免文件命名冲突
  NSString *tempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];//拼接一个临时的完整路径
  NSURL *fileURL = [NSURL fileURLWithPath:tempPath];//将字符串路径改为file://类型的本地文件URL
  BOOL writeSuccess = [imageData writeToURL:fileURL atomically:YES];
  if (!writeSuccess) {
    [self tl_stopLoadingIndicator];
    return;
  }

  TLWSDKManager *manager = [TLWSDKManager shared];
  __weak typeof(self) weakSelf = self;
  NSLog(@"开始上传图片");
  [manager uploadFileWithFile:fileURL prefix:@"uploads/identify/" completionHandler:^(AGResultString *output, NSError *error) {
    dispatch_async(dispatch_get_main_queue(), ^{
      NSLog(@"AI识别：进入回调");
      __strong typeof(weakSelf) strongSelf = weakSelf;
      if (!strongSelf) {
        NSLog(@"AI识别：传入空对象");
        [[NSFileManager defaultManager] removeItemAtURL:fileURL error:nil];
        return;
      }

      if (error || !output || output.code.integerValue != 200 || output.data.length == 0) {
        NSLog(@"AI识别：分析失败 %@", output.code);
        [[NSFileManager defaultManager] removeItemAtURL:fileURL error:nil];
        [strongSelf tl_stopLoadingIndicator];
        NSString *message = error.localizedDescription ?: output.message ?: @"图片上传失败";
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"好" style:UIAlertActionStyleDefault handler:nil]];
        [strongSelf presentViewController:alert animated:YES completion:nil];
        return;
      }
      NSLog(@"AI识别：图片正确返回");
      NSString *imageURLString = output.data;
      AGChatRequest *request = [[AGChatRequest alloc] init];
      request.text = @"请根据图片识别结果，返回3个最可能的病害，并严格使用JSON格式输出，不要输出任何额外文字。每个结果只返回1个病害名称，并按结果一、结果二、结果三对应3个结果。格式为：{\"results\":[{\"title\":\"结果一\",\"name\":\"病害名称\",\"confidence\":\"百分比\",\"reason\":\"判断依据\",\"advice\":\"处理建议\"},{\"title\":\"结果二\",\"name\":\"病害名称\",\"confidence\":\"百分比\",\"reason\":\"判断依据\",\"advice\":\"处理建议\"},{\"title\":\"结果三\",\"name\":\"病害名称\",\"confidence\":\"百分比\",\"reason\":\"判断依据\",\"advice\":\"处理建议\"}]}";
      request.imageUrl = imageURLString;
      request.useSingleModel = @(YES);
      NSLog(@"AI识别：开始识别病害");
      [manager.api chatWithChatRequest:request completionHandler:^(AGResultString *chatOutput, NSError *chatError) {
        dispatch_async(dispatch_get_main_queue(), ^{
          NSLog(@"AI识别：进入识别回调");
          [[NSFileManager defaultManager] removeItemAtURL:fileURL error:nil];
          [strongSelf tl_stopLoadingIndicator];

          if (chatError || !chatOutput || chatOutput.code.integerValue != 200 || chatOutput.data.length == 0) {
            NSLog(@"AI识别：识别失败");
            NSString *message = chatError.localizedDescription ?: chatOutput.message ?: @"AI识别失败";
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"好" style:UIAlertActionStyleDefault handler:nil]];
            [strongSelf presentViewController:alert animated:YES completion:nil];
            return;
          }
          NSLog(@"AI识别：识别成功");
          NSLog(@"[IdentifyAI] %@", chatOutput.data);
          NSArray<NSDictionary *> *parsedResults = [strongSelf tl_parseIdentifyResultsFromJSONString:chatOutput.data];
          TLWIdentifyResultController *vc = [[TLWIdentifyResultController alloc] init];
          vc.image = strongSelf.capturedImage;
          vc.identifyResults = parsedResults;
          vc.hidesBottomBarWhenPushed = YES;
          [strongSelf.navigationController pushViewController:vc animated:YES];
        });
      }];
    });
  }];
}

- (NSArray<NSDictionary *> *)tl_parseIdentifyResultsFromJSONString:(NSString *)jsonString {
  if (![jsonString isKindOfClass:[NSString class]] || jsonString.length == 0) {
    return @[];
  }

  NSString *normalized = [jsonString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
  if ([normalized hasPrefix:@"```"]) {
    NSRange firstBraceRange = [normalized rangeOfString:@"{"];
    NSRange lastBraceRange = [normalized rangeOfString:@"}" options:NSBackwardsSearch];
    if (firstBraceRange.location != NSNotFound && lastBraceRange.location != NSNotFound && lastBraceRange.location > firstBraceRange.location) {
      normalized = [normalized substringWithRange:NSMakeRange(firstBraceRange.location, lastBraceRange.location - firstBraceRange.location + 1)];
    }
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

    NSString *confidence = [result[@"confidence"] isKindOfClass:[NSString class]] ? result[@"confidence"] : @"--";
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


- (void)tl_showLoadingIndicator {
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

- (void)tl_stopLoadingIndicator {
  dispatch_async(dispatch_get_main_queue(), ^{
    [self.indicator stopAnimating];
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
