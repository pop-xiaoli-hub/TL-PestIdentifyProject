//
//  TLWAIAssistantMessageListView.h
//  TL-PestIdentify
//
//  Created by Northern Lights on 2026/4/3.
//  职责：实现AI助手页面视图组件。
//
#import <UIKit/UIKit.h>

@class TLWAIAssistantMessage;
@class TLWAIGestureCoordinator;

NS_ASSUME_NONNULL_BEGIN

@interface TLWAIAssistantMessageListView : UIView

- (void)displayMessages:(NSArray<TLWAIAssistantMessage *> *)messages;
- (void)appendMessage:(TLWAIAssistantMessage *)message;
/// 强制恢复跟随并滚动到底部；用于用户发送消息。
- (void)scrollToBottomAnimated:(BOOL)animated;
/// 仅在当前已经贴底时跟随；用于流式刷新和键盘变化，历史阅读状态不被拉走。
- (void)followBottomIfNeededAnimated:(BOOL)animated;
/// 更新可见气泡，实测行高变化才合并提交；离屏延后重测，局部交互只保护对应块。
- (void)reloadMessage:(TLWAIAssistantMessage *)message;
/// 外层或可见气泡内层正在跟踪/拖动/减速。
@property (nonatomic, assign, readonly) BOOL interactionActive;
@property (nonatomic, copy, nullable) void (^onContinueMessage)(TLWAIAssistantMessage *message);
/// 与本页 pop 共用同一个手势仲裁器。
@property (nonatomic, weak, nullable) TLWAIGestureCoordinator *gestureCoordinator;

@end

NS_ASSUME_NONNULL_END
