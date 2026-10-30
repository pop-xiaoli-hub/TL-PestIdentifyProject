#import "TLWAITurnStore.h"
#import "TLWAIAssistantSession.h"
@interface TLWAITurnStore ()
@property (nonatomic, strong) NSMutableArray<TLWAIAssistantSession *> *mutableSessions;
@property (nonatomic, strong, readwrite) TLWAIAssistantSession *currentSession;
@end
@implementation TLWAITurnStore
- (instancetype)initWithUserIdentifier:(NSInteger)userIdentifier {
    if ((self = [super init])) {
        _userIdentifier = userIdentifier; _mutableSessions = [NSMutableArray array];
        [self createSession];
    }
    return self;
}
- (NSArray<TLWAIAssistantSession *> *)sessions { return [self.mutableSessions copy]; }
- (TLWAIAssistantSession *)createSession {
    TLWAIAssistantSession *session = [TLWAIAssistantSession new];
    [self.mutableSessions insertObject:session atIndex:0]; self.currentSession = session;
    return session;
}
- (BOOL)selectSessionWithIdentifier:(NSString *)identifier {
    for (TLWAIAssistantSession *session in self.mutableSessions) {
        if ([session.identifier isEqualToString:identifier]) { self.currentSession = session; return YES; }
    }
    return NO;
}
- (void)replaceWithSessions:(NSArray<TLWAIAssistantSession *> *)sessions currentIdentifier:(NSString *)identifier {
    if (!sessions.count) return;
    [self.mutableSessions removeAllObjects];
    [self.mutableSessions addObjectsFromArray:sessions];
    if (![self selectSessionWithIdentifier:identifier]) self.currentSession = sessions.firstObject;
}
@end
