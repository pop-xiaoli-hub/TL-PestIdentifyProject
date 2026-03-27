//
//  TLWAIAssistantView.h
//  TL-PestIdentify
//

#import <UIKit/UIKit.h>

@interface TLWAIAssistantView : UIView

@property (nonatomic, strong, readonly) UIButton    *backButton;
@property (nonatomic, strong, readonly) UITextView  *inputTextField;
@property (nonatomic, strong, readonly) UIButton    *cameraButton;
@property (nonatomic, strong, readonly) UIButton    *micButton;
@property (nonatomic, strong, readonly) UIButton    *galleryButton;
@property (nonatomic, strong, readonly) UIImageView *voiceSpeechImageView;

/// 删除某张预览图时回调，index 对应 images 数组下标
@property (nonatomic, copy, nullable) void (^onRemoveImageAtIndex)(NSUInteger index);

/// 键盘弹出/收起时调用，height=0 表示收起
- (void)adjustForKeyboardHeight:(CGFloat)height duration:(NSTimeInterval)duration;
- (void)showSelectedImage:(UIImage *)image;
- (void)showSelectedImages:(NSArray<UIImage *> *)images;
- (void)hideSelectedImage;
- (void)showVoicePanel;
- (void)hideVoicePanel;
@end
