//
//  TLWRecordController.m
//  TL-PestIdentify
//
//  Created by Tommy on 2026/3/13.
//

#import "TLWRecordController.h"
#import "TLWRecordView.h"
#import "TLWRecordCell.h"
#import "TLWRecordHeaderView.h"
#import "TLWRecordModel.h"
#import "TLWRecordDetailController.h"
#import <Masonry/Masonry.h>

static NSString *const kCellID   = @"TLWRecordCell";
static NSString *const kHeaderID = @"TLWRecordHeader";

@interface TLWRecordController () <UICollectionViewDataSource, UICollectionViewDelegate>
@property (nonatomic, strong) TLWRecordView *myView;
@property (nonatomic, strong) NSArray<TLWRecordSection *> *sections;
@end

@implementation TLWRecordController

- (NSString *)navTitle { return @"识别记录"; }
- (NSString *)navTitleIconName { return @"records"; }

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.navBar setRightButtonTitle:@"筛选" iconName:@"筛选"];

    [self.view addSubview:self.myView];
    [self.myView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    [self.view bringSubviewToFront:self.navBar];

    UICollectionView *cv = self.myView.collectionView;
    cv.dataSource = self;
    cv.delegate   = self;
    [cv registerClass:[TLWRecordCell class]
           forCellWithReuseIdentifier:kCellID];
    [cv registerClass:[TLWRecordHeaderView class]
        forSupplementaryViewOfKind:UICollectionElementKindSectionHeader
               withReuseIdentifier:kHeaderID];

    [self.navBar.rightButton addTarget:self
                                action:@selector(tl_filter)
                      forControlEvents:UIControlEventTouchUpInside];

    [self tl_fetchRecords];
}

#pragma mark - Actions

- (void)tl_filter {
    // TODO: 展示筛选面板（按日期/病虫害类型过滤）
}

#pragma mark - Data

// TODO: 接口来了替换此方法内部实现，外部调用方式不变
// 预期接口格式：
// [{ "date": "2025-11-28", "items": [{
//   "recordId": "1", "imageURL": "https://...", "recordTime": "2025-11-28 14:32",
//   "results": [{ "pestName": "蚜虫", "confidence": 0.92, "solution": "..." }]
// }] }]
- (void)tl_fetchRecords {
    // Mock 数据
    TLWRecordResult *r_aphid = [TLWRecordResult new];
    r_aphid.pestName  = @"蚜虫";
    r_aphid.confidence = 0.92f;
    r_aphid.solution  = @"使用吡虫啉或噻虫嗪类杀虫剂进行喷雾处理，注意轮换用药以防产生抗药性。同时清除田间杂草，减少蚜虫越冬寄主。";

    TLWRecordResult *r_powdery = [TLWRecordResult new];
    r_powdery.pestName  = @"白粉病";
    r_powdery.confidence = 0.95f;
    r_powdery.solution  = @"喷施三唑酮（粉锈宁）或戊唑醇，重点喷施叶片正反两面。加强田间通风透光，降低株间湿度。";

    TLWRecordResult *r_rust = [TLWRecordResult new];
    r_rust.pestName  = @"锈病";
    r_rust.confidence = 0.89f;
    r_rust.solution  = @"喷施代森锰锌或三唑类杀菌剂，发病严重时可连续用药2~3次。合理密植，增强通风透光。";

    TLWRecordResult *r_anthr = [TLWRecordResult new];
    r_anthr.pestName  = @"炭疽病";
    r_anthr.confidence = 0.87f;
    r_anthr.solution  = @"发病初期喷施苯醚甲环唑或咪鲜胺，每隔7天喷1次，连续2~3次。注意雨后及时排水，避免湿度过高。";

    TLWRecordItem *item1 = [TLWRecordItem new];
    item1.recordId = @"1"; item1.imageURL = @""; item1.recordTime = @"2025-11-28 14:32";
    item1.results = @[r_aphid];

    TLWRecordItem *item2 = [TLWRecordItem new];
    item2.recordId = @"2"; item2.imageURL = @""; item2.recordTime = @"2025-11-28 12:10";
    item2.results = @[r_anthr, r_aphid];

    TLWRecordItem *item3 = [TLWRecordItem new];
    item3.recordId = @"3"; item3.imageURL = @""; item3.recordTime = @"2025-11-28 09:00";
    item3.results = @[r_powdery];

    TLWRecordItem *item4 = [TLWRecordItem new];
    item4.recordId = @"4"; item4.imageURL = @""; item4.recordTime = @"2025-11-28 08:45";
    item4.results = @[r_aphid];

    TLWRecordSection *sec1 = [TLWRecordSection new];
    sec1.dateString = @"2025-11-28";
    sec1.items = @[item1, item2, item3, item4];

    TLWRecordItem *item5 = [TLWRecordItem new];
    item5.recordId = @"5"; item5.imageURL = @""; item5.recordTime = @"2025-11-27 15:20";
    item5.results = @[r_powdery, r_rust];

    TLWRecordItem *item6 = [TLWRecordItem new];
    item6.recordId = @"6"; item6.imageURL = @""; item6.recordTime = @"2025-11-27 11:05";
    item6.results = @[r_rust];

    TLWRecordItem *item7 = [TLWRecordItem new];
    item7.recordId = @"7"; item7.imageURL = @""; item7.recordTime = @"2025-11-27 08:30";
    item7.results = @[r_aphid];

    TLWRecordSection *sec2 = [TLWRecordSection new];
    sec2.dateString = @"2025-11-27";
    sec2.items = @[item5, item6, item7];

    self.sections = @[sec1, sec2];
    [self tl_reloadData];
}

/// 统一刷新入口，同时控制空态 UI 的显隐
- (void)tl_reloadData {
    BOOL isEmpty = self.sections.count == 0;
    self.myView.emptyLabel.hidden  = !isEmpty;
    self.myView.collectionView.hidden = isEmpty;
    [self.myView.collectionView reloadData];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return self.sections.count;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.sections[section].items.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    TLWRecordCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kCellID forIndexPath:indexPath];
    TLWRecordItem *item = self.sections[indexPath.section].items[indexPath.row];
    [cell configureWithItem:item];
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView
           viewForSupplementaryElementOfKind:(NSString *)kind
                                 atIndexPath:(NSIndexPath *)indexPath {
    TLWRecordHeaderView *header = [collectionView dequeueReusableSupplementaryViewOfKind:kind
                                                                     withReuseIdentifier:kHeaderID
                                                                            forIndexPath:indexPath];
    [header configureWithDateString:self.sections[indexPath.section].dateString];
    return header;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    TLWRecordItem *item = self.sections[indexPath.section].items[indexPath.row];
    TLWRecordDetailController *detail = [[TLWRecordDetailController alloc] initWithItem:item];
    [self.navigationController pushViewController:detail animated:YES];
}

#pragma mark - Lifecycle

- (TLWRecordView *)myView {
    if (!_myView) {
        _myView = [[TLWRecordView alloc] initWithFrame:CGRectZero];
    }
    return _myView;
}

@end
