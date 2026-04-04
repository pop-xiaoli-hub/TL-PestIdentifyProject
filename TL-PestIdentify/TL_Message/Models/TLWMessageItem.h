//
//  TLWMessageItem.h
//  TL-PestIdentify
//
//  Created by Tommy-MrWu on 2026/3/15.
//  职责：定义消息模块数据模型。
//
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, TLWMessageItemType) {
    TLWMessageItemTypeNotification,
    TLWMessageItemTypeSystem,
    TLWMessageItemTypeUser,
};

@interface TLWMessageItem : NSObject

@property (nonatomic, assign) TLWMessageItemType type;
@property (nonatomic, copy) NSString *avatarImageName;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subtitle;
@property (nonatomic, copy, nullable) NSString *timeString;
@property (nonatomic, assign) BOOL hasUnread;
@property (nonatomic, copy, nullable) NSString *avatarUrl;
@property (nonatomic, strong, nullable) NSNumber *unreadCount;
@property (nonatomic, strong, nullable) NSNumber *postId;
@property (nonatomic, strong, nullable) NSNumber *messageId;
@property (nonatomic, copy, nullable) NSString *postImageUrl;

@end

NS_ASSUME_NONNULL_END
