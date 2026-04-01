//
//  TLWDBCollectedModel.h
//  TL-PestIdentify
//
//  Created by xiaoli pop on 2026/3/31.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 收藏帖子本地存储模型（WCDB）
@interface TLWDBCollectedModel : NSObject

/// 本地主键（自增）
@property (nonatomic, assign) NSInteger localId;

/// 帖子 ID（服务端）
@property (nonatomic, strong) NSNumber *postId;

/// 标题
@property (nonatomic, copy) NSString *title;


/// 图片 URL 列表
@property (nonatomic, copy) NSArray<NSString *> *images;


/// 作者名
@property (nonatomic, copy) NSString *authorName;

/// 作者头像 URL
@property (nonatomic, copy) NSString *authorAvatar;

/// 收藏数
@property (nonatomic, strong) NSNumber *favoriteCount;

/// 收藏时间戳（毫秒）
@property (nonatomic, assign) long long collectedAt;

@end

NS_ASSUME_NONNULL_END
