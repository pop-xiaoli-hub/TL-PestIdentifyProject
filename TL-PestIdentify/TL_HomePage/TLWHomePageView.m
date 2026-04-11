//
//  TLWHomePageView.m
//  TL-PestIdentify
//
//  Created by xiaoli pop on 2026/3/9.
//

#import "TLWHomePageView.h"
#import <Masonry.h>

@interface TLWHomePageView ()

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UITableView* locationTableView;
@property (nonatomic, strong) UILabel* helloLabel;
@property (nonatomic, strong) UILabel* userNameLabel;
@property (nonatomic, strong) UILabel* calendarLabel;
@property (nonatomic, strong) UILabel* temperatureDigitalLabel;
@property (nonatomic, strong) UILabel* temperatureSuffixLabel;
@property (nonatomic, strong) UIImageView* userAvatarImageView;
@property (nonatomic, strong) UIButton *userVersionButton;
@property (nonatomic, strong) UIImageView* weatherCardImageView;
@property (nonatomic, strong) UIImageView* bottomOfUserNameImageView;
@property (nonatomic, strong) UIImageView* bambooImageView;
@property (nonatomic, strong) UIView* headerContainer;

// 定位行
@property (nonatomic, strong) UIImageView *locationIconView;
@property (nonatomic, strong) UILabel *locationNameLabel;
@property (nonatomic, strong) UILabel *locationArrowLabel;

// 底部定位 Banner
@property (nonatomic, strong) UIView *locationBannerView;

@end

@implementation TLWHomePageView

- (NSString *)tl_currentLunarDateText {
  NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierChinese];
  NSDateComponents *components = [calendar components:(NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:[NSDate date]];

  NSArray<NSString *> *monthTexts = @[@"正月", @"二月", @"三月", @"四月", @"五月", @"六月",
                                      @"七月", @"八月", @"九月", @"十月", @"冬月", @"腊月"];
  NSArray<NSString *> *dayTexts = @[@"初一", @"初二", @"初三", @"初四", @"初五", @"初六", @"初七", @"初八", @"初九", @"初十",
                                    @"十一", @"十二", @"十三", @"十四", @"十五", @"十六", @"十七", @"十八", @"十九", @"二十",
                                    @"廿一", @"廿二", @"廿三", @"廿四", @"廿五", @"廿六", @"廿七", @"廿八", @"廿九", @"三十"];

  NSInteger monthIndex = MAX(1, MIN(components.month, monthTexts.count)) - 1;
  NSInteger dayIndex = MAX(1, MIN(components.day, dayTexts.count)) - 1;
  NSString *monthText = monthTexts[monthIndex];
  NSString *dayText = dayTexts[dayIndex];

  if (components.isLeapMonth) {
    monthText = [@"闰" stringByAppendingString:monthText];
  }

  return [NSString stringWithFormat:@"农历%@%@", monthText, dayText];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupSubviews];
    }
    return self;
}

- (void)setupSubviews {
  [self tl_setMainTableView];
  [self tl_setSubViewsOfHeaderContainer];
  [self tl_setupLocationBanner];
}

- (void)tl_setSubViewsOfHeaderContainer {
  [self tl_setHelloLabel];
  [self tl_setUserNameLabel];
  [self tl_setBottomNameImageView];
  [self tl_setLocationRow];
  [self tl_setUserVersionImageView];
  [self tl_setUserAvatorImageView];
  [self tl_setTemperatureLabels];
  [self tl_setWeatherCardImageView];
  [self tl_setCalendarLabel];
  [self tl_setBambooImageView];
}

#pragma mark - 定位行

- (void)tl_setLocationRow {
  UIImageView *iconView = self.locationIconView;
  iconView.image = [[UIImage imageNamed:@"iconLocation"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
  [self.headerContainer addSubview:iconView];

  UILabel *nameLabel = self.locationNameLabel;
  nameLabel.text = @"未定位";
  [self.headerContainer addSubview:nameLabel];

  UILabel *arrowLabel = self.locationArrowLabel;
  arrowLabel.text = @"▼";
  [self.headerContainer addSubview:arrowLabel];

  [iconView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.equalTo(self.headerContainer).offset(30);
    make.top.equalTo(self.helloLabel.mas_bottom).offset(5);
    make.width.height.mas_equalTo(16);
  }];

  [nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.equalTo(iconView.mas_right).offset(4);
    make.centerY.equalTo(iconView);
  }];

  [arrowLabel mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.equalTo(nameLabel.mas_right).offset(3);
    make.centerY.equalTo(iconView);
  }];
}

- (void)configureWithLocationName:(nullable NSString *)locationName {
  self.locationNameLabel.text = locationName.length > 0 ? locationName : @"未定位";
}

#pragma mark - 底部定位 Banner

- (void)tl_setupLocationBanner {
  UIView *banner = [[UIView alloc] init];
  banner.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.67];
  banner.layer.cornerRadius = 20.0;
  banner.layer.masksToBounds = YES;
  banner.hidden = YES;
  [self addSubview:banner];
  self.locationBannerView = banner;

  [banner mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.equalTo(self).offset(16);
    make.right.equalTo(self).offset(-16);
    make.bottom.equalTo(self).offset(-100);
    make.height.mas_equalTo(80);
  }];

  // 标题
  UILabel *titleLabel = [[UILabel alloc] init];
  titleLabel.text = @"开启定位服务";
  titleLabel.textColor = [UIColor whiteColor];
  titleLabel.font = [UIFont systemFontOfSize:16.0 weight:UIFontWeightHeavy];
  [banner addSubview:titleLabel];

  // 副标题
  UILabel *subtitleLabel = [[UILabel alloc] init];
  subtitleLabel.text = @"开启后，将为您精准提供病害预警信息";
  subtitleLabel.textColor = [UIColor whiteColor];
  subtitleLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightMedium];
  [banner addSubview:subtitleLabel];

  // 开启定位按钮
  UIButton *openButton = [UIButton buttonWithType:UIButtonTypeCustom];
  openButton.backgroundColor = [UIColor colorWithRed:1.0 green:0.71 blue:0.14 alpha:1.0]; // #FFB524
  openButton.layer.cornerRadius = 13.0;
  openButton.layer.masksToBounds = YES;
  openButton.titleLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightBold];
  [openButton setTitle:@"开启定位" forState:UIControlStateNormal];
  [openButton setTitleColor:[UIColor colorWithRed:0.29 green:0.16 blue:0.0 alpha:1.0] forState:UIControlStateNormal]; // #4B2800
  [openButton addTarget:self action:@selector(tl_didTapOpenLocation) forControlEvents:UIControlEventTouchUpInside];
  [banner addSubview:openButton];

  // 关闭按钮
  UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
  if (@available(iOS 13.0, *)) {
    UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:18.0 weight:UIImageSymbolWeightMedium];
    UIImage *xImage = [[UIImage systemImageNamed:@"xmark.circle.fill" withConfiguration:config] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [closeButton setImage:xImage forState:UIControlStateNormal];
    closeButton.tintColor = [UIColor colorWithWhite:0.6 alpha:1.0];
  } else {
    [closeButton setTitle:@"✕" forState:UIControlStateNormal];
    closeButton.titleLabel.font = [UIFont systemFontOfSize:18.0];
    [closeButton setTitleColor:[UIColor colorWithWhite:0.6 alpha:1.0] forState:UIControlStateNormal];
  }
  [closeButton addTarget:self action:@selector(tl_didTapCloseBanner) forControlEvents:UIControlEventTouchUpInside];
  [banner addSubview:closeButton];

  // 布局
  [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.equalTo(banner).offset(20);
    make.top.equalTo(banner).offset(14);
  }];

  [subtitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.equalTo(titleLabel);
    make.top.equalTo(titleLabel.mas_bottom).offset(6);
    make.right.lessThanOrEqualTo(openButton.mas_left).offset(-8);
  }];

  [closeButton mas_makeConstraints:^(MASConstraintMaker *make) {
    make.right.equalTo(banner).offset(-12);
    make.top.equalTo(banner).offset(12);
    make.width.height.mas_equalTo(28);
  }];

  [openButton mas_makeConstraints:^(MASConstraintMaker *make) {
    make.right.equalTo(closeButton.mas_left).offset(-8);
    make.centerY.equalTo(banner);
    make.width.mas_equalTo(72);
    make.height.mas_equalTo(33);
  }];
}

- (void)showLocationBanner {
  self.locationBannerView.hidden = NO;
}

- (void)hideLocationBanner {
  self.locationBannerView.hidden = YES;
}

- (void)tl_didTapOpenLocation {
  if (self.onOpenLocationTapped) {
    self.onOpenLocationTapped();
  }
}

- (void)tl_didTapCloseBanner {
  [self hideLocationBanner];
  if (self.onCloseLocationBanner) {
    self.onCloseLocationBanner();
  }
}

#pragma mark - 原有 Header 组件

- (void)tl_setBambooImageView {
  UIImageView* imageView = self.bambooImageView;
  imageView.image = [[UIImage imageNamed:@"hp_bamboo.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
  [self.headerContainer addSubview:imageView];
  [imageView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.right.equalTo(self.headerContainer.mas_right).offset(-15);
    make.bottom.equalTo(self.headerContainer.mas_bottom).offset(0);
  }];
}

- (void)tl_setCalendarLabel {
  UILabel* label = self.calendarLabel;
  label.text = [self tl_currentLunarDateText];
  [self.headerContainer addSubview:label];
  [label mas_makeConstraints:^(MASConstraintMaker *make) {
      make.left.equalTo(self.temperatureDigitalLabel.mas_left).offset(5);
      make.top.equalTo(self.temperatureDigitalLabel.mas_bottom).offset(-10);
  }];
}

- (void)tl_setTemperatureLabels {
  UILabel* numberLabel = self.temperatureDigitalLabel;
  UILabel* textLabel = self.temperatureSuffixLabel;
  [self.headerContainer addSubview:numberLabel];
  [self.headerContainer addSubview:textLabel];
  numberLabel.text = @"18";
  textLabel.text = @"℃/晴";
  [numberLabel mas_makeConstraints:^(MASConstraintMaker *make) {
      make.left.equalTo(self.headerContainer).offset(30);
      make.top.equalTo(self.locationIconView.mas_bottom).offset(20);
  }];
  [textLabel mas_makeConstraints:^(MASConstraintMaker *make) {
      make.left.equalTo(numberLabel.mas_right);
      make.bottom.equalTo(numberLabel.mas_bottom).offset(-15);
  }];
}

- (void)tl_setWeatherCardImageView {
  UIImageView* imageView = self.weatherCardImageView;
  imageView.image = [[UIImage imageNamed:@"hp_cloud.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
  [self.headerContainer addSubview:imageView];
  [imageView mas_makeConstraints:^(MASConstraintMaker *make) {
      make.left.equalTo(self.temperatureSuffixLabel.mas_right).offset(-60);
      make.top.equalTo(self.headerContainer).offset(95);
    make.height.mas_equalTo(80);
    make.width.mas_equalTo(100);
  }];
}

- (void)tl_setBottomNameImageView {
  UIImageView* imageView = self.bottomOfUserNameImageView;
  imageView.image = [[UIImage imageNamed:@"hp_smile.png"]imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
  [self.headerContainer addSubview:imageView];
  [imageView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.centerX.equalTo(self.userNameLabel.mas_centerX);
    make.top.equalTo(self.userNameLabel.mas_bottom);
  }];
}

- (void)tl_setUserAvatorImageView {
  UIImageView* imageView = self.userAvatarImageView;
  imageView.layer.cornerRadius = 35;
  imageView.clipsToBounds = YES;
  [self.headerContainer addSubview:imageView];
  [imageView mas_makeConstraints:^(MASConstraintMaker *make) {
      make.right.equalTo(self.headerContainer).offset(-20);
      make.top.equalTo(self.headerContainer).offset(35);
      make.height.mas_equalTo(70);
      make.width.mas_equalTo(70);
  }];
}


- (void)tl_setUserVersionImageView {
  UIButton *button = self.userVersionButton;
  [self configureElderModeEnabled:NO];
  [self.headerContainer addSubview:button];
  [button mas_makeConstraints:^(MASConstraintMaker *make) {
      make.right.equalTo(self.headerContainer.mas_right).offset(-100);
      make.top.equalTo(self.headerContainer).offset(45);
      make.height.mas_equalTo(51);
      make.width.mas_equalTo(48);
  }];
}


- (void)tl_setUserNameLabel {
  UILabel* label = self.userNameLabel;
  label.backgroundColor = [UIColor clearColor];
  label.textColor = [UIColor whiteColor];
  label.font = [UIFont systemFontOfSize:37 weight:UIFontWeightHeavy];
  UIView* headerContainer = self.headerContainer;
  [headerContainer addSubview:label];
  [label mas_makeConstraints:^(MASConstraintMaker *make) {
      make.left.equalTo(self.helloLabel.mas_right);
      make.height.mas_equalTo(40);
      make.top.equalTo(self.helloLabel);
  }];
}

- (void)configureWithUserName:(NSString* )name {
  self.userNameLabel.text = [name copy];
}

- (void)configureElderModeEnabled:(BOOL)enabled {
  NSString *imageName = enabled ? @"oldMode" : @"hp_version.png";
  UIImage *image = [[UIImage imageNamed:imageName] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
  [self.userVersionButton setImage:image forState:UIControlStateNormal];
  [self.userVersionButton setImage:image forState:UIControlStateHighlighted];
  self.userVersionButton.selected = enabled;
}

- (NSString *)tl_weatherImageNameForIconCode:(NSString *)iconCode {
  NSInteger code = iconCode.integerValue;
  if ((code >= 100 && code <= 104) || code == 150 || code == 151 || code == 152 || code == 153) {
    return @"hp_cloud.png";
  }
  if ((code >= 300 && code <= 313) || (code >= 399 && code <= 404)) {
    return @"hp_cloud.png";
  }
  return @"hp_cloud.png";
}

- (void)configureWithTemperature:(nullable NSString *)temperature
                     weatherText:(nullable NSString *)weatherText
                        iconCode:(nullable NSString *)iconCode {
  NSString *safeTemperature = temperature.length > 0 ? temperature : @"--";
  NSString *safeWeatherText = weatherText.length > 0 ? weatherText : @"未知";
  self.temperatureDigitalLabel.text = safeTemperature;
  self.temperatureSuffixLabel.text = [NSString stringWithFormat:@"℃/%@", safeWeatherText];
  NSString *imageName = [self tl_weatherImageNameForIconCode:iconCode ?: @""];
  self.weatherCardImageView.image = [[UIImage imageNamed:imageName] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
}

- (void)tl_setHelloLabel {
  UILabel* label = self.helloLabel;
  label.text = @"你好，";
  label.backgroundColor = [UIColor clearColor];
  label.textColor = [UIColor whiteColor];
  label.font = [UIFont systemFontOfSize:35 weight:UIFontWeightLight];
  UIView* headerContainer = self.headerContainer;
  [headerContainer addSubview:label];
  [label mas_makeConstraints:^(MASConstraintMaker *make) {
      make.left.equalTo(headerContainer).offset(30);
      make.height.mas_equalTo(40);
      make.top.equalTo(headerContainer).offset(20);
  }];
}

- (void)tl_setMainTableView {
  self.backgroundColor = [UIColor clearColor];
  UITableView *tableView = self.tableView;
  tableView.backgroundColor = [UIColor clearColor];
  tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
  tableView.showsVerticalScrollIndicator = NO;
  [self addSubview:tableView];
  [tableView mas_makeConstraints:^(MASConstraintMaker *make) {
      make.edges.equalTo(self);
  }];

  UIView* headerContainer = self.headerContainer;
  headerContainer.backgroundColor = [UIColor clearColor];

  UIView *headerCard = [[UIView alloc] init];
  headerCard.translatesAutoresizingMaskIntoConstraints = NO;
  headerCard.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.18];
  headerCard.layer.cornerRadius = 16.0;
  headerCard.layer.masksToBounds = YES;

  [headerContainer addSubview:headerCard];
  [headerCard mas_makeConstraints:^(MASConstraintMaker *make) {
      make.left.equalTo(headerContainer).offset(16.0);
      make.right.equalTo(headerContainer).offset(-16.0);
      make.bottom.equalTo(headerContainer).offset(-5);
      make.top.equalTo(headerContainer).offset(0);
  }];

  tableView.tableHeaderView = headerContainer;
}

#pragma mark - 懒加载实现

- (UIImageView *)locationIconView {
  if (!_locationIconView) {
    _locationIconView = [[UIImageView alloc] init];
    _locationIconView.contentMode = UIViewContentModeScaleAspectFit;
  }
  return _locationIconView;
}

- (UILabel *)locationNameLabel {
  if (!_locationNameLabel) {
    _locationNameLabel = [[UILabel alloc] init];
    _locationNameLabel.backgroundColor = [UIColor clearColor];
    _locationNameLabel.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.85];
    _locationNameLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
  }
  return _locationNameLabel;
}

- (UILabel *)locationArrowLabel {
  if (!_locationArrowLabel) {
    _locationArrowLabel = [[UILabel alloc] init];
    _locationArrowLabel.backgroundColor = [UIColor clearColor];
    _locationArrowLabel.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.7];
    _locationArrowLabel.font = [UIFont systemFontOfSize:10];
  }
  return _locationArrowLabel;
}

- (UITableView *)locationTableView {
  if (!_locationTableView) {
    _locationTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    _locationTableView.backgroundColor = [UIColor clearColor];
    _locationTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _locationTableView.scrollEnabled = NO;
  }
  return _locationTableView;
}

- (UILabel *)calendarLabel {
  if (!_calendarLabel) {
    _calendarLabel = [[UILabel alloc] init];
    _calendarLabel.backgroundColor = [UIColor clearColor];
    _calendarLabel.textColor = [UIColor whiteColor];
    _calendarLabel.font = [UIFont systemFontOfSize:25 weight:UIFontWeightBold];
  }
  return _calendarLabel;
}

- (UILabel *)temperatureDigitalLabel {
  if (!_temperatureDigitalLabel) {
    _temperatureDigitalLabel = [[UILabel alloc] init];
    _temperatureDigitalLabel.backgroundColor = [UIColor clearColor];
    _temperatureDigitalLabel.textColor = [UIColor whiteColor];
    _temperatureDigitalLabel.font = [UIFont systemFontOfSize:70 weight:UIFontWeightHeavy];
  }
  return _temperatureDigitalLabel;
}

- (UILabel *)temperatureSuffixLabel {
  if (!_temperatureSuffixLabel) {
    _temperatureSuffixLabel = [[UILabel alloc] init];
    _temperatureSuffixLabel.backgroundColor = [UIColor clearColor];
    _temperatureSuffixLabel.textColor = [UIColor whiteColor];
    _temperatureSuffixLabel.font = [UIFont systemFontOfSize:30 weight:UIFontWeightBold];
  }
  return _temperatureSuffixLabel;
}

- (UIImageView *)userAvatarImageView {
  if (!_userAvatarImageView) {
    _userAvatarImageView = [[UIImageView alloc] init];
    _userAvatarImageView.contentMode = UIViewContentModeScaleAspectFill;
    _userAvatarImageView.clipsToBounds = YES;
  }
  return _userAvatarImageView;
}

- (UIButton *)userVersionButton {
  if (!_userVersionButton) {
    _userVersionButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _userVersionButton.adjustsImageWhenHighlighted = NO;
    _userVersionButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
  }
  return _userVersionButton;
}

- (UIImageView *)weatherCardImageView {
  if (!_weatherCardImageView) {
    _weatherCardImageView = [[UIImageView alloc] init];
    _weatherCardImageView.contentMode = UIViewContentModeScaleAspectFit;
  }
  return _weatherCardImageView;
}

- (UIImageView *)bambooImageView {
  if (!_bambooImageView) {
    _bambooImageView = [[UIImageView alloc] init];
    _bambooImageView.clipsToBounds = YES;
    _bambooImageView.contentMode = UIViewContentModeScaleAspectFill;
  }
  return _bambooImageView;
}

- (UIImageView *)bottomOfUserNameImageView {
  if (!_bottomOfUserNameImageView) {
    _bottomOfUserNameImageView = [[UIImageView alloc] init];
    _bottomOfUserNameImageView.contentMode = UIViewContentModeScaleAspectFit;
  }
  return _bottomOfUserNameImageView;
}

- (UILabel *)userNameLabel {
  if (!_userNameLabel) {
    _userNameLabel = [[UILabel alloc] init];
    _userNameLabel.backgroundColor = [UIColor clearColor];
  }
  return _userNameLabel;
}

- (UILabel*)helloLabel {
  if (!_helloLabel) {
    _helloLabel = [[UILabel alloc] init];
    _helloLabel.backgroundColor = [UIColor clearColor];
  }
  return _helloLabel;
}

- (UIView *)headerContainer {
  if (!_headerContainer) {
    _headerContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, UIScreen.mainScreen.bounds.size.width, 240.0)];
    _headerContainer.backgroundColor = [UIColor clearColor];
  }
  return _headerContainer;
}

- (UITableView *)tableView {
  if (!_tableView) {
    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
  }
  return _tableView;
}

@end
