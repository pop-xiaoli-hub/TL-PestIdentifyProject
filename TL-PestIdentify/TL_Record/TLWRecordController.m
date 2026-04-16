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
#import "TLWLoadingIndicator.h"
#import "TLWToast.h"
#import <AgriPestClient/AGAgentChatHistory.h>
#import <AgriPestClient/AGResultListAgentChatHistory.h>
#import <AgriPestClient/AGDefaultConfiguration.h>
#import <Masonry/Masonry.h>

static NSString *const kCellID   = @"TLWRecordCell";
static NSString *const kHeaderID = @"TLWRecordHeader";

@interface TLWRecordController () <UICollectionViewDataSource, UICollectionViewDelegate>
@property (nonatomic, strong) TLWRecordView *myView;
@property (nonatomic, strong) NSArray<TLWRecordSection *> *sections;
@property (nonatomic, strong) NSArray<AGAgentChatHistory> *allHistoryList;
@property (nonatomic, assign) BOOL isLoading;
@property (nonatomic, strong) UIView *filterMaskView;
@property (nonatomic, strong) UIView *filterPanelView;
@property (nonatomic, strong) UILabel *filterYearLabel;
@property (nonatomic, strong) NSArray<UIButton *> *monthButtons;
@property (nonatomic, assign) NSInteger selectedFilterYear;
@property (nonatomic, assign) NSInteger selectedFilterMonth;
@property (nonatomic, assign) NSInteger pendingFilterYear;
@property (nonatomic, assign) NSInteger pendingFilterMonth;
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

  //  [self tl_debugFetchHistoryWithoutSDK];
    [self tl_fetchRecords];
}

#pragma mark - Actions

- (void)tl_filter {
    [self tl_preparePendingFilter];
    [self tl_updateFilterPanelSelection];
    [self tl_showFilterPanel];
}

#pragma mark - Data

- (void)tl_debugFetchHistoryWithoutSDK {
    NSString *token = [AGDefaultConfiguration sharedConfig].accessToken ?: @"";
    if (token.length == 0) {
        NSLog(@"[RecordDebug] accessToken 为空，无法直连识别历史接口");
        return;
    }

    NSURL *url = [NSURL URLWithString:@"http://115.191.67.35:8080/api/v1/agent/history"];
    if (!url) {
        NSLog(@"[RecordDebug] 识别历史接口 URL 无效");
        return;
    }

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"GET";
    [request setValue:@"*/*" forHTTPHeaderField:@"Accept"];
    [request setValue:[NSString stringWithFormat:@"Bearer %@", token] forHTTPHeaderField:@"Authorization"];

    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request
                                                                 completionHandler:^(NSData * _Nullable data,
                                                                                     NSURLResponse * _Nullable response,
                                                                                     NSError * _Nullable error) {
        if (error) {
            NSLog(@"[RecordDebug] 直连识别历史失败: %@", error.localizedDescription);
            return;
        }

        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        NSLog(@"[RecordDebug] 直连识别历史 status=%ld", (long)httpResponse.statusCode);

        if (data.length == 0) {
            NSLog(@"[RecordDebug] 直连识别历史返回空数据");
            return;
        }

        NSError *jsonError = nil;
        id jsonObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        if (jsonError || ![jsonObject isKindOfClass:[NSDictionary class]]) {
            NSString *raw = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSLog(@"[RecordDebug] JSON 解析失败: %@ raw=%@", jsonError.localizedDescription, raw ?: @"<nil>");
            return;
        }

        NSDictionary *dictionary = (NSDictionary *)jsonObject;
        NSArray *historyList = [dictionary[@"data"] isKindOfClass:[NSArray class]] ? dictionary[@"data"] : @[];
        NSLog(@"[RecordDebug] 直连识别历史条数=%lu", (unsigned long)historyList.count);

        [historyList enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (![obj isKindOfClass:[NSDictionary class]]) {
                return;
            }
            NSDictionary *item = (NSDictionary *)obj;
            NSString *imageURL = [item[@"imageUrl"] isKindOfClass:[NSString class]] ? item[@"imageUrl"] : @"";
            NSString *prefix = [imageURL substringToIndex:MIN((NSUInteger)80, imageURL.length)];
            NSString *suffix = imageURL.length > 80 ? [imageURL substringFromIndex:imageURL.length - 80] : imageURL;
            NSLog(@"[RecordDebug] item[%lu] imageUrl.length=%lu", (unsigned long)idx, (unsigned long)imageURL.length);
            NSLog(@"[RecordDebug] item[%lu] imageUrl.prefix=%@", (unsigned long)idx, prefix);
            NSLog(@"[RecordDebug] item[%lu] imageUrl.suffix=%@", (unsigned long)idx, suffix);
        }];
    }];
    [task resume];
}

- (void)tl_fetchRecords {
    [self tl_setLoading:YES];
    __weak typeof(self) weakSelf = self;
    [[TLWSDKManager shared].api getHistoryWithCompletionHandler:^(AGResultListAgentChatHistory *output, NSError *error) {
      NSArray* array = output.data;
      for (AGAgentChatHistory* model in array) {
        NSLog(@"识别机录：%@", model.agentResponse);
      }
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) self = weakSelf;
            if (!self) return;

            if (error) {
                [self tl_setLoading:NO];
                [TLWToast show:@"加载识别记录失败"];
                self.sections = @[];
                [self tl_reloadData];
                return;
            }
            if ([[TLWSDKManager shared].sessionManager shouldAttemptTokenRefreshForCode:output.code]) {
                [[TLWSDKManager shared].sessionManager handleUnauthorizedWithRetry:^{
                    [self tl_fetchRecords];
                }];
                return;
            }
            if (output.code.integerValue != 200) {
                [self tl_setLoading:NO];
                [TLWToast show:output.message ?: @"加载识别记录失败"];
                self.sections = @[];
                [self tl_reloadData];
                return;
            }

            NSArray<AGAgentChatHistory> *historyList = output.data ?: @[];
            self.allHistoryList = historyList;
            [self tl_prepareDefaultFilterIfNeededWithHistory:historyList];
            [self tl_setLoading:NO];
            self.sections = [self tl_buildSectionsFromHistory:[self tl_filteredHistoryListFromHistory:historyList]];
            [self tl_reloadData];
        });
    }];
}

/// 将 AGAgentChatHistory 数组转换为按日期分组的 TLWRecordSection 数组
- (NSArray<TLWRecordSection *> *)tl_buildSectionsFromHistory:(NSArray<AGAgentChatHistory> *)historyList {
    NSDateFormatter *dateFmt = [[NSDateFormatter alloc] init];
    dateFmt.dateFormat = @"yyyy-MM-dd";//分组时间
    NSDateFormatter *timeFmt = [[NSDateFormatter alloc] init];
    timeFmt.dateFormat = @"yyyy-MM-dd HH:mm";//展示时间

    // 按日期分组
    NSMutableDictionary<NSString *, NSMutableArray<TLWRecordItem *> *> *grouped = [NSMutableDictionary dictionary];
    NSMutableArray<NSString *> *dateOrder = [NSMutableArray array];

    for (AGAgentChatHistory *history in historyList) {
        TLWRecordItem *item = [TLWRecordItem new];
        item.recordId = [NSString stringWithFormat:@"%@", history._id ?: @(0)];
        item.imageURL = history.imageUrl ?: @"";
      NSLog(@"识别记录的图像URL：%@", item.imageURL);

        if (history.createTime) {
            item.recordTime = [timeFmt stringFromDate:history.createTime];
        } else {
            item.recordTime = @"";
        }

        item.results = [TLWRecordResult resultsFromAgentResponse:history.agentResponse
                                                   fallbackQuery:history.userQuery];

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

- (NSArray<AGAgentChatHistory> *)tl_filteredHistoryListFromHistory:(NSArray<AGAgentChatHistory> *)historyList {
    if (self.selectedFilterYear <= 0 || self.selectedFilterMonth <= 0) {
        return historyList ?: @[];
    }

    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSMutableArray<AGAgentChatHistory> *filtered = [NSMutableArray array];
    for (AGAgentChatHistory *history in historyList) {
        NSDate *date = history.createTime;
        if (!date) {
            continue;
        }
        NSDateComponents *components = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth fromDate:date];
        if (components.year == self.selectedFilterYear && components.month == self.selectedFilterMonth) {
            [filtered addObject:history];
        }
    }
    return [filtered copy];
}

/// 统一刷新入口，同时控制空态 UI 的显隐
- (void)tl_reloadData {
    BOOL isEmpty = self.sections.count == 0;
    self.myView.emptyLabel.hidden = self.isLoading || !isEmpty;
    self.myView.collectionView.hidden = NO;
    [self.myView.collectionView reloadData];
}

- (void)tl_setLoading:(BOOL)isLoading {
    self.isLoading = isLoading;
    self.myView.emptyLabel.hidden = YES;
    self.myView.collectionView.hidden = NO;

    if (isLoading) {
        [TLWLoadingIndicator showInView:self.myView.collectionView];
    } else {
        [TLWLoadingIndicator hideInView:self.myView.collectionView];
    }
}

#pragma mark - Filter Panel
//设置默认筛选年月
- (void)tl_prepareDefaultFilterIfNeededWithHistory:(NSArray<AGAgentChatHistory> *)historyList {
    if (self.selectedFilterYear > 0 && self.selectedFilterMonth > 0) {
        return;
    }

  //设置一个参考日期，由于接口返回的是倒序，所以是最新识别记录
    NSDate *referenceDate = nil;
    for (AGAgentChatHistory *history in historyList) {
        if (history.createTime) {
            referenceDate = history.createTime;
            break;
        }
    }
  //都没有创建时间就默认当前时间筛选
    if (!referenceDate) {
        referenceDate = [NSDate date];
    }

    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitYear | NSCalendarUnitMonth fromDate:referenceDate];
    self.selectedFilterYear = components.year;
    self.selectedFilterMonth = components.month;
}

- (void)tl_preparePendingFilter {
    if (self.selectedFilterYear <= 0 || self.selectedFilterMonth <= 0) {
        [self tl_prepareDefaultFilterIfNeededWithHistory:self.allHistoryList];
    }
    self.pendingFilterYear = self.selectedFilterYear;
    self.pendingFilterMonth = self.selectedFilterMonth;
}

- (void)tl_showFilterPanel {
    if (!self.filterMaskView) {
        [self tl_buildFilterPanelIfNeeded];
    }
    self.filterMaskView.hidden = NO;
    self.filterMaskView.alpha = 0.0;
    self.filterPanelView.transform = CGAffineTransformMakeScale(0.96, 0.96);
    [UIView animateWithDuration:0.22 animations:^{
        self.filterMaskView.alpha = 1.0;
        self.filterPanelView.transform = CGAffineTransformIdentity;
    }];
}

- (void)tl_hideFilterPanel {
    if (!self.filterMaskView || self.filterMaskView.hidden) {
        return;
    }
    [UIView animateWithDuration:0.2 animations:^{
        self.filterMaskView.alpha = 0.0;
        self.filterPanelView.transform = CGAffineTransformMakeScale(0.96, 0.96);
    } completion:^(BOOL finished) {
        self.filterMaskView.hidden = YES;
        self.filterPanelView.transform = CGAffineTransformIdentity;
    }];
}

- (void)tl_buildFilterPanelIfNeeded {
    UIView *maskView = [[UIView alloc] init];
    maskView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.16];
    maskView.hidden = YES;
    [self.view addSubview:maskView];
    [maskView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    self.filterMaskView = maskView;

    UIButton *dismissButton = [UIButton buttonWithType:UIButtonTypeCustom];
    dismissButton.backgroundColor = [UIColor clearColor];
    [dismissButton addTarget:self action:@selector(tl_hideFilterPanel) forControlEvents:UIControlEventTouchUpInside];
    [maskView addSubview:dismissButton];
    [dismissButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(maskView);
    }];

    UIView *panel = [[UIView alloc] init];
    panel.backgroundColor = [UIColor whiteColor];
    panel.layer.cornerRadius = 20.0;
    panel.layer.masksToBounds = YES;
    [maskView addSubview:panel];
    self.filterPanelView = panel;
    [panel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(maskView).offset(28);
        make.right.equalTo(maskView).offset(-28);
        make.top.equalTo(maskView).offset(92);
    }];

    UIButton *prevButton = [self tl_filterArrowButtonWithTitle:@"←"];
    prevButton.tag = -1;
    [prevButton addTarget:self action:@selector(tl_changeFilterYear:) forControlEvents:UIControlEventTouchUpInside];
    [panel addSubview:prevButton];

    UIButton *nextButton = [self tl_filterArrowButtonWithTitle:@"→"];
    nextButton.tag = 1;
    [nextButton addTarget:self action:@selector(tl_changeFilterYear:) forControlEvents:UIControlEventTouchUpInside];
    [panel addSubview:nextButton];

    UILabel *yearLabel = [[UILabel alloc] init];
    yearLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightSemibold];
    yearLabel.textColor = [UIColor colorWithWhite:0.25 alpha:1.0];
    yearLabel.textAlignment = NSTextAlignmentCenter;
    [panel addSubview:yearLabel];
    self.filterYearLabel = yearLabel;

    [prevButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(panel).offset(26);
        make.top.equalTo(panel).offset(20);
        make.width.height.mas_equalTo(40);
    }];
    [nextButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(panel).offset(-26);
        make.centerY.equalTo(prevButton);
        make.width.height.mas_equalTo(40);
    }];
    [yearLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(prevButton);
        make.centerX.equalTo(panel);
    }];

    NSArray<NSString *> *months = @[@"一月", @"二月", @"三月", @"四月", @"五月",
                                    @"六月", @"七月", @"八月", @"九月", @"十月",
                                    @"十一月", @"十二月"];
    NSMutableArray<UIButton *> *buttons = [NSMutableArray array];
    NSInteger columnCount = 5;
    CGFloat horizontalInset = 18.0;
    CGFloat buttonWidth = (UIScreen.mainScreen.bounds.size.width - 56.0 - horizontalInset * 2) / 5.0;
    CGFloat buttonHeight = 40.0;
    CGFloat topStart = 88.0;
    CGFloat rowSpacing = 22.0;

    for (NSInteger index = 0; index < months.count; index++) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button setTitle:months[index] forState:UIControlStateNormal];
        [button setTitleColor:[UIColor colorWithWhite:0.65 alpha:1.0] forState:UIControlStateNormal];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
        button.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
        button.layer.cornerRadius = 6.0;
        button.tag = index + 1;
        [button addTarget:self action:@selector(tl_monthButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [panel addSubview:button];
        [buttons addObject:button];

        NSInteger row = index / columnCount;
        NSInteger column = index % columnCount;
        CGFloat left = horizontalInset + column * buttonWidth;
        CGFloat top = topStart + row * (buttonHeight + rowSpacing);
        [button mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(panel).offset(left);
            make.top.equalTo(panel).offset(top);
            make.width.mas_equalTo(buttonWidth);
            make.height.mas_equalTo(buttonHeight);
        }];
    }
    self.monthButtons = [buttons copy];

    UIView *line = [[UIView alloc] init];
    line.backgroundColor = [UIColor colorWithWhite:0.93 alpha:1.0];
    [panel addSubview:line];
    [line mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(panel);
        make.top.equalTo(panel).offset(280);
        make.height.mas_equalTo(1.0);
    }];

    UIButton *confirmButton = [self tl_filterActionButtonWithTitle:@"确认" filled:YES];
    [confirmButton addTarget:self action:@selector(tl_confirmFilterSelection) forControlEvents:UIControlEventTouchUpInside];
    [panel addSubview:confirmButton];

    UIButton *cancelButton = [self tl_filterActionButtonWithTitle:@"取消" filled:NO];
    [cancelButton addTarget:self action:@selector(tl_hideFilterPanel) forControlEvents:UIControlEventTouchUpInside];
    [panel addSubview:cancelButton];

    [confirmButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(line.mas_bottom).offset(12);
        make.right.equalTo(panel.mas_centerX).offset(-10);
        make.width.mas_equalTo(88);
        make.height.mas_equalTo(38);
        make.bottom.equalTo(panel).offset(-14);
    }];
    [cancelButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(confirmButton);
        make.left.equalTo(panel.mas_centerX).offset(10);
        make.width.height.equalTo(confirmButton);
    }];
}

- (UIButton *)tl_filterArrowButtonWithTitle:(NSString *)title {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:[UIColor colorWithRed:1.0 green:0.69 blue:0.12 alpha:1.0] forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:24 weight:UIFontWeightSemibold];
    button.layer.cornerRadius = 20.0;
    button.layer.borderWidth = 1.0;
    button.layer.borderColor = [UIColor colorWithWhite:0.9 alpha:1.0].CGColor;
    button.backgroundColor = [UIColor whiteColor];
    return button;
}

- (UIButton *)tl_filterActionButtonWithTitle:(NSString *)title filled:(BOOL)filled {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setTitle:title forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    button.layer.cornerRadius = 6.0;
    button.layer.borderWidth = filled ? 0.0 : 1.0;
    if (filled) {
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        button.backgroundColor = [UIColor colorWithRed:1.0 green:0.69 blue:0.12 alpha:1.0];
    } else {
        [button setTitleColor:[UIColor colorWithRed:1.0 green:0.69 blue:0.12 alpha:1.0] forState:UIControlStateNormal];
        button.backgroundColor = [UIColor whiteColor];
        button.layer.borderColor = [UIColor colorWithRed:1.0 green:0.69 blue:0.12 alpha:1.0].CGColor;
    }
    return button;
}

- (void)tl_changeFilterYear:(UIButton *)sender {
    self.pendingFilterYear += sender.tag;
    [self tl_updateFilterPanelSelection];
}

- (void)tl_monthButtonTapped:(UIButton *)sender {
    self.pendingFilterMonth = sender.tag;
    [self tl_updateFilterPanelSelection];
}

- (void)tl_updateFilterPanelSelection {
    self.filterYearLabel.text = [NSString stringWithFormat:@"%ld年", (long)self.pendingFilterYear];
    for (UIButton *button in self.monthButtons) {
        BOOL selected = (button.tag == self.pendingFilterMonth);
        button.selected = selected;
        button.backgroundColor = selected ? [UIColor colorWithRed:1.0 green:0.69 blue:0.12 alpha:1.0] : [UIColor clearColor];
    }
}

- (void)tl_confirmFilterSelection {
    self.selectedFilterYear = self.pendingFilterYear;
    self.selectedFilterMonth = self.pendingFilterMonth;
    self.sections = [self tl_buildSectionsFromHistory:[self tl_filteredHistoryListFromHistory:self.allHistoryList]];
    [self tl_reloadData];
    [self tl_hideFilterPanel];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    if (self.isLoading) {
        return 0;
    }
    return self.sections.count;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.sections[section].items.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    TLWRecordCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kCellID forIndexPath:indexPath];
    TLWRecordItem *item = self.sections[indexPath.section].items[indexPath.row];
  NSLog(@"2pestName:%@",item.topPestName);
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
