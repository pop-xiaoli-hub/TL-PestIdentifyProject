//
//  TLWNotificationItem.m
//  TL-PestIdentify
//

#import "TLWNotificationItem.h"
#import <AgriPestClient/AGMessageResponseDto.h>

@implementation TLWNotificationItem

+ (instancetype)itemFromDto:(AGMessageResponseDto *)dto {
    TLWNotificationItem *item = [TLWNotificationItem new];
    item.messageId  = dto._id;
    item.title      = dto.title.length > 0 ? dto.title : @"系统消息";
    item.bodyText   = dto.content ?: @"";
    item.hasUnread  = !dto.isRead.boolValue;
    item.isExpanded = NO;
    item.createdAt  = dto.createdAt;

    if ([dto.type isEqualToString:@"ALERT"]) {
        item.tag = TLWNotificationTagDisease;
    } else {
        item.tag = TLWNotificationTagSystem;
    }
    return item;
}

@end
