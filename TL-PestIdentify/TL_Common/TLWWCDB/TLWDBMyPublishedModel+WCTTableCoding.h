//
//  TLWDBMyPublishedModel+WCTTableCoding.h
//  TL-PestIdentify
//
//  Created by xiaoli pop on 2026/4/15.
//

#import "TLWDBMyPublishedModel.h"
#import <WCDB/WCDBObjc.h>

@interface TLWDBMyPublishedModel (WCTTableCoding) <WCTTableCoding>

WCDB_PROPERTY(localId)
WCDB_PROPERTY(postId)
WCDB_PROPERTY(title)
WCDB_PROPERTY(content)
WCDB_PROPERTY(images)
WCDB_PROPERTY(tags)
WCDB_PROPERTY(authorName)
WCDB_PROPERTY(authorAvatar)
WCDB_PROPERTY(likeCount)
WCDB_PROPERTY(favoriteCount)
WCDB_PROPERTY(isLiked)
WCDB_PROPERTY(isFavorited)
WCDB_PROPERTY(publishedAt)
WCDB_PROPERTY(updatedAt)

@end
