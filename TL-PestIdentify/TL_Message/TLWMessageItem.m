//
//  TLWMessageItem.m
//  TL-PestIdentify
//

#import "TLWMessageItem.h"

@implementation TLWMessageItem

+ (NSArray<TLWMessageItem *> *)mockItems {
    TLWMessageItem *notification = [TLWMessageItem new];
    notification.type = TLWMessageItemTypeNotification;
    notification.avatarImageName = @"iconNotification";
    notification.title = @"通知";
    notification.subtitle = @"欢迎使用植小保APP";
    notification.hasUnread = YES;

    TLWMessageItem *system = [TLWMessageItem new];
    system.type = TLWMessageItemTypeSystem;
    system.avatarImageName = @"iconSystem";
    system.title = @"系统消息";
    system.subtitle = @"欢迎使用植小保APP";
    system.hasUnread = NO;

    TLWMessageItem *user1 = [TLWMessageItem new];
    user1.type = TLWMessageItemTypeUser;
    user1.avatarImageName = @"forkAvatar";
    user1.title = @"用户0526";
    user1.subtitle = @"评论了你的帖子";
    user1.timeString = @"36分钟前";
    user1.hasUnread = YES;

    TLWMessageItem *user2 = [TLWMessageItem new];
    user2.type = TLWMessageItemTypeUser;
    user2.avatarImageName = @"forkAvatar";
    user2.title = @"用户0823";
    user2.subtitle = @"评论了你的帖子";
    user2.timeString = @"2天前";
    user2.hasUnread = YES;

    return @[notification, system, user1, user2];
}

@end
