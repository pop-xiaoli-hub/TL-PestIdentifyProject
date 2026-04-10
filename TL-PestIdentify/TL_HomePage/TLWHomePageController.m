//
//  TLWHomePageController.m
//  TL-PestIdentify
//
//  Created by xiaoli pop on 2026/3/9.
//

#import "TLWHomePageController.h"
#import "TLWHomePageView.h"
#import "TLWHomeCardCell.h"
#import "TLWHomeCustomCell.h"
#import "Models/TLWPlantModel.h"
#import "TL_AddPlantPage/TLWAddPlantController.h"
#import "TL_PlantDetailPage/TLWPlantDetailController.h"
#import "TLWIdentifyPageController.h"
#import "TLWRecordController.h"
#import "TLWAIAssistantController.h"
#import "TLWWarningModel.h"
#import "TLWSDKManager.h"
#import <Masonry.h>
#import <SDWebImage/SDWebImage.h>

extern NSString * const TLWAvatarDidUpdateNotification;
extern NSString * const TLWProfileDidUpdateNotification;

@interface TLWHomePageController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) TLWHomePageView *homePageView;
@property (nonatomic, assign) BOOL warningExpanded;
@property (nonatomic, strong) NSMutableArray<TLWPlantModel *> *managedPlants;
@property (nonatomic, assign) BOOL isLoadingCrops;

@end

@implementation TLWHomePageController


- (void)viewDidLoad {
  [super viewDidLoad];
  [self tl_setHomePageBackView];
  [self tl_setupHomePageView];
  self.managedPlants = [NSMutableArray array];
  [self applyProfile];
  [self tl_fetchMyCrops];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(onProfileUpdated)
                                               name:TLWProfileDidUpdateNotification
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(onAvatarUpdated:)
                                               name:TLWAvatarDidUpdateNotification
                                             object:nil];
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)onProfileUpdated {
  [self applyProfile];
}

- (void)applyProfile {
  AGUserProfileDto *profile = [TLWSDKManager shared].sessionManager.cachedProfile;
  NSString *name = profile.fullName ?: profile.username;
  [self.homePageView configureWithUserName:name];
  if (profile.avatarUrl.length > 0) {
    [self.homePageView.userAvatarImageView sd_setImageWithURL:[NSURL URLWithString:profile.avatarUrl]];
  } else {
    self.homePageView.userAvatarImageView.image = nil;
  }
}

- (void)onAvatarUpdated:(NSNotification *)noti {
  UIImage *avatar = noti.userInfo[@"avatar"];
  if (avatar) self.homePageView.userAvatarImageView.image = avatar;
}

- (void)tl_setHomePageBackView {
  UIImage* image = [UIImage imageNamed:@"hp_backView.png"];
  self.view.layer.contents = (__bridge id)image.CGImage;
}

- (void)tl_setupHomePageView {
  self.homePageView.backgroundColor = [UIColor clearColor];
  [self.view addSubview:self.homePageView];
  [self.homePageView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.edges.equalTo(self.view);
  }];
  UITableView *tableView = self.homePageView.tableView;
  tableView.delegate = self;
  tableView.dataSource = self;
  tableView.estimatedRowHeight = 180;
  [tableView registerClass:[TLWHomeCardCell class] forCellReuseIdentifier:@"kTLWHomeCardCellIdentifier1"];
  [tableView registerClass:[TLWHomeCardCell class] forCellReuseIdentifier:@"kTLWHomeCardCellIdentifier2"];
  [tableView registerClass:[TLWHomeCustomCell class] forCellReuseIdentifier:@"kTLWHomeCustomCellIdentifier"];
  tableView.estimatedRowHeight = 160.0;
}

- (TLWHomePageView *)homePageView {
  if (!_homePageView) {
    _homePageView = [[TLWHomePageView alloc] initWithFrame:CGRectZero];
  }
  return _homePageView;
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return 3 + self.managedPlants.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  if (indexPath.row == 0) {
    TLWHomeCardCell *cell = [tableView dequeueReusableCellWithIdentifier:@"kTLWHomeCardCellIdentifier1" forIndexPath:indexPath];
    NSString* str = @"预计24小时内,我区地面最低温将降至-5℃以下,农作物面临严重冻害风险。请农户立即…面最低预计24小时内,我区地面最低温将降至-5℃以下,农作物面临严重冻害风险。请农户立即…面最低预计24小时内,我区地面最低温将降至-5℃以下,农作物面临严重冻害风险。请农户立即…面最低预计24小时内,我区地面最低温将降至-5℃以下,农作物面临严重冻害风险。请农户立即…面最低";
    TLWWarningModel* textModel = [[TLWWarningModel alloc] init];
    textModel.string = str;
    // 注意：此时 cell 还没布局，bodyLabel.frame.width 为 0，不能直接使用
    // 用 tableView 宽度减去左右内边距，近似计算 bodyLabel 可用宽度
    CGFloat tableWidth = CGRectGetWidth(tableView.bounds);
    // contentView 左右各 16，正文内部左 16、右 8，对应 TLWHomeCardCell 中的约束
    CGFloat bodyWidth = tableWidth - 16.0 - 16.0 - 16.0 - 8.0;
    textModel.shouldExpand = [self isTextViewExceedThreeLines:str width:bodyWidth];
    [cell tl_configureWithWarning:textModel];
    [cell tl_configureWarningExpanded:self.warningExpanded];
    __weak typeof(self) weakSelf = self;
    cell.clickWarningDetail = ^{
      __strong typeof(weakSelf) strongSelf = weakSelf;
      if (!strongSelf) {
        return;
      }
      strongSelf.warningExpanded = !strongSelf.warningExpanded;
      NSIndexPath *ip = [NSIndexPath indexPathForRow:0 inSection:0];
      [tableView beginUpdates];
      [tableView reloadRowsAtIndexPaths:@[ip] withRowAnimation:UITableViewRowAnimationNone];
      [tableView endUpdates];
    };
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
  } else if (indexPath.row == 1) {
    TLWHomeCardCell *cell = [tableView dequeueReusableCellWithIdentifier:@"kTLWHomeCardCellIdentifier2" forIndexPath:indexPath];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    __weak typeof(self) weakSelf = self;
    cell.clickPhotoIdentification = ^{
      TLWIdentifyPageController* identifyViewController = [[TLWIdentifyPageController alloc] init];
      identifyViewController.hidesBottomBarWhenPushed = YES;
      [weakSelf.navigationController pushViewController:identifyViewController animated:YES];
    };
    cell.clickRecordCard = ^{
      TLWRecordController *recordVC = [[TLWRecordController alloc] init];
      recordVC.hidesBottomBarWhenPushed = YES;
      [weakSelf.navigationController pushViewController:recordVC animated:YES];
    };
    cell.clickAIAssistant = ^{
      TLWAIAssistantController *aiVC = [[TLWAIAssistantController alloc] initWithInitialQuestion:nil];
      [weakSelf.navigationController pushViewController:aiVC animated:YES];
    };
    return cell;
  }
  TLWHomeCustomCell *cell = [tableView dequeueReusableCellWithIdentifier:@"kTLWHomeCustomCellIdentifier" forIndexPath:indexPath];
  __weak typeof(self) weakSelf = self;
  if (indexPath.row == 2) {
    [cell configureAsCreateCellWithLocationName:nil];
    cell.clickCreateButton = ^{
      __strong typeof(weakSelf) strongSelf = weakSelf;
      if (!strongSelf) {
        return;
      }
      [strongSelf tl_openAddPlantController];
    };
    cell.clickContentCard = ^{
      __strong typeof(weakSelf) strongSelf = weakSelf;
      if (!strongSelf) {
        return;
      }
      [strongSelf tl_openAddPlantController];
    };
  } else {
    NSInteger plantIndex = indexPath.row - 3;
    if (plantIndex >= 0 && plantIndex < self.managedPlants.count) {
      TLWPlantModel *plantModel = self.managedPlants[plantIndex];
      [cell configureWithPlantModel:plantModel locationName:nil];
      cell.clickContentCard = ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
          return;
        }
        if (plantModel.isUploading) {
          [strongSelf tl_showMessageAlert:@"正在上传"];
        } else {
          TLWPlantDetailController *detailController = [[TLWPlantDetailController alloc] initWithPlantModel:plantModel];
          detailController.hidesBottomBarWhenPushed = YES;
          [strongSelf.navigationController pushViewController:detailController animated:YES];
        }
      };
    }
    cell.clickCreateButton = nil;
  }
  cell.selectionStyle = UITableViewCellSelectionStyleNone;
  return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  if (indexPath.row == 0) {
    return UITableViewAutomaticDimension;
  } else if (indexPath.row == 1) {
    // 功能入口卡片（拍照识别区域需要更高，保证正方形比例和留白）
    return 210.0;
  } else {
    // 新建植物卡和已添加植物卡
    return 300.0;
  }
}

- (void)tl_openAddPlantController {
  __weak typeof(self) weakSelf = self;
  TLWAddPlantController *controller = [[TLWAddPlantController alloc] init];
  controller.onConfirmAddPlant = ^(NSString *plantName, UIImage *plantImage) {
    __strong typeof(weakSelf) strongSelf = weakSelf;
    if (!strongSelf) {
      return;
    }
    TLWPlantModel *plantModel = [[TLWPlantModel alloc] initWithPlantName:plantName image:plantImage];
    [strongSelf.managedPlants insertObject:plantModel atIndex:0];
    [strongSelf.homePageView.tableView reloadData];
    [strongSelf tl_uploadPlantModel:plantModel];
  };
  controller.hidesBottomBarWhenPushed = YES;
  [self.navigationController pushViewController:controller animated:YES];
}

- (void)tl_fetchMyCrops {
  if (self.isLoadingCrops) {
    return;
  }
  self.isLoadingCrops = YES;

  __weak typeof(self) weakSelf = self;
  [[TLWSDKManager shared] getMyCropsWithCompletionHandler:^(AGResultListMyCropResponseDto * output, NSError * error) {
    dispatch_async(dispatch_get_main_queue(), ^{
      __strong typeof(weakSelf) strongSelf = weakSelf;
      if (!strongSelf) {
        return;
      }

      strongSelf.isLoadingCrops = NO;
      if (error || output.code.integerValue != 200) {
        return;
      }

      NSMutableArray<TLWPlantModel *> *plants = [NSMutableArray array];
      for (AGMyCropResponseDto *crop in output.data) {
        if (![crop isKindOfClass:[AGMyCropResponseDto class]]) {
          continue;
        }

        TLWPlantModel *plantModel = [[TLWPlantModel alloc] initWithCropResponse:crop];
        [plants addObject:plantModel];
      }

      NSMutableArray<TLWPlantModel *> *pendingPlants = [NSMutableArray array];
      for (TLWPlantModel *localPlant in strongSelf.managedPlants) {
        if (localPlant.isUploading) {
          [pendingPlants addObject:localPlant];
        }
      }

      NSMutableArray<TLWPlantModel *> *mergedPlants = [NSMutableArray arrayWithArray:pendingPlants];
      [mergedPlants addObjectsFromArray:plants];
      strongSelf.managedPlants = mergedPlants;
      [strongSelf.homePageView.tableView reloadData];
    });
  }];
}

- (void)tl_uploadPlantModel:(TLWPlantModel *)plantModel {
  NSData *imageData = UIImageJPEGRepresentation(plantModel.localImage, 0.9);
  if (imageData.length == 0) {
    plantModel.isUploading = NO;
    [self.homePageView.tableView reloadData];
    [self tl_showMessageAlert:@"图片处理失败，请重新选择"];
    return;
  }

  NSString *fileName = [NSString stringWithFormat:@"plant_%@.jpg", [[NSUUID UUID] UUIDString]];
  NSString *tempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];
  BOOL writeSuccess = [imageData writeToFile:tempPath atomically:YES];
  if (!writeSuccess) {
    plantModel.isUploading = NO;
    [self.homePageView.tableView reloadData];
    [self tl_showMessageAlert:@"图片处理失败，请稍后重试"];
    return;
  }

  NSURL *fileURL = [NSURL fileURLWithPath:tempPath];
  __weak typeof(self) weakSelf = self;
  [[TLWSDKManager shared] uploadFileWithFile:fileURL prefix:@"crop/" completionHandler:^(AGResultString * output, NSError * error) {
    dispatch_async(dispatch_get_main_queue(), ^{
      __strong typeof(weakSelf) strongSelf = weakSelf;
      [[NSFileManager defaultManager] removeItemAtPath:tempPath error:nil];
      if (!strongSelf) {
        return;
      }

      NSString *imageURL = output.data;
      if (error || output.code.integerValue != 200 || imageURL.length == 0) {
        plantModel.isUploading = NO;
        [strongSelf.homePageView.tableView reloadData];
        NSString *message = error.localizedDescription ?: output.message;
        [strongSelf tl_showMessageAlert:message.length > 0 ? message : @"图片上传失败，请稍后重试"];
        return;
      }

      AGMyCropCreateRequest *request = [[AGMyCropCreateRequest alloc] init];
      request.plantName = plantModel.plantName;
      request.imageUrl = imageURL;
      request.status = @"正常";
      request.pestCount = @0;

      [[TLWSDKManager shared] createCropWithRequest:request completionHandler:^(AGResultMyCropResponseDto * output, NSError * error) {
        dispatch_async(dispatch_get_main_queue(), ^{
          __strong typeof(weakSelf) innerSelf = weakSelf;
          if (!innerSelf) {
            return;
          }

          plantModel.isUploading = NO;
          if (error || output.code.integerValue != 200) {
            NSString *message = error.localizedDescription ?: output.message;
            [innerSelf tl_showMessageAlert:message.length > 0 ? message : @"新作物创建失败，请稍后重试"];
            [innerSelf.homePageView.tableView reloadData];
            return;
          }

          plantModel.plantId = output.data._id ?: plantModel.plantId;
          plantModel.plantName = output.data.plantName.length > 0 ? output.data.plantName : plantModel.plantName;
          plantModel.imageUrl = output.data.imageUrl.length > 0 ? output.data.imageUrl : imageURL;
          plantModel.localImage = nil;
          [innerSelf.homePageView.tableView reloadData];
        });
      }];
    });
  }];
}

- (void)tl_showMessageAlert:(NSString *)message {
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
  [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
  [self presentViewController:alert animated:YES completion:nil];
}


- (BOOL)isTextViewExceedThreeLines:(NSString *)text width:(CGFloat)width {
  NSTextStorage *storage = [[NSTextStorage alloc] initWithString:text attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:16]}];//管理文本内容和属性
  NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];//将字符转换为字形，管理文本的布局过程
  NSTextContainer *container = [[NSTextContainer alloc] initWithSize:CGSizeMake(width, CGFLOAT_MAX)];//定义文本的可占据区域
  container.lineFragmentPadding = 0;
  [layoutManager addTextContainer:container];
  [storage addLayoutManager:layoutManager];
  NSUInteger glyphCount = [layoutManager numberOfGlyphs];
  __block NSInteger lines = 0;
  [layoutManager enumerateLineFragmentsForGlyphRange:NSMakeRange(0, glyphCount) usingBlock:^(CGRect rect, CGRect usedRect, NSTextContainer * _Nonnull textContainer, NSRange glyphRange, BOOL * _Nonnull stop) {
    lines++;
    if (lines > 3) {
      *stop = YES;
    }
  }];
  return lines > 3;
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
