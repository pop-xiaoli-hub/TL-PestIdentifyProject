//
//  TLWLocalIdentifyManager.m
//  TL-PestIdentify
//
//  Core ML 本地病虫害识别管理器
//

#import "TLWLocalIdentifyManager.h"
#import <CoreML/CoreML.h>
#import <ImageIO/ImageIO.h>
#import <Vision/Vision.h>

static NSString * const TLWLocalIdentifyErrorDomain = @"TLWLocalIdentify";

@implementation TLWLocalIdentifyResult
@end

@interface TLWLocalIdentifyManager ()
@property (nonatomic, strong) VNCoreMLModel *vnModel;
@property (nonatomic, strong) NSDictionary<NSString *, NSString *> *labelToChineseName;
@property (nonatomic, strong) NSDictionary<NSString *, NSString *> *labelToChineseCrop;
@end

@implementation TLWLocalIdentifyManager

+ (instancetype)shared {
    static TLWLocalIdentifyManager *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[TLWLocalIdentifyManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self tl_loadModel];
        [self tl_buildLabelMapping];
    }
    return self;
}

#pragma mark - 加载模型

- (void)tl_loadModel {
    NSError *error = nil;
    // 从 bundle 加载编译后的 mlmodel， 如果拿不到URL，说明模型没有正确打包或名字不对
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"PestClassifier" withExtension:@"mlmodelc"];
    if (!modelURL) {
        NSLog(@"[CoreML] PestClassifier.mlmodelc 未找到");
        return;
    }
    //  接着真正加载模型，把磁盘上的模型变成内存里的MLModel对象，然后
    MLModel *mlModel = [MLModel modelWithContentsOfURL:modelURL error:&error];
    if (error || !mlModel) {
        NSLog(@"[CoreML] 模型加载失败: %@", error.localizedDescription);
        return;
    }
    //  然后这一行吧MLModel包成Vision能识别的VNCoreModel
    self.vnModel = [VNCoreMLModel modelForMLModel:mlModel error:&error];
    if (error || !self.vnModel) {
        NSLog(@"[CoreML] VNCoreMLModel 创建失败: %@", error.localizedDescription);
        return;
    }
    NSLog(@"[CoreML] 模型加载成功");
}

#pragma mark - 识别

- (void)identifyImage:(UIImage *)image completion:(TLWLocalIdentifyCompletion)completion {
    if (!self.vnModel) {
        [self tl_completeWithResults:nil
                               error:[self tl_errorWithCode:-1 description:@"模型未加载"]
                          completion:completion];
        return;
    }
    if (!image) {
        [self tl_completeWithResults:nil
                               error:[self tl_errorWithCode:-2 description:@"图片为空"]
                          completion:completion];
        return;
    }

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @autoreleasepool {
            CGImagePropertyOrientation orientation = kCGImagePropertyOrientationUp;
            NSError *cgImageError = nil;
            CGImageRef cgImage = [self tl_createCGImageForImage:image orientation:&orientation error:&cgImageError];
            if (!cgImage) {
                [self tl_completeWithResults:nil error:cgImageError completion:completion];
                return;
            }

            NSError *predictError = nil;
            NSDictionary<NSString *, NSNumber *> *scores = [self tl_predictScoresForCGImage:cgImage
                                                                                orientation:orientation
                                                                                      error:&predictError];
            CGImageRelease(cgImage);

            if (!scores || scores.count == 0) {
                [self tl_completeWithResults:nil
                                       error:predictError ?: [self tl_errorWithCode:-4 description:@"模型未返回有效结果"]
                                  completion:completion];
                return;
            }

            NSArray<TLWLocalIdentifyResult *> *results = [self tl_resultsFromScores:scores];
            [self tl_completeWithResults:results error:nil completion:completion];
        }
    });
}

- (void)tl_completeWithResults:(NSArray<TLWLocalIdentifyResult *> * _Nullable)results
                         error:(NSError * _Nullable)error
                    completion:(TLWLocalIdentifyCompletion)completion {
    if (!completion) {
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        completion(results, error);
    });
}

- (NSError *)tl_errorWithCode:(NSInteger)code description:(NSString *)description {
    return [NSError errorWithDomain:TLWLocalIdentifyErrorDomain
                               code:code
                           userInfo:@{NSLocalizedDescriptionKey: description ?: @"识别失败"}];
}

- (CGImageRef)tl_createCGImageForImage:(UIImage *)image
                           orientation:(CGImagePropertyOrientation *)orientation
                                 error:(NSError **)error CF_RETURNS_RETAINED {
    if (image.CGImage) {
        if (orientation) {
            *orientation = [self tl_cgImageOrientationForImageOrientation:image.imageOrientation];
        }
        return CGImageRetain(image.CGImage);
    }

    if (CGSizeEqualToSize(image.size, CGSizeZero)) {
        if (error) {
            *error = [self tl_errorWithCode:-3 description:@"图片尺寸无效"];
        }
        return nil;
    }

    UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
    [image drawInRect:CGRectMake(0, 0, image.size.width, image.size.height)];
    UIImage *normalizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    if (!normalizedImage.CGImage) {
        if (error) {
            *error = [self tl_errorWithCode:-3 description:@"无法获取CGImage"];
        }
        return nil;
    }

    if (orientation) {
        *orientation = kCGImagePropertyOrientationUp;
    }
    return CGImageRetain(normalizedImage.CGImage);
}

- (NSDictionary<NSString *, NSNumber *> *)tl_predictScoresForCGImage:(CGImageRef)cgImage
                                                         orientation:(CGImagePropertyOrientation)orientation
                                                               error:(NSError **)error {
    NSArray<NSNumber *> *cropOptions = @[
        @(VNImageCropAndScaleOptionCenterCrop),
        @(VNImageCropAndScaleOptionScaleFit),
        @(VNImageCropAndScaleOptionScaleFill)
    ];

    NSMutableDictionary<NSString *, NSNumber *> *aggregatedScores = [NSMutableDictionary dictionary];
    NSMutableArray<NSString *> *strategyLogs = [NSMutableArray array];
    NSError *lastError = nil;
    NSUInteger successfulRuns = 0;

    for (NSNumber *optionNumber in cropOptions) {
        VNImageCropAndScaleOption cropOption = optionNumber.integerValue;
        VNCoreMLRequest *request = [[VNCoreMLRequest alloc] initWithModel:self.vnModel];
        request.imageCropAndScaleOption = cropOption;

        VNImageRequestHandler *handler = [[VNImageRequestHandler alloc] initWithCGImage:cgImage
                                                                             orientation:orientation
                                                                                 options:@{}];
        NSError *performError = nil;
        BOOL success = [handler performRequests:@[request] error:&performError];
        if (!success || performError) {
            lastError = performError;
            continue;
        }

        NSArray<VNClassificationObservation *> *observations = request.results;
        if (![observations isKindOfClass:[NSArray class]] || observations.count == 0) {
            continue;
        }

        successfulRuns += 1;
        [strategyLogs addObject:[self tl_debugSummaryForObservations:observations cropOption:cropOption]];

        for (VNClassificationObservation *observation in observations) {
            float currentScore = aggregatedScores[observation.identifier].floatValue;
            aggregatedScores[observation.identifier] = @(currentScore + observation.confidence);
        }
    }

    if (successfulRuns == 0) {
        if (error) {
            *error = lastError ?: [self tl_errorWithCode:-4 description:@"模型未返回有效结果"];
        }
        return nil;
    }

    for (NSString *label in [aggregatedScores allKeys]) {
        aggregatedScores[label] = @(aggregatedScores[label].floatValue / successfulRuns);
    }

    NSArray<TLWLocalIdentifyResult *> *combinedResults = [self tl_resultsFromScores:aggregatedScores];
    NSLog(@"[CoreML] 输入图像 %zux%zu, orientation=%ld, 成功策略=%lu",
          CGImageGetWidth(cgImage),
          CGImageGetHeight(cgImage),
          (long)orientation,
          (unsigned long)successfulRuns);
    for (NSString *strategyLog in strategyLogs) {
        NSLog(@"%@", strategyLog);
    }
    if (combinedResults.count > 0) {
        TLWLocalIdentifyResult *topResult = combinedResults.firstObject;
        NSLog(@"[CoreML] 聚合结果 Top1: %@ / %@ (%.1f%%)",
              topResult.crop.length > 0 ? topResult.crop : @"未知作物",
              topResult.name,
              topResult.confidence * 100);
        if (topResult.confidence < 0.45f) {
            NSLog(@"[CoreML] Top1 置信度偏低，结果仅供参考，建议重拍更近、更清晰的叶片");
        }
    }

    return [aggregatedScores copy];
}

- (NSArray<TLWLocalIdentifyResult *> *)tl_resultsFromScores:(NSDictionary<NSString *, NSNumber *> *)scores {
    NSArray<NSString *> *sortedLabels = [scores keysSortedByValueUsingComparator:^NSComparisonResult(NSNumber *obj1, NSNumber *obj2) {
        return [obj2 compare:obj1];
    }];

    NSMutableArray<TLWLocalIdentifyResult *> *results = [NSMutableArray array];
    NSInteger count = MIN(sortedLabels.count, 3);
    for (NSInteger i = 0; i < count; i++) {
        NSString *label = sortedLabels[i];
        TLWLocalIdentifyResult *result = [[TLWLocalIdentifyResult alloc] init];
        result.label = label;
        result.confidence = scores[label].floatValue;
        result.name = self.labelToChineseName[label] ?: label;
        result.crop = self.labelToChineseCrop[label] ?: @"";
        [results addObject:result];
    }
    return [results copy];
}

- (NSString *)tl_debugSummaryForObservations:(NSArray<VNClassificationObservation *> *)observations
                                  cropOption:(VNImageCropAndScaleOption)cropOption {
    NSInteger count = MIN(observations.count, 3);
    NSMutableArray<NSString *> *segments = [NSMutableArray array];
    for (NSInteger i = 0; i < count; i++) {
        VNClassificationObservation *observation = observations[i];
        NSString *name = self.labelToChineseName[observation.identifier] ?: observation.identifier;
        [segments addObject:[NSString stringWithFormat:@"%@ %.1f%%", name, observation.confidence * 100]];
    }

    return [NSString stringWithFormat:@"[CoreML] %@ -> %@",
            [self tl_stringForCropOption:cropOption],
            [segments componentsJoinedByString:@", "]];
}

- (NSString *)tl_stringForCropOption:(VNImageCropAndScaleOption)cropOption {
    switch (cropOption) {
        case VNImageCropAndScaleOptionCenterCrop:
            return @"CenterCrop";
        case VNImageCropAndScaleOptionScaleFit:
            return @"ScaleFit";
        case VNImageCropAndScaleOptionScaleFill:
            return @"ScaleFill";
        default:
            return @"Unknown";
    }
}

- (CGImagePropertyOrientation)tl_cgImageOrientationForImageOrientation:(UIImageOrientation)imageOrientation {
    switch (imageOrientation) {
        case UIImageOrientationUp:
            return kCGImagePropertyOrientationUp;
        case UIImageOrientationDown:
            return kCGImagePropertyOrientationDown;
        case UIImageOrientationLeft:
            return kCGImagePropertyOrientationLeft;
        case UIImageOrientationRight:
            return kCGImagePropertyOrientationRight;
        case UIImageOrientationUpMirrored:
            return kCGImagePropertyOrientationUpMirrored;
        case UIImageOrientationDownMirrored:
            return kCGImagePropertyOrientationDownMirrored;
        case UIImageOrientationLeftMirrored:
            return kCGImagePropertyOrientationLeftMirrored;
        case UIImageOrientationRightMirrored:
            return kCGImagePropertyOrientationRightMirrored;
    }
    return kCGImagePropertyOrientationUp;
}

#pragma mark - 标签映射

- (void)tl_buildLabelMapping {
    // 英文标签 → 中文病害名
    self.labelToChineseName = @{
        @"Apple___Apple_scab":           @"苹果黑星病",
        @"Apple___Black_rot":            @"苹果黑腐病",
        @"Apple___Cedar_apple_rust":     @"苹果雪松锈病",
        @"Apple___healthy":              @"苹果（健康）",
        @"Background_without_leaves":    @"背景（无叶片）",
        @"Blueberry___healthy":          @"蓝莓（健康）",
        @"Cherry___Powdery_mildew":      @"樱桃白粉病",
        @"Cherry___healthy":             @"樱桃（健康）",
        @"Corn___Cercospora_leaf_spot Gray_leaf_spot": @"玉米灰斑病",
        @"Corn___Common_rust":           @"玉米普通锈病",
        @"Corn___Northern_Leaf_Blight":  @"玉米大斑病",
        @"Corn___healthy":               @"玉米（健康）",
        @"Grape___Black_rot":            @"葡萄黑腐病",
        @"Grape___Esca_(Black_Measles)": @"葡萄黑麻疹病",
        @"Grape___Leaf_blight_(Isariopsis_Leaf_Spot)": @"葡萄叶枯病",
        @"Grape___healthy":              @"葡萄（健康）",
        @"Orange___Haunglongbing_(Citrus_greening)": @"柑橘黄龙病",
        @"Peach___Bacterial_spot":       @"桃细菌性穿孔病",
        @"Peach___healthy":              @"桃（健康）",
        @"Pepper,_bell___Bacterial_spot": @"甜椒细菌性斑点病",
        @"Pepper,_bell___healthy":       @"甜椒（健康）",
        @"Potato___Early_blight":        @"马铃薯早疫病",
        @"Potato___Late_blight":         @"马铃薯晚疫病",
        @"Potato___healthy":             @"马铃薯（健康）",
        @"Raspberry___healthy":          @"树莓（健康）",
        @"Soybean___healthy":            @"大豆（健康）",
        @"Squash___Powdery_mildew":      @"南瓜白粉病",
        @"Strawberry___Leaf_scorch":     @"草莓叶焦病",
        @"Strawberry___healthy":         @"草莓（健康）",
        @"Tomato___Bacterial_spot":      @"番茄细菌性斑点病",
        @"Tomato___Early_blight":        @"番茄早疫病",
        @"Tomato___Late_blight":         @"番茄晚疫病",
        @"Tomato___Leaf_Mold":           @"番茄叶霉病",
        @"Tomato___Septoria_leaf_spot":  @"番茄斑枯病",
        @"Tomato___Spider_mites Two-spotted_spider_mite": @"番茄红蜘蛛危害",
        @"Tomato___Target_Spot":         @"番茄靶斑病",
        @"Tomato___Tomato_Yellow_Leaf_Curl_Virus": @"番茄黄化曲叶病毒病",
        @"Tomato___Tomato_mosaic_virus": @"番茄花叶病毒病",
        @"Tomato___healthy":             @"番茄（健康）",
    };

    // 英文标签 → 中文作物名
    self.labelToChineseCrop = @{
        @"Apple___Apple_scab":           @"苹果",
        @"Apple___Black_rot":            @"苹果",
        @"Apple___Cedar_apple_rust":     @"苹果",
        @"Apple___healthy":              @"苹果",
        @"Background_without_leaves":    @"",
        @"Blueberry___healthy":          @"蓝莓",
        @"Cherry___Powdery_mildew":      @"樱桃",
        @"Cherry___healthy":             @"樱桃",
        @"Corn___Cercospora_leaf_spot Gray_leaf_spot": @"玉米",
        @"Corn___Common_rust":           @"玉米",
        @"Corn___Northern_Leaf_Blight":  @"玉米",
        @"Corn___healthy":               @"玉米",
        @"Grape___Black_rot":            @"葡萄",
        @"Grape___Esca_(Black_Measles)": @"葡萄",
        @"Grape___Leaf_blight_(Isariopsis_Leaf_Spot)": @"葡萄",
        @"Grape___healthy":              @"葡萄",
        @"Orange___Haunglongbing_(Citrus_greening)": @"柑橘",
        @"Peach___Bacterial_spot":       @"桃",
        @"Peach___healthy":              @"桃",
        @"Pepper,_bell___Bacterial_spot": @"甜椒",
        @"Pepper,_bell___healthy":       @"甜椒",
        @"Potato___Early_blight":        @"马铃薯",
        @"Potato___Late_blight":         @"马铃薯",
        @"Potato___healthy":             @"马铃薯",
        @"Raspberry___healthy":          @"树莓",
        @"Soybean___healthy":            @"大豆",
        @"Squash___Powdery_mildew":      @"南瓜",
        @"Strawberry___Leaf_scorch":     @"草莓",
        @"Strawberry___healthy":         @"草莓",
        @"Tomato___Bacterial_spot":      @"番茄",
        @"Tomato___Early_blight":        @"番茄",
        @"Tomato___Late_blight":         @"番茄",
        @"Tomato___Leaf_Mold":           @"番茄",
        @"Tomato___Septoria_leaf_spot":  @"番茄",
        @"Tomato___Spider_mites Two-spotted_spider_mite": @"番茄",
        @"Tomato___Target_Spot":         @"番茄",
        @"Tomato___Tomato_Yellow_Leaf_Curl_Virus": @"番茄",
        @"Tomato___Tomato_mosaic_virus": @"番茄",
        @"Tomato___healthy":             @"番茄",
    };
}

@end
