//
//  TLWLocationCityModel.h
//  TL-PestIdentify
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TLWLocationCitySection : NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSArray<NSString *> *cities;

+ (NSArray<TLWLocationCitySection *> *)defaultSections;
+ (NSArray<NSString *> *)recommendedCities;

@end

NS_ASSUME_NONNULL_END
