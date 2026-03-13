//
//  TLWRecordModel.h
//  TL-PestIdentify
//
//  Created by Tommy on 2026/3/13.
//

#import <Foundation/Foundation.h>

// 单条识别记录
@interface TLWRecordItem : NSObject
@property (nonatomic, copy) NSString *pestName;   // 病虫害名称
@property (nonatomic, copy) NSString *imageURL;   // 图片 URL（本地路径或远程 URL）
@property (nonatomic, copy) NSString *recordId;   // 记录 ID，备用
@end

// 按日期分组的一组记录
@interface TLWRecordSection : NSObject
@property (nonatomic, copy) NSString *dateString;          // 日期，格式 "2025-11-28"
@property (nonatomic, strong) NSArray<TLWRecordItem *> *items;
@end
