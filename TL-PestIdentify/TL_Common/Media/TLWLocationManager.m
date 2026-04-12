//
//  TLWLocationManager.m
//  TL-PestIdentify
//

#import "TLWLocationManager.h"

NSString * const TLWLocationDidUpdateNotification = @"TLWLocationDidUpdateNotification";

@interface TLWLocationManager () <CLLocationManagerDelegate>

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CLGeocoder *geocoder;
@property (nonatomic, copy, readwrite) NSString *cityName;
@property (nonatomic, assign, readwrite) CLLocationDegrees latitude;
@property (nonatomic, assign, readwrite) CLLocationDegrees longitude;
@property (nonatomic, assign, readwrite) BOOL hasLocation;
@property (nonatomic, assign, readwrite) BOOL locationDenied;

@end

@implementation TLWLocationManager

+ (instancetype)shared {
  static TLWLocationManager *instance;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[TLWLocationManager alloc] init];
  });
  return instance;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _locationManager = [[CLLocationManager alloc] init];
    _locationManager.delegate = self;
    _locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
    _geocoder = [[CLGeocoder alloc] init];
  }
  return self;
}

- (void)requestLocationPermission {
  CLAuthorizationStatus status;
  if (@available(iOS 14.0, *)) {
    status = self.locationManager.authorizationStatus;
  } else {
    status = [CLLocationManager authorizationStatus];
  }

  if (status == kCLAuthorizationStatusNotDetermined) {
    [self.locationManager requestWhenInUseAuthorization];
  } else if (status == kCLAuthorizationStatusAuthorizedWhenInUse ||
             status == kCLAuthorizationStatusAuthorizedAlways) {
    self.locationDenied = NO;
    [self startUpdatingLocation];
  } else {
    self.locationDenied = YES;
    self.hasLocation = NO;
    self.cityName = nil;
    self.latitude = 0;
    self.longitude = 0;
    [self postNotification];
  }
}

- (void)startUpdatingLocation {
  [self.locationManager requestLocation];
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManagerDidChangeAuthorization:(CLLocationManager *)manager API_AVAILABLE(ios(14.0)) {
  CLAuthorizationStatus status = manager.authorizationStatus;
  [self handleAuthorizationStatus:status];
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
  [self handleAuthorizationStatus:status];
}

- (void)handleAuthorizationStatus:(CLAuthorizationStatus)status {
  if (status == kCLAuthorizationStatusAuthorizedWhenInUse ||
      status == kCLAuthorizationStatusAuthorizedAlways) {
    self.locationDenied = NO;
    [self startUpdatingLocation];
  } else if (status == kCLAuthorizationStatusDenied ||
             status == kCLAuthorizationStatusRestricted) {
    self.locationDenied = YES;
    self.hasLocation = NO;
    self.cityName = nil;
    self.latitude = 0;
    self.longitude = 0;
    [self postNotification];
  }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
  CLLocation *location = locations.lastObject;
  if (!location) return;

  self.latitude = location.coordinate.latitude;
  self.longitude = location.coordinate.longitude;

  [self.geocoder reverseGeocodeLocation:location completionHandler:^(NSArray<CLPlacemark *> *placemarks, NSError *error) {
    dispatch_async(dispatch_get_main_queue(), ^{
      if (error || placemarks.count == 0) {
        self.hasLocation = YES;
        self.cityName = @"未知位置";
      } else {
        CLPlacemark *placemark = placemarks.firstObject;
        self.cityName = placemark.locality ?: placemark.administrativeArea ?: @"未知位置";
        self.hasLocation = YES;
      }
      self.locationDenied = NO;
      [self postNotification];
    });
  }];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
  if (error.code == kCLErrorDenied) {
    self.locationDenied = YES;
    self.hasLocation = NO;
    self.cityName = nil;
    self.latitude = 0;
    self.longitude = 0;
  }
  [self postNotification];
}

- (void)postNotification {
  [[NSNotificationCenter defaultCenter] postNotificationName:TLWLocationDidUpdateNotification
                                                      object:self];
}

@end
