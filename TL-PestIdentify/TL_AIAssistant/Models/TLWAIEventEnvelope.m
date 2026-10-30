#import "TLWAIEventEnvelope.h"
@implementation TLWAIEventEnvelope
- (instancetype)initWithEventName:(NSString *)eventName eventID:(NSString *)eventID payload:(NSDictionary *)payload {
    if ((self = [super init])) {
        _eventName = [eventName copy]; _eventID = [eventID copy]; _payload = [payload copy];
        id fallback = payload[@"fallbackText"];
        _fallbackText = [fallback isKindOfClass:NSString.class] ? [fallback copy] : @"";
    }
    return self;
}
@end
