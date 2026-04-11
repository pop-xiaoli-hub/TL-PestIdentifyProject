//
//  TLWPlantDetailView.h
//  TL-PestIdentify
//

#import <UIKit/UIKit.h>

@class TLWPlantDetailViewModel;
@class TLWPlantDetailInfoCardView;
@class TLWPlantDetailSegmentTabView;
@class TLWPlantDetailWateringView;
@class TLWPlantDetailFertilizerView;
@class TLWPlantDetailMedicineView;
@class TLWPlantDetailNoteView;
@class TLWPlantDetailPlaceholderView;

NS_ASSUME_NONNULL_BEGIN

@interface TLWPlantDetailView : UIView

@property (nonatomic, strong, readonly) UIImageView *topImageView;
@property (nonatomic, strong, readonly) UIButton *backButton;
@property (nonatomic, strong, readonly) UIButton *imageTagButton;
@property (nonatomic, strong, readonly) TLWPlantDetailInfoCardView *healthInfoCardView;
@property (nonatomic, strong, readonly) TLWPlantDetailInfoCardView *dateInfoCardView;
@property (nonatomic, strong, readonly) TLWPlantDetailSegmentTabView *segmentTabView;
@property (nonatomic, strong, readonly) TLWPlantDetailWateringView *wateringView;
@property (nonatomic, strong, readonly) TLWPlantDetailFertilizerView *fertilizerView;
@property (nonatomic, strong, readonly) TLWPlantDetailMedicineView *medicineView;
@property (nonatomic, strong, readonly) TLWPlantDetailNoteView *noteView;

- (void)configureWithViewModel:(TLWPlantDetailViewModel *)viewModel;
- (void)updateSelectedTab:(NSInteger)selectedIndex contentHeight:(CGFloat)contentHeight;
- (void)setScrollViewBottomInset:(CGFloat)bottomInset;
- (void)scrollContentRectToVisible:(CGRect)rect animated:(BOOL)animated;
- (void)scrollToBottomAnimated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
