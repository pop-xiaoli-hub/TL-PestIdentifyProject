#import <UIKit/UIKit.h>

@class TLWAIAssistantMessage;

NS_ASSUME_NONNULL_BEGIN

@interface TLWAIAssistantSystemMessageCell : UITableViewCell

+ (NSString *)reuseIdentifier;
- (void)configureWithMessage:(TLWAIAssistantMessage *)message;

@end

NS_ASSUME_NONNULL_END
