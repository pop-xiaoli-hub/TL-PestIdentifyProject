//
//  TLWLocationView.h
//  TL-PestIdentify
//

#import <UIKit/UIKit.h>

@class TLWLocationCitySection;

NS_ASSUME_NONNULL_BEGIN

@interface TLWLocationView : UIView

@property (nonatomic, copy, nullable) void (^onBackTapped)(void);
@property (nonatomic, copy, nullable) void (^onRelocateTapped)(void);
@property (nonatomic, copy, nullable) void (^onCitySelected)(NSString *cityName);
@property (nonatomic, copy, nullable) void (^onAlphabetSelected)(NSString *title);
@property (nonatomic, copy, nullable) void (^onSearchBarTapped)(void);

- (void)configureWithSelectedLocation:(nullable NSString *)selectedLocation
                      currentLocation:(nullable NSString *)currentLocation
                    recommendedCities:(NSArray<NSString *> *)recommendedCities
                        alphabetTitles:(NSArray<NSString *> *)alphabetTitles
                          citySections:(NSArray<TLWLocationCitySection *> *)citySections;

- (void)scrollToSectionTitle:(NSString *)title;

@end

NS_ASSUME_NONNULL_END
