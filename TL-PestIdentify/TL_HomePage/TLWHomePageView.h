//
//  TLWHomePageView.h
//  TL-PestIdentify
//
//  Created by xiaoli pop on 2026/3/9.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TLWHomePageView : UIView

@property (nonatomic, strong, readonly) UITableView *tableView;
@property (nonatomic, strong, readonly) UIImageView *userAvatarImageView;
- (void)configureWithUserName:(NSString* )name;
@end

NS_ASSUME_NONNULL_END
