//
//  TLWRecordHeaderView.h
//  TL-PestIdentify
//
//  Created by Tommy on 2026/3/13.
//

#import <UIKit/UIKit.h>

/// 识别记录列表的日期分组 Header
@interface TLWRecordHeaderView : UICollectionReusableView
- (void)configureWithDateString:(NSString *)dateString;
@end
