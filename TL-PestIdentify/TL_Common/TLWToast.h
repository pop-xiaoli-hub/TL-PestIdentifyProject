//
//  TLWToast.h
//  TL-PestIdentify
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 统一 Toast 组件 — 白色胶囊样式，挂载 keyWindow，自动消失
@interface TLWToast : NSObject

/// 居中显示 Toast，1.5s 后自动消失
+ (void)show:(NSString *)text;

@end

NS_ASSUME_NONNULL_END
