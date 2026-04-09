//
//  TLWPlantDetailView.m
//  TL-PestIdentify
//

#import "TLWPlantDetailView.h"
#import "TLWPlantDetailInfoCardView.h"
#import "TLWPlantDetailSegmentTabView.h"
#import "TLWPlantDetailWateringView.h"
#import "TLWPlantDetailPlaceholderView.h"
#import "../ViewModels/TLWPlantDetailViewModel.h"
#import <Masonry/Masonry.h>

@interface TLWPlantDetailView ()

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UIView *cardView;
@property (nonatomic, strong) UIView *contentContainerView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *editButton;
@property (nonatomic, strong) MASConstraint *contentHeightConstraint;

@property (nonatomic, strong, readwrite) UIImageView *topImageView;
@property (nonatomic, strong, readwrite) UIButton *backButton;
@property (nonatomic, strong, readwrite) UIButton *imageTagButton;
@property (nonatomic, strong, readwrite) TLWPlantDetailInfoCardView *healthInfoCardView;
@property (nonatomic, strong, readwrite) TLWPlantDetailInfoCardView *dateInfoCardView;
@property (nonatomic, strong, readwrite) TLWPlantDetailSegmentTabView *segmentTabView;
@property (nonatomic, strong, readwrite) TLWPlantDetailWateringView *wateringView;
@property (nonatomic, strong, readwrite) TLWPlantDetailPlaceholderView *fertilizerView;
@property (nonatomic, strong, readwrite) TLWPlantDetailPlaceholderView *medicineView;
@property (nonatomic, strong, readwrite) TLWPlantDetailPlaceholderView *noteView;

@end

@implementation TLWPlantDetailView

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    self.backgroundColor = [UIColor colorWithRed:0.91 green:0.97 blue:0.95 alpha:1.0];
    [self tl_setupSubviews];
  }
  return self;
}

- (void)tl_setupSubviews {
  UIScrollView *scrollView = [[UIScrollView alloc] init];
  scrollView.showsVerticalScrollIndicator = NO;
  scrollView.backgroundColor = [UIColor clearColor];
  if (@available(iOS 11.0, *)) {
    scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
  }
  [self addSubview:scrollView];
  self.scrollView = scrollView;

  UIView *contentView = [[UIView alloc] init];
  contentView.backgroundColor = [UIColor clearColor];
  [scrollView addSubview:contentView];
  self.contentView = contentView;

  [scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.edges.equalTo(self);
  }];

  [contentView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.edges.equalTo(scrollView);
    make.width.equalTo(scrollView);
  }];

  UIImageView *topImageView = [[UIImageView alloc] init];
  topImageView.contentMode = UIViewContentModeScaleAspectFill;
  topImageView.clipsToBounds = YES;
  [contentView addSubview:topImageView];
  self.topImageView = topImageView;

  UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
  [backButton setTitle:@"‹" forState:UIControlStateNormal];
  [backButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
  backButton.titleLabel.font = [UIFont systemFontOfSize:22.0 weight:UIFontWeightSemibold];
  backButton.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.28];
  backButton.layer.cornerRadius = 20.0;
  [contentView addSubview:backButton];
  self.backButton = backButton;

  UIButton *imageTagButton = [UIButton buttonWithType:UIButtonTypeCustom];
  [imageTagButton setTitle:@"  要使用它  " forState:UIControlStateNormal];
  [imageTagButton setTitleColor:[UIColor colorWithWhite:0.32 alpha:1.0] forState:UIControlStateNormal];
  imageTagButton.titleLabel.font = [UIFont systemFontOfSize:12.0 weight:UIFontWeightSemibold];
  imageTagButton.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.82];
  imageTagButton.layer.cornerRadius = 14.0;
  [contentView addSubview:imageTagButton];
  self.imageTagButton = imageTagButton;

  UIView *cardView = [[UIView alloc] init];
  cardView.backgroundColor = [UIColor whiteColor];
  cardView.layer.cornerRadius = 24.0;
  cardView.layer.shadowColor = [UIColor colorWithRed:0.08 green:0.28 blue:0.22 alpha:0.10].CGColor;
  cardView.layer.shadowOpacity = 1.0;
  cardView.layer.shadowOffset = CGSizeMake(0, 12);
  cardView.layer.shadowRadius = 24.0;
  [contentView addSubview:cardView];
  self.cardView = cardView;

  UILabel *titleLabel = [[UILabel alloc] init];
  titleLabel.font = [UIFont systemFontOfSize:34.0 weight:UIFontWeightBold];
  titleLabel.textColor = [UIColor colorWithWhite:0.15 alpha:1.0];
  [cardView addSubview:titleLabel];
  self.titleLabel = titleLabel;

  UIButton *editButton = [UIButton buttonWithType:UIButtonTypeCustom];
  [editButton setTitle:@"✎" forState:UIControlStateNormal];
  [editButton setTitleColor:[UIColor colorWithWhite:0.68 alpha:1.0] forState:UIControlStateNormal];
  editButton.titleLabel.font = [UIFont systemFontOfSize:16.0 weight:UIFontWeightSemibold];
  [cardView addSubview:editButton];
  self.editButton = editButton;

  TLWPlantDetailInfoCardView *healthInfoCardView = [[TLWPlantDetailInfoCardView alloc] init];
  [cardView addSubview:healthInfoCardView];
  self.healthInfoCardView = healthInfoCardView;

  TLWPlantDetailInfoCardView *dateInfoCardView = [[TLWPlantDetailInfoCardView alloc] init];
  [cardView addSubview:dateInfoCardView];
  self.dateInfoCardView = dateInfoCardView;

  UILabel *manageTitleLabel = [[UILabel alloc] init];
  manageTitleLabel.text = @"种植管理";
  manageTitleLabel.font = [UIFont systemFontOfSize:24.0 weight:UIFontWeightBold];
  manageTitleLabel.textColor = [UIColor colorWithWhite:0.16 alpha:1.0];
  [cardView addSubview:manageTitleLabel];

  TLWPlantDetailSegmentTabView *segmentTabView = [[TLWPlantDetailSegmentTabView alloc] init];
  [cardView addSubview:segmentTabView];
  self.segmentTabView = segmentTabView;

  UIView *contentContainerView = [[UIView alloc] init];
  [cardView addSubview:contentContainerView];
  self.contentContainerView = contentContainerView;

  TLWPlantDetailWateringView *wateringView = [[TLWPlantDetailWateringView alloc] init];
  [contentContainerView addSubview:wateringView];
  self.wateringView = wateringView;

  TLWPlantDetailPlaceholderView *fertilizerView = [[TLWPlantDetailPlaceholderView alloc] init];
  [fertilizerView configureWithTitle:@"施肥记录" message:@"可在这里接入施肥计划、历史记录和提醒。"];
  [contentContainerView addSubview:fertilizerView];
  self.fertilizerView = fertilizerView;

  TLWPlantDetailPlaceholderView *medicineView = [[TLWPlantDetailPlaceholderView alloc] init];
  [medicineView configureWithTitle:@"用药记录" message:@"可在这里补充用药方案、周期和病虫害处理记录。"];
  [contentContainerView addSubview:medicineView];
  self.medicineView = medicineView;

  TLWPlantDetailPlaceholderView *noteView = [[TLWPlantDetailPlaceholderView alloc] init];
  [noteView configureWithTitle:@"种植笔记" message:@"可在这里接入文字记录、图片笔记和养护心得。"];
  [contentContainerView addSubview:noteView];
  self.noteView = noteView;

  [topImageView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.left.right.equalTo(contentView);
    make.height.mas_equalTo(250.0);
  }];

  [backButton mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.equalTo(contentView).offset(16.0);
    make.top.equalTo(contentView.mas_safeAreaLayoutGuideTop).offset(14.0);
    make.width.height.mas_equalTo(40.0);
  }];

  [imageTagButton mas_makeConstraints:^(MASConstraintMaker *make) {
    make.right.equalTo(contentView).offset(-16.0);
    make.bottom.equalTo(topImageView).offset(-22.0);
    make.height.mas_equalTo(28.0);
  }];

  [cardView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(topImageView.mas_bottom).offset(-22.0);
    make.left.right.equalTo(contentView);
    make.bottom.equalTo(contentView).offset(-20.0);
  }];

  [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(cardView).offset(24.0);
    make.left.equalTo(cardView).offset(20.0);
  }];

  [editButton mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.equalTo(titleLabel.mas_right).offset(6.0);
    make.bottom.equalTo(titleLabel).offset(-3.0);
  }];

  [healthInfoCardView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(titleLabel.mas_bottom).offset(18.0);
    make.left.equalTo(cardView).offset(16.0);
    make.height.mas_equalTo(84.0);
  }];

  [dateInfoCardView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(healthInfoCardView);
    make.left.equalTo(healthInfoCardView.mas_right).offset(12.0);
    make.right.equalTo(cardView).offset(-16.0);
    make.width.equalTo(healthInfoCardView);
    make.height.equalTo(healthInfoCardView);
  }];

  [manageTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(healthInfoCardView.mas_bottom).offset(24.0);
    make.left.equalTo(cardView).offset(20.0);
  }];

  [segmentTabView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(manageTitleLabel.mas_bottom).offset(14.0);
    make.left.equalTo(cardView).offset(16.0);
    make.right.equalTo(cardView).offset(-16.0);
    make.height.mas_equalTo(42.0);
  }];

  [contentContainerView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(segmentTabView.mas_bottom).offset(14.0);
    make.left.equalTo(cardView).offset(16.0);
    make.right.equalTo(cardView).offset(-16.0);
    self.contentHeightConstraint = make.height.mas_equalTo(620.0);
    make.bottom.equalTo(cardView).offset(-20.0);
  }];

  NSArray<UIView *> *contentViews = @[wateringView, fertilizerView, medicineView, noteView];
  for (UIView *contentSubView in contentViews) {
    [contentSubView mas_makeConstraints:^(MASConstraintMaker *make) {
      make.edges.equalTo(contentContainerView);
    }];
  }
}

- (void)configureWithViewModel:(TLWPlantDetailViewModel *)viewModel {
  self.titleLabel.text = [viewModel plantTitleText];
  [self.healthInfoCardView configureWithTitle:@"健康状况" value:[viewModel healthStatusText] emphasizeValue:YES];
  [self.dateInfoCardView configureWithTitle:@"种植日期" value:[viewModel plantingDateText] emphasizeValue:NO];
  [self.segmentTabView configureWithTitles:[viewModel tabTitles]];
  [self.wateringView configureWithViewModel:viewModel];
  [self updateSelectedTab:viewModel.selectedTabType contentHeight:[viewModel preferredContentHeightForSelectedTab]];
}

- (void)updateSelectedTab:(NSInteger)selectedIndex contentHeight:(CGFloat)contentHeight {
  self.wateringView.hidden = (selectedIndex != 0);
  self.fertilizerView.hidden = (selectedIndex != 1);
  self.medicineView.hidden = (selectedIndex != 2);
  self.noteView.hidden = (selectedIndex != 3);
  [self.segmentTabView selectIndex:selectedIndex];
  [self.contentContainerView mas_updateConstraints:^(MASConstraintMaker *make) {
    self.contentHeightConstraint = make.height.mas_equalTo(contentHeight);
  }];
  [self setNeedsLayout];
  [self layoutIfNeeded];
}

@end
