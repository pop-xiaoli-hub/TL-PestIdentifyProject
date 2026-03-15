//
//  TLWNotificationItem.h
//  TL-PestIdentify
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, TLWNotificationTag) {
    TLWNotificationTagAll     = 0,
    TLWNotificationTagSystem  = 1,  // 系统通知
    TLWNotificationTagDisease = 2,  // 病害消息
    TLWNotificationTagSurvey  = 3,  // 用户调研
};

@interface TLWNotificationItem : NSObject

@property (nonatomic, copy)   NSString          *title;
@property (nonatomic, copy)   NSString          *bodyText;
@property (nonatomic, assign) BOOL               hasUnread;
@property (nonatomic, assign) BOOL               isExpanded;
@property (nonatomic, assign) TLWNotificationTag  tag;

+ (NSArray<TLWNotificationItem *> *)mockItems;

@end

NS_ASSUME_NONNULL_END
