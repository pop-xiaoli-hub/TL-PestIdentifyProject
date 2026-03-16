//
//  TLWNotificationCell.h
//  TL-PestIdentify
//

#import <UIKit/UIKit.h>
#import "TLWNotificationItem.h"

NS_ASSUME_NONNULL_BEGIN

@class TLWNotificationCell;

@protocol TLWNotificationCellDelegate <NSObject>
- (void)notificationCellDidToggleExpand:(TLWNotificationCell *)cell;
@end

@interface TLWNotificationCell : UITableViewCell

@property (nonatomic, weak, nullable) id<TLWNotificationCellDelegate> delegate;

- (void)configureWithItem:(TLWNotificationItem *)item;

@end

NS_ASSUME_NONNULL_END
