//
//  TLWDBManager.m
//  TL-PestIdentify
//
//  Created by xiaoli pop on 2026/3/31.
//

#import "TLWDBManager.h"
#import "TLWDBCollectedModel.h"
#import "TLWDBCollectedModel+WCTTableCoding.h"
#import "TLWDBIdentificationModel.h"
#import "TLWDBIdentificationModel+WCTTableCoding.h"
#import "TLWSDKManager.h"
#import <WCDB/WCDBObjc.h>
#import <AgriPestClient/AGPostResponseDto.h>

@interface TLWDBManager ()
@property (nonatomic, strong) WCTDatabase *database;
@property (nonatomic, strong) WCTTable<TLWDBCollectedModel *> *collectedTable;
@property (nonatomic, strong) WCTTable<TLWDBIdentificationModel *> *identificationTable;
@property (nonatomic, assign) NSInteger nextGeneratedLocalId;
@property (nonatomic, assign) NSInteger nextGeneratedIdentificationLocalId;
@property (nonatomic, assign) BOOL didSetupCollectedTable;
@property (nonatomic, assign) BOOL didSetupIdentificationTable;

@end

@implementation TLWDBManager

+ (instancetype)shared {
    static TLWDBManager *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[TLWDBManager alloc] init];
        [instance setupDatabase];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    return self;
}

#pragma mark - Public CRUD
//插入单条
- (BOOL)upsertCollectedPostFromDto:(AGPostResponseDto *)postDto {
    @synchronized (self) {
        [self setupCollectedTableIfNeeded];
        if (!postDto || !postDto._id) {
            return NO;
        }
        TLWDBCollectedModel *model = [self buildModelFromDto:postDto];
        if (!model) {
            return NO;
        }

        TLWDBCollectedModel *existingModel = [self fetchCollectedPostByPostId_unlocked:postDto._id];
        BOOL success = NO;
        if (existingModel) {
            model.localId = existingModel.localId;
            success = [self.collectedTable insertOrReplaceObject:model];
        } else {
            model.localId = [self generateNextLocalId];
            success = [self.collectedTable insertObject:model];
        }
        if (!success) {
            NSLog(@"[DB] upsert 单条收藏失败");
            return NO;
        }
        return YES;
    }
}

//批量插入
- (BOOL)upsertCollectedPostsFromDtos:(NSArray<AGPostResponseDto *> *)postDtos {
    @synchronized (self) {
        [self setupCollectedTableIfNeeded];
        if (postDtos.count == 0) {
            return YES;
        }

        NSMutableArray<TLWDBCollectedModel *> *insertModels = [NSMutableArray array];
        NSMutableArray<TLWDBCollectedModel *> *replaceModels = [NSMutableArray array];
        for (AGPostResponseDto *dto in postDtos) {
            TLWDBCollectedModel *model = [self buildModelFromDto:dto];
            if (model) {
                TLWDBCollectedModel *existingModel = [self fetchCollectedPostByPostId_unlocked:dto._id];
                if (existingModel) {
                    model.localId = existingModel.localId;
                    [replaceModels addObject:model];
                } else {
                    model.localId = [self generateNextLocalId];
                    [insertModels addObject:model];
                }
            }
        }
        if (insertModels.count == 0 && replaceModels.count == 0) {
            return NO;
        }

        BOOL insertSuccess = YES;
        if (insertModels.count > 0) {
            insertSuccess = [self.collectedTable insertObjects:insertModels];
        }

        BOOL replaceSuccess = YES;
        if (replaceModels.count > 0) {
            replaceSuccess = [self.collectedTable insertOrReplaceObjects:replaceModels];
        }

        if (!insertSuccess || !replaceSuccess) {
            NSLog(@"[DB] upsert 批量收藏失败");
            return NO;
        }
        return YES;
    }
}

- (NSArray<TLWDBCollectedModel *> *)fetchAllCollectedPosts {
    @synchronized (self) {
        [self setupCollectedTableIfNeeded];
        NSArray<TLWDBCollectedModel *> *result = [self.collectedTable getObjectsOrders:TLWDBCollectedModel.collectedAt.asOrder(WCTOrderedDescending)];
        return result ?: @[];
    }
}

- (nullable TLWDBCollectedModel *)fetchCollectedPostByPostId:(NSNumber *)postId {
    @synchronized (self) {
        return [self fetchCollectedPostByPostId_unlocked:postId];
    }
}

/// 内部无锁版本，供已持有锁的方法调用
- (nullable TLWDBCollectedModel *)fetchCollectedPostByPostId_unlocked:(NSNumber *)postId {
    [self setupCollectedTableIfNeeded];
    if (!postId) {
        return nil;
    }
    return [self.collectedTable getObjectWhere:TLWDBCollectedModel.postId == postId];
}

- (BOOL)isCollectedPost:(NSNumber *)postId {
    @synchronized (self) {
        return [self fetchCollectedPostByPostId_unlocked:postId] != nil;
    }
}

- (BOOL)deleteCollectedPostByPostId:(NSNumber *)postId {
    @synchronized (self) {
        [self setupCollectedTableIfNeeded];
        if (!postId) {
            return NO;
        }
        return [self.collectedTable deleteObjectsWhere:TLWDBCollectedModel.postId == postId];
    }
}

- (BOOL)deleteAllCollectedPosts {
    @synchronized (self) {
        [self setupCollectedTableIfNeeded];
        return [self.collectedTable deleteObjects];
    }
}

- (BOOL)insertIdentificationRecord:(TLWDBIdentificationModel *)record {
    @synchronized (self) {
        [self setupIdentificationTableIfNeeded];
        TLWDBIdentificationModel *normalizedRecord = [self normalizedIdentificationRecordFromRecord:record];
        if (!normalizedRecord) {
            return NO;
        }
        normalizedRecord.localId = [self generateNextIdentificationLocalId];
        return [self.identificationTable insertObject:normalizedRecord];
    }
}

- (BOOL)updateIdentificationRecord:(TLWDBIdentificationModel *)record {
    @synchronized (self) {
        [self setupIdentificationTableIfNeeded];
        TLWDBIdentificationModel *normalizedRecord = [self normalizedIdentificationRecordFromRecord:record];
        if (!normalizedRecord || normalizedRecord.localId <= 0) {
            return NO;
        }
        return [self.identificationTable insertOrReplaceObject:normalizedRecord];
    }
}

- (BOOL)upsertIdentificationRecord:(TLWDBIdentificationModel *)record {
    @synchronized (self) {
        [self setupIdentificationTableIfNeeded];
        TLWDBIdentificationModel *normalizedRecord = [self normalizedIdentificationRecordFromRecord:record];
        if (!normalizedRecord) {
            return NO;
        }

        TLWDBIdentificationModel *existingRecord = [self fetchIdentificationRecordByImageUrl_unlocked:normalizedRecord.imageUrl];
        if (existingRecord) {
            normalizedRecord.localId = existingRecord.localId;
            return [self.identificationTable insertOrReplaceObject:normalizedRecord];
        }

        normalizedRecord.localId = [self generateNextIdentificationLocalId];
        return [self.identificationTable insertObject:normalizedRecord];
    }
}

- (NSArray<TLWDBIdentificationModel *> *)fetchAllIdentificationRecords {
    @synchronized (self) {
        [self setupIdentificationTableIfNeeded];
        NSArray<TLWDBIdentificationModel *> *result = [self.identificationTable getObjectsOrders:TLWDBIdentificationModel.identifiedAt.asOrder(WCTOrderedDescending)];
        return result ?: @[];
    }
}

- (nullable TLWDBIdentificationModel *)fetchIdentificationRecordByLocalId:(NSInteger)localId {
    @synchronized (self) {
        [self setupIdentificationTableIfNeeded];
        if (localId <= 0) {
            return nil;
        }
        return [self.identificationTable getObjectWhere:TLWDBIdentificationModel.localId == localId];
    }
}

- (nullable TLWDBIdentificationModel *)fetchIdentificationRecordByImageUrl:(NSString *)imageUrl {
    @synchronized (self) {
        return [self fetchIdentificationRecordByImageUrl_unlocked:imageUrl];
    }
}

/// 内部无锁版本，供已持有锁的方法调用
- (nullable TLWDBIdentificationModel *)fetchIdentificationRecordByImageUrl_unlocked:(NSString *)imageUrl {
    [self setupIdentificationTableIfNeeded];
    if (![imageUrl isKindOfClass:[NSString class]] || imageUrl.length == 0) {
        return nil;
    }
    return [self.identificationTable getObjectWhere:TLWDBIdentificationModel.imageUrl == imageUrl];
}

- (BOOL)deleteIdentificationRecordByLocalId:(NSInteger)localId {
    @synchronized (self) {
        [self setupIdentificationTableIfNeeded];
        if (localId <= 0) {
            return NO;
        }
        return [self.identificationTable deleteObjectsWhere:TLWDBIdentificationModel.localId == localId];
    }
}

- (BOOL)deleteIdentificationRecordByImageUrl:(NSString *)imageUrl {
    @synchronized (self) {
        [self setupIdentificationTableIfNeeded];
        if (![imageUrl isKindOfClass:[NSString class]] || imageUrl.length == 0) {
            return NO;
        }
        return [self.identificationTable deleteObjectsWhere:TLWDBIdentificationModel.imageUrl == imageUrl];
    }
}

- (BOOL)deleteAllIdentificationRecords {
    @synchronized (self) {
        [self setupIdentificationTableIfNeeded];
        return [self.identificationTable deleteObjects];
    }
}

- (void)reopenForCurrentUser {
    @synchronized (self) {
        [self.database close:^{}];
        self.database = nil;
        self.collectedTable = nil;
        self.identificationTable = nil;
        self.didSetupCollectedTable = NO;
        self.didSetupIdentificationTable = NO;
        [self setupDatabase];
    }
}

#pragma mark - Private

- (void)setupDatabase {
    @synchronized (self) {
        if (self.database) {//初始化创建数据库
            return;
        }
        NSString *dbPath = [self dbPath];//获取数据库路径
        self.database = [[WCTDatabase alloc] initWithPath:dbPath];
    }
}

//创建收藏帖子列表
- (void)setupCollectedTableIfNeeded {
    @synchronized (self) {
        if (self.didSetupCollectedTable) {//如果已经建表返回
            return;
        }

        [self setupDatabase];//防御性变成，防止数据库建立失败。
        TLWDBCollectedModel *tableObject = [[TLWDBCollectedModel alloc] init];
        NSString *tableName = [self tableNameForObject:tableObject];//获取表名
        [self.database createTable:tableName withClass:TLWDBCollectedModel.class];//建表
        self.collectedTable = [self.database getTable:tableName withClass:TLWDBCollectedModel.class];//持有表
        self.didSetupCollectedTable = YES;//标记
        self.nextGeneratedLocalId = [self loadNextLocalId];//该方法会将当前表里已有的记录扫一遍，找到最大的localId，然后+1
    }
}

- (void)setupIdentificationTableIfNeeded {
    @synchronized (self) {
        if (self.didSetupIdentificationTable) {
            return;
        }

        [self setupDatabase];
        TLWDBIdentificationModel *tableObject = [[TLWDBIdentificationModel alloc] init];
    NSString *tableName = [self tableNameForObject:tableObject];
    [self.database createTable:tableName withClass:TLWDBIdentificationModel.class];
    self.identificationTable = [self.database getTable:tableName withClass:TLWDBIdentificationModel.class];
    self.didSetupIdentificationTable = YES;
    self.nextGeneratedIdentificationLocalId = [self loadNextIdentificationLocalId];
    }
}

- (NSString *)tableNameForObject:(NSObject *)object {
    if (!object) {
        return @"";
    }
    return NSStringFromClass(object.class);
}

- (NSString *)dbPath {
    NSString *documentsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSInteger userId = [TLWSDKManager shared].sessionManager.userId;
    NSString *databaseName = [NSString stringWithFormat:@"tlw_database_%ld.db", (long)userId];
    return [documentsPath stringByAppendingPathComponent:databaseName];
}

- (TLWDBCollectedModel *)buildModelFromDto:(AGPostResponseDto *)postDto {
    if (!postDto || !postDto._id) {
        return nil;
    }

    TLWDBCollectedModel *model = [[TLWDBCollectedModel alloc] init];
    model.postId = postDto._id;
    model.title = postDto.title ?: @"";
    model.images = postDto.images ?: @[];
    model.authorName = postDto.authorName ?: @"";
    model.authorAvatar = postDto.authorAvatar ?: @"";
    model.favoriteCount = postDto.favoriteCount ?: @0;
    model.collectedAt = (long long)([[NSDate date] timeIntervalSince1970] * 1000);
  NSLog(@"\nPost ID: %@\nTitle: %@\nImages: %@\nAuthor Name: %@\nAuthor Avatar: %@\nFavorite Count: %@\nCollected At: %lld\n",
        model.postId,
        model.title,
        model.images,
        model.authorName,
        model.authorAvatar,
        model.favoriteCount,
        model.collectedAt);
    return model;
}

- (NSInteger)loadNextLocalId {
    NSArray<TLWDBCollectedModel *> *allModels = [self fetchAllCollectedPosts];
    NSInteger maxLocalId = 0;
    for (TLWDBCollectedModel *model in allModels) {
        if (model.localId > maxLocalId) {
            maxLocalId = model.localId;
        }
    }
    return maxLocalId + 1;
}

- (NSInteger)generateNextLocalId {
    NSInteger localId = self.nextGeneratedLocalId;
    self.nextGeneratedLocalId += 1;
    return localId;
}

- (TLWDBIdentificationModel *)normalizedIdentificationRecordFromRecord:(TLWDBIdentificationModel *)record {
    if (![record isKindOfClass:[TLWDBIdentificationModel class]] ||
        ![record.imageUrl isKindOfClass:[NSString class]] ||
        record.imageUrl.length == 0) {
        return nil;
    }

    TLWDBIdentificationModel *normalizedRecord = [[TLWDBIdentificationModel alloc] init];
    normalizedRecord.localId = record.localId;
    normalizedRecord.imageUrl = record.imageUrl;
    normalizedRecord.pestName = ([record.pestName isKindOfClass:[NSString class]] && record.pestName.length > 0) ? record.pestName : @"";
    normalizedRecord.identifiedAt = record.identifiedAt > 0 ? record.identifiedAt : (long long)([[NSDate date] timeIntervalSince1970] * 1000);
    return normalizedRecord;
}

- (NSInteger)loadNextIdentificationLocalId {
    NSArray<TLWDBIdentificationModel *> *allModels = [self fetchAllIdentificationRecords];
    NSInteger maxLocalId = 0;
    for (TLWDBIdentificationModel *model in allModels) {
        if (model.localId > maxLocalId) {
            maxLocalId = model.localId;
        }
    }
    return maxLocalId + 1;
}

- (NSInteger)generateNextIdentificationLocalId {
    NSInteger localId = self.nextGeneratedIdentificationLocalId;
    self.nextGeneratedIdentificationLocalId += 1;
    return localId;
}

@end
