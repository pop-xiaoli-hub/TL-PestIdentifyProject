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
#import "Views/TLWPlantDetailWateringView.h"
#import <SDWebImage/SDWebImage.h>
#import "TLWSDKManager.h"

@interface TLWPlantDetailController ()

@property (nonatomic, strong) TLWPlantDetailView *detailView;
@property (nonatomic, strong) TLWPlantDetailViewModel *viewModel;
@property (nonatomic, assign) BOOL tagRequestInFlight;

@end

@implementation TLWPlantDetailController

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
  [self tl_render];
  [self tl_fetchCropDetailAndRefreshCalendar];
}

- (void)tl_bindActions {
  [self.detailView.backButton addTarget:self action:@selector(tl_backTapped) forControlEvents:UIControlEventTouchUpInside];

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
    [strongSelf.detailView.wateringView configureWithViewModel:strongSelf.viewModel];
  };

  self.detailView.wateringView.nextMonthBlock = ^{
    __strong typeof(weakSelf) strongSelf = weakSelf;
    if (!strongSelf) {
      return;
    }
    [strongSelf.viewModel moveToNextMonth];
    [strongSelf.detailView.wateringView configureWithViewModel:strongSelf.viewModel];
  };

  self.detailView.wateringView.dateSelectionBlock = ^(NSDate *date) {
    __strong typeof(weakSelf) strongSelf = weakSelf;
    if (!strongSelf) {
      return;
    }
    [strongSelf.viewModel selectDate:date];
    [strongSelf.detailView.wateringView configureWithViewModel:strongSelf.viewModel];
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
    [strongSelf tl_submitWateringTagWithStatus:@0 content:@"待浇水"];
  };
}

- (void)tl_render {
  if (self.viewModel.plantModel.localImage) {
    self.detailView.topImageView.image = self.viewModel.plantModel.localImage;
  } else if ([self.viewModel imageURLString].length > 0) {
    [self.detailView.topImageView sd_setImageWithURL:[NSURL URLWithString:[self.viewModel imageURLString]] placeholderImage:[UIImage imageNamed:@"hp_eg1.jpg"]];
  } else {
    self.detailView.topImageView.image = [UIImage imageNamed:@"hp_eg1.jpg"];
  }

  [self.detailView configureWithViewModel:self.viewModel];
}

- (void)tl_backTapped {
  [self.navigationController popViewControllerAnimated:YES];
}

- (void)tl_showMessage:(NSString *)message {
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
  [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
  [self presentViewController:alert animated:YES completion:nil];
}

- (void)tl_submitWateringTagWithStatus:(NSNumber *)status content:(NSString *)content {
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
  request.tagType = @"WATERING";
  request.content = content;
  request.status = status;

  self.tagRequestInFlight = YES;
  __weak typeof(self) weakSelf = self;
  NSLog(@"开始进行服务端浇水信息同步");
  [[TLWSDKManager shared] addTagWithCropId:cropId tagOperationRequest:request completionHandler:^(AGResultVoid * output, NSError * error) {
    dispatch_async(dispatch_get_main_queue(), ^{
      __strong typeof(weakSelf) strongSelf = weakSelf;
      if (!strongSelf) {
        return;
      }

      strongSelf.tagRequestInFlight = NO;
      if (error) {
        [strongSelf tl_showMessage:error.localizedDescription ?: @"浇水标签同步失败"];
        return;
      }

      if (output.code.integerValue == 401) {
        [[TLWSDKManager shared].sessionManager handleUnauthorizedWithRetry:^{
          [strongSelf tl_submitWateringTagWithStatus:status content:content];
        }];
        return;
      }

      if (output.code.integerValue != 200) {
        [strongSelf tl_showMessage:output.message ?: @"浇水标签同步失败"];
        return;
      }
      NSLog(@"浇水服务端信息同步成功");
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

      if (output.code.integerValue == 401) {
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

      NSLog(@"1");
      [strongSelf.viewModel applyCropDetailResponse:output.data];//将服务端状态合入本地的markedStatusMap
      [strongSelf.detailView.wateringView configureWithViewModel:strongSelf.viewModel];//刷新数据
    });
  }];
}

@end
