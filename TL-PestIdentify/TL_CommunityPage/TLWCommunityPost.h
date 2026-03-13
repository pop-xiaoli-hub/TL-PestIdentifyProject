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

/// 帖子主图（本地占位图或远程 URL 映射名）
@property (nonatomic, copy) NSString *imageName;
/// 文本标题，如“菜心被蚜虫像蜂窝煤”
@property (nonatomic, copy) NSString *title;
/// 用户昵称
@property (nonatomic, copy) NSString *userName;
/// 点赞数量
@property (nonatomic, assign) NSInteger likeCount;
/// 模拟图片纵横比（高度 / 宽度），用于计算瀑布流高度
@property (nonatomic, assign) CGFloat imageAspectRatio;

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

/// 当前页面的本地 Mock 数据，接口接入前先用本地数据驱动 UI
+ (NSArray<TLWCommunityPost *> *)mockPosts;

@end

NS_ASSUME_NONNULL_END

