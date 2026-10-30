#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
/// 一次富文本变更；范围采用旧段落 textStorage 的 UTF-16 坐标，绝不是 Markdown 原文范围。
@interface TLWAIMarkdownRenderPatch : NSObject
@property (nonatomic, assign, readonly) NSRange oldRenderedRange;
@property (nonatomic, copy, readonly) NSAttributedString *replacement;
/// 比较文字和属性，保留共同前后缀；变更边界不截断组合字符。完全相同返回 nil。
+ (nullable instancetype)patchFrom:(NSAttributedString *)previous to:(NSAttributedString *)next;
@end
NS_ASSUME_NONNULL_END
