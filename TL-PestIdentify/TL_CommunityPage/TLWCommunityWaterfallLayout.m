//
//  TLWCommunityWaterfallLayout.m
//  TL-PestIdentify
//

#import "TLWCommunityWaterfallLayout.h"

@interface TLWCommunityWaterfallLayout ()

@property (nonatomic, strong) NSMutableArray<UICollectionViewLayoutAttributes *> *cachedAttributes;
@property (nonatomic, assign) CGFloat contentHeight;

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
    }
    return self;
}

- (void)prepareLayout {
    [super prepareLayout];

    [self.cachedAttributes removeAllObjects];
    self.contentHeight = 0;

    NSInteger itemCount = [self.collectionView numberOfItemsInSection:0];
    if (itemCount == 0 || self.numberOfColumns <= 0) {
        return;
    }

    CGFloat contentWidth = CGRectGetWidth(self.collectionView.bounds);
    CGFloat availableWidth = contentWidth - self.sectionInset.left - self.sectionInset.right - (self.numberOfColumns - 1) * self.columnSpacing;
    CGFloat itemWidth = floor(availableWidth / self.numberOfColumns);

    NSMutableArray<NSNumber *> *columnHeights = [NSMutableArray arrayWithCapacity:self.numberOfColumns];
    for (NSInteger i = 0; i < self.numberOfColumns; i++) {
        [columnHeights addObject:@(self.sectionInset.top)];
    }

    for (NSInteger item = 0; item < itemCount; item++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:item inSection:0];

        // 选出目前总高度最低的一列
        NSInteger targetColumn = 0;
        CGFloat minColumnHeight = CGFLOAT_MAX;
        for (NSInteger col = 0; col < self.numberOfColumns; col++) {
            CGFloat height = columnHeights[col].doubleValue;
            if (height < minColumnHeight) {
                minColumnHeight = height;
                targetColumn = col;
            }
        }

        CGFloat x = self.sectionInset.left + (itemWidth + self.columnSpacing) * targetColumn;
        CGFloat y = minColumnHeight;
        if (y > self.sectionInset.top) {
            y += self.rowSpacing;
        }

        CGFloat itemHeight = 120.0;
        if ([self.delegate respondsToSelector:@selector(collectionView:layout:heightForItemAtIndexPath:itemWidth:)]) {
            itemHeight = [self.delegate collectionView:self.collectionView
                                                layout:self
                             heightForItemAtIndexPath:indexPath
                                            itemWidth:itemWidth];
        }

        CGRect frame = CGRectMake(x, y, itemWidth, itemHeight);
        UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
        attributes.frame = frame;
        [self.cachedAttributes addObject:attributes];

        columnHeights[targetColumn] = @(CGRectGetMaxY(frame));
        self.contentHeight = MAX(self.contentHeight, CGRectGetMaxY(frame));
    }

    self.contentHeight += self.sectionInset.bottom;
}

- (CGSize)collectionViewContentSize {
    CGFloat width = CGRectGetWidth(self.collectionView.bounds);
    return CGSizeMake(width, self.contentHeight);
}

- (NSArray<UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSMutableArray<UICollectionViewLayoutAttributes *> *result = [NSMutableArray array];
    for (UICollectionViewLayoutAttributes *attr in self.cachedAttributes) {
        if (CGRectIntersectsRect(attr.frame, rect)) {
            [result addObject:attr];
        }
    }
    return result;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    for (UICollectionViewLayoutAttributes *attr in self.cachedAttributes) {
        if ([attr.indexPath isEqual:indexPath]) {
            return attr;
        }
    }
    return [super layoutAttributesForItemAtIndexPath:indexPath];
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
    return !CGSizeEqualToSize(newBounds.size, self.collectionView.bounds.size);
}

@end

