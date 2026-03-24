//
//  TLWCustomInputCell.h
//  TL-PestIdentify
//
//  自定义输入 Cell —— 用于偏好设置页，让用户手动输入自定义农作物名称。
//  内含一个居中的 UITextField，背景为毛玻璃风格图片。
//

#import <UIKit/UIKit.h>

@interface TLWCustomInputCell : UICollectionViewCell
@property (nonatomic, strong) UITextField *textField;
@end
