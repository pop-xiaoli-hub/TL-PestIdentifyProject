//
//  TLWVoiceInputView.h
//  TL-PestIdentify
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TLWVoiceInputView : UIView

@property (nonatomic, strong, readonly) UIButton *backButton;
@property (nonatomic, strong, readonly) UITextField *searchTextField;
@property (nonatomic, strong, readonly) UIButton *longPressMicButton;

@property (nonatomic, copy, nullable) void (^onRecordingStart)(void);
@property (nonatomic, copy, nullable) void (^onRecordingEnd)(void);

@end

NS_ASSUME_NONNULL_END
