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
#import "TLWDBMyPublishedModel.h"
#import "TLWDBMyPublishedModel+WCTTableCoding.h"
#import "TLWSDKManager.h"
#import <WCDB/WCDBObjc.h>
#import <AgriPestClient/AGPostResponseDto.h>

@interface TLWDBManager ()
@property (nonatomic, strong) WCTDatabase *database;
@property (nonatomic, strong) WCTTable<TLWDBCollectedModel *> *collectedTable;
@property (nonatomic, strong) WCTTable<TLWDBIdentificationModel *> *identificationTable;
@property (nonatomic, strong) WCTTable<TLWDBMyPublishedModel *> *myPublishedTable;
@property (nonatomic, assign) NSInteger nextGeneratedLocalId;
@property (nonatomic, assign) NSInteger nextGeneratedIdentificationLocalId;
@property (nonatomic, assign) NSInteger nextGeneratedMyPublishedLocalId;
@property (nonatomic, assign) BOOL didSetupCollectedTable;
@property (nonatomic, assign) BOOL didSetupIdentificationTable;
@property (nonatomic, assign) BOOL didSetupMyPublishedTable;

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
            model.collectedAt = existingModel.collectedAt > 0 ? existingModel.collectedAt : model.collectedAt;
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
                    model.collectedAt = existingModel.collectedAt > 0 ? existingModel.collectedAt : model.collectedAt;
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

- (NSString *)formattedCollectedPostsDescription {
    NSArray<TLWDBCollectedModel *> *posts = [self fetchAllCollectedPosts];
    return [self formattedDescriptionForCollectedPosts:posts];
}

- (void)printFormattedCollectedPosts {
    NSLog(@"%@", [self formattedCollectedPostsDescription]);
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

- (BOOL)cleanCacheWithDeadDate {
    @synchronized (self) {
        [self setupCollectedTableIfNeeded];
      //倒序遍历
        NSArray<TLWDBCollectedModel *> *collectedPosts = [self.collectedTable getObjectsOrders:TLWDBCollectedModel.collectedAt.asOrder(WCTOrderedDescending)];
        if (collectedPosts.count <= 20) {
            return YES;
        }

        BOOL deleteOverflowSuccess = YES;
        for (NSUInteger idx = 20; idx < collectedPosts.count; idx++) {
            TLWDBCollectedModel *model = collectedPosts[idx];
            BOOL success = [self.collectedTable deleteObjectsWhere:TLWDBCollectedModel.localId == model.localId];
            deleteOverflowSuccess = deleteOverflowSuccess && success;
        }
        return deleteOverflowSuccess;
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

- (BOOL)insertMyPublishedPost:(TLWDBMyPublishedModel *)post {
    @synchronized (self) {
        [self setupMyPublishedTableIfNeeded];
        TLWDBMyPublishedModel *normalizedPost = [self normalizedMyPublishedPostFromPost:post existingPost:nil];
        if (!normalizedPost) {
            return NO;
        }
        normalizedPost.localId = [self generateNextMyPublishedLocalId];
        return [self.myPublishedTable insertObject:normalizedPost];
    }
}

- (BOOL)updateMyPublishedPost:(TLWDBMyPublishedModel *)post {
    @synchronized (self) {
        [self setupMyPublishedTableIfNeeded];
        TLWDBMyPublishedModel *existingPost = nil;
        if (post.localId > 0) {
            existingPost = [self fetchMyPublishedPostByLocalId_unlocked:post.localId];
        }
        if (!existingPost && post.postId) {
            existingPost = [self fetchMyPublishedPostByPostId_unlocked:post.postId];
        }

        TLWDBMyPublishedModel *normalizedPost = [self normalizedMyPublishedPostFromPost:post existingPost:existingPost];
        if (!normalizedPost || !existingPost) {
            return NO;
        }
        normalizedPost.localId = existingPost.localId;
        return [self.myPublishedTable insertOrReplaceObject:normalizedPost];
    }
}

- (BOOL)upsertMyPublishedPost:(TLWDBMyPublishedModel *)post {
    @synchronized (self) {
        [self setupMyPublishedTableIfNeeded];
        TLWDBMyPublishedModel *existingPost = [self fetchMyPublishedPostByPostId_unlocked:post.postId];
        TLWDBMyPublishedModel *normalizedPost = [self normalizedMyPublishedPostFromPost:post existingPost:existingPost];
        if (!normalizedPost) {
            return NO;
        }

        if (existingPost) {
            normalizedPost.localId = existingPost.localId;
            return [self.myPublishedTable insertOrReplaceObject:normalizedPost];
        }

        normalizedPost.localId = [self generateNextMyPublishedLocalId];
        return [self.myPublishedTable insertObject:normalizedPost];
    }
}

- (BOOL)upsertMyPublishedPostFromDto:(AGPostResponseDto *)postDto {
    TLWDBMyPublishedModel *post = [self buildMyPublishedPostFromDto:postDto];
    if (!post) {
        return NO;
    }
    return [self upsertMyPublishedPost:post];
}

- (BOOL)upsertMyPublishedPostsFromDtos:(NSArray<AGPostResponseDto *> *)postDtos {
    @synchronized (self) {
        [self setupMyPublishedTableIfNeeded];
        if (postDtos.count == 0) {
            return YES;
        }

        NSMutableArray<TLWDBMyPublishedModel *> *insertPosts = [NSMutableArray array];
        NSMutableArray<TLWDBMyPublishedModel *> *replacePosts = [NSMutableArray array];
        for (AGPostResponseDto *dto in postDtos) {
            TLWDBMyPublishedModel *post = [self buildMyPublishedPostFromDto:dto];
            if (!post) {
                continue;
            }

            TLWDBMyPublishedModel *existingPost = [self fetchMyPublishedPostByPostId_unlocked:post.postId];
            TLWDBMyPublishedModel *normalizedPost = [self normalizedMyPublishedPostFromPost:post existingPost:existingPost];
            if (!normalizedPost) {
                continue;
            }

            if (existingPost) {
                normalizedPost.localId = existingPost.localId;
                [replacePosts addObject:normalizedPost];
            } else {
                normalizedPost.localId = [self generateNextMyPublishedLocalId];
                [insertPosts addObject:normalizedPost];
            }
        }

        if (insertPosts.count == 0 && replacePosts.count == 0) {
            return NO;
        }

        BOOL insertSuccess = YES;
        if (insertPosts.count > 0) {
            insertSuccess = [self.myPublishedTable insertObjects:insertPosts];
        }

        BOOL replaceSuccess = YES;
        if (replacePosts.count > 0) {
            replaceSuccess = [self.myPublishedTable insertOrReplaceObjects:replacePosts];
        }

        return insertSuccess && replaceSuccess;
    }
}

- (NSArray<TLWDBMyPublishedModel *> *)fetchAllMyPublishedPosts {
    @synchronized (self) {
        [self setupMyPublishedTableIfNeeded];
        NSArray<TLWDBMyPublishedModel *> *result = [self.myPublishedTable getObjectsOrders:TLWDBMyPublishedModel.publishedAt.asOrder(WCTOrderedDescending)];
        return result ?: @[];
    }
}

- (nullable TLWDBMyPublishedModel *)fetchMyPublishedPostByLocalId:(NSInteger)localId {
    @synchronized (self) {
        return [self fetchMyPublishedPostByLocalId_unlocked:localId];
    }
}

- (nullable TLWDBMyPublishedModel *)fetchMyPublishedPostByLocalId_unlocked:(NSInteger)localId {
    [self setupMyPublishedTableIfNeeded];
    if (localId <= 0) {
        return nil;
    }
    return [self.myPublishedTable getObjectWhere:TLWDBMyPublishedModel.localId == localId];
}

- (nullable TLWDBMyPublishedModel *)fetchMyPublishedPostByPostId:(NSNumber *)postId {
    @synchronized (self) {
        return [self fetchMyPublishedPostByPostId_unlocked:postId];
    }
}

- (nullable TLWDBMyPublishedModel *)fetchMyPublishedPostByPostId_unlocked:(NSNumber *)postId {
    [self setupMyPublishedTableIfNeeded];
    if (!postId) {
        return nil;
    }
    return [self.myPublishedTable getObjectWhere:TLWDBMyPublishedModel.postId == postId];
}

- (BOOL)deleteMyPublishedPostByLocalId:(NSInteger)localId {
    @synchronized (self) {
        [self setupMyPublishedTableIfNeeded];
        if (localId <= 0) {
            return NO;
        }
        return [self.myPublishedTable deleteObjectsWhere:TLWDBMyPublishedModel.localId == localId];
    }
}

- (BOOL)deleteMyPublishedPostByPostId:(NSNumber *)postId {
    @synchronized (self) {
        [self setupMyPublishedTableIfNeeded];
        if (!postId) {
            return NO;
        }
        return [self.myPublishedTable deleteObjectsWhere:TLWDBMyPublishedModel.postId == postId];
    }
}

- (BOOL)deleteAllMyPublishedPosts {
    @synchronized (self) {
        [self setupMyPublishedTableIfNeeded];
        return [self.myPublishedTable deleteObjects];
    }
}

- (void)reopenForCurrentUser {
    @synchronized (self) {
        [self.database close:^{}];
        self.database = nil;
        self.collectedTable = nil;
        self.identificationTable = nil;
        self.myPublishedTable = nil;
        self.didSetupCollectedTable = NO;
        self.didSetupIdentificationTable = NO;
        self.didSetupMyPublishedTable = NO;
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

- (void)setupMyPublishedTableIfNeeded {
    @synchronized (self) {
        if (self.didSetupMyPublishedTable) {
            return;
        }

        [self setupDatabase];
        TLWDBMyPublishedModel *tableObject = [[TLWDBMyPublishedModel alloc] init];
        NSString *tableName = [self tableNameForObject:tableObject];
        [self.database createTable:tableName withClass:TLWDBMyPublishedModel.class];
        self.myPublishedTable = [self.database getTable:tableName withClass:TLWDBMyPublishedModel.class];
        self.didSetupMyPublishedTable = YES;
        self.nextGeneratedMyPublishedLocalId = [self loadNextMyPublishedLocalId];
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
    return model;
}

- (TLWDBMyPublishedModel *)buildMyPublishedPostFromDto:(AGPostResponseDto *)postDto {
    if (!postDto || !postDto._id) {
        return nil;
    }

    TLWDBMyPublishedModel *post = [[TLWDBMyPublishedModel alloc] init];
    post.postId = postDto._id;
    post.title = postDto.title ?: @"";
    post.content = postDto.content ?: @"";
    post.images = [self stringArrayFromArray:postDto.images];
    post.tags = [self stringArrayFromArray:postDto.tags];
    post.authorName = postDto.authorName ?: @"";
    post.authorAvatar = postDto.authorAvatar ?: @"";
    post.likeCount = postDto.likeCount ?: @0;
    post.favoriteCount = postDto.favoriteCount ?: @0;
    post.isLiked = postDto.isLiked.boolValue;
    post.isFavorited = postDto.isFavorited.boolValue;
    if ([postDto.createdAt isKindOfClass:NSDate.class]) {
        post.publishedAt = (long long)([postDto.createdAt timeIntervalSince1970] * 1000);
    }
    return post;
}

- (TLWDBMyPublishedModel *)normalizedMyPublishedPostFromPost:(TLWDBMyPublishedModel *)post existingPost:(nullable TLWDBMyPublishedModel *)existingPost {
    if (![post isKindOfClass:TLWDBMyPublishedModel.class] || !post.postId) {
        return nil;
    }

    long long now = (long long)([[NSDate date] timeIntervalSince1970] * 1000);
    TLWDBMyPublishedModel *normalizedPost = [[TLWDBMyPublishedModel alloc] init];
    normalizedPost.localId = post.localId;
    normalizedPost.postId = post.postId;
    normalizedPost.title = ([post.title isKindOfClass:NSString.class] && post.title.length > 0) ? post.title : @"";
    normalizedPost.content = ([post.content isKindOfClass:NSString.class] && post.content.length > 0) ? post.content : @"";
    normalizedPost.images = [self stringArrayFromArray:post.images];
    normalizedPost.tags = [self stringArrayFromArray:post.tags];
    normalizedPost.authorName = ([post.authorName isKindOfClass:NSString.class] && post.authorName.length > 0) ? post.authorName : @"";
    normalizedPost.authorAvatar = ([post.authorAvatar isKindOfClass:NSString.class] && post.authorAvatar.length > 0) ? post.authorAvatar : @"";
    normalizedPost.likeCount = post.likeCount ?: @0;
    normalizedPost.favoriteCount = post.favoriteCount ?: @0;
    normalizedPost.isLiked = post.isLiked;
    normalizedPost.isFavorited = post.isFavorited;
    normalizedPost.publishedAt = post.publishedAt > 0 ? post.publishedAt : (existingPost.publishedAt > 0 ? existingPost.publishedAt : now);
    normalizedPost.updatedAt = now;
    return normalizedPost;
}

- (NSArray<NSString *> *)stringArrayFromArray:(NSArray *)array {
    if (![array isKindOfClass:NSArray.class] || array.count == 0) {
        return @[];
    }

    NSMutableArray<NSString *> *strings = [NSMutableArray array];
    for (id item in array) {
        if ([item isKindOfClass:NSString.class] && [((NSString *)item) length] > 0) {
            [strings addObject:item];
        }
    }
    return [strings copy];
}

- (NSString *)formattedDescriptionForCollectedPosts:(NSArray<TLWDBCollectedModel *> *)posts {
    NSMutableString *output = [NSMutableString stringWithFormat:@"\n========== 收藏帖子（共 %lu 条） ==========\n", (unsigned long)posts.count];
    if (posts.count == 0) {
        [output appendString:@"暂无收藏帖子\n"];
        [output appendString:@"========================================\n"];
        return [output copy];
    }

    [posts enumerateObjectsUsingBlock:^(TLWDBCollectedModel *post, NSUInteger idx, BOOL *stop) {
        [output appendFormat:@"\n[%lu]\n", (unsigned long)idx + 1];
        [output appendFormat:@"本地 ID: %ld\n", (long)post.localId];
        [output appendFormat:@"帖子 ID: %@\n", post.postId ?: @"-"];
        [output appendFormat:@"标题: %@\n", [self safeText:post.title fallback:@"未命名帖子"]];
        [output appendFormat:@"作者: %@\n", [self safeText:post.authorName fallback:@"匿名用户"]];
        [output appendFormat:@"作者头像: %@\n", [self safeText:post.authorAvatar fallback:@"-"]];
        [output appendFormat:@"收藏数: %@\n", post.favoriteCount ?: @0];
        [output appendFormat:@"收藏时间: %@ (%lld)\n", [self readableDateStringFromMilliseconds:post.collectedAt], post.collectedAt];
        [output appendFormat:@"图片数: %lu\n", (unsigned long)post.images.count];
        if (post.images.count > 0) {
            [post.images enumerateObjectsUsingBlock:^(NSString *imageUrl, NSUInteger imageIdx, BOOL *imageStop) {
                [output appendFormat:@"  - 图片 %lu: %@\n", (unsigned long)imageIdx + 1, [self safeText:imageUrl fallback:@"-"]];
            }];
        }
    }];

    [output appendString:@"\n========================================\n"];
    return [output copy];
}

- (NSString *)safeText:(NSString *)text fallback:(NSString *)fallback {
    if (![text isKindOfClass:[NSString class]] || text.length == 0) {
        return fallback;
    }
    return text;
}

- (NSString *)readableDateStringFromMilliseconds:(long long)milliseconds {
    if (milliseconds <= 0) {
        return @"-";
    }

    NSDate *date = [NSDate dateWithTimeIntervalSince1970:milliseconds / 1000.0];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.locale = [NSLocale localeWithLocaleIdentifier:@"zh_CN"];
    formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    return [formatter stringFromDate:date];
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

- (NSInteger)loadNextMyPublishedLocalId {
    NSArray<TLWDBMyPublishedModel *> *allPosts = [self fetchAllMyPublishedPosts];
    NSInteger maxLocalId = 0;
    for (TLWDBMyPublishedModel *post in allPosts) {
        if (post.localId > maxLocalId) {
            maxLocalId = post.localId;
        }
    }
    return maxLocalId + 1;
}

- (NSInteger)generateNextMyPublishedLocalId {
    NSInteger localId = self.nextGeneratedMyPublishedLocalId;
    self.nextGeneratedMyPublishedLocalId += 1;
    return localId;
}

@end
