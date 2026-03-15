//
//  TLWMessageCell.h
//  TL-PestIdentify
//

#import <UIKit/UIKit.h>
#import "TLWMessageItem.h"

NS_ASSUME_NONNULL_BEGIN

@interface TLWMessageCell : UITableViewCell

- (void)configureWithItem:(TLWMessageItem *)item;

@end

NS_ASSUME_NONNULL_END
