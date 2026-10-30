//
//  TLWAIAssistantMessageCell.h
//  TL-PestIdentify
//
//  Created by Northern Lights on 2026/4/3.
//  职责：实现AI助手消息单元视图。
//
#import <UIKit/UIKit.h>

@class TLWAIAssistantMessage;
@class TLWAIGestureCoordinator;

NS_ASSUME_NONNULL_BEGIN

@interface TLWAIAssistantMessageCell : UITableViewCell

+ (NSString *)reuseIdentifier;
- (void)configureWithMessage:(TLWAIAssistantMessage *)message;
/// 增量更新原生 Markdown 块；已闭合块保持不变，不重建图片条。
/// @param text 当前已展示的正文快照。
/// 返回整行实测高度是否变化；尚无有效宽度时返回 YES，要求后续测量。
- (BOOL)applyStreamingText:(NSString *)text;
/// 退化卡的有界展示高度；字段为空返回0，不创建空卡。
+ (CGFloat)auxiliaryHeightForMessage:(TLWAIAssistantMessage *)message;
/// 内层拖拽/减速或选区变化；用于提交局部延迟更新，不暂停整轮消费。
@property (nonatomic, copy, nullable) dispatch_block_t onInteractionChanged;
@property (nonatomic, copy, nullable) void (^onContinue)(TLWAIAssistantMessage *message);
@property (nonatomic, assign, readonly) BOOL interactionActive;
/// 停掉图片条、识别卡和代码区已松手的减速。手指仍按住时返回 YES。
- (BOOL)stopDecelerationForExplicitJump;
@property (nonatomic, assign, readonly) BOOL hasDeferredUpdates;
/// 将有界识别卡登记到本页统一接力器；正文不设纵向内滚。
- (void)registerGestureCoordinator:(nullable TLWAIGestureCoordinator *)coordinator outerTable:(UITableView *)table;

@end

NS_ASSUME_NONNULL_END
