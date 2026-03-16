//
//  TLWCropPickerController.h
//  TL-PestIdentify
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 发布页“选择农作物”的中间跳转页，UI 仿照 TLWPreferenceController。
@interface TLWCropPickerController : UIViewController

/// 预留：当前已选的作物名称（单选或多选均可用数组承载）
@property (nonatomic, copy, nullable) NSArray<NSString *> *initialSelectedCropNames;

/// 预留：完成选择回调，把最终选中的作物名称列表回传给发布页
@property (nonatomic, copy, nullable) void (^completionHandler)(NSArray<NSString *> *selectedCropNames);

@end

NS_ASSUME_NONNULL_END

