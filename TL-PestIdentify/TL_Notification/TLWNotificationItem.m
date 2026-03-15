//
//  TLWNotificationItem.m
//  TL-PestIdentify
//

#import "TLWNotificationItem.h"

@implementation TLWNotificationItem

+ (NSArray<TLWNotificationItem *> *)mockItems {
    TLWNotificationItem *item1 = [TLWNotificationItem new];
    item1.tag       = TLWNotificationTagSystem;
    item1.title     = @"【病虫害预警通知】";
    item1.bodyText  = @"根据近期气象条件、田间监测数据及病虫害发生发展规律，经技术人员综合研判，预计将进入病虫害高发期，为有效降低危害、保障生产安全，预警信息通知如下：\n\n一、预警对象\n主要危害作物：小麦/水稻/蔬菜/果树/园林绿植等\n高发病虫害：蚜虫/白粉病/稻飞虱/叶斑病/红蜘蛛等\n\n二、发生趋势\n受高温高湿、连续降雨、气温回升等因素影响，当前病虫害已在局部区域零星发生，扩散速度快，预计未来7-10天进入高发阶段，危害程度重，需高度警惕。\n\n三、防控建议\n1. 全面开展田间/园区排查，重点监测植株叶片、茎秆、果实等部位，做到早发现、早处置。\n2. 优先采用农业防治、物理防治、生物防治等绿色防控措施，减少化学农药使用。\n3. 科学选用高效、低毒、低残留农药，严格按照用药规范操作，确保防治效果与生产安全。\n4. 做好通风、排水、清理病残体等田间管理工作，改善生长环境，降低病虫害滋生条件。\n\n请种植户高度重视，及时落实防控措施，避免造成大面积减产损失。";
    item1.hasUnread = YES;

    TLWNotificationItem *item2 = [TLWNotificationItem new];
    item2.tag       = TLWNotificationTagDisease;
    item2.title     = @"【橙色霜冻预警警报】";
    item2.bodyText  = @"预计24小时内，我区地面最低温将降至-5℃以下，农作物面临严重冻害风险。请农户立即采取防冻措施，覆盖保温材料，对幼苗和脆弱作物重点保护。各乡镇农业站将开展巡查，遇紧急情况请及时联系当地农技人员。";
    item2.hasUnread = YES;

    return @[item1, item2];
}

@end
