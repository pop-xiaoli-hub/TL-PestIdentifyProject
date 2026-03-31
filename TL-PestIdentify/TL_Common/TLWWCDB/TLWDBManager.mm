//
//  TLWDBManager.m
//  TL-PestIdentify
//
//  Created by xiaoli pop on 2026/3/31.
//

#import "TLWDBManager.h"
#import "TLWDBCollectedModel.h"
#import "TLWDBCollectedModel+WCTTableCoding.h"
#import <WCDB/WCDBObjc.h>
#import <AgriPestClient/AGPostResponseDto.h>

static NSString * const kTLWCollectedTableName = @"tl_collected_posts";

@interface TLWDBManager ()
@property (nonatomic, strong) WCTDatabase *database;
@property (nonatomic, strong) WCTTable<TLWDBCollectedModel *> *collectedTable;

@end

@implementation TLWDBManager

+ (instancetype)shared {
    static TLWDBManager *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[TLWDBManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        NSString *dbPath = [self dbPath];
        _database = [[WCTDatabase alloc] initWithPath:dbPath];
        [_database createTable:kTLWCollectedTableName withClass:TLWDBCollectedModel.class];
        _collectedTable = [_database getTable:kTLWCollectedTableName withClass:TLWDBCollectedModel.class];
    }
    return self;
}

#pragma mark - Public CRUD
//插入单条
- (BOOL)upsertCollectedPostFromDto:(AGPostResponseDto *)postDto {
    if (!postDto || !postDto._id) {
        return NO;
    }
    TLWDBCollectedModel *model = [self buildModelFromDto:postDto];
    if (!model) {
        return NO;
    }

    BOOL success = [self.collectedTable insertOrReplaceObject:model];
    if (!success) {
        NSLog(@"[DB] upsert 单条收藏失败");
        return NO;
    }
    return YES;
}

//批量插入
- (BOOL)upsertCollectedPostsFromDtos:(NSArray<AGPostResponseDto *> *)postDtos {
    if (postDtos.count == 0) {
        return YES;
    }

    NSMutableArray<TLWDBCollectedModel *> *models = [NSMutableArray array];
    for (AGPostResponseDto *dto in postDtos) {
        TLWDBCollectedModel *model = [self buildModelFromDto:dto];
        if (model) {
            [models addObject:model];
        }
    }
    if (models.count == 0) {
        return NO;
    }

    BOOL success = [self.collectedTable insertOrReplaceObjects:models];
    if (!success) {
        NSLog(@"[DB] upsert 批量收藏失败");
        return NO;
    }
    return YES;
}

- (NSArray<TLWDBCollectedModel *> *)fetchAllCollectedPosts {
    NSArray<TLWDBCollectedModel *> *result = [self.collectedTable getObjectsOrders:TLWDBCollectedModel.collectedAt.asOrder(WCTOrderedDescending)];
    return result ?: @[];
}

- (nullable TLWDBCollectedModel *)fetchCollectedPostByPostId:(NSNumber *)postId {
    if (!postId) {
        return nil;
    }
    TLWDBCollectedModel *model = [self.collectedTable getObjectWhere:TLWDBCollectedModel.postId == postId];
    return model;
}

- (BOOL)isCollectedPost:(NSNumber *)postId {
    return [self fetchCollectedPostByPostId:postId] != nil;
}

- (BOOL)deleteCollectedPostByPostId:(NSNumber *)postId {
    if (!postId) {
        return NO;
    }
    return [self.collectedTable deleteObjectsWhere:TLWDBCollectedModel.postId == postId];
}

- (BOOL)deleteAllCollectedPosts {
    return [self.collectedTable deleteObjects];
}

#pragma mark - Private

- (NSString *)dbPath {
    NSString *documentsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    return [documentsPath stringByAppendingPathComponent:@"tlw_collected_posts.db"];
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

@end
