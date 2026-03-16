//
//  TLWImagePickerController.h
//  TL-PestIdentify
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 发布页“选择图片”中间跳转页，仿照 TLWPreferenceController 结构。
/// 只负责展示图片选择 UI，不直接做网络或业务提交。
@interface TLWImagePickerController : UIViewController

/// 预留：外部传入当前已选图片（例如相册缩略图或模型对象）
@property (nonatomic, copy, nullable) NSArray *initialImages;

/// 预留：完成选择回调，将用户最终选择的图片列表回传给发布页
@property (nonatomic, copy, nullable) void (^completionHandler)(NSArray *selectedImages);

@end

NS_ASSUME_NONNULL_END

