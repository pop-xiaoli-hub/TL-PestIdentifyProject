#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN

/// 组装 extraInfo。authorizedLocation 仅在调用方已单独授权且非空时传入。
NSString *TLWAIComposeExtraInfo(NSString * _Nullable context, NSString * _Nullable authorizedLocation);
/// 上滑取消区或已取消时不得把 partial 写入草稿。
BOOL TLWAIShouldCommitSpeechPartial(BOOL cancelZone, BOOL recordingCancelled);

typedef NS_ENUM(NSInteger, TLWAILinkDecision) {
    TLWAILinkDecisionDeny = 0,
    TLWAILinkDecisionConfirm,
    TLWAILinkDecisionAllow,
};
/// 只允许 https。host 空则拒绝；白名单为空时首次需确认。
TLWAILinkDecision TLWAIDecideLink(NSString * _Nullable scheme, NSString * _Nullable host, BOOL hostConfirmed);
/// 生成中固定「正在回复」，终态才返回纯文本。
NSString *TLWAIAccessibilityLabel(BOOL streaming, NSString * _Nullable plainText);
/// 路径变化只记 trace，禁止自动重 POST。
BOOL TLWAIShouldRepostAfterPathChange(void);
/// 可恢复网络错误或未完成终态才提供「重新生成」，不自动重发。
BOOL TLWAIOffersContinue(BOOL recoverableNetworkError, BOOL incomplete);
/// 用药建议块缺少免责声明时需要补上。
BOOL TLWAITextNeedsLabelDisclaimer(NSString * _Nullable text);
NSString *TLWAILabelDisclaimer(void);
/// 客户端审核占位，不表示服务端已审核。
NSString *TLWAIModerationPlaceholder(void);
/// 沿用识图页 0.60 本地展示阈值；低于阈值返回空，不覆盖云端。
NSString *TLWAILocalHypothesisText(NSString * _Nullable name, float confidence);

NS_ASSUME_NONNULL_END
