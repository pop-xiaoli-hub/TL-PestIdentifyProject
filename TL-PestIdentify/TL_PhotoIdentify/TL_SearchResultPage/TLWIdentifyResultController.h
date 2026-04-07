//
//  TLWIdentifyResultController.h
//  TL-PestIdentify
//
//  Created by xiaoli pop on 2026/4/3.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TLWIdentifyResultController : UIViewController
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, copy) NSArray<NSDictionary *> *identifyResults;
@property (nonatomic, assign) NSInteger layoutStyleFlag;
@end

NS_ASSUME_NONNULL_END
