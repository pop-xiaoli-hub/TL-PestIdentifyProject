//
//  TLWAIAssistantMessageCell.h
//  TL-PestIdentify
//
//  Created by Northern Lights on 2026/4/3.
//  职责：实现AI助手消息单元视图。
//
#import <UIKit/UIKit.h>

@class TLWAIAssistantMessage;

NS_ASSUME_NONNULL_BEGIN

@interface TLWAIAssistantMessageCell : UITableViewCell

+ (NSString *)reuseIdentifier;
- (void)configureWithMessage:(TLWAIAssistantMessage *)message;

@end

NS_ASSUME_NONNULL_END
