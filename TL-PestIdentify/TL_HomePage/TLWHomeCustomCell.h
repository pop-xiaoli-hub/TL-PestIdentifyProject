//
//  TLWHomeCustomCell.h
//  TL-PestIdentify
//
//  Created by xiaoli pop on 2026/3/9.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TLWHomeCustomCell : UITableViewCell

@property (nonatomic, copy, nullable) void(^clickCreateButton)(void);
@property (nonatomic, copy, nullable) void(^clickContentCard)(void);

- (void)configureAsCreateCell;
- (void)configureWithPlantInfo:(NSDictionary *)plantInfo;

@end

NS_ASSUME_NONNULL_END
