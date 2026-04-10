//
//  TLWNotificationController.m
//  TL-PestIdentify
//

#import "TLWNotificationController.h"
#import "TLWNotificationView.h"
#import "TLWNotificationCell.h"
#import "TLWNotificationItem.h"
#import "TLWSDKManager.h"
#import "TLWToast.h"
#import <Masonry/Masonry.h>

static NSString *const kNotifCellID = @"TLWNotificationCell";

@interface TLWNotificationController () <UITableViewDataSource, UITableViewDelegate, TLWNotificationCellDelegate>

@property (nonatomic, strong) TLWNotificationView           *myView;
@property (nonatomic, strong) NSArray<TLWNotificationItem *> *systemItems;
@property (nonatomic, strong) NSArray<TLWNotificationItem *> *alertItems;
@property (nonatomic, strong) NSArray<TLWNotificationItem *> *allItems;
@property (nonatomic, strong) NSArray<TLWNotificationItem *> *filteredItems;
@property (nonatomic, assign) NSInteger                       selectedTabIndex;
@property (nonatomic, assign) NSInteger                       initialTab;

@end

@implementation TLWNotificationController

- (instancetype)initWithInitialTab:(NSInteger)tab {
    self = [super init];
    if (self) {
        _initialTab = tab;
    }
    return self;
}

- (NSString *)navTitle { return @"通知"; }
- (NSString *)navTitleIconName { return @"iconNotification2"; }

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.view addSubview:self.myView];
    [self.myView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    [self.view bringSubviewToFront:self.navBar];

    for (UIButton *btn in self.myView.tabButtons) {
        [btn addTarget:self action:@selector(tl_tabTapped:) forControlEvents:UIControlEventTouchUpInside];
    }

    self.myView.tableView.dataSource = self;
    self.myView.tableView.delegate   = self;
    [self.myView.tableView registerClass:[TLWNotificationCell class] forCellReuseIdentifier:kNotifCellID];

    self.systemItems   = @[];
    self.alertItems    = @[];
    self.allItems      = @[];
    self.filteredItems = @[];
    self.selectedTabIndex = _initialTab;

    [self tl_applyTabColor];
    [self fetchMessages];
}

#pragma mark - Fetch

- (void)fetchMessages {
    [[TLWSDKManager shared].api getMyMessagesWithPage:@0
                                                 size:@50
                                    completionHandler:^(AGResultMessageGroupResponseDto *output, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error || output.code.integerValue != 200) {
                if (!error && output.code.integerValue == 401) {
                    [[TLWSDKManager shared].sessionManager handleUnauthorizedWithRetry:^{ [self fetchMessages]; }];
                    return;
                }
                [TLWToast show:@"消息加载失败"];
                return;
            }

            AGMessageGroupResponseDto *data = output.data;

            NSMutableArray *sysItems   = [NSMutableArray array];
            NSMutableArray *alertItems = [NSMutableArray array];

            for (AGMessageResponseDto *dto in data.systemMessages.list) {
                [sysItems addObject:[TLWNotificationItem itemFromDto:dto]];
            }
            for (AGMessageResponseDto *dto in data.alertMessages.list) {
                [alertItems addObject:[TLWNotificationItem itemFromDto:dto]];
            }

            self.systemItems = [sysItems copy];
            self.alertItems  = [alertItems copy];

            // 全部 = system + alert 合并，按时间倒序
            NSMutableArray *all = [NSMutableArray arrayWithArray:sysItems];
            [all addObjectsFromArray:alertItems];
            [all sortUsingComparator:^NSComparisonResult(TLWNotificationItem *a, TLWNotificationItem *b) {
                if (!a.createdAt) return NSOrderedDescending;
                if (!b.createdAt) return NSOrderedAscending;
                return [b.createdAt compare:a.createdAt];
            }];
            self.allItems = [all copy];

            [self tl_filterByTab:self.selectedTabIndex];
        });
    }];
}

#pragma mark - Tab

- (void)tl_tabTapped:(UIButton *)sender {
    NSInteger idx = sender.tag;
    if (idx == self.selectedTabIndex) return;
    self.selectedTabIndex = idx;
    [self tl_applyTabColor];
    [self tl_filterByTab:idx];
}

- (void)tl_applyTabColor {
    UIColor *activeColor   = [UIColor colorWithRed:0.016 green:0.678 blue:0.780 alpha:1];
    UIColor *inactiveColor = [UIColor colorWithRed:0.38  green:0.38  blue:0.38  alpha:1];
    for (UIButton *btn in self.myView.tabButtons) {
        [btn setTitleColor:(btn.tag == self.selectedTabIndex ? activeColor : inactiveColor)
                 forState:UIControlStateNormal];
    }
}

- (void)tl_filterByTab:(NSInteger)idx {
    switch (idx) {
        case 0:  self.filteredItems = self.allItems;    break;
        case 1:  self.filteredItems = self.systemItems; break;
        case 2:  self.filteredItems = self.alertItems;  break;
        default: self.filteredItems = @[];              break; // 用户调研暂无数据
    }
    [self.myView.tableView reloadData];
}

#pragma mark - Actions

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.filteredItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TLWNotificationCell *cell = [tableView dequeueReusableCellWithIdentifier:kNotifCellID forIndexPath:indexPath];
    cell.delegate = self;
    [cell configureWithItem:self.filteredItems[indexPath.row]];
    return cell;
}

#pragma mark - UITableViewDelegate

- (UIEdgeInsets)tableView:(UITableView *)tableView layoutMarginsForCell:(UITableViewCell *)cell {
    return UIEdgeInsetsZero;
}

#pragma mark - TLWNotificationCellDelegate

- (void)notificationCellDidToggleExpand:(TLWNotificationCell *)cell {
    NSIndexPath *indexPath = [self.myView.tableView indexPathForCell:cell];
    if (!indexPath) return;

    TLWNotificationItem *item = self.filteredItems[indexPath.row];
    item.isExpanded = !item.isExpanded;

    // 展开时标记已读（乐观更新，失败回滚）
    if (item.isExpanded && item.hasUnread && item.messageId) {
        item.hasUnread = NO;
        NSNumber *msgId = item.messageId;
        NSIndexPath *currentIndexPath = indexPath;
        __weak typeof(self) weakSelf = self;
        [[TLWSDKManager shared].api markAsReadWithId:msgId
                                   completionHandler:^(AGResultVoid *output, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (error) {
                    // 网络失败，回滚未读状态
                    item.hasUnread = YES;
                    [weakSelf.myView.tableView reloadRowsAtIndexPaths:@[currentIndexPath]
                                                     withRowAnimation:UITableViewRowAnimationNone];
                    return;
                }
                if (output.code.integerValue == 401) {
                    [[TLWSDKManager shared].sessionManager handleUnauthorizedWithRetry:^{
                        [[TLWSDKManager shared].api markAsReadWithId:msgId
                                                   completionHandler:^(AGResultVoid *o, NSError *e) {
                            if (e || o.code.integerValue != 200) {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    item.hasUnread = YES;
                                    [weakSelf.myView.tableView reloadRowsAtIndexPaths:@[currentIndexPath]
                                                                     withRowAnimation:UITableViewRowAnimationNone];
                                });
                            }
                        }];
                    }];
                    return;
                }
                if (output.code.integerValue != 200) {
                    // 服务端返回非 200，回滚
                    item.hasUnread = YES;
                    [weakSelf.myView.tableView reloadRowsAtIndexPaths:@[currentIndexPath]
                                                     withRowAnimation:UITableViewRowAnimationNone];
                }
            });
        }];
    }

    [self.myView.tableView beginUpdates];
    [self.myView.tableView reloadRowsAtIndexPaths:@[indexPath]
                                 withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.myView.tableView endUpdates];
}

#pragma mark - Lazy

- (TLWNotificationView *)myView {
    if (!_myView) {
        _myView = [[TLWNotificationView alloc] initWithFrame:CGRectZero];
    }
    return _myView;
}

@end
