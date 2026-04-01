//
//  TLWWarningModel.h
//  TL-PestIdentify
//
//  Created by xiaoli pop on 2026/3/11.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TLWWarningModel : NSObject
@property (nonatomic, copy)NSString* string;
@property (nonatomic, assign)BOOL shouldExpand;//判断是否需要折叠
@end

NS_ASSUME_NONNULL_END
