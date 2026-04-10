//
//  TLWIdentifyResultController.m
//  TL-PestIdentify
//
//  Created by xiaoli pop on 2026/4/3.
//

#import "TLWIdentifyResultController.h"
#import "TLWIdentifyResultView.h"
#import "TLWIdentifyPageController.h"
#import "TLWAIAssistantController.h"
#import <Masonry/Masonry.h>

@interface TLWIdentifyResultController ()

@property (nonatomic, strong) TLWIdentifyResultView *myView;
@property (nonatomic, assign) BOOL didApplyInitialTabSelection;

@end

@implementation TLWIdentifyResultController

- (instancetype)init {
  self = [super init];
  if (self) {
    // 拍照识图结果页固定按设计稿展示，不复用“识别记录”样式。
    _layoutStyleFlag = 1;
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  self.view.backgroundColor = [UIColor blackColor];

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

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [self.navigationController setNavigationBarHidden:YES animated:animated];
  self.navigationController.interactivePopGestureRecognizer.delegate = nil;
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
}

- (void)tl_backTapped {
  if (self.navigationController) {
    [self.navigationController popViewControllerAnimated:YES];
  } else {
    [self dismissViewControllerAnimated:YES completion:nil];
  }
}

- (void)tl_retakeTapped {
  for (UIViewController *controller in [self.navigationController.viewControllers reverseObjectEnumerator]) {
    if (![controller isKindOfClass:[TLWIdentifyPageController class]]) {
      continue;
    }

    TLWIdentifyPageController *identifyController = (TLWIdentifyPageController *)controller;
    [identifyController prepareForRetakeCapture];
    [self.navigationController popToViewController:identifyController animated:YES];
    return;
  }

  [self tl_backTapped];
}

- (void)tl_aiTapped {
  NSString *pestName = [self.myView currentPestName];
  NSString *confidence = [self.myView currentConfidenceText];
  NSString *advice = [self.myView currentAdviceText];
  NSString *question = nil;

  if (pestName.length > 0) {
    NSMutableArray<NSString *> *parts = [NSMutableArray array];
    [parts addObject:[NSString stringWithFormat:@"请围绕“%@”给我一份更详细的病虫害分析和处理建议。", pestName]];
    if (confidence.length > 0) {
      [parts addObject:[NSString stringWithFormat:@"当前识别置信度：%@。", confidence]];
    }
    if (advice.length > 0) {
      [parts addObject:[NSString stringWithFormat:@"当前识图页给出的建议是：%@。", advice]];
    }
    [parts addObject:@"请按“可能原因、继续观察点、推荐处理步骤、用药/护理注意事项”展开说明。"];
    question = [parts componentsJoinedByString:@""];
  }

  TLWAIAssistantController *assistantController = [[TLWAIAssistantController alloc] initWithInitialQuestion:question];
  assistantController.hidesBottomBarWhenPushed = YES;
  [self.navigationController pushViewController:assistantController animated:YES];
}

- (void)tl_tabTapped:(UIButton *)sender {
  [self.myView selectTabAtIndex:sender.tag animated:YES];
}

@end
