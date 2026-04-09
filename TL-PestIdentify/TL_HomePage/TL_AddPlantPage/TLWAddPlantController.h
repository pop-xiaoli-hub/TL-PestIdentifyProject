//
//  TLWAddPlantController.h
//  TL-PestIdentify
//
//  Created by xiaoli pop on 2026/4/2.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^TLWAddPlantConfirmBlock)(NSString *plantName, UIImage *plantImage);

@interface TLWAddPlantController : UIViewController

@property (nonatomic, copy, nullable) TLWAddPlantConfirmBlock onConfirmAddPlant;

@end

NS_ASSUME_NONNULL_END
