//
//  TLWLocationSearchController.h
//  TL-PestIdentify
//

#import "TLWBaseViewController.h"

@class TLWLocationCitySection;

NS_ASSUME_NONNULL_BEGIN

@interface TLWLocationSearchController : TLWBaseViewController

@property (nonatomic, copy) NSArray<TLWLocationCitySection *> *allSections;
@property (nonatomic, copy, nullable) void (^onCitySelected)(NSString *cityName);

@end

NS_ASSUME_NONNULL_END
