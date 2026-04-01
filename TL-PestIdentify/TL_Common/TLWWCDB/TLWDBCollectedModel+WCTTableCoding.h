//
//  TLWDBCollectedModel+WCTTableCoding.h
//  TL-PestIdentify
//
//  Created by xiaoli pop on 2026/3/31.
//

#import "TLWDBCollectedModel.h"
#import <WCDB/WCDBObjc.h>

@interface TLWDBCollectedModel (WCTTableCoding) <WCTTableCoding>

WCDB_PROPERTY(localId)
WCDB_PROPERTY(postId)
WCDB_PROPERTY(title)
WCDB_PROPERTY(images)
WCDB_PROPERTY(authorName)
WCDB_PROPERTY(authorAvatar)
WCDB_PROPERTY(favoriteCount)
WCDB_PROPERTY(collectedAt)

@end
