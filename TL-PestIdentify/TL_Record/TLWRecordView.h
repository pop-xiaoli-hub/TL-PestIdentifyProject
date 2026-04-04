//
//  TLWRecordView.h
//  TL-PestIdentify
//
//  Created by Tommy on 2026/3/13.
//

#import <UIKit/UIKit.h>

@interface TLWRecordView : UIView
@property (nonatomic, strong, readonly) UICollectionView *collectionView;
/// 数据为空时显示的提示 label，由 Controller 控制 hidden
@property (nonatomic, strong, readonly) UILabel *emptyLabel;
@end
