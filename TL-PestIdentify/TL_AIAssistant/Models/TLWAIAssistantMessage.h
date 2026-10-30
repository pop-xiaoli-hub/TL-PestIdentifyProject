//
//  TLWAIAssistantMessage.h
//  TL-PestIdentify
//
//  Created by Northern Lights on 2026/4/3.
//  职责：定义AI助手数据模型。
//
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class TLWAITrace;
@class TLWAIEventEnvelope;
NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, TLWAIAssistantMessageRole) {
    TLWAIAssistantMessageRoleUser = 0,
    TLWAIAssistantMessageRoleAssistant,
    TLWAIAssistantMessageRoleSystem,
};

typedef NS_ENUM(NSInteger, TLWAIAssistantMessageStatus) {
    TLWAIAssistantMessageStatusIdle = 0,
    TLWAIAssistantMessageStatusSending,
    TLWAIAssistantMessageStatusFailed,
    TLWAIAssistantMessageStatusQueued,
    TLWAIAssistantMessageStatusWaiting,
    TLWAIAssistantMessageStatusRecovering,
};

@interface TLWAIAssistantMessage : NSObject

/// 稳定标识，供流式 turn 与局部刷新定位消息。
@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, assign) TLWAIAssistantMessageRole role;
@property (nonatomic, assign) TLWAIAssistantMessageStatus status;
@property (nonatomic, copy) NSString *text;
@property (nonatomic, copy) NSArray<UIImage *> *localImages;
/// 高清原图，仅用于点击放大全屏预览；localImages 存的是 120px 缩略图给气泡渲染。
@property (nonatomic, copy, nullable) NSArray<UIImage *> *previewImages;
@property (nonatomic, copy) NSArray<NSString *> *remoteImageURLs;
/// 第一张图片的原始尺寸，用于 cell 按比例显示。CGSizeZero 表示未知，fallback 正方形。
/// 沙盒图片相对路径。trim 只清内存图，不删这些路径对应的文件。
@property (nonatomic, copy) NSArray<NSString *> *imageRelativePaths;
@property (nonatomic, assign) CGSize imageDisplaySize;
@property (nonatomic, strong) NSDate *createdAt;
@property (nonatomic, copy, nullable) NSString *errorMessage;
@property (nonatomic, strong, nullable) TLWAITrace *trace;
@property (nonatomic, assign) BOOL hasAssistantOutput;
/// 仅业务 done 为 YES；取消/中断的部分答案不可冒充已完成的上下文。
@property (nonatomic, assign) BOOL completed;
/// 退化卡只使用真实 disease 事件提取出的名称/置信度，不混入方案正文。
@property (nonatomic, copy) NSString *diseaseSummary;
@property (nonatomic, copy) NSArray<NSString *> *diseaseNames;
/// 端侧初判假设，不写入 diseaseNames，不能覆盖云端卡。
@property (nonatomic, copy) NSString *localHypothesis;
/// 可恢复网络错误/未完成时为 YES；有有效 job 检查点时继续接收，否则重新生成新任务。
@property (nonatomic, assign) BOOL canContinue;
/// 可靠接收内容与已提交游标的同一检查点；UI 显示进度不作为恢复游标。
@property (nonatomic, copy, nullable) NSDictionary *recoveryCheckpoint;
/// canContinue 的动作语义：YES 继续原 job，NO 为显式重新生成；检查点可能保留作诊断。
@property (nonatomic, assign) BOOL canResumeJob;
/// 客户端审核占位，不表示服务端已审核。
@property (nonatomic, copy) NSString *moderationNote;
/// done 原始对象仅留在内存，不输出日志；仅实际字符串 info/suggestions 进入补充展示。
@property (nonatomic, copy) NSDictionary *completionInfo;
@property (nonatomic, strong, readonly) NSMutableArray<TLWAIEventEnvelope *> *eventEnvelopes;
@property (nonatomic, copy, readonly) NSString *supplementalText;
@property (nonatomic, copy, readonly) NSString *auxiliaryText;
/// 追加实际 fallbackText/info/suggestion；空白不建 view。
- (void)appendSupplementalText:(NSString *)text;
/// 鉴权重建丢弃旧连接的卡片与补充信息，不动用户原始消息。
- (void)resetAssistantMetadata;

+ (instancetype)messageWithRole:(TLWAIAssistantMessageRole)role
                           text:(nullable NSString *)text;

+ (instancetype)messageWithRole:(TLWAIAssistantMessageRole)role
                           text:(nullable NSString *)text
                    localImages:(nullable NSArray<UIImage *> *)localImages
                remoteImageURLs:(nullable NSArray<NSString *> *)remoteImageURLs;

@end

NS_ASSUME_NONNULL_END
