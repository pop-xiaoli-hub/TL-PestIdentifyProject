//
//  TLWLocationController.m
//  TL-PestIdentify
//

#import "TLWLocationController.h"
#import "TLWLocationView.h"
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
    self.locationView.onSearchTextChanged = ^(NSString *keyword) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf tl_applyFilterWithKeyword:keyword];
    };
}

- (void)tl_locationChanged {
    [self tl_refreshView];
}

- (void)tl_applyFilterWithKeyword:(NSString *)keyword {
    NSString *trimmedKeyword = [[keyword stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] lowercaseString];
    if (trimmedKeyword.length == 0) {
        self.filteredSections = self.allSections;
        [self tl_refreshView];
        return;
    }

    NSMutableArray<TLWLocationCitySection *> *filtered = [NSMutableArray array];
    for (TLWLocationCitySection *section in self.allSections) {
        NSMutableArray<NSString *> *matchedCities = [NSMutableArray array];
        for (NSString *cityName in section.cities) {
            if ([[cityName lowercaseString] containsString:trimmedKeyword]) {
                [matchedCities addObject:cityName];
            }
        }
        if (matchedCities.count > 0 || [[section.title lowercaseString] containsString:trimmedKeyword]) {
            TLWLocationCitySection *resultSection = [[TLWLocationCitySection alloc] init];
            resultSection.title = section.title;
            resultSection.cities = matchedCities.count > 0 ? matchedCities : section.cities;
            [filtered addObject:resultSection];
        }
    }
    self.filteredSections = filtered;
    [self tl_refreshView];
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
