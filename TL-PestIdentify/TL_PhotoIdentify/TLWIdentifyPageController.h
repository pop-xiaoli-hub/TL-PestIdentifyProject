//
//  TLWIdentifyPageController.h
//  TL-PestIdentify
//
//  Created by xiaoli pop on 2026/3/11.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, TLWIdentifyPageMode) {
    TLWIdentifyPageModeIdentify = 0,
    TLWIdentifyPageModePickerOnly = 1,
};

@interface TLWIdentifyPageController : UIViewController

@property (nonatomic, assign) TLWIdentifyPageMode mode;
@property (nonatomic, copy, nullable) void (^onImagePicked)(UIImage *image);

- (void)prepareForRetakeCapture;

@end

NS_ASSUME_NONNULL_END
