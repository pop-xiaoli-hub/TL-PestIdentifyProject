//
//  TLWPlantModel.m
//  TL-PestIdentify
//

#import "TLWPlantModel.h"
#import <AgriPestClient/AGMyCropResponseDto.h>

@implementation TLWPlantModel

- (instancetype)initWithCropResponse:(AGMyCropResponseDto *)cropResponse {
  self = [super init];
  if (self) {
    _plantId = cropResponse._id ?: @0;
    _plantName = [cropResponse.plantName isKindOfClass:[NSString class]] ? cropResponse.plantName : @"";
    _imageUrl = [cropResponse.imageUrl isKindOfClass:[NSString class]] ? cropResponse.imageUrl : @"";
    _plantStatus = [cropResponse.status isKindOfClass:[NSString class]] ? cropResponse.status : @"";
    _plantingDate = cropResponse.plantingDate;
    _isUploading = NO;
  }
  return self;
}

- (instancetype)initWithPlantName:(NSString *)plantName image:(UIImage *)image {
  self = [super init];
  if (self) {
    _plantId = @0;
    _plantName = [plantName isKindOfClass:[NSString class]] ? plantName : @"";
    _imageUrl = @"";
    _plantStatus = @"";
    _plantingDate = nil;
    _localImage = image;
    _isUploading = YES;
  }
  return self;
}

@end
