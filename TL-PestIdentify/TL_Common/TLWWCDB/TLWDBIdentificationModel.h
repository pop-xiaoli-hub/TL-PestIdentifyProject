//
//  TLWDBIdentificationModel.h
//  TL-PestIdentify
//
//  Created by xiaoli pop on 2026/4/7.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TLWDBIdentificationModel : NSObject

/// 本地主键（自增）
@property (nonatomic, assign) NSInteger localId;

/// 图片 URL
@property (nonatomic, copy) NSString *imageUrl;

/// 病害名称
@property (nonatomic, copy) NSString *pestName;

/// 识别时间戳（毫秒）
@property (nonatomic, assign) long long identifiedAt;

@end

NS_ASSUME_NONNULL_END
