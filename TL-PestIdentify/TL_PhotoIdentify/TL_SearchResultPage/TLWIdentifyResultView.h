//
//  TLWIdentifyResultView.h
//  TL-PestIdentify
//
//  Created by xiaoli pop on 2026/4/3.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TLWIdentifyResultView : UIView

@property (nonatomic, strong, readonly) UIButton *backButton;
@property (nonatomic, strong, readonly) UIImageView *photoView;
@property (nonatomic, strong, readonly) UIScrollView *resultScrollView;
@property (nonatomic, strong, readonly) NSArray<UIButton *> *tabButtons;
@property (nonatomic, strong, readonly) UILabel *pestNameLabel;
@property (nonatomic, strong, readonly) UILabel *confidenceLabel;
@property (nonatomic, strong, readonly) UILabel *solutionLabel;
@property (nonatomic, strong, readonly) UIButton *aiButton;
@property (nonatomic, strong, readonly) UIButton *retakeButton;

- (void)selectTabAtIndex:(NSInteger)index animated:(BOOL)animated;
- (void)configureWithImage:(nullable UIImage *)image results:(NSArray<NSDictionary *> *)results;

@end

NS_ASSUME_NONNULL_END
