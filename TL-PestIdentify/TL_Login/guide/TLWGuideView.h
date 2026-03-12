//
//  TLWGuideView.h
//  TL-PestIdentify
//
//  Created by 吴桐 on 2026/3/12.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TLWGuideView : UIView

@property (nonatomic, strong, readonly) UIButton *needButton;     // 需要（适老化）
@property (nonatomic, strong, readonly) UIButton *noNeedButton;   // 不需要
@property (nonatomic, strong, readonly) UIButton *confirmButton;  // 确认

/// option: 0 = 需要, 1 = 不需要, -1 = 未选择
- (void)setSelectedOption:(NSInteger)option;

@end

NS_ASSUME_NONNULL_END
