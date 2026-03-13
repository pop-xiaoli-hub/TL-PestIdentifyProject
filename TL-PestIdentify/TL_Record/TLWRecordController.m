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
#import <Masonry/Masonry.h>

static NSString *const kCellID   = @"TLWRecordCell";
static NSString *const kHeaderID = @"TLWRecordHeader";

@interface TLWRecordController () <UICollectionViewDataSource, UICollectionViewDelegate>
@property (nonatomic, strong) TLWRecordView *myView;
@property (nonatomic, strong) NSArray<TLWRecordSection *> *sections;
@end

@implementation TLWRecordController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view addSubview:self.myView];
    [self.myView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];

    UICollectionView *cv = self.myView.collectionView;
    cv.dataSource = self;
    cv.delegate   = self;
    [cv registerClass:[TLWRecordCell class]
           forCellWithReuseIdentifier:kCellID];
    [cv registerClass:[TLWRecordHeaderView class]
        forSupplementaryViewOfKind:UICollectionElementKindSectionHeader
               withReuseIdentifier:kHeaderID];

    [self.myView.backButton addTarget:self
                               action:@selector(tl_back)
                     forControlEvents:UIControlEventTouchUpInside];
    [self.myView.filterButton addTarget:self
                                 action:@selector(tl_filter)
                       forControlEvents:UIControlEventTouchUpInside];

    [self tl_fetchRecords];
}

#pragma mark - Actions

- (void)tl_back {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)tl_filter {
    // TODO: 展示筛选面板（按日期/病虫害类型过滤）
}

#pragma mark - Data

// TODO: 接口来了替换此方法内部实现，外部调用方式不变
// 预期接口格式：
// [{ "date": "2025-11-28", "items": [{ "recordId": "1", "pestName": "蚜虫", "imageURL": "https://..." }] }]
- (void)tl_fetchRecords {
    // Mock 数据
    TLWRecordItem *item1 = [TLWRecordItem new]; item1.pestName = @"蚜虫";  item1.imageURL = @"";
    TLWRecordItem *item2 = [TLWRecordItem new]; item2.pestName = @"蚜虫";  item2.imageURL = @"";
    TLWRecordItem *item3 = [TLWRecordItem new]; item3.pestName = @"蚜虫";  item3.imageURL = @"";
    TLWRecordItem *item4 = [TLWRecordItem new]; item4.pestName = @"蚜虫";  item4.imageURL = @"";

    TLWRecordSection *sec1 = [TLWRecordSection new];
    sec1.dateString = @"2025-11-28";
    sec1.items = @[item1, item2, item3, item4];

    TLWRecordItem *item5 = [TLWRecordItem new]; item5.pestName = @"白粉病"; item5.imageURL = @"";
    TLWRecordItem *item6 = [TLWRecordItem new]; item6.pestName = @"锈病";   item6.imageURL = @"";
    TLWRecordItem *item7 = [TLWRecordItem new]; item7.pestName = @"蚜虫";   item7.imageURL = @"";

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

#pragma mark - Lifecycle

- (TLWRecordView *)myView {
    if (!_myView) {
        _myView = [[TLWRecordView alloc] initWithFrame:CGRectZero];
    }
    return _myView;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:NO];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    // 在 pop 动画开始前恢复导航栏，避免过渡动画中导航栏突然闪现
    [self.navigationController setNavigationBarHidden:NO animated:NO];
}

@end
