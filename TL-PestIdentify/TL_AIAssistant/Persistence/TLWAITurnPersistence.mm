#import "TLWAITurnPersistence.h"
#import "TLWAIAssistantSession.h"
#import "TLWAIAssistantMessage.h"
#import <WCDB/WCDBObjc.h>

@interface TLWAIStoredSession : NSObject
@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, assign) double updatedAt;
@end
@interface TLWAIStoredSession (WCTTableCoding) <WCTTableCoding>
WCDB_PROPERTY(identifier)
WCDB_PROPERTY(title)
WCDB_PROPERTY(updatedAt)
@end
@implementation TLWAIStoredSession
WCDB_IMPLEMENTATION(TLWAIStoredSession)
WCDB_SYNTHESIZE(identifier)
WCDB_SYNTHESIZE(title)
WCDB_SYNTHESIZE(updatedAt)
WCDB_PRIMARY(identifier)
@end

@interface TLWAIStoredMessage : NSObject
@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, copy) NSString *sessionIdentifier;
@property (nonatomic, assign) NSInteger role;
@property (nonatomic, assign) NSInteger status;
@property (nonatomic, copy) NSString *text;
@property (nonatomic, copy) NSString *diseaseNames;
@property (nonatomic, copy) NSString *imageRelativePaths;
@property (nonatomic, assign) NSInteger completed;
@property (nonatomic, assign) double createdAt;
@property (nonatomic, copy) NSString *localHypothesis;
@property (nonatomic, copy) NSString *errorMessage;
@property (nonatomic, assign) NSInteger canContinue;
@property (nonatomic, copy) NSString *recoveryCheckpointJSON;
@end
@interface TLWAIStoredMessage (WCTTableCoding) <WCTTableCoding>
WCDB_PROPERTY(identifier)
WCDB_PROPERTY(sessionIdentifier)
WCDB_PROPERTY(role)
WCDB_PROPERTY(status)
WCDB_PROPERTY(text)
WCDB_PROPERTY(diseaseNames)
WCDB_PROPERTY(imageRelativePaths)
WCDB_PROPERTY(completed)
WCDB_PROPERTY(createdAt)
WCDB_PROPERTY(localHypothesis)
WCDB_PROPERTY(errorMessage)
WCDB_PROPERTY(canContinue)
WCDB_PROPERTY(recoveryCheckpointJSON)
@end
@implementation TLWAIStoredMessage
WCDB_IMPLEMENTATION(TLWAIStoredMessage)
WCDB_SYNTHESIZE(identifier)
WCDB_SYNTHESIZE(sessionIdentifier)
WCDB_SYNTHESIZE(role)
WCDB_SYNTHESIZE(status)
WCDB_SYNTHESIZE(text)
WCDB_SYNTHESIZE(diseaseNames)
WCDB_SYNTHESIZE(imageRelativePaths)
WCDB_SYNTHESIZE(completed)
WCDB_SYNTHESIZE(createdAt)
WCDB_SYNTHESIZE(localHypothesis)
WCDB_SYNTHESIZE(errorMessage)
WCDB_SYNTHESIZE(canContinue)
WCDB_SYNTHESIZE(recoveryCheckpointJSON)
WCDB_PRIMARY(identifier)
WCDB_INDEX("session_index", sessionIdentifier)
@end

@interface TLWAITurnPersistence ()
@property (nonatomic, strong) WCTDatabase *database;
@property (nonatomic, strong) WCTTable<TLWAIStoredSession *> *sessions;
@property (nonatomic, strong) WCTTable<TLWAIStoredMessage *> *messages;
@end

@implementation TLWAITurnPersistence

- (instancetype)initWithUserIdentifier:(NSInteger)userIdentifier directory:(NSString *)directory {
    if ((self = [super init])) {
        _userIdentifier = userIdentifier;
        NSString *root = directory.length ? directory : [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"TLWAIAssistant"];
        [NSFileManager.defaultManager createDirectoryAtPath:root withIntermediateDirectories:YES attributes:nil error:nil];
        _databasePath = [root stringByAppendingPathComponent:[NSString stringWithFormat:@"tlw_ai_assistant_%ld.db", (long)userIdentifier]];
        _database = [[WCTDatabase alloc] initWithPath:_databasePath];
        [_database createTable:@"tlw_ai_session" withClass:TLWAIStoredSession.class];
        [_database createTable:@"tlw_ai_message" withClass:TLWAIStoredMessage.class];
        _sessions = [_database getTable:@"tlw_ai_session" withClass:TLWAIStoredSession.class];
        _messages = [_database getTable:@"tlw_ai_message" withClass:TLWAIStoredMessage.class];
    }
    return self;
}

- (BOOL)upsertSession:(TLWAIAssistantSession *)session {
    if (!session.identifier.length) return NO;
    @synchronized (self) {
        TLWAIStoredSession *row = [TLWAIStoredSession new];
        row.identifier = session.identifier;
        row.title = session.title ?: @"";
        row.updatedAt = session.updatedAt.timeIntervalSince1970;
        if (![self.sessions insertOrReplaceObject:row]) return NO;
        for (TLWAIAssistantMessage *message in session.messages) {
            if (!message.identifier.length) continue;
            TLWAIStoredMessage *stored = [self storedMessage:message session:session checkpoint:message.recoveryCheckpoint];
            if (!stored) return NO;
            if (![self.messages insertOrReplaceObject:stored]) return NO;
        }
        return YES;
    }
}

- (TLWAIStoredMessage *)storedMessage:(TLWAIAssistantMessage *)message
                            session:(TLWAIAssistantSession *)session checkpoint:(NSDictionary *)checkpoint {
    TLWAIStoredMessage *stored = [TLWAIStoredMessage new];
    stored.identifier = message.identifier;
    stored.sessionIdentifier = session.identifier;
    stored.role = message.role;
    stored.status = message.status;
    stored.text = message.text ?: @"";
    stored.diseaseNames = [message.diseaseNames componentsJoinedByString:@"\n"] ?: @"";
    stored.imageRelativePaths = [message.imageRelativePaths componentsJoinedByString:@"\n"] ?: @"";
    stored.completed = message.completed ? 1 : 0;
    stored.createdAt = message.createdAt.timeIntervalSince1970;
    stored.localHypothesis = message.localHypothesis ?: @"";
    stored.errorMessage = message.errorMessage ?: @"";
    stored.canContinue = message.canContinue ? 1 : 0;
    stored.recoveryCheckpointJSON = @"";
    if (checkpoint) {
        if (![checkpoint isKindOfClass:NSDictionary.class] ||
            ![checkpoint[@"ownerId"] isKindOfClass:NSNumber.class] ||
            [checkpoint[@"ownerId"] integerValue] != self.userIdentifier ||
            ![checkpoint[@"sessionId"] isEqual:session.identifier] ||
            ![checkpoint[@"messageId"] isEqual:message.identifier] ||
            message.role != TLWAIAssistantMessageRoleAssistant) return nil;
        NSData *data = [NSJSONSerialization dataWithJSONObject:checkpoint options:0 error:nil];
        if (!data) return nil;
        stored.recoveryCheckpointJSON = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
    return stored;
}

- (BOOL)saveRecoveryCheckpoint:(NSDictionary *)checkpoint forMessage:(TLWAIAssistantMessage *)message
                      session:(TLWAIAssistantSession *)session {
    if (!session.identifier.length || !message.identifier.length) return NO;
    @synchronized (self) {
        TLWAIStoredMessage *stored = [self storedMessage:message session:session checkpoint:checkpoint];
        if (!stored) return NO;
        TLWAIStoredMessage *question = nil;
        id userID = checkpoint[@"userMessageId"];
        if ([userID isKindOfClass:NSString.class] && [userID length]) {
            for (TLWAIAssistantMessage *item in session.messages) {
                if (![item.identifier isEqual:userID]) continue;
                if (item.role != TLWAIAssistantMessageRoleUser) return NO;
                question = [self storedMessage:item session:session checkpoint:nil];
                if (!question) return NO;
                break;
            }
        }
        TLWAIStoredSession *row = [TLWAIStoredSession new];
        row.identifier = session.identifier; row.title = session.title ?: @"";
        row.updatedAt = session.updatedAt.timeIntervalSince1970;
        BOOL saved = [self.database runTransaction:^BOOL(__unused WCTHandle *handle) {
            if (![self.sessions insertOrReplaceObject:row] || ![self.messages insertOrReplaceObject:stored]) return NO;
            return question ? [self.messages insertOrReplaceObject:question] : YES;
        }];
        if (saved) message.recoveryCheckpoint = checkpoint;
        return saved;
    }
}

- (NSArray<TLWAIAssistantSession *> *)loadSessions {
    @synchronized (self) {
        NSArray<TLWAIStoredSession *> *rows = [self.sessions getObjectsOrders:TLWAIStoredSession.updatedAt.asOrder(WCTOrderedDescending)] ?: @[];
        NSMutableArray<TLWAIAssistantSession *> *sessions = [NSMutableArray arrayWithCapacity:rows.count];
        for (TLWAIStoredSession *row in rows) {
            TLWAIAssistantSession *session = [TLWAIAssistantSession new];
            session.identifier = row.identifier;
            session.title = row.title;
            session.updatedAt = [NSDate dateWithTimeIntervalSince1970:row.updatedAt];
            NSArray<TLWAIStoredMessage *> *stored = [self.messages getObjectsWhere:TLWAIStoredMessage.sessionIdentifier == row.identifier orders:TLWAIStoredMessage.createdAt.asOrder(WCTOrderedAscending)] ?: @[];
            NSMutableArray<TLWAIAssistantMessage *> *messages = [NSMutableArray arrayWithCapacity:stored.count];
            for (TLWAIStoredMessage *item in stored) {
                TLWAIAssistantMessage *message = [TLWAIAssistantMessage messageWithRole:(TLWAIAssistantMessageRole)item.role text:item.text];
                message.identifier = item.identifier;
                message.status = (TLWAIAssistantMessageStatus)item.status;
                message.completed = item.completed != 0;
                message.createdAt = [NSDate dateWithTimeIntervalSince1970:item.createdAt];
                message.diseaseNames = item.diseaseNames.length ? [item.diseaseNames componentsSeparatedByString:@"\n"] : @[];
                message.imageRelativePaths = item.imageRelativePaths.length ? [item.imageRelativePaths componentsSeparatedByString:@"\n"] : @[];
                message.localHypothesis = item.localHypothesis;
                message.errorMessage = item.errorMessage;
                message.canContinue = item.canContinue != 0;
                if (item.recoveryCheckpointJSON.length) {
                    id checkpoint = [NSJSONSerialization JSONObjectWithData:[item.recoveryCheckpointJSON dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
                    if ([checkpoint isKindOfClass:NSDictionary.class] &&
                        [checkpoint[@"ownerId"] isKindOfClass:NSNumber.class] &&
                        [checkpoint[@"ownerId"] integerValue] == self.userIdentifier &&
                        [checkpoint[@"sessionId"] isEqual:row.identifier] && [checkpoint[@"messageId"] isEqual:item.identifier])
                        message.recoveryCheckpoint = checkpoint;
                }
                [messages addObject:message];
            }
            [session replaceMessages:messages];
            [sessions addObject:session];
        }
        return sessions;
    }
}

@end
