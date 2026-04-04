//
//  TLWAddPlantController.m
//  TL-PestIdentify
//
//  Created by xiaoli pop on 2026/4/2.
//

#import "TLWAddPlantController.h"
#import "TLWAddPlantView.h"
#import <Masonry/Masonry.h>

@interface TLWAddPlantController ()

@property (nonatomic, strong) TLWAddPlantView *myView;

@end

@implementation TLWAddPlantController

- (void)viewDidLoad {
  [super viewDidLoad];
  self.view.backgroundColor = [UIColor clearColor];
  self.navigationController.navigationBarHidden = YES;

  TLWAddPlantView *myView = [[TLWAddPlantView alloc] initWithFrame:CGRectZero];
  [self.view addSubview:myView];
  [myView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.edges.equalTo(self.view);
  }];
  self.myView = myView;

  [self.myView.backButton addTarget:self action:@selector(tl_backTapped) forControlEvents:UIControlEventTouchUpInside];
  [self.myView.createButton addTarget:self action:@selector(tl_createTapped) forControlEvents:UIControlEventTouchUpInside];
  [self.myView.contentCardButton addTarget:self action:@selector(tl_addImageTapped) forControlEvents:UIControlEventTouchUpInside];
  [self.myView.confirmButton addTarget:self action:@selector(tl_confirmTapped) forControlEvents:UIControlEventTouchUpInside];
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  self.navigationController.navigationBarHidden = NO;
}

- (void)tl_backTapped {
  if (self.navigationController) {
    [self.navigationController popViewControllerAnimated:YES];
  } else {
    [self dismissViewControllerAnimated:YES completion:nil];
  }
}

- (void)tl_createTapped {
  NSLog(@"[AddPlant] 新建按钮点击");
}

- (void)tl_addImageTapped {
  NSLog(@"[AddPlant] 添加图片卡片点击");
}

- (void)tl_confirmTapped {
  NSLog(@"[AddPlant] 确认按钮点击，当前植物名：%@", self.myView.plantNameTextField.text ?: @"");
}

@end
