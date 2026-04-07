//
//  TLWDBIdentificationModel.mm
//  TL-PestIdentify
//
//  Created by xiaoli pop on 2026/4/7.
//

#import "TLWDBIdentificationModel+WCTTableCoding.h"
#import <WCDB/WCDBObjc.h>

@implementation TLWDBIdentificationModel

WCDB_IMPLEMENTATION(TLWDBIdentificationModel)
WCDB_SYNTHESIZE(localId)
WCDB_SYNTHESIZE(imageUrl)
WCDB_SYNTHESIZE(pestName)
WCDB_SYNTHESIZE(identifiedAt)

WCDB_PRIMARY_AUTO_INCREMENT(localId)
WCDB_UNIQUE(imageUrl)//同一张图只保留一次识别记录
WCDB_INDEX("imageUrl_index", imageUrl)
WCDB_INDEX("identifiedAt_index", identifiedAt)

@end
