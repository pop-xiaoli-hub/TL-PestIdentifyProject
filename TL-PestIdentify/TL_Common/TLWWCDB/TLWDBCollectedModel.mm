//
//  TLWDBCollectedModel.mm
//  TL-PestIdentify
//
//  Created by xiaoli pop on 2026/3/31.
//

#import "TLWDBCollectedModel+WCTTableCoding.h"
#import <WCDB/WCDBObjc.h>

@implementation TLWDBCollectedModel

WCDB_IMPLEMENTATION(TLWDBCollectedModel)
WCDB_SYNTHESIZE(localId)
WCDB_SYNTHESIZE(postId)
WCDB_SYNTHESIZE(title)
WCDB_SYNTHESIZE(images)
WCDB_SYNTHESIZE(authorName)
WCDB_SYNTHESIZE(authorAvatar)
WCDB_SYNTHESIZE(favoriteCount)
WCDB_SYNTHESIZE(collectedAt)

WCDB_PRIMARY_AUTO_INCREMENT(localId)//自增主键
WCDB_UNIQUE(postId)//不重复
WCDB_INDEX("postId_index", postId)
WCDB_INDEX("collectedAt_index", collectedAt)

@end
