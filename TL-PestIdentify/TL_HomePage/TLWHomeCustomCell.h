//
//  TLWHomeCustomCell.h
//  TL-PestIdentify
//
//  Created by xiaoli pop on 2026/3/9.
//

#import <UIKit/UIKit.h>

@class TLWPlantModel;

NS_ASSUME_NONNULL_BEGIN

@interface TLWHomeCustomCell : UITableViewCell

@property (nonatomic, copy, nullable) void(^clickCreateButton)(void);
@property (nonatomic, copy, nullable) void(^clickContentCard)(void);
@property (nonatomic, copy, nullable) void(^longPressContentCard)(void);

- (void)configureAsCreateCell;
- (void)configureAsCreateCellWithLocationName:(nullable NSString *)locationName;
- (void)configureWithPlantModel:(TLWPlantModel *)plantModel locationName:(nullable NSString *)locationName;

@end

NS_ASSUME_NONNULL_END
