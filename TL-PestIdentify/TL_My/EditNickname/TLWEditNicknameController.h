//
//  TLWEditNicknameController.h
//  TL-PestIdentify
//

#import "TLWBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@class TLWEditNicknameController;

@protocol TLWEditNicknameDelegate <NSObject>
- (void)editNicknameController:(TLWEditNicknameController *)vc didSaveNickname:(NSString *)nickname;
@end

@interface TLWEditNicknameController : TLWBaseViewController

@property (nonatomic, weak) id<TLWEditNicknameDelegate> delegate;

- (instancetype)initWithCurrentNickname:(NSString *)nickname;

@end

NS_ASSUME_NONNULL_END
