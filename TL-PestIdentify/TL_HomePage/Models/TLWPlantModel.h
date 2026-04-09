//
//  TLWPlantModel.h
//  TL-PestIdentify
//

#import <UIKit/UIKit.h>

@class AGMyCropResponseDto;

NS_ASSUME_NONNULL_BEGIN

@interface TLWPlantModel : NSObject

@property (nonatomic, strong) NSNumber *plantId;
@property (nonatomic, copy) NSString *plantName;
@property (nonatomic, copy) NSString *imageUrl;
@property (nonatomic, strong, nullable) UIImage *localImage;
@property (nonatomic, assign) BOOL isUploading;

- (instancetype)initWithCropResponse:(AGMyCropResponseDto *)cropResponse;
- (instancetype)initWithPlantName:(NSString *)plantName image:(UIImage *)image;

@end

NS_ASSUME_NONNULL_END
