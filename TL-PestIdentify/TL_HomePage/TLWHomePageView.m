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
@property (nonatomic, strong) UIImageView* userVersionImageView;
@property (nonatomic, strong) UIImageView* weatherCardImageView;
@property (nonatomic, strong) UIImageView* bottomOfUserNameImageView;
@property (nonatomic, strong) UIImageView* bambooImageView;
@property (nonatomic, strong) UIView* headerContainer;
@end

@implementation TLWHomePageView

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
}

- (void)tl_setSubViewsOfHeaderContainer {
  [self tl_setHelloLabel];
  [self tl_setUserNameLabel];
  [self tl_setBottomNameImageView];
  [self tl_setUserVersionImageView];
  [self tl_setUserAvatorImageView];
  [self tl_setTemperatureLabels];
  [self tl_setWeatherCardImageView];
  [self tl_setCalendarLabel];
  [self tl_setBambooImageView];
}

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
  label.text = @"农历冬月十二";
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
      make.top.equalTo(self.helloLabel.mas_bottom).offset(60);
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
  imageView.image = [[UIImage imageNamed:@"hp_avator.png"]imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
  [self.headerContainer addSubview:imageView];
  [imageView mas_makeConstraints:^(MASConstraintMaker *make) {
      make.right.equalTo(self.headerContainer).offset(-20);
      make.top.equalTo(self.headerContainer).offset(35);
      make.height.mas_equalTo(70);
      make.width.mas_equalTo(70);
  }];
}


- (void)tl_setUserVersionImageView {
  UIImageView* imageView = self.userVersionImageView;
  imageView.image = [[UIImage imageNamed:@"hp_version.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
  [self.headerContainer addSubview:imageView];
  [imageView mas_makeConstraints:^(MASConstraintMaker *make) {
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



- (UITableView *)locationTableView {
  if (!_locationTableView) {
    _locationTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    _locationTableView.backgroundColor = [UIColor clearColor];
    _locationTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _locationTableView.scrollEnabled = NO; // 通常嵌套在 Header 里的 TableView 不需要滚动
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

- (UIImageView *)userVersionImageView {
  if (!_userVersionImageView) {
    _userVersionImageView = [[UIImageView alloc] init];
    _userVersionImageView.contentMode = UIViewContentModeScaleAspectFit;
  }
  return _userVersionImageView;
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
