//
//  TLWRecordCell.h
//  TL-PestIdentify
//
//  Created by Tommy on 2026/3/13.
//

#import <UIKit/UIKit.h>
@class TLWRecordItem;

@interface TLWRecordCell : UICollectionViewCell
@property (nonatomic, strong) UIImageView *photoView;
@property (nonatomic, strong) UILabel *nameLabel;
- (void)configureWithItem:(TLWRecordItem *)item;
@end
