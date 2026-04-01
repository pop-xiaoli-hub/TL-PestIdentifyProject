//
//  TLWDBManager.h
//  TL-PestIdentify
//
//  Created by xiaoli pop on 2026/3/31.
//

#import <Foundation/Foundation.h>

@class AGPostResponseDto;
@class TLWDBCollectedModel;

NS_ASSUME_NONNULL_BEGIN

@interface TLWDBManager : NSObject

+ (instancetype)shared;

/// 插入或更新单条收藏帖子
- (BOOL)upsertCollectedPostFromDto:(AGPostResponseDto *)postDto;

/// 批量插入或更新收藏帖子
- (BOOL)upsertCollectedPostsFromDtos:(NSArray<AGPostResponseDto *> *)postDtos;

/// 查询全部收藏（按收藏时间倒序）
- (NSArray<TLWDBCollectedModel *> *)fetchAllCollectedPosts;

/// 根据帖子 ID 查询收藏
- (nullable TLWDBCollectedModel *)fetchCollectedPostByPostId:(NSNumber *)postId;

/// 是否已收藏
- (BOOL)isCollectedPost:(NSNumber *)postId;

/// 删除指定帖子收藏
- (BOOL)deleteCollectedPostByPostId:(NSNumber *)postId;

/// 清空收藏表
- (BOOL)deleteAllCollectedPosts;

@end

NS_ASSUME_NONNULL_END
