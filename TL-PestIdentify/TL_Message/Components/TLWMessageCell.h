//
//  TLWMessageCell.h
//  TL-PestIdentify
//
//  Created by Tommy-MrWu on 2026/3/15.
//  职责：实现消息列表单元组件。
//
#import <UIKit/UIKit.h>
#import "TLWMessageItem.h"

NS_ASSUME_NONNULL_BEGIN

@interface TLWMessageCell : UITableViewCell

- (void)configureWithItem:(TLWMessageItem *)item;

@end

NS_ASSUME_NONNULL_END
