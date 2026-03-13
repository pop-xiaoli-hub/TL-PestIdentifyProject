//
//  TLWRecordModel.h
//  TL-PestIdentify
//
//  Created by Tommy on 2026/3/13.
//

#import <Foundation/Foundation.h>

/// 单个候选识别结果（一张图最多对应 3 个候选）
@interface TLWRecordResult : NSObject
@property (nonatomic, copy) NSString *pestName;   // 病害名称，如"炭疽病"
@property (nonatomic, assign) float confidence;    // 置信度，0.0~1.0
@property (nonatomic, copy) NSString *solution;    // 解决方案文本
@end

/// 单条识别记录
@interface TLWRecordItem : NSObject
@property (nonatomic, copy) NSString *recordId;                       // 记录 ID
@property (nonatomic, copy) NSString *imageURL;                       // 图片 URL
@property (nonatomic, copy) NSString *recordTime;                     // 识别时间，如 "2025-11-28 14:32"
@property (nonatomic, strong) NSArray<TLWRecordResult *> *results;    // 候选结果，最多 3 条，按置信度降序
/// 置信度最高的病害名称，供列表页展示
- (NSString *)topPestName;
@end

/// 按日期分组的一组记录
@interface TLWRecordSection : NSObject
@property (nonatomic, copy) NSString *dateString;
@property (nonatomic, strong) NSArray<TLWRecordItem *> *items;
@end
