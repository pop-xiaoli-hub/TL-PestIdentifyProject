#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN
typedef NS_ENUM(NSUInteger, TLWAITextBlockKind) { TLWAITextBlockKindParagraph, TLWAITextBlockKindCode, TLWAITextBlockKindTable };
/// 与视图共用 ATX 标题规则；返回 1–6，非标题返回 0；位置采用原始行的 UTF-16 坐标。
FOUNDATION_EXPORT NSUInteger TLWAIATXHeadingLevel(NSString *line, NSUInteger * _Nullable contentStart);
/// 已闭合块不可变；仅保留原文，不冒充完整 CommonMark AST。
@interface TLWAITextBlock : NSObject
@property (nonatomic, assign, readonly) TLWAITextBlockKind kind;
@property (nonatomic, copy, readonly) NSString *source;
@end
/// 视图层唯一的增量分块状态；只扫描新字符，冻结已闭合块，不负责展示暂存或富文本转换。
@interface TLWAIIncrementalMarkdown : NSObject
@property (nonatomic, copy, readonly) NSString *source;
@property (nonatomic, copy, readonly) NSArray<TLWAITextBlock *> *closedBlocks;
@property (nonatomic, assign, readonly) TLWAITextBlockKind openBlockKind;
- (void)appendText:(NSString *)text;
/// 冻结最后一行和尾块，不执行 one-shot Markdown 解析。
- (void)finish;
/// 鉴权重建/最终快照替换时丢弃旧代全部解析状态。
- (void)reset;
@end
NS_ASSUME_NONNULL_END
