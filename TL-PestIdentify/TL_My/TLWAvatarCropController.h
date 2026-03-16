//
//  TLWAvatarCropController.h
//  TL-PestIdentify
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class TLWAvatarCropController;

@protocol TLWAvatarCropDelegate <NSObject>
- (void)avatarCropController:(TLWAvatarCropController *)vc didConfirmImage:(UIImage *)image;
@end

@interface TLWAvatarCropController : UIViewController

- (instancetype)initWithImage:(UIImage *)image;
@property (nonatomic, weak, nullable) id<TLWAvatarCropDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
