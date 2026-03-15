//
//  TLWCameraManager.h
//  TL-PestIdentify
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@class TLWCameraManager;

@protocol TLWCameraManagerDelegate <NSObject>
/// 拍照或从相册选图完成后回调
- (void)cameraManager:(TLWCameraManager *)manager didCapturePhoto:(UIImage *)image;
@end

@interface TLWCameraManager : NSObject <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic, weak) id<TLWCameraManagerDelegate> delegate;

/// 相机预览层，添加到目标 view.layer 上即可显示画面
@property (nonatomic, strong, readonly) AVCaptureVideoPreviewLayer *previewLayer;

/// 初始化，传入宿主 VC 用于弹权限提示和相册 picker
- (instancetype)initWithHostViewController:(UIViewController *)viewController;

/// 申请权限 + 初始化 session（在 viewDidLoad 调用）
- (void)setupCamera;

/// 启动预览（在 viewWillAppear 调用）
- (void)startRunning;

/// 停止预览（在 viewWillDisappear 调用）
- (void)stopRunning;

/// 拍照
- (void)capturePhoto;

/// 开关闪光灯
- (void)setFlashEnabled:(BOOL)enabled;

/// 打开系统相册
- (void)openPhotoAlbum;

@end

NS_ASSUME_NONNULL_END
