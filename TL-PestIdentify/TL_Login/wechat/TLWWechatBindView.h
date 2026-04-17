//
//  TLWWechatBindView.h
//  TL-PestIdentify
//
//  Created by 吴桐 on 2026/3/12.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TLWWechatBindView : UIView

@property (nonatomic, strong, readonly) UIButton *wechatAuthButton;    // 一键授权
@property (nonatomic, strong, readonly) UIButton *qqLoginButton;
@property (nonatomic, strong, readonly) UIButton *smsLoginButton;
@property (nonatomic, strong, readonly) UIButton *passwordLoginButton;
@property (nonatomic, strong, readonly) UIButton *termsCheckButton;

@end

NS_ASSUME_NONNULL_END
