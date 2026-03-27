//
//  TLWCommentCell.h
//  TL-PestIdentify
//

#import <UIKit/UIKit.h>
#import <AgriPestClient/AGCommentResponseDto.h>

NS_ASSUME_NONNULL_BEGIN

@interface TLWCommentModel : NSObject
@property (nonatomic, copy) NSString *username;
@property (nonatomic, copy) NSString *avatarUrl;
@property (nonatomic, copy) NSString *content;
@property (nonatomic, copy) NSString *timeString;
@property (nonatomic, assign) NSInteger likeCount;
@end

@interface TLWCommentCell : UITableViewCell
- (void)configureWithComment:(AGCommentResponseDto *)comment;
@end

NS_ASSUME_NONNULL_END
