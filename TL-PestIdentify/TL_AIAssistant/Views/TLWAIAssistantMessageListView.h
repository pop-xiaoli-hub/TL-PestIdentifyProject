//
//  TLWAIAssistantMessageListView.h
//  TL-PestIdentify
//
//  Created by Northern Lights on 2026/4/3.
//  职责：实现AI助手页面视图组件。
//
#import <UIKit/UIKit.h>

@class TLWAIAssistantMessage;

NS_ASSUME_NONNULL_BEGIN

@interface TLWAIAssistantMessageListView : UIView

- (void)displayMessages:(NSArray<TLWAIAssistantMessage *> *)messages;
- (void)appendMessage:(TLWAIAssistantMessage *)message;
- (void)scrollToBottomAnimated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
