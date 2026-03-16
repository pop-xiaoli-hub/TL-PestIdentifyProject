//
//  TLWPublishController.h
//  TL-PestIdentify
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 发布页面控制器（我要发布）
/// 负责收集用户输入并发起发布请求，具体业务逻辑由后续接入接口时补充。
@interface TLWPublishController : UIViewController

/// 预留：外部可传入草稿数据，用于编辑已保存的发布内容
- (void)tl_configureWithDraft:(nullable id)draft;

@end

NS_ASSUME_NONNULL_END

