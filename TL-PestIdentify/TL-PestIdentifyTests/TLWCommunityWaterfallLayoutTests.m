#import <XCTest/XCTest.h>

#import "../TL_Community/TLWCommunityWaterfallLayout.h"

#import "../TL_Community/TLWCommunityPost.h"
@interface TLWCommunityWaterfallLayoutTestDataSource : NSObject <UICollectionViewDataSource, TLWCommunityWaterfallLayoutDelegate>
@property (nonatomic, assign) NSInteger itemCount;
@property (nonatomic, assign) NSInteger heightCallCount;
@property (nonatomic, assign) CGFloat itemHeight;
@property (nonatomic, copy) NSArray<NSNumber *> *heights;
@end

@implementation TLWCommunityWaterfallLayoutTestDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return section == 0 ? self.itemCount : 0;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    return [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)layout heightForItemAtIndexPath:(NSIndexPath *)indexPath itemWidth:(CGFloat)width {
    self.heightCallCount += 1;
    return indexPath.item < self.heights.count ? self.heights[indexPath.item].doubleValue : self.itemHeight;
}

@end

@interface TLWCommunityWaterfallLayoutTests : XCTestCase
@end

@implementation TLWCommunityWaterfallLayoutTests

- (UICollectionView *)collectionWithHeights:(NSArray<NSNumber *> *)heights source:(TLWCommunityWaterfallLayoutTestDataSource **)source {
    TLWCommunityWaterfallLayoutTestDataSource *data = [TLWCommunityWaterfallLayoutTestDataSource new];
    data.heights = heights;
    data.itemCount = heights.count;
    TLWCommunityWaterfallLayout *layout = [TLWCommunityWaterfallLayout new];
    layout.delegate = data;
    UICollectionView *collection = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, 320, 480) collectionViewLayout:layout];
    collection.dataSource = data;
    [collection registerClass:UICollectionViewCell.class forCellWithReuseIdentifier:@"cell"];
    [collection layoutIfNeeded];
    *source = data;
    return collection;
}

- (void)testHeadInsertionReassignsExistingItemsToTheirNewHeights {
    TLWCommunityWaterfallLayoutTestDataSource *source;
    UICollectionView *collection = [self collectionWithHeights:@[@80, @120, @60] source:&source];
    source.heights = @[@160, @80, @120, @60];
    source.itemCount = 4;
    [collection performBatchUpdates:^{ [collection insertItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:0 inSection:0]]]; } completion:nil];
    [collection layoutIfNeeded];
    UICollectionViewLayout *layout = collection.collectionViewLayout;
    XCTAssertEqualWithAccuracy([layout layoutAttributesForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]].frame.size.height, 160, 0.01);
    XCTAssertEqualWithAccuracy([layout layoutAttributesForItemAtIndexPath:[NSIndexPath indexPathForItem:1 inSection:0]].frame.size.height, 80, 0.01);
}

- (void)testMovingAnItemRecomputesTheAffectedSuffix {
    TLWCommunityWaterfallLayoutTestDataSource *source;
    UICollectionView *collection = [self collectionWithHeights:@[@80, @120, @60] source:&source];
    source.heights = @[@60, @80, @120];
    [collection performBatchUpdates:^{ [collection moveItemAtIndexPath:[NSIndexPath indexPathForItem:2 inSection:0] toIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]]; } completion:nil];
    [collection layoutIfNeeded];
    UICollectionViewLayout *layout = collection.collectionViewLayout;
    XCTAssertEqualWithAccuracy([layout layoutAttributesForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]].frame.size.height, 60, 0.01);
    XCTAssertEqualWithAccuracy([layout layoutAttributesForItemAtIndexPath:[NSIndexPath indexPathForItem:2 inSection:0]].frame.size.height, 120, 0.01);
}

- (void)testReloadingAnItemUpdatesItsHeightAndFollowingPlacement {
    TLWCommunityWaterfallLayoutTestDataSource *source;
    UICollectionView *collection = [self collectionWithHeights:@[@80, @120, @60] source:&source];
    source.heights = @[@200, @120, @60];
    [collection performBatchUpdates:^{ [collection reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:0 inSection:0]]]; } completion:nil];
    [collection layoutIfNeeded];
    UICollectionViewLayout *layout = collection.collectionViewLayout;
    CGRect first = [layout layoutAttributesForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]].frame;
    CGRect second = [layout layoutAttributesForItemAtIndexPath:[NSIndexPath indexPathForItem:1 inSection:0]].frame;
    CGRect third = [layout layoutAttributesForItemAtIndexPath:[NSIndexPath indexPathForItem:2 inSection:0]].frame;
    XCTAssertEqualWithAccuracy(first.size.height, 200, 0.01);
    XCTAssertEqualWithAccuracy(third.origin.x, second.origin.x, 0.01);
    XCTAssertGreaterThan(third.origin.y, CGRectGetMaxY(second));
}

- (void)testDeletingTheFirstItemReflowsTheRemainingColumns {
    TLWCommunityWaterfallLayoutTestDataSource *source;
    UICollectionView *collection = [self collectionWithHeights:@[@80, @120, @60] source:&source];
    source.heights = @[@120, @60];
    source.itemCount = 2;
    [collection performBatchUpdates:^{ [collection deleteItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:0 inSection:0]]]; } completion:nil];
    [collection layoutIfNeeded];
    UICollectionViewLayout *layout = collection.collectionViewLayout;
    CGRect first = [layout layoutAttributesForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]].frame;
    CGRect second = [layout layoutAttributesForItemAtIndexPath:[NSIndexPath indexPathForItem:1 inSection:0]].frame;
    XCTAssertEqualWithAccuracy(first.size.height, 120, 0.01);
    XCTAssertEqualWithAccuracy(second.size.height, 60, 0.01);
    XCTAssertEqualWithAccuracy(first.origin.y, second.origin.y, 0.01);
}
- (void)testAppendingItemsKeepsExistingFramesAndOnlyCalculatesNewHeights {
    TLWCommunityWaterfallLayoutTestDataSource *dataSource = [[TLWCommunityWaterfallLayoutTestDataSource alloc] init];
    dataSource.itemCount = 2;
    dataSource.itemHeight = 80.0;

    TLWCommunityWaterfallLayout *layout = [[TLWCommunityWaterfallLayout alloc] init];
    layout.delegate = dataSource;
    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, 320, 480) collectionViewLayout:layout];
    collectionView.dataSource = dataSource;
    [collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"cell"];
    [collectionView layoutIfNeeded];

    UICollectionViewLayoutAttributes *firstBeforeAppend = [layout layoutAttributesForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
    UICollectionViewLayoutAttributes *secondBeforeAppend = [layout layoutAttributesForItemAtIndexPath:[NSIndexPath indexPathForItem:1 inSection:0]];
    CGRect firstFrameBeforeAppend = firstBeforeAppend.frame;
    CGRect secondFrameBeforeAppend = secondBeforeAppend.frame;
    NSInteger callsBeforeAppend = dataSource.heightCallCount;

    dataSource.itemCount = 4;
    NSArray<NSIndexPath *> *inserted = @[
        [NSIndexPath indexPathForItem:2 inSection:0],
        [NSIndexPath indexPathForItem:3 inSection:0],
    ];
    [collectionView performBatchUpdates:^{
      [collectionView insertItemsAtIndexPaths:inserted];
    } completion:nil];
    [collectionView layoutIfNeeded];

    XCTAssertEqual(dataSource.heightCallCount - callsBeforeAppend, 2);
    XCTAssertTrue(CGRectEqualToRect(firstFrameBeforeAppend, [layout layoutAttributesForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]].frame));
    XCTAssertTrue(CGRectEqualToRect(secondFrameBeforeAppend, [layout layoutAttributesForItemAtIndexPath:[NSIndexPath indexPathForItem:1 inSection:0]].frame));
    XCTAssertNotNil([layout layoutAttributesForItemAtIndexPath:[NSIndexPath indexPathForItem:3 inSection:0]]);
}

- (void)testReloadingSameItemCountRecalculatesFrames {
    TLWCommunityWaterfallLayoutTestDataSource *dataSource = [[TLWCommunityWaterfallLayoutTestDataSource alloc] init];
    dataSource.itemCount = 2;
    dataSource.itemHeight = 80.0;

    TLWCommunityWaterfallLayout *layout = [[TLWCommunityWaterfallLayout alloc] init];
    layout.delegate = dataSource;
    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, 320, 480) collectionViewLayout:layout];
    collectionView.dataSource = dataSource;
    [collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"cell"];
    [collectionView layoutIfNeeded];

    dataSource.itemHeight = 140.0;
    [collectionView reloadData];
    [collectionView layoutIfNeeded];

    UICollectionViewLayoutAttributes *attributes = [layout layoutAttributesForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
    XCTAssertEqualWithAccuracy(CGRectGetHeight(attributes.frame), 140.0, 0.001);
}

- (void)testPostHeightCacheKeysWidthAndClearsWhenCoverRatioChanges {
    TLWCommunityPost *post = [[TLWCommunityPost alloc] init];
    post.imageAspectRatio = 0.50;

    CGFloat firstHeight = [post cellHeightForWidth:100.0];
    CGFloat repeatedHeight = [post cellHeightForWidth:100.0];
    CGFloat widerHeight = [post cellHeightForWidth:200.0];
    XCTAssertEqualWithAccuracy(widerHeight - firstHeight, 50, 0.001);
    XCTAssertEqualWithAccuracy(repeatedHeight, firstHeight, 0.001);
    XCTAssertTrue([post applyCoverAspectRatioWithWidth:100.0 height:100.0]);
    XCTAssertEqualWithAccuracy([post cellHeightForWidth:100.0] - firstHeight, 50, 0.001);
}
@end
