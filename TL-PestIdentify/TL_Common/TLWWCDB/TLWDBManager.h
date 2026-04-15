//
//  TLWDBManager.h
//  TL-PestIdentify
//
//  Created by xiaoli pop on 2026/3/31.
//

#import <Foundation/Foundation.h>

@class AGPostResponseDto;
@class TLWDBCollectedModel;
@class TLWDBIdentificationModel;
@class TLWDBMyPublishedModel;

NS_ASSUME_NONNULL_BEGIN

@interface TLWDBManager : NSObject

+ (instancetype)shared;

/// 插入或更新单条收藏帖子
- (BOOL)upsertCollectedPostFromDto:(AGPostResponseDto *)postDto;

/// 批量插入或更新收藏帖子
- (BOOL)upsertCollectedPostsFromDtos:(NSArray<AGPostResponseDto *> *)postDtos;

/// 查询全部收藏（按收藏时间倒序）
- (NSArray<TLWDBCollectedModel *> *)fetchAllCollectedPosts;

/// 格式化输出全部收藏帖子（按收藏时间倒序）
- (NSString *)formattedCollectedPostsDescription;

/// 打印全部收藏帖子的格式化内容
- (void)printFormattedCollectedPosts;

/// 根据帖子 ID 查询收藏
- (nullable TLWDBCollectedModel *)fetchCollectedPostByPostId:(NSNumber *)postId;

/// 是否已收藏
- (BOOL)isCollectedPost:(NSNumber *)postId;

/// 删除指定帖子收藏
- (BOOL)deleteCollectedPostByPostId:(NSNumber *)postId;

/// 清空收藏表
- (BOOL)deleteAllCollectedPosts;

/// 清理早于指定时间的收藏缓存
- (BOOL)cleanCacheWithDeadDate;

/// 插入识别记录
- (BOOL)insertIdentificationRecord:(TLWDBIdentificationModel *)record;

/// 更新识别记录
- (BOOL)updateIdentificationRecord:(TLWDBIdentificationModel *)record;

/// 插入或更新识别记录
- (BOOL)upsertIdentificationRecord:(TLWDBIdentificationModel *)record;

/// 查询全部识别记录（按识别时间倒序）
- (NSArray<TLWDBIdentificationModel *> *)fetchAllIdentificationRecords;

/// 根据本地主键查询识别记录
- (nullable TLWDBIdentificationModel *)fetchIdentificationRecordByLocalId:(NSInteger)localId;

/// 根据图片 URL 查询识别记录
- (nullable TLWDBIdentificationModel *)fetchIdentificationRecordByImageUrl:(NSString *)imageUrl;

/// 删除指定本地主键的识别记录
- (BOOL)deleteIdentificationRecordByLocalId:(NSInteger)localId;

/// 删除指定图片 URL 的识别记录
- (BOOL)deleteIdentificationRecordByImageUrl:(NSString *)imageUrl;

/// 清空识别记录表
- (BOOL)deleteAllIdentificationRecords;

/// 插入我的发布帖子
- (BOOL)insertMyPublishedPost:(TLWDBMyPublishedModel *)post;

/// 更新我的发布帖子
- (BOOL)updateMyPublishedPost:(TLWDBMyPublishedModel *)post;

/// 插入或更新我的发布帖子
- (BOOL)upsertMyPublishedPost:(TLWDBMyPublishedModel *)post;

/// 从接口 DTO 插入或更新我的发布帖子
- (BOOL)upsertMyPublishedPostFromDto:(AGPostResponseDto *)postDto;

/// 从接口 DTO 批量插入或更新我的发布帖子
- (BOOL)upsertMyPublishedPostsFromDtos:(NSArray<AGPostResponseDto *> *)postDtos;

/// 查询全部我的发布帖子（按发布时间倒序）
- (NSArray<TLWDBMyPublishedModel *> *)fetchAllMyPublishedPosts;

/// 根据本地主键查询我的发布帖子
- (nullable TLWDBMyPublishedModel *)fetchMyPublishedPostByLocalId:(NSInteger)localId;

/// 根据帖子 ID 查询我的发布帖子
- (nullable TLWDBMyPublishedModel *)fetchMyPublishedPostByPostId:(NSNumber *)postId;

/// 删除指定本地主键的我的发布帖子
- (BOOL)deleteMyPublishedPostByLocalId:(NSInteger)localId;

/// 删除指定帖子 ID 的我的发布帖子
- (BOOL)deleteMyPublishedPostByPostId:(NSNumber *)postId;

/// 清空我的发布帖子表
- (BOOL)deleteAllMyPublishedPosts;

/// 切换用户后重新打开对应的数据库文件（按当前 userId 重建路径）
- (void)reopenForCurrentUser;

@end

NS_ASSUME_NONNULL_END
