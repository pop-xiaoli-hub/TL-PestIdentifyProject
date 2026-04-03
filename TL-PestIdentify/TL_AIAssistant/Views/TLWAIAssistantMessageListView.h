#import <UIKit/UIKit.h>

@class TLWAIAssistantMessage;

NS_ASSUME_NONNULL_BEGIN

@interface TLWAIAssistantMessageListView : UIView

- (void)displayMessages:(NSArray<TLWAIAssistantMessage *> *)messages;
- (void)appendMessage:(TLWAIAssistantMessage *)message;
- (void)scrollToBottomAnimated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
