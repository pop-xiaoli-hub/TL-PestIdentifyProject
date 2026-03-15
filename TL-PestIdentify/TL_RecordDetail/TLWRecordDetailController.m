//
//  TLWRecordDetailController.m
//  TL-PestIdentify
//
//  Created by Tommy on 2026/3/13.
//

#import "TLWRecordDetailController.h"
#import "TLWRecordDetailView.h"
#import <Masonry/Masonry.h>
#import <SDWebImage/UIImageView+WebCache.h>

@interface TLWRecordDetailController ()
@property (nonatomic, strong) TLWRecordDetailView *myView;
@property (nonatomic, strong) TLWRecordItem *item;
@property (nonatomic, assign) NSInteger selectedIndex;
@end

@implementation TLWRecordDetailController

- (instancetype)initWithItem:(TLWRecordItem *)item {
    self = [super init];
    if (self) {
        _item = item;
        _selectedIndex = 0;
        self.hidesBottomBarWhenPushed = YES;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view addSubview:self.myView];
    [self.myView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];

    [self tl_bindActions];
    [self tl_configureView];
}

#pragma mark - Setup

- (void)tl_bindActions {
    [self.myView.backButton addTarget:self
                               action:@selector(tl_back)
                     forControlEvents:UIControlEventTouchUpInside];

    [self.myView.aiButton addTarget:self
                             action:@selector(tl_openAIAssistant)
                   forControlEvents:UIControlEventTouchUpInside];

    for (UIButton *btn in self.myView.tabButtons) {
        [btn addTarget:self
                action:@selector(tl_tabTapped:)
      forControlEvents:UIControlEventTouchUpInside];
    }
}

- (void)tl_configureView {
    // 加载照片
    if (_item.imageURL.length > 0) {
        [self.myView.photoView sd_setImageWithURL:[NSURL URLWithString:_item.imageURL]
                                placeholderImage:nil];
    }

    // 隐藏没有数据的 Tab 按钮（结果数量可能不足 3 个）
    NSArray<UIButton *> *tabs = self.myView.tabButtons;
    for (int i = 0; i < 3; i++) {
        tabs[i].hidden = (i >= (NSInteger)_item.results.count);
    }

    // 展示第一个结果
    [self tl_showResultAtIndex:0 animated:NO];
}

/// 切换展示某个候选结果的内容
- (void)tl_showResultAtIndex:(NSInteger)index animated:(BOOL)animated {
    if (index >= (NSInteger)_item.results.count) return;

    _selectedIndex = index;
    TLWRecordResult *result = _item.results[index];

    [self.myView selectTabAtIndex:index animated:animated];
    self.myView.pestNameLabel.text   = result.pestName;
    self.myView.confidenceLabel.text = [NSString stringWithFormat:@"%.0f%%", result.confidence * 100];
    self.myView.solutionLabel.text   = result.solution;
}

#pragma mark - Actions

- (void)tl_back {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)tl_tabTapped:(UIButton *)sender {
    [self tl_showResultAtIndex:sender.tag animated:YES];
}

- (void)tl_openAIAssistant {
    // TODO: 跳转 AI 助手页面，传入当前病害名称作为预填问题
}

#pragma mark - Lifecycle

- (TLWRecordDetailView *)myView {
    if (!_myView) {
        _myView = [[TLWRecordDetailView alloc] initWithFrame:CGRectZero];
    }
    return _myView;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    // 隐藏系统导航栏后手动恢复右滑返回手势
    self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    self.navigationController.interactivePopGestureRecognizer.delegate = nil;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:NO];
}

@end
