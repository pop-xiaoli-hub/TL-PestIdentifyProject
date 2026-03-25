//
//  TLWEditNicknameController.h
//  TL-PestIdentify
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class TLWEditNicknameController;

@protocol TLWEditNicknameDelegate <NSObject>
- (void)editNicknameController:(TLWEditNicknameController *)vc didSaveNickname:(NSString *)nickname;
@end

@interface TLWEditNicknameController : UIViewController

@property (nonatomic, weak) id<TLWEditNicknameDelegate> delegate;

- (instancetype)initWithCurrentNickname:(NSString *)nickname;

@end

NS_ASSUME_NONNULL_END
