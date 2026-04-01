//
//  TLWCommunityPost.h
//  TL-PestIdentify
//
//  社区瀑布流单条内容模型（MVC 中的 M）
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TLWCommunityPost : NSObject
@property(nonatomic) NSNumber* _id;
@property(nonatomic) NSString* content;
@property(nonatomic) NSArray* images;
/* 标签列表 [optional]
 */
@property(nonatomic) NSArray<NSString*>* tags;
/* 作者用户名 [optional]
  */
 @property(nonatomic) NSString* authorName;
 /* 作者头像 [optional]
  */
 @property(nonatomic) NSString* authorAvatar;
/// 文本标题，如“菜心被蚜虫像蜂窝煤”
@property (nonatomic, copy) NSString *title;
/// 点赞数量
@property (nonatomic, assign) NSNumber* likeCount;

@property (nonatomic, assign) NSNumber* favoriteCount;
/// 当前用户是否已点赞
@property (nonatomic, strong, nullable) NSNumber *isLiked;
/// 当前用户是否已收藏
@property (nonatomic, strong, nullable) NSNumber *isFavorited;
/// 图片纵横比（高度 / 宽度），用于计算瀑布流高度
@property (nonatomic, assign) CGFloat imageAspectRatio;

/// 是否为本地发布中（尚未上传成功）的帖子，显示毛玻璃遮罩
@property (nonatomic, assign) BOOL isLocalPending;

@property (nonatomic, strong) NSArray* picUrls;

/// 根据给定宽度，返回 cell 的总高度（图片 + 文本 + 底部信息）
- (CGFloat)cellHeightForWidth:(CGFloat)width;

/// TODO: 接口完成后，服务端 JSON -> Model 的统一入口
/// 预期 JSON 结构：
/// [{
///   "imageUrl": "https://...",
///   "title": "菜心被蚜虫像蜂窝煤",
///   "userName": "用户2759",
///   "likeCount": 16
/// }]
+ (instancetype)postWithDictionary:(NSDictionary *)dict;


@end

NS_ASSUME_NONNULL_END
