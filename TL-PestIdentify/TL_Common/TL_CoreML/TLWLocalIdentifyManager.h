//
//  TLWLocalIdentifyManager.h
//  TL-PestIdentify
//
//  Core ML 本地病虫害识别管理器
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 单条识别结果
@interface TLWLocalIdentifyResult : NSObject
@property (nonatomic, copy) NSString *label;       // 原始英文标签，如 Tomato___Late_blight
@property (nonatomic, copy) NSString *name;        // 中文病害名，如 番茄晚疫病
@property (nonatomic, copy) NSString *crop;        // 中文作物名，如 番茄
@property (nonatomic, assign) float confidence;    // 置信度 0~1
@end

typedef void(^TLWLocalIdentifyCompletion)(NSArray<TLWLocalIdentifyResult *> * _Nullable results, NSError * _Nullable error);

@interface TLWLocalIdentifyManager : NSObject

+ (instancetype)shared;

/// 对图片进行本地识别，返回 Top3 结果，回调在主线程
- (void)identifyImage:(UIImage *)image completion:(TLWLocalIdentifyCompletion)completion;

@end

NS_ASSUME_NONNULL_END
