//
//  TLWPhotoPickerController.h
//  TL-PestIdentify
//

#import <UIKit/UIKit.h>
#import "TLWAvatarCropController.h"

NS_ASSUME_NONNULL_BEGIN

@interface TLWPhotoPickerController : UIViewController

/// 选图完成后由 Picker 推入 CropController，CropController 的 delegate 设为此对象
@property (nonatomic, weak, nullable) id<TLWAvatarCropDelegate> cropDelegate;

@end

NS_ASSUME_NONNULL_END
