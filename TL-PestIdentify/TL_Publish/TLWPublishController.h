//
//  TLWPublishController.h
//  TL-PestIdentify
//

#import <UIKit/UIKit.h>
@class TLWCommunityPost;
NS_ASSUME_NONNULL_BEGIN

/// 发布页面控制器（我要发布）
/// 收集输入、上传图片并发布；只有服务端确认后才回调列表。
@interface TLWPublishController : UIViewController
@property (nonatomic, copy, nullable) void (^onPublished)(TLWCommunityPost *post);
/// 预留：外部可传入草稿数据，用于编辑已保存的发布内容
- (void)tl_configureWithDraft:(nullable id)draft;

@end

NS_ASSUME_NONNULL_END

