//
//  TLWLocationView.h
//  TL-PestIdentify
//

#import <UIKit/UIKit.h>

@class TLWLocationCitySection;

NS_ASSUME_NONNULL_BEGIN

@interface TLWLocationSearchResult : NSObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *distance;
@property (nonatomic, copy) NSString *address;
@end

@interface TLWLocationView : UIView

@property (nonatomic, copy, nullable) void (^onBackTapped)(void);
@property (nonatomic, copy, nullable) void (^onRelocateTapped)(void);
@property (nonatomic, copy, nullable) void (^onCitySelected)(NSString *cityName);
@property (nonatomic, copy, nullable) void (^onAlphabetSelected)(NSString *title);
@property (nonatomic, copy, nullable) void (^onSearchTextChanged)(NSString *keyword);
@property (nonatomic, copy, nullable) void (^onSearchResultSelected)(NSString *cityName);

- (void)configureWithSelectedLocation:(nullable NSString *)selectedLocation
                      currentLocation:(nullable NSString *)currentLocation
                    recommendedCities:(NSArray<NSString *> *)recommendedCities
                        alphabetTitles:(NSArray<NSString *> *)alphabetTitles
                          citySections:(NSArray<TLWLocationCitySection *> *)citySections;

- (void)showSearchResults:(NSArray<TLWLocationSearchResult *> *)results forKeyword:(NSString *)keyword;
- (void)hideSearchResults;
- (void)scrollToSectionTitle:(NSString *)title;

@end

NS_ASSUME_NONNULL_END
