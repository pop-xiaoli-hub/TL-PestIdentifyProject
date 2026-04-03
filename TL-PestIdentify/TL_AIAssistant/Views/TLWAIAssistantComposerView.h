#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TLWAIAssistantComposerView : UIView

@property (nonatomic, strong, readonly) UITextView *inputTextField;
@property (nonatomic, strong, readonly) UIButton *cameraButton;
@property (nonatomic, strong, readonly) UIButton *micButton;
@property (nonatomic, strong, readonly) UIButton *galleryButton;
@property (nonatomic, strong, readonly) UIButton *sendButton;
@property (nonatomic, strong, readonly) UIImageView *voiceSpeechImageView;
@property (nonatomic, copy, nullable) void (^onRemoveImageAtIndex)(NSUInteger index);
@property (nonatomic, copy, nullable) void (^onHeightDidChange)(CGFloat height);
@property (nonatomic, assign, readonly) CGFloat preferredHeight;

- (void)setInputText:(nullable NSString *)text;
- (void)showSelectedImage:(UIImage *)image;
- (void)showSelectedImages:(NSArray<UIImage *> *)images;
- (void)hideSelectedImage;
- (void)showVoicePanel;
- (void)hideVoicePanel;

@end

NS_ASSUME_NONNULL_END
