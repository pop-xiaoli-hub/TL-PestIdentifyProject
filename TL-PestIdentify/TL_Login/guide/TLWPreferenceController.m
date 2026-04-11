//
//  TLWPreferenceController.m
//  TL-PestIdentify
//
//  Created by 吴桐 on 2026/3/12.
//

#import "TLWPreferenceController.h"
#import "TLWPreferenceView.h"
#import "TLWMainTabBarController.h"
#import "TLWSDKManager.h"
#import "TLWCropCell.h"
#import "TLWCustomInputCell.h"
#import "TLWAddCropCell.h"
#import "TLWCropSectionHeaderView.h"
#import "TLWToast.h"
#import <Masonry/Masonry.h>

static NSString * const kCropCellID   = @"CropCell";
static NSString * const kInputCellID  = @"InputCell";
static NSString * const kAddCellID    = @"AddCell";
static NSString * const kHeaderViewID = @"HeaderView";

typedef NS_ENUM(NSInteger, TLWPrefSection) {
    TLWPrefSectionCustom    = 0,
    TLWPrefSectionGrain     = 1,   // 粮食作物
    TLWPrefSectionVegetable = 2,   // 蔬菜
    TLWPrefSectionFruit     = 3,   // 果树
};

@interface TLWPreferenceController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UITextFieldDelegate>
@property (nonatomic, strong) TLWPreferenceView *preferenceView;
@property (nonatomic, strong) NSMutableSet<NSString *> *selectedPlantNames;
@property (nonatomic, strong) NSMutableArray<NSString *> *customCrops;
@property (nonatomic, strong) NSArray<NSArray<NSString *> *> *plantSections;  // grain / veg / fruit
@property (nonatomic, copy)   NSString *currentInputText;
@end

@implementation TLWPreferenceController

- (void)loadView {
    self.preferenceView = [[TLWPreferenceView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.view = self.preferenceView;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    _selectedPlantNames  = [NSMutableSet set];
    _customCrops         = [NSMutableArray array];
    _currentInputText    = @"";

    _plantSections = @[
        @[@"小麦", @"水稻", @"玉米"],
        @[@"白菜", @"萝卜", @"莲藕", @"芋头", @"黄瓜", @"番茄", @"茄子", @"辣椒", @"香菇"],
        @[@"桃子", @"梨", @"杏树", @"葡萄", @"苹果", @"李子", @"杨梅"],
    ];

    UICollectionView *cv = self.preferenceView.collectionView;
    [cv registerClass:[TLWCropCell class]        forCellWithReuseIdentifier:kCropCellID];
    [cv registerClass:[TLWCustomInputCell class] forCellWithReuseIdentifier:kInputCellID];
    [cv registerClass:[TLWAddCropCell class]     forCellWithReuseIdentifier:kAddCellID];
    [cv registerClass:[TLWCropSectionHeaderView class]
           forSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                  withReuseIdentifier:kHeaderViewID];
    cv.dataSource = self;
    cv.delegate   = self;
    cv.allowsMultipleSelection = YES;

    [self.preferenceView.confirmButton addTarget:self
                                          action:@selector(handleConfirm)
                                forControlEvents:UIControlEventTouchUpInside];

    // 点击空白处收起键盘
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                          action:@selector(dismissKeyboard)];
    tap.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tap];
}

- (void)dismissKeyboard {
    [self.view endEditing:YES];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)cv {
    return 4;
}

- (NSInteger)collectionView:(UICollectionView *)cv numberOfItemsInSection:(NSInteger)section {
    if (section == TLWPrefSectionCustom) {
        return (NSInteger)_customCrops.count + 2;  // 自定义 crops + 输入框 + "+" 按钮
    }
    return (NSInteger)[_plantSections[section - 1] count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == TLWPrefSectionCustom) {
        NSInteger inputIndex = (NSInteger)_customCrops.count;
        NSInteger addIndex   = inputIndex + 1;

        if (indexPath.item < inputIndex) {
            // 已添加的自定义农作物
            TLWCropCell *cell = [cv dequeueReusableCellWithReuseIdentifier:kCropCellID forIndexPath:indexPath];
            NSString *name = _customCrops[indexPath.item];
            cell.nameLabel.text = name;
            BOOL sel = [_selectedPlantNames containsObject:name];
            cell.selected = sel;
            if (sel) {
                [cv selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
            } else {
                [cv deselectItemAtIndexPath:indexPath animated:NO];
            }
            return cell;

        } else if (indexPath.item == inputIndex) {
            // 输入框 cell
            TLWCustomInputCell *cell = [cv dequeueReusableCellWithReuseIdentifier:kInputCellID forIndexPath:indexPath];
            cell.textField.text = _currentInputText;
            cell.textField.delegate = self;
            [cell.textField removeTarget:nil action:nil forControlEvents:UIControlEventEditingChanged];
            [cell.textField addTarget:self action:@selector(inputTextChanged:) forControlEvents:UIControlEventEditingChanged];
            return cell;

        } else {
            // "+" 添加按钮 cell
            return [cv dequeueReusableCellWithReuseIdentifier:kAddCellID forIndexPath:indexPath];
        }
    }

    // 粮食 / 蔬菜 / 果树
    TLWCropCell *cell = [cv dequeueReusableCellWithReuseIdentifier:kCropCellID forIndexPath:indexPath];
    NSString *name = _plantSections[indexPath.section - 1][indexPath.item];
    cell.nameLabel.text = name;
    BOOL sel = [_selectedPlantNames containsObject:name];
    cell.selected = sel;
    if (sel) {
        [cv selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
    } else {
        [cv deselectItemAtIndexPath:indexPath animated:NO];
    }
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)cv
           viewForSupplementaryElementOfKind:(NSString *)kind
                                 atIndexPath:(NSIndexPath *)indexPath {
    TLWCropSectionHeaderView *header = [cv dequeueReusableSupplementaryViewOfKind:kind
                                                               withReuseIdentifier:kHeaderViewID
                                                                      forIndexPath:indexPath];
    NSArray *titles = @[@"自定义作物", @"粮食作物", @"蔬菜", @"果树"];
    header.titleLabel.text = titles[indexPath.section];
    return header;
}

#pragma mark - UICollectionViewDelegate

- (BOOL)collectionView:(UICollectionView *)cv shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == TLWPrefSectionCustom) {
        NSInteger inputIndex = (NSInteger)_customCrops.count;
        return indexPath.item != inputIndex;  // 输入框不可"选中"
    }
    return YES;
}

- (void)collectionView:(UICollectionView *)cv didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == TLWPrefSectionCustom) {
        NSInteger addIndex = (NSInteger)_customCrops.count + 1;
        if (indexPath.item == addIndex) {
            // 点击 "+" — 添加农作物
            [cv deselectItemAtIndexPath:indexPath animated:NO];
            [self addCustomCrop];
            return;
        }
        // 选中自定义农作物
        if (indexPath.item < (NSInteger)_customCrops.count) {
            [_selectedPlantNames addObject:_customCrops[indexPath.item]];
        }
        return;
    }
    NSString *name = _plantSections[indexPath.section - 1][indexPath.item];
    [_selectedPlantNames addObject:name];
}

- (void)collectionView:(UICollectionView *)cv didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == TLWPrefSectionCustom) {
        if (indexPath.item < (NSInteger)_customCrops.count) {
            [_selectedPlantNames removeObject:_customCrops[indexPath.item]];
        }
        return;
    }
    NSString *name = _plantSections[indexPath.section - 1][indexPath.item];
    [_selectedPlantNames removeObject:name];
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)cv
                  layout:(UICollectionViewLayout *)layout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat margin  = 22.0;
    CGFloat gap     = 10.0;
    CGFloat columns = 3.0;
    CGFloat cellW = floor((cv.bounds.size.width - 2 * margin - (columns - 1) * gap) / columns);
    return CGSizeMake(cellW, 71);
}

- (CGSize)collectionView:(UICollectionView *)cv
                  layout:(UICollectionViewLayout *)layout
referenceSizeForHeaderInSection:(NSInteger)section {
    return CGSizeMake(cv.bounds.size.width - 44, 36);
}

#pragma mark - UITextField tracking

- (void)inputTextChanged:(UITextField *)textField {
    _currentInputText = textField.text ?: @"";
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self addCustomCrop];
    return YES;
}

#pragma mark - Add custom crop

- (void)addCustomCrop {
    NSString *text = [_currentInputText stringByTrimmingCharactersInSet:
                      [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (text.length == 0) return;

    // 不允许重复
    if ([_customCrops containsObject:text]) return;
    for (NSArray *section in _plantSections) {
        if ([section containsObject:text]) return;
    }

    NSInteger insertPos = (NSInteger)_customCrops.count;  // 在输入框前插入
    [_customCrops addObject:text];
    _currentInputText = @"";

    UICollectionView *cv = self.preferenceView.collectionView;
    NSIndexPath *newIP = [NSIndexPath indexPathForItem:insertPos inSection:TLWPrefSectionCustom];

    [cv performBatchUpdates:^{
        [cv insertItemsAtIndexPaths:@[newIP]];
    } completion:^(BOOL finished) {
        // 清空输入框并收起键盘
        NSIndexPath *inputIP = [NSIndexPath indexPathForItem:(NSInteger)self->_customCrops.count
                                                   inSection:TLWPrefSectionCustom];
        TLWCustomInputCell *inputCell = (TLWCustomInputCell *)[cv cellForItemAtIndexPath:inputIP];
        inputCell.textField.text = @"";
        [inputCell.textField resignFirstResponder];
    }];
}

#pragma mark - Actions

- (void)handleConfirm {
    NSLog(@"用户选择的农作物: %@", _selectedPlantNames);
    AGProfileUpdateRequest *req = [[AGProfileUpdateRequest alloc] init];
    req.followedCrops = [_selectedPlantNames allObjects];
    TLWSDKManager *manager = [TLWSDKManager shared];
    __weak typeof(self) weakSelf = self;

    __block void (^savePreferenceBlock)(BOOL);
    savePreferenceBlock = ^(BOOL didRetryAuth) {
        [manager.api updateProfileWithProfileUpdateRequest:req completionHandler:^(AGResultUserProfileDto *output, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong typeof(weakSelf) strongSelf = weakSelf;
                if (!strongSelf) return;

                if (!didRetryAuth
                    && [manager.sessionManager handleAuthFailureForCode:output.code
                                                               message:output.message
                                                            retryBlock:^{
                    savePreferenceBlock(YES);
                }]) {
                    return;
                }

                if (error || output.code.integerValue != 200) {
                    NSLog(@"偏好保存失败: %@", error.localizedDescription ?: output.message);
                    NSString *message = [manager.sessionManager userFacingMessageForError:error
                                                                                     code:output.code
                                                                            serverMessage:output.message
                                                                           defaultMessage:@"偏好同步失败，已进入首页"];
                    [TLWToast show:message];
                    [strongSelf navigateToMain];
                    return;
                }

                [manager.sessionManager fetchProfileWithCompletion:^(AGUserProfileDto *profile) {
                    [strongSelf navigateToMain];
                }];
            });
        }];
    };

    savePreferenceBlock(NO);
}

- (void)navigateToMain {
    TLWMainTabBarController *tabBar = [[TLWMainTabBarController alloc] init];
    UIWindow *window = self.view.window;
    window.rootViewController = tabBar;
    [UIView transitionWithView:window
                      duration:0.3
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:nil
                    completion:nil];
}

@end
