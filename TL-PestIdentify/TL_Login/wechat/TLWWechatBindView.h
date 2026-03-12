//
//  TLWWechatBindView.h
//  TL-PestIdentify
//
//  微信登录绑定页 View
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TLWWechatBindView : UIView

@property (nonatomic, strong, readonly) UIButton *wechatAuthButton;    // 一键授权
@property (nonatomic, strong, readonly) UIButton *qqLoginButton;
@property (nonatomic, strong, readonly) UIButton *phoneLoginButton;

@end

NS_ASSUME_NONNULL_END
