//
//  TLWLocationView.m
//  TL-PestIdentify
//

#import "TLWLocationView.h"
#import "Models/TLWLocationCityModel.h"
#import <Masonry/Masonry.h>

// MARK: - TLWLocationSearchResult

@implementation TLWLocationSearchResult
@end

// MARK: - TLWLocationTagGridView

@interface TLWLocationTagGridView : UIView
@property (nonatomic, copy) void (^onTagTapped)(NSString *title);
- (void)updateWithTitles:(NSArray<NSString *> *)titles
           selectedTitle:(nullable NSString *)selectedTitle
             columnCount:(NSInteger)columnCount;
@end

@implementation TLWLocationTagGridView {
    UIStackView *_rootStackView;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _rootStackView = [[UIStackView alloc] init];
        _rootStackView.axis = UILayoutConstraintAxisVertical;
        _rootStackView.spacing = 12.0;
        _rootStackView.distribution = UIStackViewDistributionFillEqually;
        [self addSubview:_rootStackView];
        [_rootStackView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self);
        }];
    }
    return self;
}

- (void)updateWithTitles:(NSArray<NSString *> *)titles
           selectedTitle:(nullable NSString *)selectedTitle
             columnCount:(NSInteger)columnCount {
    for (UIView *rowView in _rootStackView.arrangedSubviews) {
        [_rootStackView removeArrangedSubview:rowView];
        [rowView removeFromSuperview];
    }
    CGFloat itemHeight = columnCount >= 6 ? 30.0 : 34.0;
    NSInteger totalRows = (NSInteger)ceil((CGFloat)titles.count / MAX(columnCount, 1));

    for (NSInteger row = 0; row < totalRows; row++) {
        UIStackView *rowStack = [[UIStackView alloc] init];
        rowStack.axis = UILayoutConstraintAxisHorizontal;
        rowStack.spacing = 12.0;
        rowStack.distribution = UIStackViewDistributionFillEqually;
        [_rootStackView addArrangedSubview:rowStack];

        for (NSInteger column = 0; column < columnCount; column++) {
            NSInteger index = row * columnCount + column;
            UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
            button.layer.cornerRadius = itemHeight * 0.5;
            button.layer.masksToBounds = YES;
            button.titleLabel.font = [UIFont systemFontOfSize:(columnCount >= 6 ? 14.0 : 15.0) weight:UIFontWeightSemibold];
            [button mas_makeConstraints:^(MASConstraintMaker *make) {
                make.height.mas_equalTo(itemHeight);
            }];

            if (index < (NSInteger)titles.count) {
                NSString *title = titles[index];
                [button setTitle:title forState:UIControlStateNormal];
                button.backgroundColor = [title isEqualToString:selectedTitle] ? [UIColor colorWithRed:0.40 green:0.76 blue:0.98 alpha:0.22] : [UIColor colorWithWhite:0.95 alpha:1.0];
                [button setTitleColor:[title isEqualToString:selectedTitle] ? [UIColor colorWithRed:0.25 green:0.64 blue:0.90 alpha:1.0] : [UIColor colorWithRed:0.35 green:0.36 blue:0.40 alpha:1.0] forState:UIControlStateNormal];
                [button addTarget:self action:@selector(tl_handleButtonTap:) forControlEvents:UIControlEventTouchUpInside];
            } else {
                button.hidden = YES;
                button.userInteractionEnabled = NO;
            }
            [rowStack addArrangedSubview:button];
        }
    }
}

- (void)tl_handleButtonTap:(UIButton *)sender {
    NSString *title = [sender titleForState:UIControlStateNormal];
    if (title.length > 0 && self.onTagTapped) {
        self.onTagTapped(title);
    }
}

@end

// MARK: - TLWSearchResultCell

static NSString *const kSearchResultCellID = @"TLWSearchResultCell";

@interface TLWSearchResultCell : UITableViewCell
- (void)configureWithResult:(TLWLocationSearchResult *)result keyword:(NSString *)keyword;
@end

@implementation TLWSearchResultCell {
    UIImageView *_pinIconView;
    UILabel *_nameLabel;
    UILabel *_detailLabel;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.selectionStyle = UITableViewCellSelectionStyleGray;

        _pinIconView = [[UIImageView alloc] init];
        _pinIconView.contentMode = UIViewContentModeScaleAspectFit;
        _pinIconView.tintColor = [UIColor colorWithRed:0.90 green:0.56 blue:0.10 alpha:1.0];
        if (@available(iOS 13.0, *)) {
            _pinIconView.image = [[UIImage systemImageNamed:@"mappin"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        }
        [self.contentView addSubview:_pinIconView];

        _nameLabel = [[UILabel alloc] init];
        _nameLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightBold];
        [self.contentView addSubview:_nameLabel];

        _detailLabel = [[UILabel alloc] init];
        _detailLabel.font = [UIFont systemFontOfSize:12];
        _detailLabel.textColor = [UIColor colorWithRed:0.55 green:0.58 blue:0.63 alpha:1.0];
        [self.contentView addSubview:_detailLabel];

        [_pinIconView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.contentView).offset(16);
            make.centerY.equalTo(self.contentView);
            make.width.height.mas_equalTo(18);
        }];
        [_nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(_pinIconView.mas_right).offset(12);
            make.right.equalTo(self.contentView).offset(-16);
            make.top.equalTo(self.contentView).offset(10);
        }];
        [_detailLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(_nameLabel);
            make.top.equalTo(_nameLabel.mas_bottom).offset(4);
        }];
    }
    return self;
}

- (void)configureWithResult:(TLWLocationSearchResult *)result keyword:(NSString *)keyword {
    UIColor *orangeColor = [UIColor colorWithRed:0.90 green:0.56 blue:0.10 alpha:1.0];
    UIColor *defaultColor = [UIColor colorWithRed:0.15 green:0.16 blue:0.19 alpha:1.0];

    NSMutableAttributedString *nameAttr = [[NSMutableAttributedString alloc] initWithString:result.name attributes:@{
        NSFontAttributeName: [UIFont systemFontOfSize:16 weight:UIFontWeightBold],
        NSForegroundColorAttributeName: defaultColor
    }];

    if (keyword.length > 0) {
        NSString *lowerName = result.name.lowercaseString;
        NSString *lowerKeyword = keyword.lowercaseString;
        NSRange searchRange = NSMakeRange(0, lowerName.length);
        while (searchRange.location < lowerName.length) {
            NSRange matchRange = [lowerName rangeOfString:lowerKeyword options:0 range:searchRange];
            if (matchRange.location == NSNotFound) { break; }
            [nameAttr addAttribute:NSForegroundColorAttributeName value:orangeColor range:matchRange];
            NSUInteger nextStart = matchRange.location + matchRange.length;
            if (nextStart >= lowerName.length) { break; }
            searchRange = NSMakeRange(nextStart, lowerName.length - nextStart);
        }
    }
    _nameLabel.attributedText = nameAttr;
    _detailLabel.text = [NSString stringWithFormat:@"%@   %@", result.distance, result.address];
}

@end

// MARK: - TLWLocationView

@interface TLWLocationView () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UIImageView *backgroundImageView;
@property (nonatomic, strong) UIView *overlayView;

// Top bar (outside scrollView so overlay positioning is simple)
@property (nonatomic, strong) UIView *topBarView;
@property (nonatomic, strong) UIButton *backButton;
@property (nonatomic, strong) UIView *searchContainerView;
@property (nonatomic, strong) UITextField *searchField;

// Main scroll content
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UILabel *selectedLocationLabel;
@property (nonatomic, strong) UILabel *currentLocationLabel;
@property (nonatomic, strong) TLWLocationTagGridView *recommendedGridView;
@property (nonatomic, strong) UIStackView *sectionsStackView;
@property (nonatomic, strong) NSMutableDictionary<NSString *, UIView *> *sectionAnchorViews;
@property (nonatomic, copy) NSString *selectedLocationName;

// Search results overlay
@property (nonatomic, strong) UIView *searchResultsCard;
@property (nonatomic, strong) UITableView *searchResultsTableView;
@property (nonatomic, copy) NSArray<TLWLocationSearchResult *> *searchResults;
@property (nonatomic, copy) NSString *searchKeyword;
@property (nonatomic, strong) MASConstraint *tableHeightConstraint;

@end

@implementation TLWLocationView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _sectionAnchorViews = [NSMutableDictionary dictionary];
        _searchResults = @[];
        _searchKeyword = @"";
        [self tl_setupUI];
    }
    return self;
}

- (void)tl_setupUI {
    self.backgroundColor = [UIColor whiteColor];

    // Background
    self.backgroundImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"hp_backView"]];
    self.backgroundImageView.contentMode = UIViewContentModeScaleAspectFill;
    [self addSubview:self.backgroundImageView];

    self.overlayView = [[UIView alloc] init];
    self.overlayView.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.18];
    [self addSubview:self.overlayView];

    [self.backgroundImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];
    [self.overlayView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];

    // Top bar (fixed, not in scrollView)
    [self tl_setupTopBar];

    // ScrollView below top bar
    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    [self addSubview:self.scrollView];

    self.contentView = [[UIView alloc] init];
    [self.scrollView addSubview:self.contentView];

    [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.topBarView.mas_bottom);
        make.left.right.bottom.equalTo(self);
    }];
    [self.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.scrollView);
        make.width.equalTo(self.scrollView);
    }];

    UIView *currentCard = [self tl_buildCurrentCard];
    UIView *recommendCard = [self tl_buildRecommendCard];
    [self.contentView addSubview:currentCard];
    [self.contentView addSubview:recommendCard];

    [currentCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView).offset(14);
        make.left.equalTo(self.contentView).offset(16);
        make.right.equalTo(self.contentView).offset(-16);
    }];
    [recommendCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(currentCard.mas_bottom).offset(18);
        make.left.right.equalTo(currentCard);
        make.bottom.equalTo(self.contentView).offset(-24);
    }];

    // Search results overlay (on top of scrollView)
    [self tl_setupSearchResultsCard];
}

- (void)tl_setupTopBar {
    self.topBarView = [[UIView alloc] init];
    [self addSubview:self.topBarView];

    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = @"定位";
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.font = [UIFont systemFontOfSize:24 weight:UIFontWeightBold];
    [self.topBarView addSubview:titleLabel];

    self.backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.backButton.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.22];
    self.backButton.layer.cornerRadius = 22.0;
    self.backButton.layer.borderWidth = 1.0;
    self.backButton.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.22].CGColor;
    if (@available(iOS 13.0, *)) {
        UIImageSymbolConfiguration *configuration = [UIImageSymbolConfiguration configurationWithPointSize:18 weight:UIImageSymbolWeightSemibold];
        UIImage *chevronImage = [[UIImage systemImageNamed:@"chevron.left" withConfiguration:configuration] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [self.backButton setImage:chevronImage forState:UIControlStateNormal];
        self.backButton.tintColor = [UIColor whiteColor];
    } else {
        [self.backButton setTitle:@"<" forState:UIControlStateNormal];
        [self.backButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        self.backButton.titleLabel.font = [UIFont boldSystemFontOfSize:18];
    }
    [self.backButton addTarget:self action:@selector(tl_backTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.topBarView addSubview:self.backButton];

    self.searchContainerView = [[UIView alloc] init];
    self.searchContainerView.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.82];
    self.searchContainerView.layer.cornerRadius = 22.0;
    self.searchContainerView.layer.borderWidth = 1.0;
    self.searchContainerView.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.3].CGColor;
    [self.topBarView addSubview:self.searchContainerView];

    self.searchField = [[UITextField alloc] init];
    self.searchField.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    self.searchField.textColor = [UIColor colorWithRed:0.32 green:0.35 blue:0.39 alpha:1.0];
    self.searchField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"城市/区县/村镇等地点"
                                                                              attributes:@{
        NSForegroundColorAttributeName: [UIColor colorWithRed:0.70 green:0.75 blue:0.78 alpha:1.0],
        NSFontAttributeName: [UIFont systemFontOfSize:15 weight:UIFontWeightMedium]
    }];
    self.searchField.clearButtonMode = UITextFieldViewModeWhileEditing;
    [self.searchField addTarget:self action:@selector(tl_searchChanged:) forControlEvents:UIControlEventEditingChanged];
    [self.searchContainerView addSubview:self.searchField];

    // Top bar constraints
    [self.topBarView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self);
    }];
    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.topBarView);
        make.top.equalTo(self.topBarView.mas_safeAreaLayoutGuideTop).offset(6);
    }];
    [self.backButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.topBarView).offset(16);
        make.top.equalTo(titleLabel.mas_bottom).offset(14);
        make.width.height.mas_equalTo(44);
    }];
    [self.searchContainerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.backButton);
        make.left.equalTo(self.backButton.mas_right).offset(14);
        make.right.equalTo(self.topBarView).offset(-16);
        make.height.mas_equalTo(44);
    }];
    [self.searchField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.searchContainerView).offset(18);
        make.right.equalTo(self.searchContainerView).offset(-16);
        make.centerY.equalTo(self.searchContainerView);
        make.height.mas_equalTo(36);
    }];
    // topBarView bottom pinned to searchContainerView bottom + padding
    [self.topBarView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.searchContainerView.mas_bottom).offset(14);
    }];
}

- (void)tl_setupSearchResultsCard {
    self.searchResultsCard = [[UIView alloc] init];
    self.searchResultsCard.backgroundColor = [UIColor colorWithRed:0.98 green:0.99 blue:1.0 alpha:1.0];
    self.searchResultsCard.layer.cornerRadius = 18.0;
    self.searchResultsCard.layer.shadowColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.10].CGColor;
    self.searchResultsCard.layer.shadowOpacity = 1.0;
    self.searchResultsCard.layer.shadowRadius = 12.0;
    self.searchResultsCard.layer.shadowOffset = CGSizeMake(0, 4);
    self.searchResultsCard.clipsToBounds = NO;
    self.searchResultsCard.hidden = YES;
    [self addSubview:self.searchResultsCard];

    self.searchResultsTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.searchResultsTableView.backgroundColor = [UIColor clearColor];
    self.searchResultsTableView.separatorInset = UIEdgeInsetsMake(0, 46, 0, 0);
    self.searchResultsTableView.separatorColor = [UIColor colorWithRed:0.88 green:0.90 blue:0.93 alpha:1.0];
    self.searchResultsTableView.rowHeight = 62.0;
    self.searchResultsTableView.dataSource = self;
    self.searchResultsTableView.delegate = self;
    self.searchResultsTableView.layer.cornerRadius = 18.0;
    self.searchResultsTableView.layer.masksToBounds = YES;
    self.searchResultsTableView.bounces = YES;
    self.searchResultsTableView.showsVerticalScrollIndicator = NO;
    [self.searchResultsTableView registerClass:[TLWSearchResultCell class] forCellReuseIdentifier:kSearchResultCellID];
    [self.searchResultsCard addSubview:self.searchResultsTableView];

    [self.searchResultsCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.topBarView.mas_bottom).offset(-8);
        make.left.equalTo(self).offset(16);
        make.right.equalTo(self).offset(-16);
    }];
    [self.searchResultsTableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.searchResultsCard);
        self.tableHeightConstraint = make.height.mas_equalTo(0);
    }];
}

// MARK: - Card builders

- (UIView *)tl_buildCurrentCard {
    UIView *card = [self tl_cardView];

    UILabel *selectedTitleLabel = [self tl_sectionTitleLabelWithText:@"当前选择："];
    [card addSubview:selectedTitleLabel];

    self.selectedLocationLabel = [[UILabel alloc] init];
    self.selectedLocationLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    self.selectedLocationLabel.textColor = [UIColor colorWithRed:0.38 green:0.39 blue:0.44 alpha:1.0];
    [card addSubview:self.selectedLocationLabel];

    UIView *divider = [[UIView alloc] init];
    divider.backgroundColor = [UIColor colorWithRed:0.86 green:0.89 blue:0.92 alpha:1.0];
    [card addSubview:divider];

    UILabel *locationTitleLabel = [self tl_sectionTitleLabelWithText:@"当前定位"];
    [card addSubview:locationTitleLabel];

    self.currentLocationLabel = [[UILabel alloc] init];
    self.currentLocationLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
    self.currentLocationLabel.textColor = [UIColor colorWithRed:0.22 green:0.24 blue:0.28 alpha:1.0];
    [card addSubview:self.currentLocationLabel];

    UIButton *relocateButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [relocateButton setTitle:@"重新定位" forState:UIControlStateNormal];
    [relocateButton setTitleColor:[UIColor colorWithRed:0.32 green:0.73 blue:0.96 alpha:1.0] forState:UIControlStateNormal];
    relocateButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    UIImage *relocateIcon = [[UIImage imageNamed:@"location_icon"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    if (@available(iOS 15.0, *)) {
        UIButtonConfiguration *configuration = [UIButtonConfiguration plainButtonConfiguration];
        configuration.image = relocateIcon;
        configuration.imagePadding = 8.0;
        configuration.contentInsets = NSDirectionalEdgeInsetsZero;
        relocateButton.configuration = configuration;
    } else {
        [relocateButton setImage:relocateIcon forState:UIControlStateNormal];
        relocateButton.semanticContentAttribute = UISemanticContentAttributeForceLeftToRight;
    }
    [relocateButton addTarget:self action:@selector(tl_relocateTapped) forControlEvents:UIControlEventTouchUpInside];
    [card addSubview:relocateButton];

    [selectedTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(card).offset(16);
        make.top.equalTo(card).offset(18);
    }];
    [self.selectedLocationLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(selectedTitleLabel.mas_right).offset(8);
        make.centerY.equalTo(selectedTitleLabel);
        make.right.lessThanOrEqualTo(card).offset(-16);
    }];
    [divider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(card);
        make.top.equalTo(selectedTitleLabel.mas_bottom).offset(18);
        make.height.mas_equalTo(1);
    }];
    [locationTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(card).offset(16);
        make.top.equalTo(divider.mas_bottom).offset(14);
    }];
    [self.currentLocationLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(locationTitleLabel);
        make.top.equalTo(locationTitleLabel.mas_bottom).offset(10);
        make.right.lessThanOrEqualTo(relocateButton.mas_left).offset(-12);
        make.bottom.equalTo(card).offset(-20);
    }];
    [relocateButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(card).offset(-16);
        make.centerY.equalTo(self.currentLocationLabel);
    }];

    return card;
}

- (UIView *)tl_buildRecommendCard {
    UIView *card = [self tl_cardView];

    UIView *recommendPanel = [self tl_innerPanelView];
    UIView *listPanel = [self tl_innerPanelView];
    [card addSubview:recommendPanel];
    [card addSubview:listPanel];

    UILabel *recommendTitle = [self tl_groupHeaderLabelWithText:@"推荐城市"];
    [recommendPanel addSubview:recommendTitle];

    self.recommendedGridView = [[TLWLocationTagGridView alloc] init];
    __weak typeof(self) weakSelf = self;
    self.recommendedGridView.onTagTapped = ^(NSString *title) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf.onCitySelected) { strongSelf.onCitySelected(title); }
    };
    [recommendPanel addSubview:self.recommendedGridView];

    self.sectionsStackView = [[UIStackView alloc] init];
    self.sectionsStackView.axis = UILayoutConstraintAxisVertical;
    self.sectionsStackView.spacing = 0.0;
    [listPanel addSubview:self.sectionsStackView];

    [recommendPanel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(card).offset(16);
        make.left.equalTo(card).offset(14);
        make.right.equalTo(card).offset(-14);
    }];
    [recommendTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(recommendPanel).offset(16);
        make.left.equalTo(recommendPanel).offset(14);
    }];
    [self.recommendedGridView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(recommendTitle.mas_bottom).offset(14);
        make.left.equalTo(recommendPanel).offset(12);
        make.right.equalTo(recommendPanel).offset(-12);
        make.bottom.equalTo(recommendPanel).offset(-14);
    }];
    [listPanel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(recommendPanel.mas_bottom).offset(14);
        make.left.right.equalTo(recommendPanel);
        make.bottom.equalTo(card).offset(-16);
    }];
    [self.sectionsStackView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(listPanel).offset(10);
        make.left.right.equalTo(listPanel);
        make.bottom.equalTo(listPanel).offset(-8);
    }];

    return card;
}

// MARK: - Public configure

- (void)configureWithSelectedLocation:(nullable NSString *)selectedLocation
                      currentLocation:(nullable NSString *)currentLocation
                    recommendedCities:(NSArray<NSString *> *)recommendedCities
                        alphabetTitles:(NSArray<NSString *> *)alphabetTitles
                          citySections:(NSArray<TLWLocationCitySection *> *)citySections {
    (void)alphabetTitles;
    self.selectedLocationName = selectedLocation ?: @"未选择";
    self.selectedLocationLabel.text = self.selectedLocationName;
    self.currentLocationLabel.text = currentLocation.length > 0 ? currentLocation : @"暂未获取定位";

    [self.recommendedGridView updateWithTitles:recommendedCities selectedTitle:selectedLocation columnCount:4];
    [self tl_reloadCitySections:citySections];
}

- (void)showSearchResults:(NSArray<TLWLocationSearchResult *> *)results forKeyword:(NSString *)keyword {
    self.searchResults = results ?: @[];
    self.searchKeyword = keyword ?: @"";

    CGFloat rowH = self.searchResultsTableView.rowHeight;
    CGFloat maxH = rowH * 5;
    CGFloat tableH = MIN((CGFloat)self.searchResults.count * rowH, maxH);
    [self.tableHeightConstraint setOffset:tableH];

    [self.searchResultsTableView reloadData];
    self.searchResultsCard.hidden = (self.searchResults.count == 0);
    [self bringSubviewToFront:self.searchResultsCard];
}

- (void)hideSearchResults {
    self.searchResultsCard.hidden = YES;
    self.searchResults = @[];
}

// MARK: - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (NSInteger)self.searchResults.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TLWSearchResultCell *cell = [tableView dequeueReusableCellWithIdentifier:kSearchResultCellID forIndexPath:indexPath];
    TLWLocationSearchResult *result = self.searchResults[indexPath.row];
    [cell configureWithResult:result keyword:self.searchKeyword];
    return cell;
}

// MARK: - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    TLWLocationSearchResult *result = self.searchResults[indexPath.row];
    if (self.onSearchResultSelected) {
        self.onSearchResultSelected(result.name);
    }
}

// MARK: - Reload sections

- (void)tl_reloadCitySections:(NSArray<TLWLocationCitySection *> *)citySections {
    [self.sectionAnchorViews removeAllObjects];
    for (UIView *view in self.sectionsStackView.arrangedSubviews) {
        [self.sectionsStackView removeArrangedSubview:view];
        [view removeFromSuperview];
    }

    for (TLWLocationCitySection *section in citySections) {
        UIView *container = [[UIView alloc] init];
        container.backgroundColor = [UIColor clearColor];
        [self.sectionsStackView addArrangedSubview:container];

        UILabel *titleLabel = [[UILabel alloc] init];
        titleLabel.text = section.title;
        titleLabel.font = [UIFont systemFontOfSize:24 weight:UIFontWeightMedium];
        titleLabel.textColor = [UIColor colorWithRed:0.46 green:0.49 blue:0.55 alpha:1.0];
        [container addSubview:titleLabel];
        self.sectionAnchorViews[section.title] = container;

        UIView *previousView = titleLabel;
        [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(container).offset(16);
            make.top.equalTo(container).offset(8);
        }];

        for (NSString *cityName in section.cities) {
            UIButton *rowButton = [UIButton buttonWithType:UIButtonTypeCustom];
            rowButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
            rowButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:[cityName isEqualToString:self.selectedLocationName] ? UIFontWeightBold : UIFontWeightMedium];
            [rowButton setTitle:cityName forState:UIControlStateNormal];
            [rowButton setTitleColor:[cityName isEqualToString:self.selectedLocationName] ? [UIColor colorWithRed:0.26 green:0.68 blue:0.94 alpha:1.0] : [UIColor colorWithRed:0.36 green:0.37 blue:0.41 alpha:1.0] forState:UIControlStateNormal];
            [rowButton addTarget:self action:@selector(tl_cityButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
            [container addSubview:rowButton];

            UIView *divider = [[UIView alloc] init];
            divider.backgroundColor = [UIColor colorWithRed:0.88 green:0.90 blue:0.93 alpha:1.0];
            [container addSubview:divider];

            [rowButton mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(container).offset(16);
                make.right.equalTo(container).offset(-16);
                make.top.equalTo(previousView.mas_bottom).offset(previousView == titleLabel ? 12 : 0);
                make.height.mas_equalTo(46);
            }];
            [divider mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(rowButton);
                make.right.equalTo(container).offset(-16);
                make.top.equalTo(rowButton.mas_bottom);
                make.height.mas_equalTo(1);
            }];
            previousView = divider;
        }

        [container mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.equalTo(self.sectionsStackView);
            make.bottom.equalTo(previousView).offset(8);
        }];
    }
}

// MARK: - Scroll

- (void)scrollToSectionTitle:(NSString *)title {
    UIView *anchorView = self.sectionAnchorViews[title];
    if (!anchorView) { return; }
    [self layoutIfNeeded];
    CGRect rect = [self.scrollView convertRect:anchorView.frame fromView:self.sectionsStackView];
    CGFloat offsetY = MAX(0, CGRectGetMinY(rect) - 12.0);
    [self.scrollView setContentOffset:CGPointMake(0, offsetY) animated:YES];
}

// MARK: - Actions

- (void)tl_backTapped {
    [self endEditing:YES];
    if (self.onBackTapped) { self.onBackTapped(); }
}

- (void)tl_relocateTapped {
    [self endEditing:YES];
    if (self.onRelocateTapped) { self.onRelocateTapped(); }
}

- (void)tl_cityButtonTapped:(UIButton *)sender {
    NSString *cityName = [sender titleForState:UIControlStateNormal];
    if (cityName.length > 0 && self.onCitySelected) { self.onCitySelected(cityName); }
}

- (void)tl_searchChanged:(UITextField *)textField {
    if (self.onSearchTextChanged) { self.onSearchTextChanged(textField.text ?: @""); }
}

// MARK: - Helpers

- (UIView *)tl_cardView {
    UIView *card = [[UIView alloc] init];
    card.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.86];
    card.layer.cornerRadius = 22.0;
    card.layer.shadowColor = [UIColor colorWithRed:0.37 green:0.76 blue:0.90 alpha:0.18].CGColor;
    card.layer.shadowOpacity = 1.0;
    card.layer.shadowRadius = 18.0;
    card.layer.shadowOffset = CGSizeMake(0, 8);
    return card;
}

- (UIView *)tl_innerPanelView {
    UIView *panel = [[UIView alloc] init];
    panel.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.72];
    panel.layer.cornerRadius = 18.0;
    panel.layer.borderWidth = 1.0;
    panel.layer.borderColor = [UIColor colorWithRed:0.92 green:0.95 blue:0.97 alpha:1.0].CGColor;
    return panel;
}

- (UILabel *)tl_sectionTitleLabelWithText:(NSString *)text {
    UILabel *label = [[UILabel alloc] init];
    label.text = text;
    label.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
    label.textColor = [UIColor colorWithRed:0.48 green:0.49 blue:0.54 alpha:1.0];
    return label;
}

- (UILabel *)tl_groupHeaderLabelWithText:(NSString *)text {
    UILabel *label = [[UILabel alloc] init];
    label.text = text;
    label.font = [UIFont systemFontOfSize:17 weight:UIFontWeightBold];
    label.textColor = [UIColor colorWithRed:0.40 green:0.43 blue:0.48 alpha:1.0];
    return label;
}

@end
