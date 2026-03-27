//
//  TLWPhotoPickerController.h
//  TL-PestIdentify
//

#import <UIKit/UIKit.h>
#import "TLWAvatarCropController.h"

NS_ASSUME_NONNULL_BEGIN

@interface TLWPhotoPickerController : UIViewController

/// 最大可选数量，默认 1（单选模式：点击直接回调）
@property (nonatomic, assign) NSUInteger maxCount;

/// 选图完成后由 Picker 推入 CropController，CropController 的 delegate 设为此对象
@property (nonatomic, weak, nullable) id<TLWAvatarCropDelegate> cropDelegate;

/// 单选回调（设置后优先走 block，不走 cropDelegate → CropController 的流程）
@property (nonatomic, copy, nullable) void (^onSelectImage)(UIImage *image);

/// 多选回调（maxCount > 1 时，点击"完成"后回调）
@property (nonatomic, copy, nullable) void (^onSelectImages)(NSArray<UIImage *> *images);

@end

NS_ASSUME_NONNULL_END
