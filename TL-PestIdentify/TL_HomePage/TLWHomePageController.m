//
//  TLWHomePageController.m
//  TL-PestIdentify
//
//  Created by xiaoli pop on 2026/3/9.
//

#import "TLWHomePageController.h"
#import "TLWHomePageView.h"
#import "TLWHomeCardCell.h"
#import "TLWHomeCustomCell.h"
#import "Models/TLWPlantModel.h"
#import "TL_AddPlantPage/TLWAddPlantController.h"
#import "TL_PlantDetailPage/TLWPlantDetailController.h"
#import "TLWIdentifyPageController.h"
#import "TLWRecordController.h"
#import "TLWAIAssistantController.h"
#import "TLWWarningModel.h"
#import "TLWSDKManager.h"
#import "TLWLocationManager.h"
#import "TLWToast.h"
#import <AgriPestClient/AGResultListAgentChatHistory.h>
#import <float.h>
#import <Masonry.h>
#import <SDWebImage/SDWebImage.h>

extern NSString * const TLWAvatarDidUpdateNotification;
extern NSString * const TLWProfileDidUpdateNotification;

@interface TLWHomePageController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) TLWHomePageView *homePageView;
@property (nonatomic, assign) BOOL warningExpanded;
@property (nonatomic, strong) NSMutableArray<TLWPlantModel *> *managedPlants;
@property (nonatomic, assign) BOOL isLoadingCrops;
@property (nonatomic, assign) BOOL elderModeEnabled;
@property (nonatomic, assign) BOOL bannerDismissed; // 用户手动关闭 Banner 后不再弹出
@property (nonatomic, strong) TLWWarningModel *currentWarning; // 当前预警数据
@property (nonatomic, assign) NSInteger historyRecordCount;
@property (nonatomic, strong) UIControl *warningBackdropControl;
@property (nonatomic, strong) UIView *warningPopupCardView;
@property (nonatomic, strong) UILabel *warningPopupTitleLabel;
@property (nonatomic, strong) UILabel *warningPopupBodyLabel;
@property (nonatomic, strong) UIButton *warningPopupCollapseButton;
@property (nonatomic, strong) MASConstraint *warningPopupTopConstraint;
@property (nonatomic, strong) MASConstraint *warningPopupHeightConstraint;
@property (nonatomic, copy) NSString *currentWeatherTemperature;
@property (nonatomic, copy) NSString *currentWeatherText;
@property (nonatomic, copy) NSString *currentWeatherIconCode;
@property (nonatomic, assign) BOOL isLoadingWeather;

@end

@implementation TLWHomePageController

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [self tl_applyElderModeState];
  [self tl_refreshLocationState];
  [self tl_fetchHistoryRecordCount];
}

- (void)viewDidLayoutSubviews {
  [super viewDidLayoutSubviews];

  if (self.warningPopupCardView) {
    self.warningPopupCardView.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.warningPopupCardView.bounds cornerRadius:20.0].CGPath;
  }

  if (self.warningExpanded) {
    CGFloat cardWidth = CGRectGetWidth(self.view.bounds) - 48.0;
    [self.warningPopupTopConstraint setOffset:[self tl_warningPopupTopOffset]];
    [self.warningPopupHeightConstraint setOffset:[self tl_warningPopupHeightForWidth:cardWidth]];
  }
}

- (void)viewDidLoad {
  [super viewDidLoad];
  [self tl_setHomePageBackView];
  [self tl_setupHomePageView];
  self.currentWeatherTemperature = @"--";
  self.currentWeatherText = @"获取中";
  self.currentWeatherIconCode = @"999";
  [self.homePageView configureWithTemperature:self.currentWeatherTemperature weatherText:self.currentWeatherText iconCode:self.currentWeatherIconCode];
  self.managedPlants = [NSMutableArray array];
  [self applyProfile];
  [self tl_fetchMyCrops];

  // 用户资料通知
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(onProfileUpdated)
                                               name:TLWProfileDidUpdateNotification
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(onAvatarUpdated:)
                                               name:TLWAvatarDidUpdateNotification
                                             object:nil];

  // 定位通知
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(onLocationUpdated)
                                               name:TLWLocationDidUpdateNotification
                                             object:nil];

  // 请求定位
  [[TLWLocationManager shared] requestLocationPermission];
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - 定位相关

- (void)onLocationUpdated {
  [self tl_refreshLocationState];
}

- (void)tl_fetchCurrentWeatherIfNeeded {
  TLWLocationManager *locMgr = [TLWLocationManager shared];
  if (!locMgr.hasLocation || self.isLoadingWeather) {
    return;
  }
  if (fabs(locMgr.latitude) < DBL_EPSILON && fabs(locMgr.longitude) < DBL_EPSILON) {
    return;
  }

  self.isLoadingWeather = YES;
  __weak typeof(self) weakSelf = self;
  [[TLWSDKManager shared] getCurrentWeatherWithLatitude:locMgr.latitude longitude:locMgr.longitude completion:^(NSDictionary * _Nullable weatherInfo, NSError * _Nullable error) {
    __strong typeof(weakSelf) strongSelf = weakSelf;
    if (!strongSelf) return;
    strongSelf.isLoadingWeather = NO;
    if (error || ![weatherInfo isKindOfClass:[NSDictionary class]]) {
      NSLog(@"[HomeWeather] apply failed error=%@", error.localizedDescription ?: @"unknown");
      strongSelf.currentWeatherTemperature = @"--";
      strongSelf.currentWeatherText = @"暂不可用";
      strongSelf.currentWeatherIconCode = @"999";
      [strongSelf.homePageView configureWithTemperature:strongSelf.currentWeatherTemperature
                                            weatherText:strongSelf.currentWeatherText
                                               iconCode:strongSelf.currentWeatherIconCode];
      return;
    }

    strongSelf.currentWeatherTemperature = [weatherInfo[@"temperature"] isKindOfClass:[NSString class]] ? weatherInfo[@"temperature"] : [[weatherInfo[@"temperature"] description] copy];
    strongSelf.currentWeatherText = [weatherInfo[@"weatherText"] isKindOfClass:[NSString class]] ? weatherInfo[@"weatherText"] : @"未知";
    strongSelf.currentWeatherIconCode = [weatherInfo[@"iconCode"] isKindOfClass:[NSString class]] ? weatherInfo[@"iconCode"] : @"999";
    [strongSelf.homePageView configureWithTemperature:strongSelf.currentWeatherTemperature
                                          weatherText:strongSelf.currentWeatherText
                                             iconCode:strongSelf.currentWeatherIconCode];
  }];
}

- (void)tl_refreshLocationState {
  TLWLocationManager *locMgr = [TLWLocationManager shared];
  NSString *cityName = locMgr.cityName;

  // 更新 header 定位文字
  [self.homePageView configureWithLocationName:cityName];
  [self.homePageView configureWithTemperature:self.currentWeatherTemperature
                                  weatherText:self.currentWeatherText
                                     iconCode:self.currentWeatherIconCode];

  // 更新底部 Banner
  if (locMgr.hasLocation || self.bannerDismissed) {
    [self.homePageView hideLocationBanner];
  } else if (locMgr.locationDenied) {
    [self.homePageView showLocationBanner];
  }

  // 更新预警卡片 + 种植物卡片
  if (locMgr.hasLocation) {
    [self tl_fetchAlertMessages];
    [self tl_fetchCurrentWeatherIfNeeded];
  } else {
    self.currentWarning = nil;
    [self tl_dismissExpandedWarningCardAnimated:NO];
  }
  [self.homePageView.tableView reloadData];
}

- (void)tl_fetchAlertMessages {
  __weak typeof(self) weakSelf = self;
  [[TLWSDKManager shared] getAlertMessagesWithPage:@0 size:@1 completionHandler:^(AGResultPageResultMessageResponseDto *output, NSError *error) {
    dispatch_async(dispatch_get_main_queue(), ^{
      __strong typeof(weakSelf) strongSelf = weakSelf;
      if (!strongSelf) return;

      if (error || output.code.integerValue != 200) {
        strongSelf.currentWarning = nil;
        [strongSelf tl_dismissExpandedWarningCardAnimated:NO];
        [strongSelf.homePageView.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
        return;
      }

      NSArray *list = output.data.list;
      if (list.count > 0) {
        AGMessageResponseDto *msg = list.firstObject;
        TLWWarningModel *model = [[TLWWarningModel alloc] init];
        model.title = msg.title;
        model.string = msg.content;
        strongSelf.currentWarning = model;
      } else {
        strongSelf.currentWarning = nil;
        [strongSelf tl_dismissExpandedWarningCardAnimated:NO];
      }
      [strongSelf.homePageView.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
    });
  }];
}

- (void)tl_fetchHistoryRecordCount {
  __weak typeof(self) weakSelf = self;
  [[TLWSDKManager shared].api getHistoryWithCompletionHandler:^(AGResultListAgentChatHistory *output, NSError *error) {
    dispatch_async(dispatch_get_main_queue(), ^{
      __strong typeof(weakSelf) strongSelf = weakSelf;
      if (!strongSelf) return;

      if (error) {
        [strongSelf.homePageView.tableView reloadData];
        return;
      }
      if ([[TLWSDKManager shared].sessionManager shouldAttemptTokenRefreshForCode:output.code]) {
        [[TLWSDKManager shared].sessionManager handleUnauthorizedWithRetry:^{
          [strongSelf tl_fetchHistoryRecordCount];
        }];
        return;
      }
      if (output.code.integerValue != 200) {
        [strongSelf.homePageView.tableView reloadData];
        return;
      }

      NSArray *historyList = [output.data isKindOfClass:[NSArray class]] ? output.data : @[];
      strongSelf.historyRecordCount = historyList.count;
      [strongSelf.homePageView.tableView reloadData];
    });
  }];
}

#pragma mark - 用户资料

- (void)onProfileUpdated {
  [self applyProfile];
}

- (void)applyProfile {
  AGUserProfileDto *profile = [TLWSDKManager shared].sessionManager.cachedProfile;
  NSString *name = profile.fullName ?: profile.username;
  [self.homePageView configureWithUserName:name];
  if (profile.avatarUrl.length > 0) {
    [self.homePageView.userAvatarImageView sd_setImageWithURL:[NSURL URLWithString:profile.avatarUrl]];
  } else {
    self.homePageView.userAvatarImageView.image = nil;
  }
}

- (void)onAvatarUpdated:(NSNotification *)noti {
  UIImage *avatar = noti.userInfo[@"avatar"];
  if (avatar) self.homePageView.userAvatarImageView.image = avatar;
}

- (void)tl_setHomePageBackView {
  UIImage* image = [UIImage imageNamed:@"hp_backView.png"];
  self.view.layer.contents = (__bridge id)image.CGImage;
}

- (void)tl_setupHomePageView {
  self.homePageView.backgroundColor = [UIColor clearColor];
  [self.view addSubview:self.homePageView];
  [self.homePageView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.edges.equalTo(self.view);
  }];
  UITableView *tableView = self.homePageView.tableView;
  tableView.delegate = self;
  tableView.dataSource = self;
  tableView.estimatedRowHeight = 180;
  [tableView registerClass:[TLWHomeCardCell class] forCellReuseIdentifier:@"kTLWHomeCardCellIdentifier1"];
  [tableView registerClass:[TLWHomeCardCell class] forCellReuseIdentifier:@"kTLWHomeCardCellIdentifier2"];
  [tableView registerClass:[TLWHomeCustomCell class] forCellReuseIdentifier:@"kTLWHomeCustomCellIdentifier"];
  tableView.estimatedRowHeight = 160.0;
  [self.homePageView.userVersionButton addTarget:self action:@selector(tl_toggleElderMode) forControlEvents:UIControlEventTouchUpInside];
  [self tl_applyElderModeState];

  // Banner 回调
  __weak typeof(self) weakSelf = self;
  self.homePageView.onOpenLocationTapped = ^{
    __strong typeof(weakSelf) strongSelf = weakSelf;
    if (!strongSelf) return;
    // 跳转系统设置
    NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
      [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
    }
  };
  self.homePageView.onCloseLocationBanner = ^{
    __strong typeof(weakSelf) strongSelf = weakSelf;
    if (!strongSelf) return;
    strongSelf.bannerDismissed = YES;
  };
}

- (TLWHomePageView *)homePageView {
  if (!_homePageView) {
    _homePageView = [[TLWHomePageView alloc] initWithFrame:CGRectZero];
  }
  return _homePageView;
}

- (BOOL)tl_isElderModeEnabled {
  NSInteger currentUserId = [TLWSDKManager shared].sessionManager.userId;
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSString *elderModeKey = [NSString stringWithFormat:@"TLW_elder_mode_%ld", (long)currentUserId];
  if ([defaults objectForKey:elderModeKey] != nil) {
    return [defaults boolForKey:elderModeKey];
  }
  if ([defaults objectForKey:@"TLW_elder_mode"] != nil) {
    return [defaults boolForKey:@"TLW_elder_mode"];
  }
  return NO;
}

- (void)tl_applyElderModeState {
  self.elderModeEnabled = [self tl_isElderModeEnabled];
  [self.homePageView configureElderModeEnabled:self.elderModeEnabled];
}

- (void)tl_toggleElderMode {
  BOOL elderModeEnabled = !self.elderModeEnabled;
  NSInteger currentUserId = [TLWSDKManager shared].sessionManager.userId;
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSString *elderModeKey = [NSString stringWithFormat:@"TLW_elder_mode_%ld", (long)currentUserId];
  NSString *elderSetKey = [NSString stringWithFormat:@"TLW_elder_mode_set_%ld", (long)currentUserId];
  [defaults setBool:elderModeEnabled forKey:elderModeKey];
  [defaults setBool:elderModeEnabled forKey:@"TLW_elder_mode"];
  [defaults setBool:YES forKey:elderSetKey];
  [defaults setBool:YES forKey:@"TLW_elder_mode_set"];

  self.elderModeEnabled = elderModeEnabled;
  [self.homePageView configureElderModeEnabled:elderModeEnabled];
  [TLWToast show:(elderModeEnabled ? @"已切换为老年版" : @"已切换为青年版")];
}

#pragma mark - 预警聚焦态

- (void)tl_setupWarningOverlayIfNeeded {
  if (self.warningBackdropControl && self.warningPopupCardView) {
    return;
  }

  UIControl *backdropControl = [[UIControl alloc] init];
  backdropControl.hidden = YES;
  backdropControl.alpha = 0.0;
  [backdropControl addTarget:self action:@selector(tl_warningBackdropTapped) forControlEvents:UIControlEventTouchUpInside];
  [self.view addSubview:backdropControl];
  self.warningBackdropControl = backdropControl;

  [backdropControl mas_makeConstraints:^(MASConstraintMaker *make) {
    make.edges.equalTo(self.view);
  }];

  UIBlurEffectStyle blurStyle = UIBlurEffectStyleLight;
  if (@available(iOS 13.0, *)) {
    blurStyle = UIBlurEffectStyleExtraLight;
  }
  UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:blurStyle]];
  blurView.userInteractionEnabled = NO;
  blurView.alpha = 0.68;
  [backdropControl addSubview:blurView];
  [blurView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.edges.equalTo(backdropControl);
  }];

  UIView *dimView = [[UIView alloc] init];
  dimView.userInteractionEnabled = NO;
  dimView.backgroundColor = [[UIColor colorWithWhite:0.35 alpha:1.0] colorWithAlphaComponent:0.10];
  [backdropControl addSubview:dimView];
  [dimView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.edges.equalTo(backdropControl);
  }];

  UIView *cardView = [[UIView alloc] init];
  cardView.hidden = YES;
  cardView.alpha = 0.0;
  cardView.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.65];
  cardView.layer.cornerRadius = 20.0;
  cardView.layer.masksToBounds = NO;
  cardView.layer.shadowColor = [UIColor colorWithRed:0.0 green:0.40 blue:0.37 alpha:0.18].CGColor;
  cardView.layer.shadowOpacity = 1.0;
  cardView.layer.shadowOffset = CGSizeMake(0.0, 11.0);
  cardView.layer.shadowRadius = 13.5;
  [self.view addSubview:cardView];
  self.warningPopupCardView = cardView;

  [cardView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.equalTo(self.view).offset(24.0);
    make.right.equalTo(self.view).offset(-24.0);
    self.warningPopupTopConstraint = make.top.equalTo(self.view).offset(249.0);
    self.warningPopupHeightConstraint = make.height.mas_equalTo(232.0);
  }];

  UIView *innerGlowView = [[UIView alloc] init];
  innerGlowView.userInteractionEnabled = NO;
  innerGlowView.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.10];
  innerGlowView.layer.cornerRadius = 20.0;
  innerGlowView.layer.borderWidth = 1.0;
  innerGlowView.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.25].CGColor;
  [cardView addSubview:innerGlowView];
  [innerGlowView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.edges.equalTo(cardView);
  }];

  UIView *iconBackgroundView = [[UIView alloc] init];
  iconBackgroundView.backgroundColor = [UIColor colorWithRed:1.0 green:0.55 blue:0.12 alpha:1.0];
  iconBackgroundView.layer.cornerRadius = 9.0;
  iconBackgroundView.layer.masksToBounds = YES;
  [cardView addSubview:iconBackgroundView];

  UIImageView *iconImageView = [[UIImageView alloc] init];
  iconImageView.tintColor = [UIColor whiteColor];
  iconImageView.contentMode = UIViewContentModeScaleAspectFit;
  if (@available(iOS 13.0, *)) {
    UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:10.0 weight:UIImageSymbolWeightBold];
    iconImageView.image = [[UIImage systemImageNamed:@"bolt.fill" withConfiguration:config] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
  }
  [iconBackgroundView addSubview:iconImageView];

  UILabel *titleLabel = [[UILabel alloc] init];
  titleLabel.textColor = [UIColor colorWithRed:0.13 green:0.13 blue:0.13 alpha:1.0];
  titleLabel.font = [UIFont systemFontOfSize:18.0 weight:UIFontWeightSemibold];
  [cardView addSubview:titleLabel];
  self.warningPopupTitleLabel = titleLabel;

  UILabel *bodyLabel = [[UILabel alloc] init];
  bodyLabel.numberOfLines = 0;
  bodyLabel.textColor = [UIColor blackColor];
  bodyLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightRegular];
  [cardView addSubview:bodyLabel];
  self.warningPopupBodyLabel = bodyLabel;

  UIButton *collapseButton = [UIButton buttonWithType:UIButtonTypeSystem];
  [collapseButton setTitle:@"收起详细" forState:UIControlStateNormal];
  [collapseButton setTitleColor:[[UIColor blackColor] colorWithAlphaComponent:0.48] forState:UIControlStateNormal];
  collapseButton.titleLabel.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightMedium];
  if (@available(iOS 13.0, *)) {
    UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:10.0 weight:UIImageSymbolWeightSemibold];
    UIImage *image = [[UIImage systemImageNamed:@"chevron.up" withConfiguration:config] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [collapseButton setImage:image forState:UIControlStateNormal];
    collapseButton.tintColor = [[UIColor blackColor] colorWithAlphaComponent:0.48];
    collapseButton.semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;
  }
  [collapseButton addTarget:self action:@selector(tl_warningBackdropTapped) forControlEvents:UIControlEventTouchUpInside];
  [cardView addSubview:collapseButton];
  self.warningPopupCollapseButton = collapseButton;

  [iconBackgroundView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.equalTo(cardView).offset(20.0);
    make.top.equalTo(cardView).offset(20.0);
    make.width.height.mas_equalTo(18.0);
  }];

  [iconImageView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.center.equalTo(iconBackgroundView);
    make.width.height.mas_equalTo(10.0);
  }];

  [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.equalTo(iconBackgroundView.mas_right).offset(8.0);
    make.centerY.equalTo(iconBackgroundView);
    make.right.lessThanOrEqualTo(cardView).offset(-20.0);
  }];

  [collapseButton mas_makeConstraints:^(MASConstraintMaker *make) {
    make.right.equalTo(cardView).offset(-16.0);
    make.bottom.equalTo(cardView).offset(-14.0);
    make.height.mas_equalTo(20.0);
  }];

  [bodyLabel mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.equalTo(cardView).offset(22.0);
    make.right.equalTo(cardView).offset(-22.0);
    make.top.equalTo(cardView).offset(55.0);
    make.bottom.lessThanOrEqualTo(collapseButton.mas_top).offset(-16.0);
  }];
}

- (void)tl_warningBackdropTapped {
  [self tl_dismissExpandedWarningCardAnimated:YES];
}

- (void)tl_presentExpandedWarningCard {
  if (self.warningExpanded || self.currentWarning.string.length == 0) {
    return;
  }

  [self tl_setupWarningOverlayIfNeeded];
  self.warningExpanded = YES;
  self.homePageView.tableView.scrollEnabled = NO;

  CGFloat cardWidth = CGRectGetWidth(self.view.bounds) - 48.0;
  [self.warningPopupTopConstraint setOffset:[self tl_warningPopupTopOffset]];
  [self.warningPopupHeightConstraint setOffset:[self tl_warningPopupHeightForWidth:cardWidth]];
  self.warningPopupTitleLabel.text = self.currentWarning.title.length > 0 ? self.currentWarning.title : @"【预警通知】";
  self.warningPopupBodyLabel.attributedText = [self tl_warningBodyAttributedText:self.currentWarning.string ?: @""];

  self.warningBackdropControl.hidden = NO;
  self.warningPopupCardView.hidden = NO;
  [self.view bringSubviewToFront:self.warningBackdropControl];
  [self.view bringSubviewToFront:self.warningPopupCardView];
  [self.view layoutIfNeeded];

  self.warningPopupCardView.transform = CGAffineTransformMakeScale(0.97, 0.97);

  [UIView animateWithDuration:0.26
                        delay:0.0
                      options:UIViewAnimationOptionCurveEaseOut
                   animations:^{
    self.warningBackdropControl.alpha = 1.0;
    self.warningPopupCardView.alpha = 1.0;
    self.warningPopupCardView.transform = CGAffineTransformIdentity;
  } completion:nil];
}

- (void)tl_dismissExpandedWarningCardAnimated:(BOOL)animated {
  if (!self.warningBackdropControl || !self.warningPopupCardView) {
    self.warningExpanded = NO;
    return;
  }

  self.warningExpanded = NO;
  self.homePageView.tableView.scrollEnabled = YES;

  void (^completionBlock)(BOOL) = ^(BOOL finished) {
    self.warningBackdropControl.hidden = YES;
    self.warningPopupCardView.hidden = YES;
    self.warningBackdropControl.alpha = 0.0;
    self.warningPopupCardView.alpha = 0.0;
    self.warningPopupCardView.transform = CGAffineTransformIdentity;
  };

  if (!animated) {
    completionBlock(YES);
    return;
  }

  [UIView animateWithDuration:0.22
                        delay:0.0
                      options:UIViewAnimationOptionCurveEaseInOut
                   animations:^{
    self.warningBackdropControl.alpha = 0.0;
    self.warningPopupCardView.alpha = 0.0;
    self.warningPopupCardView.transform = CGAffineTransformMakeScale(0.97, 0.97);
  } completion:completionBlock];
}

- (CGFloat)tl_warningPopupTopOffset {
  NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
  CGRect rowRect = [self.homePageView.tableView rectForRowAtIndexPath:indexPath];
  CGRect convertedRect = [self.homePageView.tableView convertRect:rowRect toView:self.view];
  CGFloat fallbackTop = 249.0;

  if (CGRectIsEmpty(convertedRect)) {
    return fallbackTop;
  }

  CGFloat topOffset = CGRectGetMinY(convertedRect) + 2.0;
  return MAX(140.0, topOffset);
}

- (CGFloat)tl_warningPopupHeightForWidth:(CGFloat)width {
  CGFloat textWidth = MAX(width - 44.0, 0.0);
  NSAttributedString *bodyText = [self tl_warningBodyAttributedText:self.currentWarning.string ?: @""];
  CGRect textRect = [bodyText boundingRectWithSize:CGSizeMake(textWidth, CGFLOAT_MAX)
                                           options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                           context:nil];
  CGFloat contentHeight = 55.0 + ceil(textRect.size.height) + 52.0;
  return MAX(232.0, contentHeight);
}

- (NSAttributedString *)tl_warningBodyAttributedText:(NSString *)text {
  NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
  paragraphStyle.minimumLineHeight = 22.0;
  paragraphStyle.maximumLineHeight = 22.0;
  paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;

  NSDictionary *attributes = @{
    NSFontAttributeName: [UIFont systemFontOfSize:14.0 weight:UIFontWeightRegular],
    NSForegroundColorAttributeName: [UIColor blackColor],
    NSParagraphStyleAttributeName: paragraphStyle
  };

  return [[NSAttributedString alloc] initWithString:text ?: @"" attributes:attributes];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return 3 + self.managedPlants.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  if (indexPath.row == 0) {
    TLWHomeCardCell *cell = [tableView dequeueReusableCellWithIdentifier:@"kTLWHomeCardCellIdentifier1" forIndexPath:indexPath];
    TLWLocationManager *locMgr = [TLWLocationManager shared];

    if (!locMgr.hasLocation) {
      // 无定位：显示"暂无预警信息，请开启定位功能"
      [cell tl_configureAsNoLocationWarning];
    } else if (self.currentWarning) {
      // 有定位 + 有预警数据：显示真实预警
      CGFloat tableWidth = CGRectGetWidth(tableView.bounds);
      CGFloat bodyWidth = tableWidth - 16.0 - 16.0 - 16.0 - 8.0;
      self.currentWarning.shouldExpand = [self isTextViewExceedThreeLines:self.currentWarning.string width:bodyWidth];
      [cell tl_configureWithWarning:self.currentWarning];
      [cell tl_configureWarningExpanded:NO];
      __weak typeof(self) weakSelf = self;
      cell.clickWarningDetail = ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        [strongSelf tl_presentExpandedWarningCard];
      };
    } else {
      // 有定位但无预警数据
      [cell tl_configureAsNoLocationWarning];
      // 复用无定位的居中样式，但改文案
      cell.bodyLabel.text = @"当前无预警信息";
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
  } else if (indexPath.row == 1) {
    TLWHomeCardCell *cell = [tableView dequeueReusableCellWithIdentifier:@"kTLWHomeCardCellIdentifier2" forIndexPath:indexPath];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    [cell tl_configureRecordCount:self.historyRecordCount];
    __weak typeof(self) weakSelf = self;
    cell.clickPhotoIdentification = ^{
      TLWIdentifyPageController* identifyViewController = [[TLWIdentifyPageController alloc] init];
      identifyViewController.hidesBottomBarWhenPushed = YES;
      [weakSelf.navigationController pushViewController:identifyViewController animated:YES];
    };
    cell.clickRecordCard = ^{
      TLWRecordController *recordVC = [[TLWRecordController alloc] init];
      recordVC.hidesBottomBarWhenPushed = YES;
      [weakSelf.navigationController pushViewController:recordVC animated:YES];
    };
    cell.clickAIAssistant = ^{
      TLWAIAssistantController *aiVC = [[TLWAIAssistantController alloc] initWithInitialQuestion:nil];
      [weakSelf.navigationController pushViewController:aiVC animated:YES];
    };
    return cell;
  }

  // 种植物管理卡片
  TLWHomeCustomCell *cell = [tableView dequeueReusableCellWithIdentifier:@"kTLWHomeCustomCellIdentifier" forIndexPath:indexPath];
  NSString *locationName = [TLWLocationManager shared].cityName;
  __weak typeof(self) weakSelf = self;

  if (indexPath.row == 2) {
    [cell configureAsCreateCellWithLocationName:locationName];
    cell.clickCreateButton = ^{
      __strong typeof(weakSelf) strongSelf = weakSelf;
      if (!strongSelf) return;
      [strongSelf tl_openAddPlantController];
    };
    cell.clickContentCard = ^{
      __strong typeof(weakSelf) strongSelf = weakSelf;
      if (!strongSelf) return;
      [strongSelf tl_openAddPlantController];
    };
  } else {
    NSInteger plantIndex = indexPath.row - 3;
    if (plantIndex >= 0 && plantIndex < self.managedPlants.count) {
      TLWPlantModel *plantModel = self.managedPlants[plantIndex];
      [cell configureWithPlantModel:plantModel locationName:locationName];
      cell.clickContentCard = ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        if (plantModel.isUploading) {
          [strongSelf tl_showMessageAlert:@"正在上传"];
        } else {
          TLWPlantDetailController *detailController = [[TLWPlantDetailController alloc] initWithPlantModel:plantModel];
          detailController.hidesBottomBarWhenPushed = YES;
          [strongSelf.navigationController pushViewController:detailController animated:YES];
        }
      };
    }
    cell.clickCreateButton = nil;
  }
  cell.selectionStyle = UITableViewCellSelectionStyleNone;
  return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  if (indexPath.row == 0) {
    return UITableViewAutomaticDimension;
  } else if (indexPath.row == 1) {
    return 210.0;
  } else {
    return 300.0;
  }
}

- (void)tl_openAddPlantController {
  __weak typeof(self) weakSelf = self;
  TLWAddPlantController *controller = [[TLWAddPlantController alloc] init];
  controller.onConfirmAddPlant = ^(NSString *plantName, UIImage *plantImage) {
    __strong typeof(weakSelf) strongSelf = weakSelf;
    if (!strongSelf) return;
    TLWPlantModel *plantModel = [[TLWPlantModel alloc] initWithPlantName:plantName image:plantImage];
    [strongSelf.managedPlants insertObject:plantModel atIndex:0];
    [strongSelf.homePageView.tableView reloadData];
    [strongSelf tl_uploadPlantModel:plantModel];
  };
  controller.hidesBottomBarWhenPushed = YES;
  [self.navigationController pushViewController:controller animated:YES];
}

- (void)tl_fetchMyCrops {
  if (self.isLoadingCrops) return;
  self.isLoadingCrops = YES;

  __weak typeof(self) weakSelf = self;
  TLWSDKManager *manager = [TLWSDKManager shared];
  __block void (^fetchCropsBlock)(BOOL);
  fetchCropsBlock = ^(BOOL didRetryAuth) {
    [manager getMyCropsWithCompletionHandler:^(AGResultListMyCropResponseDto * output, NSError * error) {
      dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;

        strongSelf.isLoadingCrops = NO;
        if (!didRetryAuth
            && [manager.sessionManager handleAuthFailureForCode:output.code
                                                       message:output.message
                                                    retryBlock:^{
          fetchCropsBlock(YES);
        }]) {
          return;
        }
        if (error || output.code.integerValue != 200) {
          [TLWToast show:[manager.sessionManager userFacingMessageForError:error
                                                                     code:output.code
                                                            serverMessage:output.message
                                                           defaultMessage:@"作物列表加载失败，请稍后重试"]];
          return;
        }

        NSMutableArray<TLWPlantModel *> *plants = [NSMutableArray array];
        for (AGMyCropResponseDto *crop in output.data) {
          if (![crop isKindOfClass:[AGMyCropResponseDto class]]) continue;
          TLWPlantModel *plantModel = [[TLWPlantModel alloc] initWithCropResponse:crop];
          [plants addObject:plantModel];
        }

        NSMutableArray<TLWPlantModel *> *pendingPlants = [NSMutableArray array];
        for (TLWPlantModel *localPlant in strongSelf.managedPlants) {
          if (localPlant.isUploading) {
            [pendingPlants addObject:localPlant];
          }
        }

        NSMutableArray<TLWPlantModel *> *mergedPlants = [NSMutableArray arrayWithArray:pendingPlants];
        [mergedPlants addObjectsFromArray:plants];
        strongSelf.managedPlants = mergedPlants;
        [strongSelf.homePageView.tableView reloadData];
      });
    }];
  };

  fetchCropsBlock(NO);
}

- (void)tl_uploadPlantModel:(TLWPlantModel *)plantModel {
  NSData *imageData = UIImageJPEGRepresentation(plantModel.localImage, 0.9);
  if (imageData.length == 0) {
    plantModel.isUploading = NO;
    [self.homePageView.tableView reloadData];
    [self tl_showMessageAlert:@"图片处理失败，请重新选择"];
    return;
  }

  NSString *fileName = [NSString stringWithFormat:@"plant_%@.jpg", [[NSUUID UUID] UUIDString]];
  NSString *tempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];
  BOOL writeSuccess = [imageData writeToFile:tempPath atomically:YES];
  if (!writeSuccess) {
    plantModel.isUploading = NO;
    [self.homePageView.tableView reloadData];
    [self tl_showMessageAlert:@"图片处理失败，请稍后重试"];
    return;
  }

  NSURL *fileURL = [NSURL fileURLWithPath:tempPath];
  __weak typeof(self) weakSelf = self;
  TLWSDKManager *manager = [TLWSDKManager shared];
  __block void (^createCropBlock)(NSString *, BOOL);
  createCropBlock = ^(NSString *imageURL, BOOL didRetryAuth) {
    AGMyCropCreateRequest *request = [[AGMyCropCreateRequest alloc] init];
    request.plantName = plantModel.plantName;
    request.imageUrl = imageURL;
    request.status = @"正常";
    request.plantingDate = [NSDate date];
    request.pestCount = @0;

    [manager createCropWithRequest:request completionHandler:^(AGResultMyCropResponseDto * output, NSError * error) {
      dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) innerSelf = weakSelf;
        if (!innerSelf) return;

        if (!didRetryAuth
            && [manager.sessionManager handleAuthFailureForCode:output.code
                                                       message:output.message
                                                    retryBlock:^{
          createCropBlock(imageURL, YES);
        }]) {
          return;
        }

        plantModel.isUploading = NO;
        if (error || output.code.integerValue != 200) {
          NSString *message = [manager.sessionManager userFacingMessageForError:error
                                                                           code:output.code
                                                                  serverMessage:output.message
                                                                 defaultMessage:@"新作物创建失败，请稍后重试"];
          [innerSelf tl_showMessageAlert:message];
          [innerSelf.homePageView.tableView reloadData];
          return;
        }

        plantModel.plantId = output.data._id ?: plantModel.plantId;
        plantModel.plantName = output.data.plantName.length > 0 ? output.data.plantName : plantModel.plantName;
        plantModel.imageUrl = output.data.imageUrl.length > 0 ? output.data.imageUrl : imageURL;
        plantModel.plantStatus = output.data.status.length > 0 ? output.data.status : request.status;
        plantModel.plantingDate = output.data.plantingDate ?: request.plantingDate;
        plantModel.localImage = nil;
        [innerSelf.homePageView.tableView reloadData];
      });
    }];
  };

  __block void (^uploadBlock)(BOOL);
  uploadBlock = ^(BOOL didRetryAuth) {
    [manager uploadFileWithFile:fileURL prefix:@"crop/" completionHandler:^(AGResultString * output, NSError * error) {
      dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;

        if (!didRetryAuth
            && [manager.sessionManager handleAuthFailureForCode:output.code
                                                       message:output.message
                                                    retryBlock:^{
          uploadBlock(YES);
        }]) {
          return;
        }

        NSString *imageURL = output.data;
        if (error || output.code.integerValue != 200 || imageURL.length == 0) {
          [[NSFileManager defaultManager] removeItemAtPath:tempPath error:nil];
          plantModel.isUploading = NO;
          [strongSelf.homePageView.tableView reloadData];
          NSString *message = [manager.sessionManager userFacingMessageForError:error
                                                                           code:output.code
                                                                  serverMessage:output.message
                                                                 defaultMessage:@"图片上传失败，请稍后重试"];
          [strongSelf tl_showMessageAlert:message];
          return;
        }

        [[NSFileManager defaultManager] removeItemAtPath:tempPath error:nil];
        createCropBlock(imageURL, NO);
      });
    }];
  };

  uploadBlock(NO);
}

- (void)tl_showMessageAlert:(NSString *)message {
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
  [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
  [self presentViewController:alert animated:YES completion:nil];
}


- (BOOL)isTextViewExceedThreeLines:(NSString *)text width:(CGFloat)width {
  NSTextStorage *storage = [[NSTextStorage alloc] initWithString:text attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:16]}];
  NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
  NSTextContainer *container = [[NSTextContainer alloc] initWithSize:CGSizeMake(width, CGFLOAT_MAX)];
  container.lineFragmentPadding = 0;
  [layoutManager addTextContainer:container];
  [storage addLayoutManager:layoutManager];
  NSUInteger glyphCount = [layoutManager numberOfGlyphs];
  __block NSInteger lines = 0;
  [layoutManager enumerateLineFragmentsForGlyphRange:NSMakeRange(0, glyphCount) usingBlock:^(CGRect rect, CGRect usedRect, NSTextContainer * _Nonnull textContainer, NSRange glyphRange, BOOL * _Nonnull stop) {
    lines++;
    if (lines > 3) {
      *stop = YES;
    }
  }];
  return lines > 3;
}

@end
