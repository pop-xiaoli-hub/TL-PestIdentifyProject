//
//  TLWMessageController.m
//  TL-PestIdentify
//
//  Created by Tommy-MrWu on 2026/3/15.
//  职责：编排消息页面交互与数据流程。
//
#import "TLWMessageController.h"
#import "TLWMessageView.h"
#import "TLWMessageCell.h"
#import "TLWMessageItem.h"
#import "TLWNotificationController.h"
#import "TLWSDKManager.h"
#import "TLWToast.h"
#import "TLWPostDetailController.h"
#import <Masonry/Masonry.h>

static NSString *const kMessageCellID = @"TLWMessageCell";
static NSInteger const kMessagePageSize = 20;

@interface TLWMessageController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) TLWMessageView           *myView;
@property (nonatomic, strong) NSMutableArray<TLWMessageItem *> *items;
@property (nonatomic, strong) NSMutableArray<TLWMessageItem *> *commentItems;
@property (nonatomic, assign) NSInteger currentPage;
@property (nonatomic, assign) BOOL isLoadingMessages;
@property (nonatomic, assign) BOOL hasMoreMessages;
@property (nonatomic, copy) NSString *latestAlertTitle;
@property (nonatomic, strong) NSNumber *alertUnreadCount;
@property (nonatomic, strong) NSNumber *systemUnreadCount;
@property (nonatomic, strong) UIActivityIndicatorView *footerSpinner;

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
    self.commentItems = [NSMutableArray array];
    self.alertUnreadCount = @0;
    self.systemUnreadCount = @0;
    self.currentPage = 0;
    self.hasMoreMessages = YES;
    self.myView.tableView.refreshControl = [self tl_buildRefreshControl];

    [self tl_buildStaticItems];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self tl_refreshMessages];
}

#pragma mark - Static structure (骨架行)

- (void)tl_buildStaticItems {
    self.items = [NSMutableArray array];

    TLWMessageItem *alert = [TLWMessageItem new];
    alert.type            = TLWMessageItemTypeNotification;
    alert.avatarImageName = @"iconNotification";
    alert.title           = @"通知";
    alert.subtitle        = @"加载中...";
    alert.hasUnread       = NO;
    [self.items addObject:alert];

    TLWMessageItem *sys = [TLWMessageItem new];
    sys.type            = TLWMessageItemTypeSystem;
    sys.avatarImageName = @"iconSystem";
    sys.title           = @"系统消息";
    sys.subtitle        = @"欢迎使用植小保app";
    sys.hasUnread       = NO;
    [self.items addObject:sys];

    [self.myView.tableView reloadData];
}

#pragma mark - Fetch

- (void)fetchMessages {
    [self fetchMessagesPage:0 reset:YES];
}

- (void)fetchMessagesPage:(NSInteger)page reset:(BOOL)reset {
    if (self.isLoadingMessages) return;
    if (!reset && !self.hasMoreMessages) return;
    self.isLoadingMessages = YES;
    if (!reset) {
        [self.footerSpinner startAnimating];
        self.myView.tableView.tableFooterView = self.footerSpinner;
    }

    [[TLWSDKManager shared].api getMyMessagesWithPage:@(page)
                                                 size:@(kMessagePageSize)
                                    completionHandler:^(AGResultMessageGroupResponseDto *output, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.isLoadingMessages = NO;
            [self.myView.tableView.refreshControl endRefreshing];
            self.myView.tableView.tableFooterView = nil;
            [self.footerSpinner stopAnimating];

            if (error || output.code.integerValue != 200) {
                if (!error && output.code.integerValue == 401) {
                    [[TLWSDKManager shared] handleUnauthorizedWithRetry:^{ [self fetchMessagesPage:page reset:reset]; }];
                    return;
                }
                [TLWToast show:@"消息加载失败"];
                return;
            }

            AGMessageGroupResponseDto *data = output.data;
            AGMessageResponseDto *latestAlert = data.alertMessages.list.firstObject;
            if (reset) {
                self.alertUnreadCount = data.alertUnreadCount ?: @0;
                self.systemUnreadCount = data.systemUnreadCount ?: @0;
                self.latestAlertTitle = latestAlert.title;
                [self.commentItems removeAllObjects];
            }

            NSMutableArray<TLWMessageItem *> *newCommentItems = [NSMutableArray array];
            for (AGMessageResponseDto *dto in data.commentMessages.list) {
                TLWMessageItem *commentItem = [TLWMessageItem new];
                commentItem.type            = TLWMessageItemTypeUser;
                commentItem.avatarUrl       = dto.senderAvatar;
                commentItem.avatarImageName = @"forkAvatar";
                commentItem.title           = dto.senderName.length > 0 ? dto.senderName : @"用户";
                commentItem.subtitle        = dto.content ?: @"评论了你的帖子";
                commentItem.hasUnread       = !dto.isRead.boolValue;
                commentItem.timeString      = [self tl_relativeTime:dto.createdAt];
                commentItem.postId          = dto.postId;
                commentItem.messageId       = dto._id;
                commentItem.postImageUrl    = dto.postImageUrl;
                [newCommentItems addObject:commentItem];
            }

            [self.commentItems addObjectsFromArray:newCommentItems];
            self.currentPage = page;
            self.hasMoreMessages = [self tl_hasMoreFromCommentPage:data.commentMessages fetchedCount:newCommentItems.count];
            [self tl_rebuildItems];
        });
    }];
}

- (NSString *)tl_relativeTime:(NSDate *)date {
    if (!date) return @"";
    NSTimeInterval interval = -[date timeIntervalSinceNow];
    if (interval < 60)           return @"刚刚";
    if (interval < 3600)         return [NSString stringWithFormat:@"%.0f分钟前", interval / 60];
    if (interval < 86400)        return [NSString stringWithFormat:@"%.0f小时前", interval / 3600];
    if (interval < 86400 * 30)   return [NSString stringWithFormat:@"%.0f天前", interval / 86400];
    return [NSString stringWithFormat:@"%.0f月前", interval / (86400 * 30)];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TLWMessageCell *cell = [tableView dequeueReusableCellWithIdentifier:kMessageCellID forIndexPath:indexPath];
    TLWMessageItem *item = self.items[indexPath.row];
    [cell configureWithItem:item];
    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 72;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    TLWMessageItem *item = self.items[indexPath.row];

    if (item.type == TLWMessageItemTypeNotification) {
        // 通知行默认进入“全部”tab (0)
        TLWNotificationController *vc = [[TLWNotificationController alloc] initWithInitialTab:0];
        vc.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:vc animated:YES];
    } else if (item.type == TLWMessageItemTypeSystem) {
        // 系统消息行无点击事件
    } else if (item.type == TLWMessageItemTypeUser) {
        if (!item.postId) return;
        // 标记已读，消红点（不等回调，跳转同步进行）
        if (item.hasUnread && item.messageId) {
            item.hasUnread = NO;
            [self.myView.tableView reloadRowsAtIndexPaths:@[indexPath]
                                        withRowAnimation:UITableViewRowAnimationNone];
            [self tl_markMessageAsReadForItem:item preferredIndexPath:indexPath];
        }

        TLWPostDetailController *vc = [[TLWPostDetailController alloc] init];
        vc._id = item.postId;
        vc.hasCollectedPosts = [NSMutableArray arrayWithArray:[TLWSDKManager shared].cachedFavoritedPosts ?: @[]];
        vc.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:vc animated:YES];
    }
}

#pragma mark - Private

- (UIRefreshControl *)tl_buildRefreshControl {
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(tl_refreshMessages) forControlEvents:UIControlEventValueChanged];
    return refreshControl;
}

- (void)tl_refreshMessages {
    [self fetchMessagesPage:0 reset:YES];
}

- (void)tl_loadMoreMessagesIfNeeded {
    if (self.isLoadingMessages || !self.hasMoreMessages) return;
    [self fetchMessagesPage:self.currentPage + 1 reset:NO];
}

- (BOOL)tl_hasMoreFromCommentPage:(id)commentPage fetchedCount:(NSInteger)count {
    if (!commentPage) return NO;
    if ([commentPage respondsToSelector:@selector(hasNext)]) {
        NSNumber *hasNext = [commentPage valueForKey:@"hasNext"];
        if ([hasNext isKindOfClass:[NSNumber class]]) {
            return hasNext.boolValue;
        }
    }
    return count >= kMessagePageSize;
}

- (void)tl_rebuildItems {
    NSMutableArray<TLWMessageItem *> *newItems = [NSMutableArray array];

    TLWMessageItem *alertItem = [TLWMessageItem new];
    alertItem.type            = TLWMessageItemTypeNotification;
    alertItem.avatarImageName = @"iconNotification";
    alertItem.title           = @"通知";
    alertItem.hasUnread       = self.alertUnreadCount.integerValue > 0;
    alertItem.unreadCount     = self.alertUnreadCount;
    alertItem.subtitle = self.latestAlertTitle.length > 0 ? self.latestAlertTitle :
                         (self.alertUnreadCount.integerValue > 0 ? @"有新通知" : @"暂无通知");
    [newItems addObject:alertItem];

    TLWMessageItem *sysItem = [TLWMessageItem new];
    sysItem.type            = TLWMessageItemTypeSystem;
    sysItem.avatarImageName = @"iconSystem";
    sysItem.title           = @"系统消息";
    sysItem.hasUnread       = self.systemUnreadCount.integerValue > 0;
    sysItem.unreadCount     = self.systemUnreadCount;
    sysItem.subtitle        = @"欢迎使用植小保app";
    [newItems addObject:sysItem];

    [newItems addObjectsFromArray:self.commentItems];
    self.items = newItems;
    [self.myView.tableView reloadData];
}

- (void)tl_markMessageAsReadForItem:(TLWMessageItem *)item preferredIndexPath:(NSIndexPath *)indexPath {
    if (!item.messageId) return;
    NSNumber *messageId = item.messageId;
    [[TLWSDKManager shared].api markAsReadWithId:messageId
                              completionHandler:^(AGResultVoid *output, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!error && output.code.integerValue == 200) return;

            item.hasUnread = YES;
            [self tl_reloadMessageRowForMessageId:messageId preferredIndexPath:indexPath];

            if (!error && output.code.integerValue == 401) {
                [[TLWSDKManager shared] handleUnauthorizedWithRetry:^{ [self tl_markMessageAsReadForItem:item preferredIndexPath:indexPath]; }];
            }
        });
    }];
}

- (void)tl_reloadMessageRowForMessageId:(NSNumber *)messageId preferredIndexPath:(NSIndexPath *)indexPath {
    NSIndexPath *targetIndexPath = nil;
    if (indexPath.row < self.items.count &&
        [self.items[indexPath.row].messageId isEqual:messageId]) {
        targetIndexPath = indexPath;
    } else {
        NSInteger targetIndex = [self.items indexOfObjectPassingTest:^BOOL(TLWMessageItem *obj, NSUInteger idx, BOOL *stop) {
            return [obj.messageId isEqual:messageId];
        }];
        if (targetIndex != NSNotFound) {
            targetIndexPath = [NSIndexPath indexPathForRow:targetIndex inSection:0];
        }
    }
    if (!targetIndexPath) return;
    [self.myView.tableView reloadRowsAtIndexPaths:@[targetIndexPath]
                                withRowAnimation:UITableViewRowAnimationNone];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat contentH = scrollView.contentSize.height;
    CGFloat offsetY  = scrollView.contentOffset.y;
    CGFloat frameH   = scrollView.bounds.size.height;
    if (contentH > frameH && offsetY > contentH - frameH - 120) {
        [self tl_loadMoreMessagesIfNeeded];
    }
}

#pragma mark - Lazy

- (TLWMessageView *)myView {
    if (!_myView) {
        _myView = [[TLWMessageView alloc] initWithFrame:CGRectZero];
    }
    return _myView;
}

- (UIActivityIndicatorView *)footerSpinner {
    if (!_footerSpinner) {
        _footerSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
        _footerSpinner.frame = CGRectMake(0, 0, self.myView.tableView.bounds.size.width, 44);
        _footerSpinner.color = [UIColor colorWithWhite:0.6 alpha:1.0];
    }
    return _footerSpinner;
}

@end
