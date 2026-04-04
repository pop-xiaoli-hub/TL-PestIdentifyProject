//
//  TLWRecordDetailView.h
//  TL-PestIdentify
//
//  Created by Tommy on 2026/3/13.
//

#import <UIKit/UIKit.h>

@interface TLWRecordDetailView : UIView

// 照片
@property (nonatomic, strong, readonly) UIImageView *photoView;

// Tab 按钮（共 3 个：结果一/结果二/结果三）
@property (nonatomic, strong, readonly) NSArray<UIButton *> *tabButtons;

// 病害名称区域
@property (nonatomic, strong, readonly) UILabel *pestNameLabel;    // 标签内的病害名
@property (nonatomic, strong, readonly) UILabel *confidenceLabel;  // 橙色角标内的置信度

// 解决方案文本
@property (nonatomic, strong, readonly) UILabel *solutionLabel;

// AI 助手按钮
@property (nonatomic, strong, readonly) UIButton *aiButton;

/// 切换 Tab 选中态并动画移动指示器
- (void)selectTabAtIndex:(NSInteger)index animated:(BOOL)animated;

@end
