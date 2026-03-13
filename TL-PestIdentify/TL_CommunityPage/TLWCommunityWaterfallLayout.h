//
//  TLWCommunityWaterfallLayout.h
//  TL-PestIdentify
//
//  简单双列瀑布流布局：始终将下一个 item 放到当前总高度较低的一列，
//  让左右两列的纵向间距尽量一致，不再出现一列空隙过大的情况。
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol TLWCommunityWaterfallLayoutDelegate <NSObject>

/// 根据给定宽度返回 item 的实际高度
- (CGFloat)collectionView:(UICollectionView *)collectionView
                   layout:(UICollectionViewLayout *)layout
 heightForItemAtIndexPath:(NSIndexPath *)indexPath
                itemWidth:(CGFloat)width;

@end

@interface TLWCommunityWaterfallLayout : UICollectionViewLayout

@property (nonatomic, weak) id<TLWCommunityWaterfallLayoutDelegate> delegate;

/// 两列之间的水平间距，默认 10
@property (nonatomic, assign) CGFloat columnSpacing;
/// 不同行之间的纵向间距，默认 10
@property (nonatomic, assign) CGFloat rowSpacing;
/// section 的内边距，默认 {12, 12, 20, 12}
@property (nonatomic, assign) UIEdgeInsets sectionInset;

/// 列数，当前设计固定为 2
@property (nonatomic, assign) NSInteger numberOfColumns;

@end

NS_ASSUME_NONNULL_END

