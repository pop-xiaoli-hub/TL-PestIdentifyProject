//
//  TLWLocationSearchController.m
//  TL-PestIdentify
//

#import "TLWLocationSearchController.h"
#import "Models/TLWLocationCityModel.h"
#import "TLWLocationManager.h"
#import <MapKit/MapKit.h>
#import <Masonry/Masonry.h>

// MARK: - Search result model

@interface TLWSearchResult : NSObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *distance;
@property (nonatomic, copy) NSString *address;
@property (nonatomic, strong, nullable) MKMapItem *mapItem;
@end
@implementation TLWSearchResult
@end

// MARK: - Cell

static NSString *const kCellID = @"TLWLocationSearchCell";

@interface TLWLocationSearchCell : UITableViewCell
- (void)configureWithResult:(TLWSearchResult *)result keyword:(NSString *)keyword;
@end

@implementation TLWLocationSearchCell {
    UIImageView *_pinIcon;
    UILabel *_nameLabel;
    UILabel *_detailLabel;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.selectionStyle = UITableViewCellSelectionStyleDefault;

        UIView *selectedBackground = [[UIView alloc] init];
        selectedBackground.backgroundColor = [UIColor colorWithRed:0.33 green:0.73 blue:0.95 alpha:0.12];
        self.selectedBackgroundView = selectedBackground;

        _pinIcon = [[UIImageView alloc] init];
        _pinIcon.contentMode = UIViewContentModeScaleAspectFit;
        _pinIcon.image = [[UIImage imageNamed:@"locationSearch_icon"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        [self.contentView addSubview:_pinIcon];

        _nameLabel = [[UILabel alloc] init];
        [self.contentView addSubview:_nameLabel];

        _detailLabel = [[UILabel alloc] init];
        _detailLabel.font = [UIFont systemFontOfSize:12];
        _detailLabel.textColor = [UIColor colorWithRed:0.55 green:0.58 blue:0.63 alpha:1.0];
        [self.contentView addSubview:_detailLabel];

        [_pinIcon mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.contentView).offset(16);
            make.centerY.equalTo(self.contentView);
            make.width.height.mas_equalTo(18);
        }];
        [_nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(_pinIcon.mas_right).offset(12);
            make.right.equalTo(self.contentView).offset(-16);
            make.top.equalTo(self.contentView).offset(12);
        }];
        [_detailLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(_nameLabel);
            make.top.equalTo(_nameLabel.mas_bottom).offset(4);
        }];
    }
    return self;
}

- (void)configureWithResult:(TLWSearchResult *)result keyword:(NSString *)keyword {
    UIColor *orange = [UIColor colorWithRed:0.90 green:0.56 blue:0.10 alpha:1.0];
    UIColor *dark   = [UIColor colorWithRed:0.15 green:0.16 blue:0.19 alpha:1.0];

    NSMutableAttributedString *attr = [[NSMutableAttributedString alloc] initWithString:result.name attributes:@{
        NSFontAttributeName: [UIFont systemFontOfSize:16 weight:UIFontWeightBold],
        NSForegroundColorAttributeName: dark
    }];
    if (keyword.length > 0) {
        NSString *lower = result.name.lowercaseString;
        NSString *kw    = keyword.lowercaseString;
        NSRange search  = NSMakeRange(0, lower.length);
        while (search.location < lower.length) {
            NSRange hit = [lower rangeOfString:kw options:0 range:search];
            if (hit.location == NSNotFound) { break; }
            [attr addAttribute:NSForegroundColorAttributeName value:orange range:hit];
            NSUInteger next = hit.location + hit.length;
            if (next >= lower.length) { break; }
            search = NSMakeRange(next, lower.length - next);
        }
    }
    _nameLabel.attributedText = attr;
    if (result.distance.length > 0 && result.address.length > 0) {
        _detailLabel.text = [NSString stringWithFormat:@"%@   %@", result.distance, result.address];
    } else if (result.address.length > 0) {
        _detailLabel.text = result.address;
    } else {
        _detailLabel.text = result.distance;
    }
}

@end

// MARK: - TLWLocationSearchController

@interface TLWLocationSearchController () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIImageView *backgroundImageView;
@property (nonatomic, strong) UIView *topBarView;
@property (nonatomic, strong) UIButton *backButton;
@property (nonatomic, strong) UIView *searchContainerView;
@property (nonatomic, strong) UITextField *searchField;
@property (nonatomic, strong) UIView *resultsCard;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UILabel *emptyLabel;

@property (nonatomic, copy) NSArray<TLWSearchResult *> *results;
@property (nonatomic, copy) NSString *currentKeyword;
@property (nonatomic, strong, nullable) MKLocalSearch *searchTask;
@property (nonatomic, strong) UITapGestureRecognizer *dismissKeyboardTapGesture;

@end

@implementation TLWLocationSearchController

- (instancetype)init {
    self = [super init];
    if (self) {
        self.hideNavBar = YES;
        self.hidesBottomBarWhenPushed = YES;
        _results = @[];
        _currentKeyword = @"";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self tl_setupBackground];
    [self tl_setupTopBar];
    [self tl_setupResultsCard];
    [self tl_setupDismissKeyboardGesture];
    [self tl_setupSwipeBack];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.searchField becomeFirstResponder];
}

- (void)tl_setupBackground {
    self.backgroundImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"hp_backView"]];
    self.backgroundImageView.contentMode = UIViewContentModeScaleAspectFill;
    [self.view addSubview:self.backgroundImageView];

    UIView *overlay = [[UIView alloc] init];
    overlay.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.18];
    [self.view addSubview:overlay];

    [self.backgroundImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    [overlay mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
}

- (void)tl_setupTopBar {
    self.topBarView = [[UIView alloc] init];
    [self.view addSubview:self.topBarView];

    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = @"定位";
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.font = [UIFont systemFontOfSize:20 weight:UIFontWeightSemibold];
    [self.topBarView addSubview:titleLabel];

    self.backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.backButton.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.22];
    self.backButton.layer.cornerRadius = 22.0;
    self.backButton.layer.borderWidth = 1.0;
    self.backButton.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.22].CGColor;
    if (@available(iOS 13.0, *)) {
        UIImageSymbolConfiguration *cfg = [UIImageSymbolConfiguration configurationWithPointSize:18 weight:UIImageSymbolWeightSemibold];
        UIImage *img = [[UIImage systemImageNamed:@"chevron.left" withConfiguration:cfg] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [self.backButton setImage:img forState:UIControlStateNormal];
        self.backButton.tintColor = [UIColor whiteColor];
    } else {
        [self.backButton setTitle:@"<" forState:UIControlStateNormal];
        [self.backButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    }
    [self.backButton addTarget:self action:@selector(tl_backTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.topBarView addSubview:self.backButton];

    self.searchContainerView = [[UIView alloc] init];
    self.searchContainerView.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.92];
    self.searchContainerView.layer.cornerRadius = 22.0;
    self.searchContainerView.layer.borderWidth = 1.0;
    self.searchContainerView.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.3].CGColor;
    [self.topBarView addSubview:self.searchContainerView];

    self.searchField = [[UITextField alloc] init];
    self.searchField.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    self.searchField.textColor = [UIColor colorWithRed:0.22 green:0.24 blue:0.28 alpha:1.0];
    self.searchField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"城市/区县/村镇等地点"
                                                                              attributes:@{
        NSForegroundColorAttributeName: [UIColor colorWithRed:0.70 green:0.75 blue:0.78 alpha:1.0],
        NSFontAttributeName: [UIFont systemFontOfSize:15 weight:UIFontWeightMedium]
    }];
    self.searchField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.searchField.returnKeyType = UIReturnKeySearch;
    self.searchField.delegate = self;
    [self.searchField addTarget:self action:@selector(tl_searchTextChanged:) forControlEvents:UIControlEventEditingChanged];
    [self.searchContainerView addSubview:self.searchField];

    [self.topBarView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.view);
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
    [self.topBarView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.searchContainerView.mas_bottom).offset(14);
    }];
}

- (void)tl_setupResultsCard {
    self.resultsCard = [[UIView alloc] init];
    self.resultsCard.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.96];
    self.resultsCard.layer.cornerRadius = 22.0;
    self.resultsCard.layer.shadowColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.08].CGColor;
    self.resultsCard.layer.shadowOpacity = 1.0;
    self.resultsCard.layer.shadowRadius = 16.0;
    self.resultsCard.layer.shadowOffset = CGSizeMake(0, 6);
    [self.view addSubview:self.resultsCard];

    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 46, 0, 0);
    self.tableView.separatorColor = [UIColor colorWithRed:0.88 green:0.90 blue:0.93 alpha:1.0];
    self.tableView.rowHeight = 62.0;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.layer.cornerRadius = 22.0;
    self.tableView.layer.masksToBounds = YES;
    self.tableView.showsVerticalScrollIndicator = NO;
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    [self.tableView registerClass:[TLWLocationSearchCell class] forCellReuseIdentifier:kCellID];
    [self.resultsCard addSubview:self.tableView];

    self.emptyLabel = [[UILabel alloc] init];
    self.emptyLabel.text = @"输入关键词搜索地点";
    self.emptyLabel.textAlignment = NSTextAlignmentCenter;
    self.emptyLabel.font = [UIFont systemFontOfSize:15];
    self.emptyLabel.textColor = [UIColor colorWithRed:0.70 green:0.75 blue:0.78 alpha:1.0];
    [self.resultsCard addSubview:self.emptyLabel];

    [self.resultsCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.topBarView.mas_bottom).offset(8);
        make.left.equalTo(self.view).offset(16);
        make.right.equalTo(self.view).offset(-16);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-16);
    }];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.resultsCard);
    }];
    [self.emptyLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.resultsCard);
    }];
}

- (void)tl_setupSwipeBack {
    self.navigationController.interactivePopGestureRecognizer.delegate = nil;
}

- (void)tl_setupDismissKeyboardGesture {
    self.dismissKeyboardTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tl_dismissKeyboard)];
    self.dismissKeyboardTapGesture.cancelsTouchesInView = NO;
    self.dismissKeyboardTapGesture.delegate = self;
    [self.view addGestureRecognizer:self.dismissKeyboardTapGesture];
}

- (void)tl_dismissKeyboard {
    [self.view endEditing:YES];
}

// MARK: - Search logic

- (void)tl_searchTextChanged:(UITextField *)tf {
    NSString *raw = tf.text ?: @"";
    NSString *keyword = [raw stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    self.currentKeyword = keyword;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(tl_performSearch) object:nil];
    [self.searchTask cancel];
    self.searchTask = nil;

    if (keyword.length == 0) {
        self.results = @[];
        self.emptyLabel.text = @"输入关键词搜索地点";
        self.emptyLabel.hidden = NO;
        [self.tableView reloadData];
        return;
    }

    self.emptyLabel.text = @"正在搜索...";
    self.emptyLabel.hidden = NO;
    [self.tableView reloadData];
    [self performSelector:@selector(tl_performSearch) withObject:nil afterDelay:0.25];
}

- (void)tl_performSearch {
    NSString *keyword = [self.currentKeyword stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (keyword.length == 0) {
        return;
    }

    MKLocalSearchRequest *request = [[MKLocalSearchRequest alloc] init];
    request.naturalLanguageQuery = keyword;
    if (@available(iOS 13.0, *)) {
        request.resultTypes = MKLocalSearchResultTypeAddress | MKLocalSearchResultTypePointOfInterest;
    }

    TLWLocationManager *locationManager = [TLWLocationManager shared];
    if (locationManager.hasLocation) {
        CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(locationManager.latitude, locationManager.longitude);
        request.region = MKCoordinateRegionMakeWithDistance(coordinate, 50000, 50000);
    }

    MKLocalSearch *search = [[MKLocalSearch alloc] initWithRequest:request];
    self.searchTask = search;

    __weak typeof(self) weakSelf = self;
    [search startWithCompletionHandler:^(MKLocalSearchResponse * _Nullable response, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf || strongSelf.searchTask != search) {
                return;
            }
            strongSelf.searchTask = nil;

            NSString *latestKeyword = [strongSelf.currentKeyword stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            if (latestKeyword.length == 0 || ![latestKeyword isEqualToString:keyword]) {
                return;
            }

            if (error) {
                strongSelf.results = @[];
                strongSelf.emptyLabel.text = @"搜索失败，请稍后重试";
                strongSelf.emptyLabel.hidden = NO;
                [strongSelf.tableView reloadData];
                return;
            }

            NSMutableArray<TLWSearchResult *> *found = [NSMutableArray array];
            CLLocation *currentLocation = nil;
            if (locationManager.hasLocation) {
                currentLocation = [[CLLocation alloc] initWithLatitude:locationManager.latitude longitude:locationManager.longitude];
            }

            for (MKMapItem *item in response.mapItems) {
                TLWSearchResult *result = [[TLWSearchResult alloc] init];
                result.mapItem = item;
                result.name = item.name.length > 0 ? item.name : [strongSelf tl_displayAddressForMapItem:item];
                result.address = [strongSelf tl_displayAddressForMapItem:item];
                result.distance = [strongSelf tl_distanceTextForMapItem:item currentLocation:currentLocation];
                [found addObject:result];
            }

            strongSelf.results = found;
            strongSelf.emptyLabel.text = found.count > 0 ? @"" : @"未找到相关地点";
            strongSelf.emptyLabel.hidden = (found.count > 0);
            [strongSelf.tableView reloadData];
        });
    }];
}

// MARK: - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (NSInteger)self.results.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TLWLocationSearchCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellID forIndexPath:indexPath];
    [cell configureWithResult:self.results[indexPath.row] keyword:self.currentKeyword];
    return cell;
}

// MARK: - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    TLWSearchResult *result = self.results[indexPath.row];
    NSString *cityName = result.name.length > 0 ? result.name : result.address;
    if (self.onCitySelected) { self.onCitySelected(cityName); }
}

// MARK: - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if (gestureRecognizer != self.dismissKeyboardTapGesture) {
        return YES;
    }

    UIView *touchedView = touch.view;
    if ([touchedView isDescendantOfView:self.searchContainerView] ||
        [touchedView isDescendantOfView:self.tableView] ||
        [touchedView isDescendantOfView:self.backButton]) {
        return NO;
    }
    return YES;
}

// MARK: - Actions

- (void)tl_backTapped {
    [self.view endEditing:YES];
    [self.navigationController popViewControllerAnimated:YES];
}

- (NSString *)tl_displayAddressForMapItem:(MKMapItem *)item {
    NSMutableArray<NSString *> *parts = [NSMutableArray array];
    MKPlacemark *placemark = item.placemark;
    NSString *province = placemark.administrativeArea;
    NSString *city = placemark.locality ?: placemark.subAdministrativeArea;
    NSString *district = placemark.subLocality;
    NSString *street = placemark.thoroughfare;
    NSString *subStreet = placemark.subThoroughfare;

    for (NSString *part in @[province ?: @"", city ?: @"", district ?: @"", street ?: @"", subStreet ?: @""]) {
        if (part.length > 0) {
            if (parts.count == 0 || ![parts.lastObject isEqualToString:part]) {
                [parts addObject:part];
            }
        }
    }

    if (parts.count == 0 && placemark.title.length > 0) {
        return placemark.title;
    }
    return [parts componentsJoinedByString:@""];
}

- (NSString *)tl_distanceTextForMapItem:(MKMapItem *)item currentLocation:(nullable CLLocation *)currentLocation {
    if (!currentLocation) {
        return @"";
    }

    CLLocation *itemLocation = item.placemark.location;
    if (!itemLocation) {
        return @"";
    }

    CLLocationDistance distance = [currentLocation distanceFromLocation:itemLocation];
    if (distance < 1000.0) {
        return [NSString stringWithFormat:@"%.0f米", distance];
    }
    return [NSString stringWithFormat:@"%.1f公里", distance / 1000.0];
}

@end
