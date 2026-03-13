//
//  TLWRecordModel.m
//  TL-PestIdentify
//
//  Created by Tommy on 2026/3/13.
//

#import "TLWRecordModel.h"

@implementation TLWRecordResult
@end

@implementation TLWRecordItem

- (NSString *)topPestName {
    return self.results.firstObject.pestName ?: @"未知";
}

@end

@implementation TLWRecordSection
@end
