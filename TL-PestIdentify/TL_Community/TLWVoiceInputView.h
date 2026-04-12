//
//  TLWVoiceInputView.h
//  TL-PestIdentify
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TLWVoiceInputView : UIView

@property (nonatomic, strong, readonly) UIButton *backButton;
@property (nonatomic, strong, readonly) UITextField *searchTextField;
@property (nonatomic, strong, readonly) UIButton *searchButton;
@property (nonatomic, strong, readonly) UIButton *longPressMicButton;

@property (nonatomic, copy, nullable) void (^onRecordingStart)(void);
@property (nonatomic, copy, nullable) void (^onRecordingEnd)(void);

- (void)updateSearchActionVisible:(BOOL)visible animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
