//
//  TLWDBMyPublishedModel.h
//  TL-PestIdentify
//
//  Created by xiaoli pop on 2026/4/15.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 我的发布帖子本地存储模型（WCDB）
@interface TLWDBMyPublishedModel : NSObject

/// 本地主键（自增）
@property (nonatomic, assign) NSInteger localId;

/// 帖子 ID（服务端）
@property (nonatomic, strong) NSNumber *postId;

/// 标题
@property (nonatomic, copy) NSString *title;

/// 正文内容
@property (nonatomic, copy) NSString *content;

/// 图片 URL 列表
@property (nonatomic, copy) NSArray<NSString *> *images;

/// 标签列表
@property (nonatomic, copy) NSArray<NSString *> *tags;

/// 作者名
@property (nonatomic, copy) NSString *authorName;

/// 作者头像 URL
@property (nonatomic, copy) NSString *authorAvatar;

/// 点赞数
@property (nonatomic, strong) NSNumber *likeCount;

/// 收藏数
@property (nonatomic, strong) NSNumber *favoriteCount;

/// 当前用户是否已点赞
@property (nonatomic, assign) BOOL isLiked;

/// 当前用户是否已收藏
@property (nonatomic, assign) BOOL isFavorited;

/// 发布时间戳（毫秒）
@property (nonatomic, assign) long long publishedAt;

/// 本地更新时间戳（毫秒）
@property (nonatomic, assign) long long updatedAt;

@end

NS_ASSUME_NONNULL_END
