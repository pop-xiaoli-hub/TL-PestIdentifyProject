#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN
/// 未知事件兼容信封；字段来自真实帧，仅 fallbackText 可进入退化展示，不把 payload 转成正文。
@interface TLWAIEventEnvelope : NSObject
@property (nonatomic, copy, readonly) NSString *eventName;
@property (nonatomic, copy, readonly) NSString *eventID;
@property (nonatomic, copy, readonly) NSDictionary *payload;
@property (nonatomic, copy, readonly) NSString *fallbackText;
/// eventID 缺失为空；payload 非对象时为空字典，fallbackText 必须是实际字符串字段。
- (instancetype)initWithEventName:(NSString *)eventName eventID:(NSString *)eventID payload:(NSDictionary *)payload;
@end
NS_ASSUME_NONNULL_END
