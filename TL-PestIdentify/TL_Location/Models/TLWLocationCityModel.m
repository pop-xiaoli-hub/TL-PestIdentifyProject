//
//  TLWLocationCityModel.m
//  TL-PestIdentify
//

#import "TLWLocationCityModel.h"

@implementation TLWLocationCitySection

+ (instancetype)sectionWithTitle:(NSString *)title cities:(NSArray<NSString *> *)cities {
    TLWLocationCitySection *section = [[TLWLocationCitySection alloc] init];
    section.title = title;
    section.cities = cities;
    return section;
}

+ (NSArray<TLWLocationCitySection *> *)defaultSections {
    return @[
        [self sectionWithTitle:@"A" cities:@[@"阿坝", @"阿拉善盟", @"安庆", @"鞍山", @"安阳"]],
        [self sectionWithTitle:@"B" cities:@[@"北京", @"保定", @"包头", @"北海", @"蚌埠"]],
        [self sectionWithTitle:@"C" cities:@[@"成都", @"重庆", @"长沙", @"长春", @"常州"]],
        [self sectionWithTitle:@"D" cities:@[@"东莞", @"大连", @"大庆", @"德阳", @"大同"]],
        [self sectionWithTitle:@"E" cities:@[@"鄂尔多斯", @"恩施"]],
        [self sectionWithTitle:@"F" cities:@[@"福州", @"佛山", @"抚州", @"阜阳"]],
        [self sectionWithTitle:@"G" cities:@[@"广州", @"贵阳", @"桂林", @"赣州"]],
        [self sectionWithTitle:@"H" cities:@[@"杭州", @"合肥", @"哈尔滨", @"海口", @"呼和浩特"]],
        [self sectionWithTitle:@"J" cities:@[@"济南", @"金华", @"嘉兴", @"九江", @"揭阳"]],
        [self sectionWithTitle:@"K" cities:@[@"昆明", @"开封"]],
        [self sectionWithTitle:@"L" cities:@[@"洛阳", @"兰州", @"廊坊", @"临沂", @"丽江"]],
        [self sectionWithTitle:@"M" cities:@[@"绵阳", @"茂名", @"马鞍山"]],
        [self sectionWithTitle:@"N" cities:@[@"南京", @"宁波", @"南昌", @"南宁", @"南通"]],
        [self sectionWithTitle:@"P" cities:@[@"平顶山", @"莆田", @"濮阳"]],
        [self sectionWithTitle:@"Q" cities:@[@"青岛", @"泉州", @"衢州", @"秦皇岛"]],
        [self sectionWithTitle:@"R" cities:@[@"日照"]],
        [self sectionWithTitle:@"S" cities:@[@"上海", @"深圳", @"沈阳", @"苏州", @"绍兴", @"石家庄"]],
        [self sectionWithTitle:@"T" cities:@[@"天津", @"太原", @"唐山", @"台州"]],
        [self sectionWithTitle:@"W" cities:@[@"武汉", @"无锡", @"温州", @"乌鲁木齐", @"潍坊"]],
        [self sectionWithTitle:@"X" cities:@[@"西安", @"厦门", @"徐州", @"襄阳", @"咸阳"]],
        [self sectionWithTitle:@"Y" cities:@[@"扬州", @"银川", @"宜昌", @"烟台", @"义乌"]],
        [self sectionWithTitle:@"Z" cities:@[@"郑州", @"珠海", @"中山", @"镇江", @"株洲"]]
    ];
}

+ (NSArray<NSString *> *)recommendedCities {
    return @[@"杭州", @"北京", @"上海", @"深圳", @"广州", @"成都", @"武汉", @"天津", @"西安", @"南京", @"重庆", @"长沙"];
}

@end
