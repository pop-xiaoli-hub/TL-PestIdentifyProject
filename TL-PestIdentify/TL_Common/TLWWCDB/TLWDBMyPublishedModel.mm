//
//  TLWDBMyPublishedModel.mm
//  TL-PestIdentify
//
//  Created by xiaoli pop on 2026/4/15.
//

#import "TLWDBMyPublishedModel+WCTTableCoding.h"
#import <WCDB/WCDBObjc.h>

@implementation TLWDBMyPublishedModel

WCDB_IMPLEMENTATION(TLWDBMyPublishedModel)
WCDB_SYNTHESIZE(localId)
WCDB_SYNTHESIZE(postId)
WCDB_SYNTHESIZE(title)
WCDB_SYNTHESIZE(content)
WCDB_SYNTHESIZE(images)
WCDB_SYNTHESIZE(tags)
WCDB_SYNTHESIZE(authorName)
WCDB_SYNTHESIZE(authorAvatar)
WCDB_SYNTHESIZE(likeCount)
WCDB_SYNTHESIZE(favoriteCount)
WCDB_SYNTHESIZE(isLiked)
WCDB_SYNTHESIZE(isFavorited)
WCDB_SYNTHESIZE(publishedAt)
WCDB_SYNTHESIZE(updatedAt)

WCDB_PRIMARY_AUTO_INCREMENT(localId)
WCDB_UNIQUE(postId)
WCDB_INDEX("postId_index", postId)
WCDB_INDEX("publishedAt_index", publishedAt)
WCDB_INDEX("updatedAt_index", updatedAt)

@end
