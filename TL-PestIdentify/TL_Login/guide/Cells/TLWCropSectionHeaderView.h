//
//  TLWCropSectionHeaderView.h
//  TL-PestIdentify
//
//  Section 标题头 —— 偏好设置页 CollectionView 各分区的标题视图。
//  显示 "自定义作物"、"粮食作物"、"蔬菜"、"果树" 等分区名称。
//

#import <UIKit/UIKit.h>

@interface TLWCropSectionHeaderView : UICollectionReusableView
@property (nonatomic, strong) UILabel *titleLabel;
@end
