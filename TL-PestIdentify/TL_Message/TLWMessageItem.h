//
//  TLWMessageItem.h
//  TL-PestIdentify
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

+ (NSArray<TLWMessageItem *> *)mockItems;

@end

NS_ASSUME_NONNULL_END
