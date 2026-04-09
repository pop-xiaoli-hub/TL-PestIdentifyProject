//
//  TLWPlantDetailController.m
//  TL-PestIdentify
//

#import "TLWPlantDetailController.h"
#import "../Models/TLWPlantModel.h"
#import "TLWPlantDetailView.h"
#import "ViewModels/TLWPlantDetailViewModel.h"
#import "Views/TLWPlantDetailSegmentTabView.h"
#import "Views/TLWPlantDetailWateringView.h"
#import <SDWebImage/SDWebImage.h>

@interface TLWPlantDetailController ()

@property (nonatomic, strong) TLWPlantDetailView *detailView;
@property (nonatomic, strong) TLWPlantDetailViewModel *viewModel;

@end

@implementation TLWPlantDetailController

- (instancetype)initWithPlantModel:(TLWPlantModel *)plantModel {
  self = [super init];
  if (self) {
    _viewModel = [[TLWPlantDetailViewModel alloc] initWithPlantModel:plantModel];
  }
  return self;
}

- (void)loadView {
  self.detailView = [[TLWPlantDetailView alloc] initWithFrame:[UIScreen mainScreen].bounds];
  self.view = self.detailView;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  self.navigationController.navigationBarHidden = YES;
  [self tl_bindActions];
  [self tl_render];
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
  self.detailView.wateringView.tagActionBlock = ^{
    __strong typeof(weakSelf) strongSelf = weakSelf;
    [strongSelf tl_showMessage:@"已预留“打上标签”业务接口"];
  };
  self.detailView.wateringView.cancelTagActionBlock = ^{
    __strong typeof(weakSelf) strongSelf = weakSelf;
    [strongSelf tl_showMessage:@"已预留“取消标签”业务接口"];
  };
}

- (void)tl_render {
  if (self.viewModel.plantModel.localImage) {
    self.detailView.topImageView.image = self.viewModel.plantModel.localImage;
  } else if ([self.viewModel imageURLString].length > 0) {
    [self.detailView.topImageView sd_setImageWithURL:[NSURL URLWithString:[self.viewModel imageURLString]]
                                    placeholderImage:[UIImage imageNamed:@"hp_eg1.jpg"]];
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

@end
