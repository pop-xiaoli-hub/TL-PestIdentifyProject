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
#import "TLWSDKManager.h"
#import "TLWToast.h"
#import <AgriPestClient/AGAgentChatHistory.h>
#import <AgriPestClient/AGResultListAgentChatHistory.h>
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

- (void)tl_fetchRecords {
    __weak typeof(self) weakSelf = self;
    [[TLWSDKManager shared].api getHistoryWithCompletionHandler:^(AGResultListAgentChatHistory *output, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) self = weakSelf;
            if (!self) return;

            if (error) {
                [TLWToast show:@"加载识别记录失败"];
                self.sections = @[];
                [self tl_reloadData];
                return;
            }
            if (output.code.integerValue == 401) {
                [[TLWSDKManager shared] handleUnauthorizedWithRetry:^{
                    [self tl_fetchRecords];
                }];
                return;
            }
            if (output.code.integerValue != 200) {
                [TLWToast show:output.message ?: @"加载识别记录失败"];
                self.sections = @[];
                [self tl_reloadData];
                return;
            }

            NSArray<AGAgentChatHistory> *historyList = output.data ?: @[];
            self.sections = [self tl_buildSectionsFromHistory:historyList];
            [self tl_reloadData];
        });
    }];
}

/// 将 AGAgentChatHistory 数组转换为按日期分组的 TLWRecordSection 数组
- (NSArray<TLWRecordSection *> *)tl_buildSectionsFromHistory:(NSArray<AGAgentChatHistory> *)historyList {
    NSDateFormatter *dateFmt = [[NSDateFormatter alloc] init];
    dateFmt.dateFormat = @"yyyy-MM-dd";
    NSDateFormatter *timeFmt = [[NSDateFormatter alloc] init];
    timeFmt.dateFormat = @"yyyy-MM-dd HH:mm";

    // 按日期分组
    NSMutableDictionary<NSString *, NSMutableArray<TLWRecordItem *> *> *grouped = [NSMutableDictionary dictionary];
    NSMutableArray<NSString *> *dateOrder = [NSMutableArray array];

    for (AGAgentChatHistory *history in historyList) {
        TLWRecordItem *item = [TLWRecordItem new];
        item.recordId = [NSString stringWithFormat:@"%@", history._id ?: @(0)];
        item.imageURL = history.imageUrl ?: @"";

        if (history.createTime) {
            item.recordTime = [timeFmt stringFromDate:history.createTime];
        } else {
            item.recordTime = @"";
        }

        // 从 agentResponse 中提取病害名和解决方案
        TLWRecordResult *result = [TLWRecordResult new];
        result.pestName = [self tl_extractPestNameFromResponse:history.agentResponse
                                                    userQuery:history.userQuery];
        result.confidence = 0;
        result.solution = history.agentResponse ?: @"";
        item.results = @[result];

        NSString *dateKey = history.createTime ? [dateFmt stringFromDate:history.createTime] : @"未知日期";
        if (!grouped[dateKey]) {
            grouped[dateKey] = [NSMutableArray array];
            [dateOrder addObject:dateKey];
        }
        [grouped[dateKey] addObject:item];
    }

    NSMutableArray<TLWRecordSection *> *sections = [NSMutableArray array];
    for (NSString *date in dateOrder) {
        TLWRecordSection *sec = [TLWRecordSection new];
        sec.dateString = date;
        sec.items = [grouped[date] copy];
        [sections addObject:sec];
    }
    return [sections copy];
}

/// 从 agentResponse 中提取病害名称，优先取第一行或冒号前的关键词
- (NSString *)tl_extractPestNameFromResponse:(NSString *)response userQuery:(NSString *)userQuery {
    if (!response.length) {
        return userQuery.length ? userQuery : @"未知病害";
    }
    // 尝试从第一行提取（通常 Agent 回复开头会包含病害名）
    NSString *firstLine = [[response componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] firstObject];
    // 如果第一行太长（超过20字），可能不是病害名，截取前20字
    if (firstLine.length > 20) {
        firstLine = [firstLine substringToIndex:20];
    }
    return firstLine.length ? firstLine : @"识别结果";
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
