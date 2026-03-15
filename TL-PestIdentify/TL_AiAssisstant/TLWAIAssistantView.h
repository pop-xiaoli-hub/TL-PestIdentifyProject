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
@property (nonatomic, strong, readonly) UIButton    *removePreviewButton;

/// 键盘弹出/收起时调用，height=0 表示收起
- (void)adjustForKeyboardHeight:(CGFloat)height duration:(NSTimeInterval)duration;
- (void)showSelectedImage:(UIImage *)image;
- (void)hideSelectedImage;
@end
