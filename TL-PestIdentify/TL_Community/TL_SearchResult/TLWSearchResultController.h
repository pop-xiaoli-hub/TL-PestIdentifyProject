//
//  TLWSearchResultController.h
//  TL-PestIdentify
//

#import <UIKit/UIKit.h>

@class TLWCommunityPost;

NS_ASSUME_NONNULL_BEGIN

@interface TLWSearchResultController : UIViewController

@property (nonatomic, copy) NSString *queryText;
@property (nonatomic, strong) NSMutableArray<TLWCommunityPost *> *posts;
@property (nonatomic, strong) NSArray<TLWCommunityPost *> *recommendations;
@property (nonatomic, strong) NSArray<NSString *> *keywordSuggestions;
@property (nonatomic, strong) NSMutableArray *hasCollectedPosts;

@end

NS_ASSUME_NONNULL_END
