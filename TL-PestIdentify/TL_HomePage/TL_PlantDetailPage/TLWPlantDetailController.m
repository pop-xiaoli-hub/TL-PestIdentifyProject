//
//  TLWPlantDetailController.m
//  TL-PestIdentify
//

#import "TLWPlantDetailController.h"
#import "../Models/TLWPlantModel.h"
#import "../../TL_Common/Network/TLWSDKManager.h"
#import "TLWPlantDetailView.h"
#import "ViewModels/TLWPlantDetailViewModel.h"
#import "Views/TLWPlantDetailSegmentTabView.h"
#import "Views/TLWPlantDetailFertilizerView.h"
#import "Views/TLWPlantDetailMedicineView.h"
#import "Views/TLWPlantDetailNoteView.h"
#import "Views/TLWPlantDetailWateringView.h"
#import "TLWImagePickerManager.h"
#import <AgriPestClient/AGMyCropUpdateRequest.h>
#import <SDWebImage/SDWebImage.h>
#import "TLWSDKManager.h"

@interface TLWPlantDetailController () <UIGestureRecognizerDelegate, TLWImagePickerDelegate>

@property (nonatomic, strong) TLWPlantDetailView *detailView;
@property (nonatomic, strong) TLWPlantDetailViewModel *viewModel;
@property (nonatomic, assign) BOOL tagRequestInFlight;
@property (nonatomic, strong) UITapGestureRecognizer *dismissKeyboardTapGesture;
@property (nonatomic, strong) TLWImagePickerManager *imagePickerManager;

@end

@implementation TLWPlantDetailController

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)initWithPlantModel:(TLWPlantModel *)plantModel {
  self = [super init];
  if (self) {
    _viewModel = [[TLWPlantDetailViewModel alloc] initWithPlantModel:plantModel];//初始化viewMdel
  }
  return self;
}

- (void)loadView {
  self.detailView = [[TLWPlantDetailView alloc] initWithFrame:[UIScreen mainScreen].bounds];//加载主视图
  self.view = self.detailView;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  self.navigationController.navigationBarHidden = YES;
  [self tl_bindActions];//绑定控件的回调行为
  [self tl_setupDismissKeyboardGesture];
  [self tl_registerKeyboardNotifications];
  [self tl_render];
  [self tl_fetchCropDetailAndRefreshCalendar];
}

- (void)tl_bindActions {
  [self.detailView.backButton addTarget:self action:@selector(tl_backTapped) forControlEvents:UIControlEventTouchUpInside];
  [self.detailView.imageTagButton addTarget:self action:@selector(tl_imageTagButtonTapped) forControlEvents:UIControlEventTouchUpInside];

  __weak typeof(self) weakSelf = self;
  self.detailView.segmentTabView.selectionChangedBlock = ^(NSInteger index) {
    __strong typeof(weakSelf) strongSelf = weakSelf;
    if (!strongSelf) {
      return;
    }
    strongSelf.viewModel.selectedTabType = index;
    [strongSelf.detailView updateSelectedTab:index contentHeight:[strongSelf.viewModel preferredContentHeightForSelectedTab]];
  };

  self.detailView.wateringView.previousMonthBlock = ^{
    __strong typeof(weakSelf) strongSelf = weakSelf;
    if (!strongSelf) {
      return;
    }
    [strongSelf.viewModel moveToPreviousMonth];
    [strongSelf.detailView configureWithViewModel:strongSelf.viewModel];
  };

  self.detailView.wateringView.nextMonthBlock = ^{
    __strong typeof(weakSelf) strongSelf = weakSelf;
    if (!strongSelf) {
      return;
    }
    [strongSelf.viewModel moveToNextMonth];
    [strongSelf.detailView configureWithViewModel:strongSelf.viewModel];
  };

  self.detailView.wateringView.dateSelectionBlock = ^(NSDate *date) {
    __strong typeof(weakSelf) strongSelf = weakSelf;
    if (!strongSelf) {
      return;
    }
    [strongSelf.viewModel selectDate:date];
    [strongSelf.detailView configureWithViewModel:strongSelf.viewModel];
  };

  self.detailView.wateringView.tagActionBlock = ^{
    __strong typeof(weakSelf) strongSelf = weakSelf;
    if (!strongSelf) {
      return;
    }
    [strongSelf tl_submitWateringTagWithStatus:@1 content:@"已浇水"];
  };

  self.detailView.wateringView.cancelTagActionBlock = ^{
    __strong typeof(weakSelf) strongSelf = weakSelf;
    if (!strongSelf) {
      return;
    }
    [strongSelf tl_submitCultivationTagWithStatus:@0 content:@"待浇水" tagType:@"WATERING"];
  };

  self.detailView.fertilizerView.tagActionBlock = ^{
    __strong typeof(weakSelf) strongSelf = weakSelf;
    if (!strongSelf) {
      return;
    }
    [strongSelf tl_submitCultivationTagWithStatus:@1 content:@"已施肥" tagType:@"FERTILIZING"];
  };

  self.detailView.fertilizerView.cancelTagActionBlock = ^{
    __strong typeof(weakSelf) strongSelf = weakSelf;
    if (!strongSelf) {
      return;
    }
    [strongSelf tl_submitCultivationTagWithStatus:@0 content:@"待施肥" tagType:@"FERTILIZING"];
  };

  self.detailView.medicineView.tagActionBlock = ^{
    __strong typeof(weakSelf) strongSelf = weakSelf;
    if (!strongSelf) {
      return;
    }
    [strongSelf tl_submitCultivationTagWithStatus:@1 content:@"已用药" tagType:@"MEDICATION"];
  };

  self.detailView.medicineView.cancelTagActionBlock = ^{
    __strong typeof(weakSelf) strongSelf = weakSelf;
    if (!strongSelf) {
      return;
    }
    [strongSelf tl_submitCultivationTagWithStatus:@0 content:@"待用药" tagType:@"MEDICATION"];
  };

  self.detailView.noteView.tagActionBlock = ^{
    __strong typeof(weakSelf) strongSelf = weakSelf;
    if (!strongSelf) {
      return;
    }
    NSString *noteText = [[strongSelf.detailView.noteView currentNoteText] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (noteText.length == 0) {
      [strongSelf tl_showMessage:@"请输入笔记内容"];
      return;
    }
    [strongSelf tl_submitCultivationTagWithStatus:@1 content:noteText tagType:@"NOTE"];
  };

  self.detailView.noteView.cancelTagActionBlock = ^{
    __strong typeof(weakSelf) strongSelf = weakSelf;
    if (!strongSelf) {
      return;
    }
    [strongSelf tl_submitCultivationTagWithStatus:@0 content:@"" tagType:@"NOTE"];
  };
}

- (void)tl_setupDismissKeyboardGesture {
  UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tl_handleBackgroundTap)];
  tapGesture.cancelsTouchesInView = NO;
  tapGesture.delegate = self;
  [self.detailView addGestureRecognizer:tapGesture];
  self.dismissKeyboardTapGesture = tapGesture;
}

- (void)tl_handleBackgroundTap {
  [self.detailView endEditing:YES];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
  if (gestureRecognizer != self.dismissKeyboardTapGesture) {
    return YES;
  }

  UIView *touchedView = touch.view;
  while (touchedView != nil) {
    if ([touchedView isKindOfClass:[UIControl class]] || [touchedView isKindOfClass:[UITextView class]]) {
      return NO;
    }
    touchedView = touchedView.superview;
  }

  return YES;
}

- (void)tl_registerKeyboardNotifications {
  NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
  [notificationCenter addObserver:self selector:@selector(tl_keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
  [notificationCenter addObserver:self selector:@selector(tl_keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)tl_keyboardWillShow:(NSNotification *)notification {
  NSDictionary *userInfo = notification.userInfo;
  CGRect keyboardFrame = [userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
  NSTimeInterval animationDuration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
  UIViewAnimationOptions animationOptions = ([userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue] << 16);

  CGRect keyboardFrameInView = [self.view convertRect:keyboardFrame fromView:nil];
  CGFloat keyboardOverlap = MAX(0.0, CGRectGetMaxY(self.view.bounds) - CGRectGetMinY(keyboardFrameInView));
  CGFloat bottomInset = MAX(0.0, keyboardOverlap - self.view.safeAreaInsets.bottom);

  [UIView animateWithDuration:animationDuration delay:0 options:animationOptions animations:^{
    [self.detailView setScrollViewBottomInset:bottomInset];
    if (self.viewModel.selectedTabType == TLWPlantDetailTabTypeNote && [self.detailView.noteView isEditingNoteText]) {
      [self.detailView scrollToBottomAnimated:NO];
    }
  } completion:nil];
}

- (void)tl_keyboardWillHide:(NSNotification *)notification {
  NSDictionary *userInfo = notification.userInfo;
  NSTimeInterval animationDuration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
  UIViewAnimationOptions animationOptions = ([userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue] << 16);

  [UIView animateWithDuration:animationDuration delay:0 options:animationOptions animations:^{
    [self.detailView setScrollViewBottomInset:0.0];
  } completion:nil];
}

- (void)tl_render {
  if (self.viewModel.plantModel.localImage) {
    self.detailView.topImageView.image = self.viewModel.plantModel.localImage;
  } else if ([self.viewModel imageURLString].length > 0) {
    [self.detailView.topImageView sd_setImageWithURL:[NSURL URLWithString:[self.viewModel imageURLString]] placeholderImage:[UIImage imageNamed:@"hp_eg1"]];
  } else {
    self.detailView.topImageView.image = [UIImage imageNamed:@"hp_eg1"];
  }

  [self.detailView configureWithViewModel:self.viewModel];
}

- (void)tl_backTapped {
  [self.navigationController popViewControllerAnimated:YES];
}

- (void)tl_imageTagButtonTapped {
  UIAlertController *sheet = [UIAlertController alertControllerWithTitle:nil
                                                                 message:nil
                                                          preferredStyle:UIAlertControllerStyleActionSheet];
  __weak typeof(self) weakSelf = self;
  [sheet addAction:[UIAlertAction actionWithTitle:@"拍照" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
    __strong typeof(weakSelf) strongSelf = weakSelf;
    if (!strongSelf) {
      return;
    }
    [strongSelf.imagePickerManager openCameraFrom:strongSelf];
  }]];
  [sheet addAction:[UIAlertAction actionWithTitle:@"从相册选择" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
    __strong typeof(weakSelf) strongSelf = weakSelf;
    if (!strongSelf) {
      return;
    }
    [strongSelf.imagePickerManager openAlbumFrom:strongSelf];
  }]];
  [sheet addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];

  UIPopoverPresentationController *popover = sheet.popoverPresentationController;
  if (popover) {
    popover.sourceView = self.detailView.imageTagButton;
    popover.sourceRect = self.detailView.imageTagButton.bounds;
    popover.permittedArrowDirections = UIPopoverArrowDirectionAny;
  }

  [self presentViewController:sheet animated:YES completion:nil];
}

- (void)imagePicker:(TLWImagePickerManager *)picker didSelectImage:(UIImage *)image {
  if (![image isKindOfClass:[UIImage class]]) {
    return;
  }
  self.viewModel.plantModel.localImage = image;
  self.viewModel.plantModel.imageUrl = @"";
  self.detailView.topImageView.image = image;
  [self tl_uploadAndUpdatePlantImage:image];
}

- (TLWImagePickerManager *)imagePickerManager {
  if (!_imagePickerManager) {
    _imagePickerManager = [[TLWImagePickerManager alloc] init];
    _imagePickerManager.maxCount = 1;
    _imagePickerManager.delegate = self;
  }
  return _imagePickerManager;
}

- (void)tl_uploadAndUpdatePlantImage:(UIImage *)image {
  NSNumber *cropId = self.viewModel.plantModel.plantId;
  if (cropId.integerValue <= 0) {
    return;
  }

  __weak typeof(self) weakSelf = self;
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    NSData *imageData = UIImageJPEGRepresentation(image, 0.9);
    if (imageData.length == 0) {
      dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
          return;
        }
        [strongSelf tl_showMessage:@"图片处理失败，请稍后重试"];
      });
      return;
    }
    NSString *fileName = [NSString stringWithFormat:@"crop_detail_%@.jpg", [[NSUUID UUID] UUIDString]];
    NSString *tempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];
    if (![imageData writeToFile:tempPath atomically:YES]) {
      dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
          return;
        }
        [strongSelf tl_showMessage:@"图片处理失败，请稍后重试"];
      });
      return;
    }

    NSURL *fileURL = [NSURL fileURLWithPath:tempPath];
    TLWSDKManager *manager = [TLWSDKManager shared];
    NSLog(@"1");
    __block void (^updateCropBlock)(NSString *imageURL, BOOL didRetryAuth);
    updateCropBlock = ^(NSString *imageURL, BOOL didRetryAuth) {
      AGMyCropUpdateRequest *request = [[AGMyCropUpdateRequest alloc] init];
      request.plantName = weakSelf.viewModel.plantModel.plantName;
      request.imageUrl = imageURL;
      request.status = weakSelf.viewModel.plantModel.plantStatus;
      request.plantingDate = weakSelf.viewModel.plantModel.plantingDate;

      [manager.api updateCropWithId:cropId myCropUpdateRequest:request completionHandler:^(AGResultMyCropResponseDto *output, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
          NSLog(@"2");
          __strong typeof(weakSelf) strongSelf = weakSelf;
          if (!strongSelf) {
            return;
          }

          if (!didRetryAuth
              && [manager.sessionManager handleAuthFailureForCode:output.code
                                                         message:output.message
                                                      retryBlock:^{
            updateCropBlock(imageURL, YES);
          }]) {
            return;
          }

          if (error || output.code.integerValue != 200) {
            NSString *message = [manager.sessionManager userFacingMessageForError:error
                                                                             code:output.code
                                                                    serverMessage:output.message
                                                                   defaultMessage:@"作物图片更新失败，请稍后重试"];
            [strongSelf tl_showMessage:message];
            return;
          }
          NSLog(@"3");
          strongSelf.viewModel.plantModel.imageUrl = output.data.imageUrl.length > 0 ? output.data.imageUrl : imageURL;
          strongSelf.viewModel.plantModel.localImage = image;
        });
      }];
    };

    __block void (^uploadBlock)(BOOL didRetryAuth);
    uploadBlock = ^(BOOL didRetryAuth) {
      [manager uploadFileWithFile:fileURL prefix:@"crop/" completionHandler:^(AGResultString *output, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
          __strong typeof(weakSelf) strongSelf = weakSelf;
          if (!strongSelf) {
            [[NSFileManager defaultManager] removeItemAtPath:tempPath error:nil];
            return;
          }

          if (!didRetryAuth
              && [manager.sessionManager handleAuthFailureForCode:output.code
                                                         message:output.message
                                                      retryBlock:^{
            uploadBlock(YES);
          }]) {
            return;
          }

          NSString *imageURL = [output.data isKindOfClass:[NSString class]] ? output.data : @"";
          if (error || output.code.integerValue != 200 || imageURL.length == 0) {
            [[NSFileManager defaultManager] removeItemAtPath:tempPath error:nil];
            NSString *message = [manager.sessionManager userFacingMessageForError:error
                                                                             code:output.code
                                                                    serverMessage:output.message
                                                                   defaultMessage:@"图片上传失败，请稍后重试"];
            [strongSelf tl_showMessage:message];
            return;
          }

          [[NSFileManager defaultManager] removeItemAtPath:tempPath error:nil];
          updateCropBlock(imageURL, NO);
        });
      }];
    };

    uploadBlock(NO);
  });
}

- (void)tl_showMessage:(NSString *)message {
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
  [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
  [self presentViewController:alert animated:YES completion:nil];
}

- (void)tl_submitWateringTagWithStatus:(NSNumber *)status content:(NSString *)content {
  [self tl_submitCultivationTagWithStatus:status content:content tagType:@"WATERING"];
}

- (void)tl_submitCultivationTagWithStatus:(NSNumber *)status content:(NSString *)content tagType:(NSString *)tagType {
  if (self.tagRequestInFlight) {//节流，如果上一条打标签请求还没回来，再次点击不发送请求
    return;
  }

  NSNumber *cropId = self.viewModel.plantModel.plantId;
  if (cropId == nil || cropId.integerValue <= 0) {
    [self tl_showMessage:@"当前作物还没有可用的服务端 ID"];
    return;
  }

  NSDate *selectedDate = [self.viewModel currentSelectedDate];
  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSDateComponents *components = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:selectedDate];
  components.hour = 12;
  components.minute = 0;
  components.second = 0;

  AGTagOperationRequest *request = [[AGTagOperationRequest alloc] init];
  request.recordDate = [calendar dateFromComponents:components] ?: selectedDate;
  request.tagType = tagType;
  request.content = content;
  request.status = status;

  self.tagRequestInFlight = YES;
  __weak typeof(self) weakSelf = self;
  NSLog(@"开始进行服务端标签同步, tagType=%@", tagType);
  [[TLWSDKManager shared] addTagWithCropId:cropId tagOperationRequest:request completionHandler:^(AGResultVoid * output, NSError * error) {
    dispatch_async(dispatch_get_main_queue(), ^{
      __strong typeof(weakSelf) strongSelf = weakSelf;
      if (!strongSelf) {
        return;
      }

      strongSelf.tagRequestInFlight = NO;
      if (error) {
        [strongSelf tl_showMessage:error.localizedDescription ?: @"标签同步失败"];
        return;
      }

      if ([[TLWSDKManager shared].sessionManager shouldAttemptTokenRefreshForCode:output.code]) {
        [[TLWSDKManager shared].sessionManager handleUnauthorizedWithRetry:^{
          [strongSelf tl_submitCultivationTagWithStatus:status content:content tagType:tagType];
        }];
        return;
      }

      if (output.code.integerValue != 200) {
        [strongSelf tl_showMessage:output.message ?: @"标签同步失败"];
        return;
      }
      NSLog(@"服务端标签同步成功, tagType=%@", tagType);
      [strongSelf tl_fetchCropDetailAndRefreshCalendar];
    });
  }];
}

- (void)tl_fetchCropDetailAndRefreshCalendar {
  NSNumber *cropId = self.viewModel.plantModel.plantId;
  if (cropId == nil || cropId.integerValue <= 0) {
    return;
  }

  __weak typeof(self) weakSelf = self;
  [[TLWSDKManager shared] getCropDetailWithId:cropId completionHandler:^(AGResultMyCropResponseDto * output, NSError * error) {
    dispatch_async(dispatch_get_main_queue(), ^{
      __strong typeof(weakSelf) strongSelf = weakSelf;
      if (!strongSelf) {
        return;
      }

      if (error) {
        NSLog(@"[PlantDetail] getCropDetail error: %@", error);
        return;
      }

      if ([[TLWSDKManager shared].sessionManager shouldAttemptTokenRefreshForCode:output.code]) {
        [[TLWSDKManager shared].sessionManager handleUnauthorizedWithRetry:^{
          [strongSelf tl_fetchCropDetailAndRefreshCalendar];
        }];
        return;
      }

      if (output.code.integerValue != 200 || ![output.data isKindOfClass:[AGMyCropResponseDto class]]) {
        NSLog(@"[PlantDetail] getCropDetail invalid response, code=%@ message=%@", output.code, output.message);
        return;
      }
      NSLog(@"[PlantDetail] crop detail success, cropId=%@", cropId);
      NSLog(@"[PlantDetail] crop detail records=%@", output.data.records);
      NSLog(@"[PlantDetail] crop detail watering records=%@", output.data.records[@"WATERING"]);
      NSLog(@"[PlantDetail] crop detail fertilizing records=%@", output.data.records[@"FERTILIZING"]);
      NSLog(@"[PlantDetail] crop detail medication records=%@", output.data.records[@"MEDICATION"]);
      NSLog(@"[PlantDetail] crop detail note records=%@", output.data.records[@"NOTE"]);
      NSLog(@"[PlantDetail] crop detail plantName=%@ status=%@ plantingDate=%@",
            output.data.plantName,
            output.data.status,
            output.data.plantingDate);

      if ([output.data.plantName isKindOfClass:[NSString class]] && output.data.plantName.length > 0) {
        strongSelf.viewModel.plantModel.plantName = output.data.plantName;
      }
      if ([output.data.imageUrl isKindOfClass:[NSString class]] && output.data.imageUrl.length > 0) {
        strongSelf.viewModel.plantModel.imageUrl = output.data.imageUrl;
      }
      strongSelf.viewModel.plantModel.plantStatus = [output.data.status isKindOfClass:[NSString class]] ? output.data.status : @"";
      strongSelf.viewModel.plantModel.plantingDate = output.data.plantingDate;

      [strongSelf.viewModel applyCropDetailResponse:output.data];//将服务端状态合入本地的markedStatusMap
      [strongSelf.detailView configureWithViewModel:strongSelf.viewModel];//刷新数据
    });
  }];
}

@end
