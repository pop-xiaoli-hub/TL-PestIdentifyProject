//
//  TLWVoiceInputViewController.h
//  TL-PestIdentify
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TLWVoiceInputViewController : UIViewController

@property (nonatomic, copy, nullable) NSString *initialSearchText;
@property (nonatomic, copy, nullable) void (^onSearchTextChanged)(NSString *text);
@property (nonatomic, strong) NSMutableArray *hasCollectedPosts;

@end

NS_ASSUME_NONNULL_END
