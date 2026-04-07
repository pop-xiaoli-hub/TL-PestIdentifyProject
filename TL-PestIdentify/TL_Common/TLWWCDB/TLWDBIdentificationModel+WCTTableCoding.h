//
//  TLWDBIdentificationModel+WCTTableCoding.h
//  TL-PestIdentify
//
//  Created by xiaoli pop on 2026/4/7.
//

#import "TLWDBIdentificationModel.h"
#import <WCDB/WCDBObjc.h>

@interface TLWDBIdentificationModel (WCTTableCoding) <WCTTableCoding>

WCDB_PROPERTY(localId)
WCDB_PROPERTY(imageUrl)
WCDB_PROPERTY(pestName)
WCDB_PROPERTY(identifiedAt)

@end
