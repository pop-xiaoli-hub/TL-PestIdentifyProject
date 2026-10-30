//
//  TLWAIAssistantView.h
//  TL-PestIdentify
//
//  Created by Tommy-MrWu on 2026/3/15.
//  职责：实现AI助手页面视图组件。
//
#import <UIKit/UIKit.h>

@class TLWAIAssistantMessage;
@class TLWAIGestureCoordinator;

NS_ASSUME_NONNULL_BEGIN

@interface TLWAIAssistantView : UIView

@property (nonatomic, strong, readonly) UITextView  *inputTextField;
@property (nonatomic, strong, readonly) UIButton    *cameraButton;
@property (nonatomic, strong, readonly) UIButton    *micButton;
@property (nonatomic, strong, readonly) UIButton    *plusButton;
@property (nonatomic, strong, readonly) UIButton    *sendButton;
@property (nonatomic, strong, readonly) UIImageView *voiceSpeechImageView;
@property (nonatomic, strong, readonly) UIButton    *plusCameraButton;
@property (nonatomic, strong, readonly) UIButton    *plusAlbumButton;
@property (nonatomic, strong, readonly) UIButton    *plusAICallButton;
@property (nonatomic, strong, readonly) UIButton    *plusSessionButton;
@property (nonatomic, strong, readonly) UIButton    *plusLocationButton;
@property (nonatomic, assign, readonly) BOOL        isPlusPanelVisible;
@property (nonatomic, strong, readonly) UIButton    *stopButton;

/// 删除某张预览图时回调，index 对应 images 数组下标
@property (nonatomic, copy, nullable) void (^onRemoveImageAtIndex)(NSUInteger index);
@property (nonatomic, copy, nullable) void (^onContinueMessage)(TLWAIAssistantMessage *message);
/// 页面级 pop/横滑/纵向像素接力仲裁器。
@property (nonatomic, weak, nullable) TLWAIGestureCoordinator *gestureCoordinator;

/// 键盘弹出/收起时调用，height=0 表示收起
- (void)adjustForKeyboardHeight:(CGFloat)height duration:(NSTimeInterval)duration options:(UIViewAnimationOptions)options;
- (void)setInputText:(nullable NSString *)text;
- (void)showSelectedImage:(UIImage *)image;
- (void)showSelectedImages:(NSArray<UIImage *> *)images;
- (void)hideSelectedImage;
- (void)showVoicePanel;
- (void)hideVoicePanel;
- (void)setVoiceCancelArmed:(BOOL)armed;
- (void)showPlusPanel;
- (void)hidePlusPanel;
- (void)enterAILoadingMode;
- (void)exitAILoadingMode;
- (void)displayMessages:(NSArray<TLWAIAssistantMessage *> *)messages;
- (void)appendMessage:(TLWAIAssistantMessage *)message;
- (void)scrollMessagesToBottomAnimated:(BOOL)animated;
/// 仅在消息列表已贴底时滚动；用于键盘变化与流式增量。
- (void)followMessagesToBottomIfNeededAnimated:(BOOL)animated;
/// 转交列表更新单条消息；离屏延后配置/测高，未找到则忽略，不回退整表刷新。
- (void)reloadMessage:(TLWAIAssistantMessage *)message;
@end

NS_ASSUME_NONNULL_END
