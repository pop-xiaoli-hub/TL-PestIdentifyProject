//
//  TLWLocationController.m
//  TL-PestIdentify
//

#import "TLWLocationController.h"
#import "TLWLocationView.h"
#import "TLWLocationSearchController.h"
#import "Models/TLWLocationCityModel.h"
#import "TLWLocationManager.h"
#import <Masonry/Masonry.h>

@interface TLWLocationController ()

@property (nonatomic, strong) TLWLocationView *locationView;
@property (nonatomic, copy) NSArray<TLWLocationCitySection *> *allSections;
@property (nonatomic, copy) NSArray<TLWLocationCitySection *> *filteredSections;
@property (nonatomic, copy) NSArray<NSString *> *recommendedCities;

@end

@implementation TLWLocationController

- (instancetype)init {
    self = [super init];
    if (self) {
        self.hideNavBar = YES;
        self.hidesBottomBarWhenPushed = YES;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view addSubview:self.locationView];
    [self.locationView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];

    self.allSections = [TLWLocationCitySection defaultSections];
    self.filteredSections = self.allSections;
    self.recommendedCities = [TLWLocationCitySection recommendedCities];
    [self tl_bindActions];
    [self tl_refreshView];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(tl_locationChanged)
                                                 name:TLWLocationDidUpdateNotification
                                               object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)tl_bindActions {
    __weak typeof(self) weakSelf = self;
    self.locationView.onBackTapped = ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf.navigationController popViewControllerAnimated:YES];
    };
    self.locationView.onRelocateTapped = ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [[TLWLocationManager shared] clearSelectedLocationName];
        [[TLWLocationManager shared] requestLocationPermission];
        [strongSelf tl_refreshView];
    };
    self.locationView.onCitySelected = ^(NSString *cityName) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [[TLWLocationManager shared] selectLocationName:cityName];
        [strongSelf.navigationController popViewControllerAnimated:YES];
    };
    self.locationView.onAlphabetSelected = ^(NSString *title) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf.locationView scrollToSectionTitle:title];
    };
    self.locationView.onSearchBarTapped = ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf tl_pushSearchController];
    };
}

- (void)tl_locationChanged {
    [self tl_refreshView];
}

- (void)tl_pushSearchController {
    TLWLocationSearchController *searchVC = [[TLWLocationSearchController alloc] init];
    searchVC.allSections = self.allSections;
    __weak typeof(self) weakSelf = self;
    searchVC.onCitySelected = ^(NSString *cityName) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [[TLWLocationManager shared] selectLocationName:cityName];
        [strongSelf.navigationController popToViewController:strongSelf animated:YES];
    };
    [self.navigationController pushViewController:searchVC animated:YES];
}

- (void)tl_refreshView {
    TLWLocationManager *locationManager = [TLWLocationManager shared];
    NSString *selectedLocation = locationManager.displayLocationName ?: locationManager.currentLocationDisplayName ?: @"未选择";
    NSString *currentLocation = locationManager.currentLocationDisplayName ?: @"暂未获取定位";

    NSMutableArray<NSString *> *alphabetTitles = [NSMutableArray array];
    for (TLWLocationCitySection *section in self.filteredSections) {
        [alphabetTitles addObject:section.title];
    }

    [self.locationView configureWithSelectedLocation:selectedLocation
                                     currentLocation:currentLocation
                                   recommendedCities:self.recommendedCities
                                       alphabetTitles:alphabetTitles
                                         citySections:self.filteredSections];
}

- (TLWLocationView *)locationView {
    if (!_locationView) {
        _locationView = [[TLWLocationView alloc] initWithFrame:CGRectZero];
    }
    return _locationView;
}

@end
