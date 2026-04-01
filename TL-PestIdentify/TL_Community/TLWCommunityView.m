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

/// 每行最多放置的标签个数（横向填满再换行）
static NSInteger const kTagItemsPerRow = 5;
/// 联想词列表内边距
static CGFloat const kSuggestionListHorizontalInset = 12.0;

@interface TLWCommunityView () <UIGestureRecognizerDelegate>

@property (nonatomic, strong, readwrite) UICollectionView *collectionView;
@property (nonatomic, strong, readwrite) UITextField *searchTextField;
@property (nonatomic, strong, readwrite) UITableView *suggestionTableView;
@property (nonatomic, strong, readwrite) UIButton *voiceButton;
@property (nonatomic, strong) UIView *searchContainer;
/// 搜索时的毛玻璃覆盖层（含历史记录、猜你想搜）
@property (nonatomic, strong) UIVisualEffectView *searchBlurPanel;
@property (nonatomic, strong) UIView *defaultSearchContentView;
@property (nonatomic, strong) MASConstraint *suggestionTableHeightConstraint;
/// 历史记录行容器（垂直 StackView，每行一个水平 StackView）
@property (nonatomic, strong) UIStackView *historyStackView;
/// 猜你想搜行容器（垂直 StackView，每行一个水平 StackView）
@property (nonatomic, strong) UIStackView *guessStackView;
/// 搜索区域点击手势（用于排除点击语音按钮时触发）
@property (nonatomic, strong) UITapGestureRecognizer *searchFieldTapGesture;

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
  self.voiceButton = voiceButton;

  UITextField *textField = [[UITextField alloc] init];
  textField.placeholder = @"请输入关键词";
  textField.font = [UIFont systemFontOfSize:14];
  textField.textColor = [UIColor darkTextColor];
  textField.returnKeyType = UIReturnKeySearch;
  [searchFieldBackground addSubview:textField];
  self.searchTextField = textField;

  // 点击整个搜索区域时也可以唤起搜索面板（需排除语音按钮，让语音按钮能正常跳转）
  searchFieldBackground.userInteractionEnabled = YES;
  UITapGestureRecognizer *searchTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tl_showSearchOverlay)];
  searchTap.delegate = self;
  [searchFieldBackground addGestureRecognizer:searchTap];
  self.searchFieldTapGesture = searchTap;

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
    make.left.equalTo(searchFieldBackground).offset(8);
    make.centerY.equalTo(searchFieldBackground);
    make.width.height.mas_equalTo(32);
  }];

  [voiceButton mas_makeConstraints:^(MASConstraintMaker *make) {
    make.right.equalTo(searchFieldBackground).offset(-8);
    make.centerY.equalTo(searchFieldBackground);
    make.width.height.mas_equalTo(32);
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
  button.titleLabel.lineBreakMode = NSLineBreakByClipping;
  // 文字完整展示，按钮宽度随内容自适应
  [button setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];

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

  [button addTarget:self action:@selector(tl_searchSuggestionTapped:) forControlEvents:UIControlEventTouchUpInside];
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

  UIBlurEffect *bgEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];

  UIVisualEffectView *bgBlurView1 = [[UIVisualEffectView alloc] initWithEffect:bgEffect];
  bgBlurView1.alpha = 1.0;
  bgBlurView1.userInteractionEnabled = NO;

  [overlay addSubview:bgBlurView1];
  [bgBlurView1 mas_makeConstraints:^(MASConstraintMaker *make) {
      make.edges.equalTo(overlay);
  }];

  UIVisualEffectView *bgBlurView2 = [[UIVisualEffectView alloc] initWithEffect:bgEffect];
  bgBlurView2.alpha = 1.0;
  bgBlurView2.userInteractionEnabled = NO;

  [overlay addSubview:bgBlurView2];
  [bgBlurView2 mas_makeConstraints:^(MASConstraintMaker *make) {
      make.edges.equalTo(overlay);
  }];
  // 轻微的暗色遮罩，增强层次但保持通透
  UIView *dimView = [[UIView alloc] init];
  dimView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.25];
  // 不拦截点击，让点击落到 searchOverlay 上用于退出
  dimView.userInteractionEnabled = NO;
  [overlay addSubview:dimView];
  [dimView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.edges.equalTo(overlay);
  }];


  UITapGestureRecognizer *dismissTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tl_hideSearchOverlay)];
  dismissTap.delegate = self;
  [overlay addGestureRecognizer:dismissTap];

  UISwipeGestureRecognizer *swipeDown = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(tl_dismissKeyboard)];
  swipeDown.direction = UISwipeGestureRecognizerDirectionDown;
  [overlay addGestureRecognizer:swipeDown];

  // 更强对比的毛玻璃背景
  UIView *panelContainer = [[UIView alloc] init];
  panelContainer.layer.cornerRadius = 20.0;
  panelContainer.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.18].CGColor;
  panelContainer.layer.shadowOpacity = 1.0;
  panelContainer.layer.shadowRadius = 22.0;
  panelContainer.layer.shadowOffset = CGSizeMake(0, 12);
  [overlay addSubview:panelContainer];

  UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemMaterialLight];
  UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
  blurView.layer.cornerRadius = 20.0;
  blurView.layer.masksToBounds = YES;
  [panelContainer addSubview:blurView];
  self.searchBlurPanel = blurView;
  UIView *contentView = blurView.contentView;
  UIView *glassLayer = [[UIView alloc] init];
  glassLayer.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.22];
  glassLayer.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  [contentView addSubview:glassLayer];
  UIView *highlightLayer = [[UIView alloc] init];
  highlightLayer.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.20];
  highlightLayer.userInteractionEnabled = NO;
  highlightLayer.layer.cornerRadius = 20.0;
  highlightLayer.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
  highlightLayer.layer.masksToBounds = YES;
  [contentView addSubview:highlightLayer];
  // 边框
  blurView.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.42].CGColor;
  blurView.layer.borderWidth = 1.0;
  [panelContainer mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.equalTo(overlay).offset(16);
    make.right.equalTo(overlay).offset(-16);
    // 毛玻璃板距离搜索栏底部 10pt，这里用覆盖层顶部再下移 10
    make.top.equalTo(self.searchContainer.mas_bottom).offset(10);
  }];
  [blurView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.edges.equalTo(panelContainer);
  }];
  [glassLayer mas_makeConstraints:^(MASConstraintMaker *make) {
    make.edges.equalTo(contentView);
  }];
  [highlightLayer mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.left.right.equalTo(contentView);
    make.height.mas_equalTo(72);
  }];

  UITableView *suggestionTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
  suggestionTableView.backgroundColor = [UIColor clearColor];
  suggestionTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
  suggestionTableView.separatorInset = UIEdgeInsetsZero;
  suggestionTableView.contentInset = UIEdgeInsetsMake(10, 0, 8, 0);
  suggestionTableView.rowHeight = 58.0;
  suggestionTableView.scrollEnabled = NO;
  suggestionTableView.hidden = YES;
  suggestionTableView.tableFooterView = [UIView new];
  suggestionTableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
  [suggestionTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"TLWCommunitySuggestionCell"];
  if (@available(iOS 15.0, *)) {
    suggestionTableView.sectionHeaderTopPadding = 0;
  }
  [contentView addSubview:suggestionTableView];
  self.suggestionTableView = suggestionTableView;
  [suggestionTableView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(contentView).offset(6);
    make.left.equalTo(contentView).offset(kSuggestionListHorizontalInset);
    make.right.equalTo(contentView).offset(-kSuggestionListHorizontalInset);
    self.suggestionTableHeightConstraint = make.height.mas_equalTo(0);
  }];
  
  [self bringSubviewToFront:self.searchContainer];
  UIView *defaultSearchContentView = [[UIView alloc] init];
  [contentView addSubview:defaultSearchContentView];
  self.defaultSearchContentView = defaultSearchContentView;
  UILabel *historyTitle = [[UILabel alloc] init];
  historyTitle.text = @"历史记录";
  historyTitle.textColor = [UIColor systemBlueColor];
  historyTitle.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
  [defaultSearchContentView addSubview:historyTitle];

  UIButton *clearButton = [UIButton buttonWithType:UIButtonTypeSystem];
  [clearButton setTitle:@"清除记录" forState:UIControlStateNormal];
  [clearButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
  clearButton.titleLabel.font = [UIFont systemFontOfSize:14];
  [clearButton addTarget:self
                  action:@selector(tl_clearHistoryTapped)
        forControlEvents:UIControlEventTouchUpInside];
  [defaultSearchContentView addSubview:clearButton];

  // 历史记录行容器（内容通过 tl_setSearchHistoryItems: 设置）
  UIStackView *historyRowsStack = [[UIStackView alloc] init];
  historyRowsStack.axis = UILayoutConstraintAxisVertical;
  historyRowsStack.alignment = UIStackViewAlignmentLeading;
  historyRowsStack.spacing = 8.0;
  [defaultSearchContentView addSubview:historyRowsStack];
  self.historyStackView = historyRowsStack;

  UILabel *guessTitle = [[UILabel alloc] init];
  guessTitle.text = @"猜你想搜";
  guessTitle.textColor = [UIColor systemBlueColor];
  guessTitle.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];

  // 猜你想搜行容器（内容通过 tl_setGuessYouWantToSearchItems: 设置）
  UIStackView *guessRowsStack = [[UIStackView alloc] init];
  guessRowsStack.axis = UILayoutConstraintAxisVertical;
  guessRowsStack.alignment = UIStackViewAlignmentLeading;
  guessRowsStack.spacing = 8.0;
  self.guessStackView = guessRowsStack;

  UIStackView *guessSectionStack = [[UIStackView alloc] initWithArrangedSubviews:@[ guessTitle, guessRowsStack ]];
  guessSectionStack.axis = UILayoutConstraintAxisVertical;
  guessSectionStack.alignment = UIStackViewAlignmentLeading;
  guessSectionStack.spacing = 8.0;
  [defaultSearchContentView addSubview:guessSectionStack];

  [defaultSearchContentView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(self.suggestionTableView.mas_bottom);
    make.left.right.bottom.equalTo(contentView);
  }];

  [historyTitle mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(defaultSearchContentView).offset(14);
    make.left.equalTo(defaultSearchContentView).offset(16);
  }];

  [clearButton mas_makeConstraints:^(MASConstraintMaker *make) {
    make.centerY.equalTo(historyTitle);
    make.right.equalTo(defaultSearchContentView).offset(-16);
  }];

  [historyRowsStack mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(historyTitle.mas_bottom).offset(8);
    make.left.equalTo(defaultSearchContentView).offset(16);
    make.right.lessThanOrEqualTo(defaultSearchContentView).offset(-16);
  }];

  [guessSectionStack mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(historyRowsStack.mas_bottom).offset(16);
    make.left.equalTo(defaultSearchContentView).offset(16);
    make.right.lessThanOrEqualTo(defaultSearchContentView).offset(-16);
    make.bottom.equalTo(defaultSearchContentView).offset(-16);
  }];

  // 默认展示数据，外部可通过接口覆盖
  [self tl_setSearchHistoryItems:@[ @"水稻", @"杨梅树", @"白菜", @"地瓜", @"水稻", @"小麦", @"白菜", @"地瓜", @"水稻", @"小麦", @"白菜", @"地瓜" ]];
  [self tl_setGuessYouWantToSearchItems:@[ @"水稻", @"小麦", @"白菜" ]];
}

#pragma mark - 搜索历史 / 猜你想搜 数据接口

- (void)tl_rebuildTagRowsInStackView:(UIStackView *)stackView withItems:(NSArray<NSString *> *)items {
  for (UIView *subview in stackView.arrangedSubviews) {
    [stackView removeArrangedSubview:subview];
    [subview removeFromSuperview];
  }
  if (items.count == 0) {
    return;
  }
  for (NSInteger i = 0; i < items.count; i += kTagItemsPerRow) {
    NSInteger count = MIN(kTagItemsPerRow, (NSInteger)items.count - i);
    NSArray<NSString *> *rowItems = [items subarrayWithRange:NSMakeRange((NSUInteger)i, (NSUInteger)count)];
    UIStackView *rowStack = [[UIStackView alloc] init];
    rowStack.axis = UILayoutConstraintAxisHorizontal;
    rowStack.alignment = UIStackViewAlignmentCenter;
    rowStack.spacing = 10.0;
    rowStack.distribution = UIStackViewDistributionFill;
    for (NSString *item in rowItems) {
      UIButton *btn = [self tl_tagButtonWithTitle:item];
      [rowStack addArrangedSubview:btn];
    }
    [stackView addArrangedSubview:rowStack];
  }
}

- (void)tl_setSearchHistoryItems:(NSArray<NSString *> *)items {
  [self tl_rebuildTagRowsInStackView:self.historyStackView withItems:items ?: @[]];
}

- (void)tl_setGuessYouWantToSearchItems:(NSArray<NSString *> *)items {
  [self tl_rebuildTagRowsInStackView:self.guessStackView withItems:items ?: @[]];
}

- (void)tl_setSuggestionListHidden:(BOOL)hidden itemCount:(NSInteger)itemCount {
  NSInteger visibleCount = MAX(0, MIN(itemCount, 6));
  UIEdgeInsets contentInset = self.suggestionTableView.contentInset;
  CGFloat targetHeight = hidden ? 0.0 : visibleCount * self.suggestionTableView.rowHeight + contentInset.top + contentInset.bottom;
  self.suggestionTableView.hidden = hidden;
  self.suggestionTableView.scrollEnabled = itemCount > 6;
  [self.suggestionTableHeightConstraint setOffset:targetHeight];
  self.defaultSearchContentView.hidden = !hidden;
  [self layoutIfNeeded];
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
  [self.searchTextField sendActionsForControlEvents:UIControlEventEditingChanged];
  [self.searchTextField becomeFirstResponder];
}

- (void)tl_dismissKeyboard {
  [self endEditing:YES];
}

- (void)tl_clearHistoryTapped {
  for (UIView *subview in self.historyStackView.arrangedSubviews) {
    [self.historyStackView removeArrangedSubview:subview];
    [subview removeFromSuperview];
  }
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
  // 搜索区域点击：点击在语音按钮上时不触发，让语音按钮响应跳转
  if (gestureRecognizer == self.searchFieldTapGesture) {
    if (touch.view == self.voiceButton || [touch.view isDescendantOfView:self.voiceButton]) {
      return NO;
    }
    return YES;
  }
  // 覆盖层点击：仅当点击在覆盖层空白区域时才触发收起，点击毛玻璃内容区域不收起
  if (touch.view != self.searchOverlay) {
    return NO;
  }
  return YES;
}

@end
