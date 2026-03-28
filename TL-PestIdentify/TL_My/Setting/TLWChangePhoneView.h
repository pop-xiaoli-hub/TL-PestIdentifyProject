//
//  TLWChangePhoneView.h
//  TL-PestIdentify
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TLWChangePhoneView : UIView

@property (nonatomic, strong, readonly) UIButton    *backButton;
@property (nonatomic, strong, readonly) UILabel     *currentPhoneLabel;
@property (nonatomic, strong, readonly) UITextField *phoneField;
@property (nonatomic, strong, readonly) UITextField *codeField;
@property (nonatomic, strong, readonly) UIButton    *sendCodeButton;
@property (nonatomic, strong, readonly) UIButton    *confirmButton;

@end

NS_ASSUME_NONNULL_END
