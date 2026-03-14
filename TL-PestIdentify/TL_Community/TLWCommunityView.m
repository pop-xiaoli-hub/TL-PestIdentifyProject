//
//  TLWCommunityView.m
//  TL-PestIdentify
//

#import "TLWCommunityView.h"
#import "TLWCommunityWaterfallLayout.h"
#import <Masonry/Masonry.h>

/// 顶部搜索区域高度
static CGFloat const kSearchBarHeight = 64.0;
/// 搜索区域与安全区顶部的间距
static CGFloat const kSearchBarTopInset = 12.0;
/// 瀑布流左右内边距
static CGFloat const kHorizontalInset = 12.0;
/// 瀑布流 item 间距
static CGFloat const kItemGap = 10.0;

@interface TLWCommunityView () <UIGestureRecognizerDelegate>

@property (nonatomic, strong, readwrite) UICollectionView *collectionView;
@property (nonatomic, strong, readwrite) UITextField *searchTextField;
@property (nonatomic, strong) UIView *searchContainer;
/// 搜索时的毛玻璃覆盖层（含历史记录、猜你想搜）
@property (nonatomic, strong) UIView *searchOverlay;
@property (nonatomic, strong) UIVisualEffectView *searchBlurPanel;
@property (nonatomic, strong) UIStackView *historyStackView;

@end

@implementation TLWCommunityView

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    [self tl_setupBackground];
    [self tl_setupSearchBar];
    [self tl_setupCollectionView];
    [self tl_setupSearchOverlay]; // 提前创建覆盖层，确保点击时能正常显示
  }
  return self;
}

#pragma mark - Setup UI

- (void)tl_setupBackground {
  UIImage* image = [UIImage imageNamed:@"hp_backView.png"];
  self.layer.contents = (__bridge id)image.CGImage;
}

- (void)tl_setupSearchBar {
  UIView *container = [[UIView alloc] init];
  container.backgroundColor = [UIColor clearColor];
  container.layer.cornerRadius = 24.0;
  container.layer.masksToBounds = YES;
  [self addSubview:container];
  self.searchContainer = container;



  UILabel *titleLabel = [[UILabel alloc] init];
  titleLabel.text = @"社区";
  titleLabel.textColor = [UIColor whiteColor];
  titleLabel.font = [UIFont systemFontOfSize:20 weight:UIFontWeightSemibold];
  [self addSubview:titleLabel];

  UIView *searchFieldBackground = [[UIView alloc] init];
  searchFieldBackground.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.95];
  searchFieldBackground.layer.cornerRadius = 22.0;
  searchFieldBackground.layer.masksToBounds = YES;
  [container addSubview:searchFieldBackground];

  UIImageView *searchIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cp_search.png"]];
  searchIcon.contentMode = UIViewContentModeScaleAspectFit;
  [searchFieldBackground addSubview:searchIcon];

  UIButton *voiceButton = [UIButton buttonWithType:UIButtonTypeCustom];
  [voiceButton setImage:[UIImage imageNamed:@"cp_voice.png"] forState:UIControlStateNormal];
  voiceButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
  [searchFieldBackground addSubview:voiceButton];

  UITextField *textField = [[UITextField alloc] init];
  textField.placeholder = @"请输入关键词";
  textField.font = [UIFont systemFontOfSize:14];
  textField.textColor = [UIColor darkTextColor];
  textField.returnKeyType = UIReturnKeySearch;
  [searchFieldBackground addSubview:textField];
  self.searchTextField = textField;

  // 点击整个搜索区域时也可以唤起搜索面板
  searchFieldBackground.userInteractionEnabled = YES;
  UITapGestureRecognizer *searchTap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                              action:@selector(tl_showSearchOverlay)];
  [searchFieldBackground addGestureRecognizer:searchTap];

  self.publishButton = [UIButton buttonWithType:UIButtonTypeCustom];
  [self.publishButton setImage:[UIImage imageNamed:@"cp_publish.png"] forState:UIControlStateNormal];
  self.publishButton.frame = CGRectMake(300, 400, 100, 100);
  [self addSubview:self.publishButton];

  [container mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.equalTo(self).offset(12);
    make.right.equalTo(self).offset(-12);
    make.top.equalTo(self.mas_safeAreaLayoutGuideTop).offset(kSearchBarTopInset);
    make.height.mas_equalTo(kSearchBarHeight);
  }];

  [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
    make.centerX.equalTo(self);
    make.bottom.equalTo(container.mas_top).offset(-8);
  }];

  [searchFieldBackground mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.equalTo(container).offset(12);
    make.top.equalTo(container).offset(10);
    make.bottom.equalTo(container).offset(-10);
    make.right.equalTo(container).offset(-12);
  }];

  [searchIcon mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.equalTo(searchFieldBackground).offset(12);
    make.centerY.equalTo(searchFieldBackground);
    make.width.height.mas_equalTo(18);
  }];

  [voiceButton mas_makeConstraints:^(MASConstraintMaker *make) {
    make.right.equalTo(searchFieldBackground).offset(-12);
    make.centerY.equalTo(searchFieldBackground);
    make.width.height.mas_equalTo(18);
  }];

  [textField mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.equalTo(searchIcon.mas_right).offset(8);
    make.right.equalTo(voiceButton.mas_left).offset(-8);
    make.centerY.equalTo(searchFieldBackground);
    make.height.mas_equalTo(32);
  }];
}


- (void)tl_setupCollectionView {
  TLWCommunityWaterfallLayout *layout = [[TLWCommunityWaterfallLayout alloc] init];
  layout.columnSpacing = kItemGap;
  layout.rowSpacing = kItemGap;
  layout.sectionInset = UIEdgeInsetsMake(12, kHorizontalInset, 20, kHorizontalInset);

  UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
  collectionView.backgroundColor = [UIColor whiteColor];
  collectionView.showsVerticalScrollIndicator = NO;
  collectionView.layer.masksToBounds = YES;
  collectionView.layer.cornerRadius = 20;
  [self addSubview:collectionView];
  self.collectionView = collectionView;

  [collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.bottom.equalTo(self);
    make.left.equalTo(self.mas_left).offset(10);
    make.right.equalTo(self.mas_right).offset(-10);
    make.top.equalTo(self.searchContainer.mas_bottom).offset(0);
  }];
}


- (UIButton *)tl_tagButtonWithTitle:(NSString *)title {
  UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
  [button setTitle:title forState:UIControlStateNormal];
  [button setTitleColor:[UIColor colorWithWhite:0.25 alpha:1.0] forState:UIControlStateNormal];
  button.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];

  // 胶囊样式：背景 + 描边 + 内边距
  button.contentEdgeInsets = UIEdgeInsetsMake(6, 14, 6, 14);
  button.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.88];
  button.layer.cornerRadius = 16.0;
  button.layer.masksToBounds = YES;
  button.layer.borderWidth = 1.0 / [UIScreen mainScreen].scale;
  button.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.9].CGColor;

  // 按下态更“实”一点，手感更接近截图
  [button addTarget:self action:@selector(tl_tagTouchDown:) forControlEvents:UIControlEventTouchDown];
  [button addTarget:self action:@selector(tl_tagTouchUp:) forControlEvents:UIControlEventTouchUpInside];
  [button addTarget:self action:@selector(tl_tagTouchUp:) forControlEvents:UIControlEventTouchCancel];
  [button addTarget:self action:@selector(tl_tagTouchUp:) forControlEvents:UIControlEventTouchDragExit];

  [button addTarget:self
             action:@selector(tl_searchSuggestionTapped:)
   forControlEvents:UIControlEventTouchUpInside];
  return button;
}

- (void)tl_tagTouchDown:(UIButton *)sender {
  [UIView animateWithDuration:0.12 animations:^{
    sender.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.98];
  }];
}

- (void)tl_tagTouchUp:(UIButton *)sender {
  [UIView animateWithDuration:0.18 animations:^{
    sender.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.88];
  }];
}

- (void)tl_setupSearchOverlay {
  UIView *overlay = [[UIView alloc] init];
  overlay.backgroundColor = [UIColor clearColor];
  overlay.hidden = YES;
  overlay.alpha = 0.0;
  [self addSubview:overlay];
  self.searchOverlay = overlay;

  [overlay mas_makeConstraints:^(MASConstraintMaker *make) {
    make.edges.equalTo(self);
  }];

  // 全屏背景毛玻璃：用于让底层社区列表产生模糊感
  UIBlurEffect *bgEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
  UIVisualEffectView *bgBlurView = [[UIVisualEffectView alloc] initWithEffect:bgEffect];
  bgBlurView.alpha = 0.85;
  // 不拦截点击，让点击落到 searchOverlay 上用于退出
  bgBlurView.userInteractionEnabled = NO;
  [overlay addSubview:bgBlurView];
  [bgBlurView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.edges.equalTo(overlay);
  }];

  // 轻微的暗色遮罩，增强层次但保持通透
  UIView *dimView = [[UIView alloc] init];
  dimView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.08];
  // 不拦截点击，让点击落到 searchOverlay 上用于退出
  dimView.userInteractionEnabled = NO;
  [overlay addSubview:dimView];
  [dimView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.edges.equalTo(overlay);
  }];


  UITapGestureRecognizer *dismissTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tl_hideSearchOverlay)];
  dismissTap.delegate = self;
  [overlay addGestureRecognizer:dismissTap];

  // 使用更亮的毛玻璃效果，整体显得更通透
  UIBlurEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight];
  UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithEffect:effect];
  blurView.layer.masksToBounds = YES;
  blurView.layer.cornerRadius = 20;
  [overlay addSubview:blurView];
  self.searchBlurPanel = blurView;

  [blurView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.equalTo(overlay).offset(16);
    make.right.equalTo(overlay).offset(-16);
    // 毛玻璃板距离搜索栏底部 10pt，这里用覆盖层顶部再下移 10
    make.top.equalTo(self.searchContainer.mas_bottom).offset(10);
  }];
  [self bringSubviewToFront:self.searchContainer];

  UIView *contentView = blurView.contentView;

  UILabel *historyTitle = [[UILabel alloc] init];
  historyTitle.text = @"历史记录";
  historyTitle.textColor = [UIColor systemBlueColor];
  historyTitle.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
  [contentView addSubview:historyTitle];

  UIButton *clearButton = [UIButton buttonWithType:UIButtonTypeSystem];
  [clearButton setTitle:@"清除记录" forState:UIControlStateNormal];
  [clearButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
  clearButton.titleLabel.font = [UIFont systemFontOfSize:14];
  [clearButton addTarget:self
                  action:@selector(tl_clearHistoryTapped)
        forControlEvents:UIControlEventTouchUpInside];
  [contentView addSubview:clearButton];

  UIStackView *historyStack = [[UIStackView alloc] init];
  historyStack.axis = UILayoutConstraintAxisVertical;
  historyStack.alignment = UIStackViewAlignmentLeading;
  historyStack.spacing = 4.0;
  [contentView addSubview:historyStack];
  self.historyStackView = historyStack;

  NSArray<NSString *> *historyItems = @[ @"水稻", @"杨梅树", @"白菜" ];
  for (NSString *item in historyItems) {
    UIButton *btn = [self tl_tagButtonWithTitle:item];
    [historyStack addArrangedSubview:btn];
  }

  UILabel *guessTitle = [[UILabel alloc] init];
  guessTitle.text = @"猜你想搜";
  guessTitle.textColor = [UIColor systemBlueColor];
  guessTitle.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
  [contentView addSubview:guessTitle];

  UIStackView *guessStack = [[UIStackView alloc] init];
  guessStack.axis = UILayoutConstraintAxisHorizontal;
  guessStack.alignment = UIStackViewAlignmentCenter;
  guessStack.spacing = 10.0;
  guessStack.distribution = UIStackViewDistributionFillProportionally;
  [contentView addSubview:guessStack];

  NSArray<NSString *> *guessItems = @[ @"水稻", @"小麦", @"白菜", @"地瓜" ];
  for (NSString *item in guessItems) {
    UIButton *btn = [self tl_tagButtonWithTitle:item];
    [guessStack addArrangedSubview:btn];
  }

  [historyTitle mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(contentView).offset(14);
    make.left.equalTo(contentView).offset(16);
  }];

  [clearButton mas_makeConstraints:^(MASConstraintMaker *make) {
    make.centerY.equalTo(historyTitle);
    make.right.equalTo(contentView).offset(-16);
  }];

  [historyStack mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(historyTitle.mas_bottom).offset(8);
    make.left.equalTo(contentView).offset(16);
    make.right.lessThanOrEqualTo(contentView).offset(-16);
  }];

  [guessTitle mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(historyStack.mas_bottom).offset(16);
    make.left.equalTo(contentView).offset(16);
  }];

  [guessStack mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(guessTitle.mas_bottom).offset(8);
    make.left.equalTo(contentView).offset(16);
    make.right.lessThanOrEqualTo(contentView).offset(-16);
    make.bottom.equalTo(contentView).offset(-16);
  }];
}

- (void)tl_showSearchOverlay {
  if (!self.searchOverlay) {
    return;
  }
  self.searchOverlay.hidden = NO;
  self.searchOverlay.alpha = 0.0;
  [self.searchTextField becomeFirstResponder];
  [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
    self.searchOverlay.alpha = 1.0;
  }completion:nil];
}

- (void)tl_hideSearchOverlay {
  if (!self.searchOverlay || self.searchOverlay.hidden) {
    return;
  }

  [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveEaseInOut  animations:^{
    self.searchOverlay.alpha = 0.0;
  }completion:^(BOOL finished) {
    self.searchOverlay.hidden = YES;
    self.collectionView.hidden = NO;
    // 收起键盘
    [self endEditing:YES];
  }];
}

- (void)tl_searchSuggestionTapped:(UIButton *)sender {
  NSString *text = sender.currentTitle ?: @"";
  self.searchTextField.text = text;
  // 选中推荐词后，直接视为一次搜索并关闭面板
  [self tl_hideSearchOverlay];
}

- (void)tl_clearHistoryTapped {
  for (UIView *subview in self.historyStackView.arrangedSubviews) {
    [self.historyStackView removeArrangedSubview:subview];
    [subview removeFromSuperview];
  }
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
  // 仅当点击在覆盖层空白区域时才触发收起，点击毛玻璃内容区域不收起
  if (touch.view != self.searchOverlay) {
    return NO;
  }
  return YES;
}

@end

