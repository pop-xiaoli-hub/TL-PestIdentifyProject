//
//  TLWPostModel.h
//  TL-PestIdentify
//
//  Created by xiaoli pop on 2026/3/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TLWPostModel : NSObject
@property(nonatomic) NSNumber* _id;
/* 标题 [optional]
 */
@property(nonatomic) NSString* title;
/* 内容 [optional]
 */
@property(nonatomic) NSString* content;
/* 图片列表 [optional]
 */
@property(nonatomic) NSArray* images;
/* 标签列表 [optional]
 */
@property(nonatomic) NSArray<NSString*>* tags;
/* 作者ID [optional]
 */
@property(nonatomic) NSNumber* authorId;
/* 作者用户名 [optional]
 */
@property(nonatomic) NSString* authorName;
/* 作者头像 [optional]
 */
@property(nonatomic) NSString* authorAvatar;
/* 点赞数 [optional]
 */
@property(nonatomic) NSNumber* likeCount;
/* 收藏数 [optional]
 */
@property(nonatomic) NSNumber* favoriteCount;
/* 评论数 [optional]
 */
@property(nonatomic) NSNumber* commentCount;
/* 当前用户是否已点赞 [optional]
 */
@property(nonatomic) NSNumber* isLiked;
/* 当前用户是否已收藏 [optional]
 */
@property(nonatomic) NSNumber* isFavorited;
/* 创建时间 [optional]
 */
@property(nonatomic) NSDate* createdAt;
/* 更新时间 [optional]
 */
@property(nonatomic) NSDate* updatedAt;
@end

NS_ASSUME_NONNULL_END
