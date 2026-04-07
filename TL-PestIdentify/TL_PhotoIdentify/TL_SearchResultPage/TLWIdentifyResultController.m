//
//  TLWIdentifyResultController.m
//  TL-PestIdentify
//
//  Created by xiaoli pop on 2026/4/3.
//

#import "TLWIdentifyResultController.h"
#import "TLWIdentifyResultView.h"
#import <Masonry/Masonry.h>

@interface TLWIdentifyResultController ()

@property (nonatomic, strong) TLWIdentifyResultView *myView;
@property (nonatomic, assign) BOOL didApplyInitialTabSelection;

@end

@implementation TLWIdentifyResultController

- (instancetype)init {
  self = [super init];
  if (self) {
    _layoutStyleFlag = 0;
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  self.view.backgroundColor = [UIColor blackColor];
  self.navigationController.navigationBarHidden = YES;

  TLWIdentifyResultView *myView = [[TLWIdentifyResultView alloc] initWithFrame:CGRectZero];
  [self.view addSubview:myView];
  [myView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.edges.equalTo(self.view);
  }];
  self.myView = myView;

  [self.myView.backButton addTarget:self action:@selector(tl_backTapped) forControlEvents:UIControlEventTouchUpInside];
  [self.myView.retakeButton addTarget:self action:@selector(tl_retakeTapped) forControlEvents:UIControlEventTouchUpInside];
  [self.myView.aiButton addTarget:self action:@selector(tl_aiTapped) forControlEvents:UIControlEventTouchUpInside];

  [self.myView.tabButtons enumerateObjectsUsingBlock:^(UIButton * _Nonnull button, NSUInteger idx, BOOL * _Nonnull stop) {
    [button addTarget:self action:@selector(tl_tabTapped:) forControlEvents:UIControlEventTouchUpInside];
  }];

  [self.myView applyLayoutStyleFlag:self.layoutStyleFlag];
  [self.myView configureWithImage:self.image results:self.identifyResults ?: @[]];
}

- (void)viewDidLayoutSubviews {
  [super viewDidLayoutSubviews];
  if (!self.didApplyInitialTabSelection) {
    self.didApplyInitialTabSelection = YES;
    [self.myView selectTabAtIndex:0 animated:NO];
  }
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

- (void)tl_retakeTapped {
  NSLog(@"[IdentifyResult] 重新拍摄点击");
}

- (void)tl_aiTapped {
  NSLog(@"[IdentifyResult] AI 助手点击");
}

- (void)tl_tabTapped:(UIButton *)sender {
  [self.myView selectTabAtIndex:sender.tag animated:YES];
}

@end
