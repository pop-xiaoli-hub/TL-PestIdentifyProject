//
//  TWLGuideView.h
//  TL-PestIdentify
//
//  引导页 View — 询问用户是否需要适老化模式
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TWLGuideView : UIView

@property (nonatomic, strong, readonly) UIButton *needButton;     // 需要（适老化）
@property (nonatomic, strong, readonly) UIButton *noNeedButton;   // 不需要
@property (nonatomic, strong, readonly) UIButton *confirmButton;  // 确认

/// option: 0 = 需要, 1 = 不需要, -1 = 未选择
- (void)setSelectedOption:(NSInteger)option;

@end

NS_ASSUME_NONNULL_END
