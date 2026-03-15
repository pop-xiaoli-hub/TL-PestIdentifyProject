//
//  TLWMessageController.m
//  TL-PestIdentify
//

#import "TLWMessageController.h"
#import "TLWMessageView.h"
#import "TLWMessageCell.h"
#import "TLWMessageItem.h"
#import "TLWNotificationController.h"
#import <Masonry/Masonry.h>

static NSString *const kMessageCellID = @"TLWMessageCell";

@interface TLWMessageController () <UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, strong) TLWMessageView *myView;
@property (nonatomic, strong) NSArray<TLWMessageItem *> *items;

@end

@implementation TLWMessageController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.myView];
    [self.myView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];

    self.myView.tableView.dataSource = self;
    self.myView.tableView.delegate = self;
    [self.myView.tableView registerClass:[TLWMessageCell class] forCellReuseIdentifier:kMessageCellID];

    // TODO: 接口接入后替换 mock 数据
    self.items = [TLWMessageItem mockItems];
    [self.myView.tableView reloadData];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TLWMessageCell *cell = [tableView dequeueReusableCellWithIdentifier:kMessageCellID forIndexPath:indexPath];
    [cell configureWithItem:self.items[indexPath.row]];
    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 72;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    TLWMessageItem *item = self.items[indexPath.row];
    if (item.type == TLWMessageItemTypeNotification) {
        TLWNotificationController *notifVC = [[TLWNotificationController alloc] init];
        notifVC.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:notifVC animated:YES];
    }
}

#pragma mark - Lazy

- (TLWMessageView *)myView {
    if (!_myView) {
        _myView = [[TLWMessageView alloc] initWithFrame:CGRectZero];
    }
    return _myView;
}

@end
