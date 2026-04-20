//
//  TLWRecordDetailController.m
//  TL-PestIdentify
//
//  Created by Tommy on 2026/3/13.
//

#import "TLWRecordDetailController.h"
#import "TLWRecordDetailView.h"
#import "TLWAIAssistantController.h"
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

- (NSString *)navTitle { return @"识别记录"; }
- (NSString *)navTitleIconName { return @"records"; }

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view addSubview:self.myView];
    [self.myView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    self.navBar.hidden = YES;

    [self tl_bindActions];
    [self tl_configureView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    self.navBar.hidden = YES;
}

#pragma mark - Setup

- (void)tl_bindActions {
    [self.myView.backButton addTarget:self
                               action:@selector(tl_backTapped)
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

    [self.myView configureWithResults:self.item.results ?: @[]];

    // 展示第一个结果
    [self tl_showResultAtIndex:0 animated:NO];
}

/// 切换展示某个候选结果的内容
- (void)tl_showResultAtIndex:(NSInteger)index animated:(BOOL)animated {
    if (index >= (NSInteger)_item.results.count) return;

    _selectedIndex = index;
    [self.myView selectTabAtIndex:index animated:animated];
}

#pragma mark - Actions

- (void)tl_backTapped {
    if (self.navigationController) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)tl_tabTapped:(UIButton *)sender {
    [self tl_showResultAtIndex:sender.tag animated:YES];
}

- (void)tl_openAIAssistant {
    TLWRecordResult *result = (_selectedIndex < (NSInteger)_item.results.count) ? _item.results[_selectedIndex] : nil;
    NSString *question = result.pestName.length > 0 ? result.pestName : @"帮我分析这条识别记录";
    TLWAIAssistantController *aiVC = [[TLWAIAssistantController alloc] initWithInitialQuestion:question];
    [self.navigationController pushViewController:aiVC animated:YES];
}

#pragma mark - Lifecycle

- (TLWRecordDetailView *)myView {
    if (!_myView) {
        _myView = [[TLWRecordDetailView alloc] initWithFrame:CGRectZero];
    }
    return _myView;
}


@end
