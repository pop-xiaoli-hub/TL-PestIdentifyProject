//
//  TLWHomeCardCell.h
//  TL-PestIdentify
//
//  Created by xiaoli pop on 2026/3/9.
//

#import <UIKit/UIKit.h>
@class TLWWarningModel;
NS_ASSUME_NONNULL_BEGIN

@interface TLWHomeCardCell : UITableViewCell
@property (nonatomic, strong) UILabel *bodyLabel;
@property (nonatomic, strong, readonly) UIView *cardContainerView;
/// 第二个卡片 cell：点击「拍照识别」
@property (nonatomic, copy) void(^clickPhotoIdentification)(void);

/// 第一个预警 card：点击右下角「查看详细/收起」
@property (nonatomic, copy) void(^clickWarningDetail)(void);

/// 设置预警正文文案
- (void)tl_configureWithWarning:(TLWWarningModel* )model;

/// 根据是否展开，更新预警正文行数和右下角文案
- (void)tl_configureWarningExpanded:(BOOL)expanded;
@end

NS_ASSUME_NONNULL_END

