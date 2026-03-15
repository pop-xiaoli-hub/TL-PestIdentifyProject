//
//  TLWNotificationController.m
//  TL-PestIdentify
//

#import "TLWNotificationController.h"
#import "TLWNotificationView.h"
#import "TLWNotificationCell.h"
#import "TLWNotificationItem.h"
#import <Masonry/Masonry.h>

static NSString *const kNotifCellID = @"TLWNotificationCell";

@interface TLWNotificationController () <UITableViewDataSource, UITableViewDelegate, TLWNotificationCellDelegate>

@property (nonatomic, strong) TLWNotificationView          *myView;
@property (nonatomic, strong) NSArray<TLWNotificationItem *> *allItems;
@property (nonatomic, strong) NSArray<TLWNotificationItem *> *filteredItems;
@property (nonatomic, assign) NSInteger                      selectedTabIndex;

@end

@implementation TLWNotificationController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.view addSubview:self.myView];
    [self.myView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];

    // Wire back button
    [self.myView.backButton addTarget:self
                               action:@selector(tl_back)
                     forControlEvents:UIControlEventTouchUpInside];

    // Wire tab buttons
    for (UIButton *btn in self.myView.tabButtons) {
        [btn addTarget:self
                action:@selector(tl_tabTapped:)
      forControlEvents:UIControlEventTouchUpInside];
    }

    // Table view
    self.myView.tableView.dataSource = self;
    self.myView.tableView.delegate   = self;
    [self.myView.tableView registerClass:[TLWNotificationCell class]
                  forCellReuseIdentifier:kNotifCellID];

    // Load mock data
    self.allItems      = [TLWNotificationItem mockItems];
    self.filteredItems = self.allItems;
    self.selectedTabIndex = 0;
    [self.myView.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    // Re-enable swipe-back even with hidden system nav bar
    self.navigationController.interactivePopGestureRecognizer.delegate = nil;
    self.navigationController.interactivePopGestureRecognizer.enabled  = YES;
}

#pragma mark - Actions

- (void)tl_back {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)tl_tabTapped:(UIButton *)sender {
    NSInteger idx = sender.tag;
    if (idx == self.selectedTabIndex) return;
    self.selectedTabIndex = idx;

    UIColor *activeColor   = [UIColor colorWithRed:0.016 green:0.678 blue:0.780 alpha:1];
    UIColor *inactiveColor = [UIColor colorWithRed:0.38  green:0.38  blue:0.38  alpha:1];
    for (UIButton *btn in self.myView.tabButtons) {
        [btn setTitleColor:(btn.tag == idx ? activeColor : inactiveColor)
                 forState:UIControlStateNormal];
    }

    if (idx == 0) {
        self.filteredItems = self.allItems;
    } else {
        TLWNotificationTag target = (TLWNotificationTag)idx;
        self.filteredItems = [self.allItems filteredArrayUsingPredicate:
            [NSPredicate predicateWithBlock:^BOOL(TLWNotificationItem *item, NSDictionary *b) {
                return item.tag == target;
            }]];
    }
    [self.myView.tableView reloadData];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.filteredItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TLWNotificationCell *cell = [tableView dequeueReusableCellWithIdentifier:kNotifCellID
                                                                forIndexPath:indexPath];
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
