//
//  TLWMessageController.m
//  TL-PestIdentify

#import "TLWMessageController.h"
#import "TLWMessageView.h"
#import "TLWMessageCell.h"
#import "TLWMessageItem.h"
#import "TLWNotificationController.h"
#import "TLWSDKManager.h"
#import "TLWToast.h"
#import "TLWPostDetailController.h"
#import "TLWCommunityPost.h"
#import <AgriPestClient/AGResultPostResponseDto.h>
#import <AgriPestClient/AGPostResponseDto.h>
#import <Masonry/Masonry.h>

static NSString *const kMessageCellID = @"TLWMessageCell";

@interface TLWMessageController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) TLWMessageView           *myView;
@property (nonatomic, strong) NSMutableArray<TLWMessageItem *> *items;

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

    [self tl_buildStaticItems];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self fetchMessages];
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
    [[TLWSDKManager shared].api getMyMessagesWithPage:@0
                                                 size:@10
                                    completionHandler:^(AGResultMessageGroupResponseDto *output, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error || output.code.integerValue != 200) {
                if (!error && output.code.integerValue == 401) {
                    [[TLWSDKManager shared] handleUnauthorizedWithRetry:^{ [self fetchMessages]; }];
                    return;
                }
                return;
            }

            AGMessageGroupResponseDto *data = output.data;
            NSMutableArray *newItems = [NSMutableArray array];

            // 通知行（预警消息）
            TLWMessageItem *alertItem = [TLWMessageItem new];
            alertItem.type            = TLWMessageItemTypeNotification;
            alertItem.avatarImageName = @"iconNotification";
            alertItem.title           = @"通知";
            alertItem.hasUnread       = data.alertUnreadCount.integerValue > 0;
            alertItem.unreadCount     = data.alertUnreadCount;
            AGMessageResponseDto *latestAlert = data.alertMessages.list.firstObject;
            alertItem.subtitle = latestAlert.title.length > 0 ? latestAlert.title :
                                 (data.alertUnreadCount.integerValue > 0 ? @"有新通知" : @"暂无通知");
            [newItems addObject:alertItem];

            // 系统消息行
            TLWMessageItem *sysItem = [TLWMessageItem new];
            sysItem.type            = TLWMessageItemTypeSystem;
            sysItem.avatarImageName = @"iconSystem";
            sysItem.title           = @"系统消息";
            sysItem.hasUnread       = data.systemUnreadCount.integerValue > 0;
            sysItem.unreadCount     = data.systemUnreadCount;
            sysItem.subtitle = @"还原使用植小保app";
            [newItems addObject:sysItem];

            // 评论互动行（直接展开，每条一行）
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
                [newItems addObject:commentItem];
            }

            self.items = newItems;
            [self.myView.tableView reloadData];

            // 异步补全评论行的帖子首图
            for (NSInteger i = 0; i < newItems.count; i++) {
                TLWMessageItem *it = newItems[i];
                if (it.type != TLWMessageItemTypeUser || !it.postId) continue;
                NSInteger capturedIndex = i;
                NSNumber *postId = it.postId;
                [[TLWSDKManager shared].api getPostDetailWithId:postId
                                              completionHandler:^(AGResultPostResponseDto *out, NSError *err) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (err || out.code.integerValue != 200 || !out.data) return;
                        if (capturedIndex >= (NSInteger)self.items.count) return;
                        if (![self.items[capturedIndex].postId isEqual:postId]) return;
                        self.items[capturedIndex].postImageUrl = out.data.images.firstObject;
                        NSIndexPath *ip = [NSIndexPath indexPathForRow:capturedIndex inSection:0];
                        [self.myView.tableView reloadRowsAtIndexPaths:@[ip]
                                                    withRowAnimation:UITableViewRowAnimationNone];
                    });
                }];
            }
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
            [[TLWSDKManager shared].api markAsReadWithId:item.messageId
                                      completionHandler:^(AGResultVoid *output, NSError *error) {}];
        }

        [[TLWSDKManager shared].api getPostDetailWithId:item.postId
                                      completionHandler:^(AGResultPostResponseDto *output, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (error || output.code.integerValue != 200 || !output.data) return;
                AGPostResponseDto *dto = output.data;
                TLWCommunityPost *post = [TLWCommunityPost new];
                post._id            = dto._id;
                post.title          = dto.title ?: @"";
                post.content        = dto.content ?: @"";
                post.images         = dto.images ?: @[];
                post.tags           = dto.tags ?: @[];
                post.authorName     = dto.authorName ?: @"";
                post.authorAvatar   = dto.authorAvatar ?: @"";
                post.likeCount      = dto.likeCount ?: @0;
                post.favoriteCount  = dto.favoriteCount ?: @0;
                post.isLiked        = dto.isLiked.boolValue;
                post.isFavorited    = dto.isFavorited.boolValue;
                TLWPostDetailController *vc = [[TLWPostDetailController alloc] init];
                vc._id = post._id;
                vc.post = post;
                vc.hasCollectedPosts = [NSMutableArray arrayWithArray:[TLWSDKManager shared].cachedFavoritedPosts ?: @[]];
                vc.hidesBottomBarWhenPushed = YES;
                [self.navigationController pushViewController:vc animated:YES];
            });
        }];
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
