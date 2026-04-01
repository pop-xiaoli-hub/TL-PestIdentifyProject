//
//  TLWImagePickerManager.h
//  TL-PestIdentify
//
//  Created by 吴桐 on 2026/3/26.
//

#import <Foundation/Foundation.h>
#import "UIKit/UIKit.h"

NS_ASSUME_NONNULL_BEGIN

@class TLWImagePickerManager;

@protocol TLWImagePickerDelegate <NSObject>
@optional
/// 单选回调（头像、AI助手、拍照识别）
- (void)imagePicker:(TLWImagePickerManager *)picker didSelectImage:(UIImage *)image;
/// 多选回调（发帖）
- (void)imagePicker:(TLWImagePickerManager *)picker didSelectImages:(NSArray<UIImage *> *)images;
/// 取消
- (void)imagePickerDidCancel:(TLWImagePickerManager *)picker;
@end

@interface TLWImagePickerManager : NSObject

@property (nonatomic, assign) NSInteger maxCount;
@property (nonatomic, weak) id<TLWImagePickerDelegate> delegate;
- (void)openAlbumFrom:(UIViewController *)vc;
- (void)openCameraFrom:(UIViewController *)vc;

@end

NS_ASSUME_NONNULL_END
