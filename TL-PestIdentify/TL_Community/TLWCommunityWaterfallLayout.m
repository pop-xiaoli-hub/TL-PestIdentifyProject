//
//  TLWCommunityWaterfallLayout.m
//  TL-PestIdentify
//

#import "TLWCommunityWaterfallLayout.h"

@interface TLWCommunityWaterfallLayout ()

@property (nonatomic, strong) NSMutableArray<UICollectionViewLayoutAttributes *> *cachedAttributes;
@property (nonatomic, strong) NSMutableDictionary<NSString *, UICollectionViewLayoutAttributes *> *attributesByIndexPath;
@property (nonatomic, strong) NSMutableArray<NSMutableArray<UICollectionViewLayoutAttributes *> *> *columnAttributes;
@property (nonatomic, strong) NSMutableArray<NSNumber *> *columnHeights;
@property (nonatomic, assign) CGFloat contentHeight;
@property (nonatomic, assign) CGFloat laidOutItemWidth;
@property (nonatomic, assign) NSInteger laidOutColumnCount;
@property (nonatomic, assign) BOOL needsFullRebuild;
@property (nonatomic, assign) NSInteger dirtyItem;

@end

@implementation TLWCommunityWaterfallLayout

- (instancetype)init {
    self = [super init];
    if (self) {
        _columnSpacing = 10.0;
        _rowSpacing = 10.0;
        _sectionInset = UIEdgeInsetsMake(12, 12, 20, 12);
        _numberOfColumns = 2;
        _cachedAttributes = [NSMutableArray array];
        _attributesByIndexPath = [NSMutableDictionary dictionary];
        _columnAttributes = [NSMutableArray array];
        _columnHeights = [NSMutableArray array];
        _needsFullRebuild = YES;
        _dirtyItem = NSNotFound;
    }
    return self;
}

- (void)invalidateLayoutWithContext:(UICollectionViewLayoutInvalidationContext *)context {
    if (context.invalidateEverything) {
        self.needsFullRebuild = YES;
    }
    for (NSIndexPath *path in context.invalidatedItemIndexPaths) {
        if (path.section == 0) self.dirtyItem = MIN(self.dirtyItem, path.item);
    }
    [super invalidateLayoutWithContext:context];
}

- (void)prepareForCollectionViewUpdates:(NSArray<UICollectionViewUpdateItem *> *)updateItems {
    [super prepareForCollectionViewUpdates:updateItems];
    NSInteger previousCount = [self.collectionView numberOfItemsInSection:0] - (NSInteger)updateItems.count;
    BOOL onlyTailInsertions = updateItems.count > 0;
    for (UICollectionViewUpdateItem *update in updateItems) {
        NSIndexPath *after = update.indexPathAfterUpdate;
        if (update.updateAction != UICollectionUpdateActionInsert || !after ||
            after.section != 0 || after.item == NSNotFound || after.item < previousCount) {
            onlyTailInsertions = NO;
            break;
        }
    }
    if (!onlyTailInsertions) {
        for (UICollectionViewUpdateItem *update in updateItems) {
            NSIndexPath *before = update.indexPathBeforeUpdate;
            NSIndexPath *after = update.indexPathAfterUpdate;
            if (before && before.section == 0) self.dirtyItem = MIN(self.dirtyItem, before.item);
            if (after && after.section == 0) self.dirtyItem = MIN(self.dirtyItem, after.item);
        }
    }
    // UIKit 可能已在收到 updateItems 前 prepare，须在提交动画属性前重建。
    [self prepareLayout];
}

- (void)prepareLayout {
    [super prepareLayout];

    NSInteger itemCount = [self.collectionView numberOfItemsInSection:0];
    if (itemCount == 0 || self.numberOfColumns <= 0) {
        [self tl_resetCache];
        return;
    }

    CGFloat itemWidth = [self tl_itemWidth];
    BOOL geometryChanged = self.laidOutColumnCount != self.numberOfColumns || fabs(self.laidOutItemWidth - itemWidth) > 0.5;
    if (self.needsFullRebuild || geometryChanged || itemCount < (NSInteger)self.cachedAttributes.count) {
        [self tl_resetCache];
        [self tl_prepareColumns];
        [self tl_appendItemsFrom:0 to:itemCount itemWidth:itemWidth];
        self.needsFullRebuild = NO;
        return;
    }

    if (self.dirtyItem != NSNotFound) {
        [self tl_discardCacheFrom:MIN(self.dirtyItem, itemCount)];
        self.dirtyItem = NSNotFound;
    }

    if (itemCount == (NSInteger)self.cachedAttributes.count) {
        return;
    }

    [self tl_appendItemsFrom:self.cachedAttributes.count to:itemCount itemWidth:itemWidth];
}

- (CGSize)collectionViewContentSize {
    CGFloat width = CGRectGetWidth(self.collectionView.bounds);
    CGFloat height = self.cachedAttributes.count == 0 ? 0 : self.contentHeight + self.sectionInset.bottom;
    return CGSizeMake(width, height);
}

- (NSArray<UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSMutableArray<UICollectionViewLayoutAttributes *> *result = [NSMutableArray array];
    for (NSArray<UICollectionViewLayoutAttributes *> *column in self.columnAttributes) {
        NSInteger start = [self tl_firstIndexInColumn:column withMaxYGreaterThan:CGRectGetMinY(rect)];
        for (NSInteger index = start; index < (NSInteger)column.count; index++) {
            UICollectionViewLayoutAttributes *attr = column[index];
            if (CGRectGetMinY(attr.frame) >= CGRectGetMaxY(rect)) {
                break;
            }
            if (CGRectIntersectsRect(attr.frame, rect)) {
                [result addObject:attr];
            }
        }
    }
    return result;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewLayoutAttributes *attr = self.attributesByIndexPath[[self tl_keyForIndexPath:indexPath]];
    return attr ?: [super layoutAttributesForItemAtIndexPath:indexPath];
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
    return !CGSizeEqualToSize(newBounds.size, self.collectionView.bounds.size);
}

- (CGFloat)tl_itemWidth {
    CGFloat contentWidth = CGRectGetWidth(self.collectionView.bounds);
    CGFloat availableWidth = contentWidth - self.sectionInset.left - self.sectionInset.right - (self.numberOfColumns - 1) * self.columnSpacing;
    return floor(availableWidth / self.numberOfColumns);
}

- (void)tl_resetCache {
    [self.cachedAttributes removeAllObjects];
    [self.attributesByIndexPath removeAllObjects];
    [self.columnAttributes removeAllObjects];
    [self.columnHeights removeAllObjects];
    self.contentHeight = 0;
    self.laidOutItemWidth = 0;
    self.laidOutColumnCount = 0;
    self.dirtyItem = NSNotFound;
}

// 最短列分配依赖前序高度；只保留受影响位置之前的稳定前缀。
- (void)tl_discardCacheFrom:(NSInteger)item {
    if (item >= (NSInteger)self.cachedAttributes.count) return;
    for (NSInteger index = item; index < (NSInteger)self.cachedAttributes.count; index++) {
        [self.attributesByIndexPath removeObjectForKey:[self tl_keyForIndexPath:self.cachedAttributes[index].indexPath]];
    }
    [self.cachedAttributes removeObjectsInRange:NSMakeRange(item, self.cachedAttributes.count - item)];
    self.contentHeight = 0;
    for (NSInteger column = 0; column < (NSInteger)self.columnAttributes.count; column++) {
        NSMutableArray<UICollectionViewLayoutAttributes *> *attributes = self.columnAttributes[column];
        while (attributes.count && attributes.lastObject.indexPath.item >= item) [attributes removeLastObject];
        CGFloat height = attributes.count ? CGRectGetMaxY(attributes.lastObject.frame) : self.sectionInset.top;
        self.columnHeights[column] = @(height);
        self.contentHeight = MAX(self.contentHeight, height);
    }
}

- (void)tl_prepareColumns {
    for (NSInteger column = 0; column < self.numberOfColumns; column++) {
        [self.columnAttributes addObject:[NSMutableArray array]];
        [self.columnHeights addObject:@(self.sectionInset.top)];
    }
    self.laidOutColumnCount = self.numberOfColumns;
}

- (void)tl_appendItemsFrom:(NSInteger)start to:(NSInteger)end itemWidth:(CGFloat)itemWidth {
    if (self.columnHeights.count != (NSUInteger)self.numberOfColumns) {
        [self tl_prepareColumns];
    }
    self.laidOutItemWidth = itemWidth;

    for (NSInteger item = start; item < end; item++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:item inSection:0];
        NSInteger targetColumn = 0;
        CGFloat minColumnHeight = CGFLOAT_MAX;
        for (NSInteger column = 0; column < self.numberOfColumns; column++) {
            CGFloat height = self.columnHeights[column].doubleValue;
            if (height < minColumnHeight) {
                minColumnHeight = height;
                targetColumn = column;
            }
        }

        CGFloat x = self.sectionInset.left + (itemWidth + self.columnSpacing) * targetColumn;
        CGFloat y = minColumnHeight;
        if (y > self.sectionInset.top) {
            y += self.rowSpacing;
        }

        CGFloat itemHeight = 120.0;
        if ([self.delegate respondsToSelector:@selector(collectionView:layout:heightForItemAtIndexPath:itemWidth:)]) {
            itemHeight = [self.delegate collectionView:self.collectionView layout:self heightForItemAtIndexPath:indexPath itemWidth:itemWidth];
        }

        UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
        attributes.frame = CGRectMake(x, y, itemWidth, itemHeight);
        [self.cachedAttributes addObject:attributes];
        [self.columnAttributes[targetColumn] addObject:attributes];
        self.attributesByIndexPath[[self tl_keyForIndexPath:indexPath]] = attributes;
        self.columnHeights[targetColumn] = @(CGRectGetMaxY(attributes.frame));
        self.contentHeight = MAX(self.contentHeight, CGRectGetMaxY(attributes.frame));
    }
}

- (NSInteger)tl_firstIndexInColumn:(NSArray<UICollectionViewLayoutAttributes *> *)column withMaxYGreaterThan:(CGFloat)minY {
    NSInteger low = 0;
    NSInteger high = column.count;
    while (low < high) {
        NSInteger mid = (low + high) / 2;
        if (CGRectGetMaxY(column[mid].frame) <= minY) {
            low = mid + 1;
        } else {
            high = mid;
        }
    }
    return low;
}

- (NSString *)tl_keyForIndexPath:(NSIndexPath *)indexPath {
    return [NSString stringWithFormat:@"%ld-%ld", (long)indexPath.section, (long)indexPath.item];
}

@end
