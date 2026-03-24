//
//  TLWCropCell.h
//  TL-PestIdentify
//
//  农作物选择 Cell —— 用于偏好设置页的 CollectionView。
//  显示农作物名称，选中时覆盖绿色渐变背景并切换为白色粗体文字。
//

#import <UIKit/UIKit.h>

@interface TLWCropCell : UICollectionViewCell
@property (nonatomic, strong) UILabel *nameLabel;
@end
