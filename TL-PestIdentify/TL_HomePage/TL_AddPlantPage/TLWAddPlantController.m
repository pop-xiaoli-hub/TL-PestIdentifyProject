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
@property (nonatomic, strong) UITapGestureRecognizer *dismissKeyboardTapGesture;

@end

@implementation TLWAddPlantController

- (void)viewDidLoad {
  [super viewDidLoad];
  self.view.backgroundColor = [UIColor clearColor];

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
  [self tl_setupDismissKeyboardGesture];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [self.navigationController setNavigationBarHidden:YES animated:animated];
  self.navigationController.interactivePopGestureRecognizer.delegate = nil;
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
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

- (void)tl_setupDismissKeyboardGesture {
  UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tl_dismissKeyboard)];
  tapGesture.cancelsTouchesInView = NO;
  [self.view addGestureRecognizer:tapGesture];
  self.dismissKeyboardTapGesture = tapGesture;
}

- (void)tl_dismissKeyboard {
  [self.view endEditing:YES];
}

@end
