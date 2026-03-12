//
//  TWLPreferenceViewController.m
//  TL-PestIdentify
//

#import "TWLPreferenceViewController.h"
#import "TWLPreferenceView.h"
#import "TLWMainTabBarController.h"
#import <Masonry/Masonry.h>

// ─────────────────────────────────────────────
#pragma mark - TWLCropCell
// ─────────────────────────────────────────────

@interface TWLCropCell : UICollectionViewCell
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) CAGradientLayer *selectedGradient;
@end

@implementation TWLCropCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (!self) return nil;

    self.layer.cornerRadius = 13;
    self.clipsToBounds = YES;

    // Normal background — cropRectangle frosted glass image
    UIImageView *bgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cropRectangle"]];
    bgView.contentMode = UIViewContentModeScaleToFill;
    bgView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    bgView.frame = self.contentView.bounds;
    [self.contentView addSubview:bgView];

    // Selected: green gradient overlay
    _selectedGradient = [CAGradientLayer layer];
    _selectedGradient.colors = @[
        (__bridge id)[UIColor colorWithRed:0.0 green:1.0 blue:0.588 alpha:1.0].CGColor,
        (__bridge id)[UIColor colorWithRed:0.0 green:0.812 blue:0.773 alpha:1.0].CGColor,
    ];
    _selectedGradient.startPoint = CGPointMake(0.05, 0.1);
    _selectedGradient.endPoint   = CGPointMake(1.0,  0.9);
    _selectedGradient.cornerRadius = 13;
    _selectedGradient.hidden = YES;
    [self.contentView.layer addSublayer:_selectedGradient];

    // Name label
    _nameLabel = [[UILabel alloc] init];
    _nameLabel.font          = [UIFont systemFontOfSize:20];
    _nameLabel.textColor     = [UIColor colorWithRed:0.176 green:0.176 blue:0.176 alpha:1.0];
    _nameLabel.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:_nameLabel];
    _nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [_nameLabel.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor],
        [_nameLabel.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
    ]];

    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _selectedGradient.frame = self.contentView.bounds;
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    _selectedGradient.hidden = !selected;
    _nameLabel.textColor = selected
        ? UIColor.whiteColor
        : [UIColor colorWithRed:0.176 green:0.176 blue:0.176 alpha:1.0];
    _nameLabel.font = selected
        ? [UIFont systemFontOfSize:20 weight:UIFontWeightBold]
        : [UIFont systemFontOfSize:20];
}

@end

// ─────────────────────────────────────────────
#pragma mark - TWLCustomInputCell
// ─────────────────────────────────────────────

@interface TWLCustomInputCell : UICollectionViewCell
@property (nonatomic, strong) UITextField *textField;
@end

@implementation TWLCustomInputCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (!self) return nil;

    self.layer.cornerRadius = 13;
    self.clipsToBounds = YES;

    UIImageView *bgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cropRectangle"]];
    bgView.contentMode = UIViewContentModeScaleToFill;
    bgView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    bgView.frame = self.contentView.bounds;
    [self.contentView addSubview:bgView];

    _textField = [[UITextField alloc] init];
    _textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"请输入" attributes:@{
        NSForegroundColorAttributeName: [UIColor colorWithRed:0.569 green:0.569 blue:0.569 alpha:1.0],
        NSFontAttributeName:            [UIFont systemFontOfSize:20],
    }];
    _textField.textColor     = [UIColor colorWithRed:0.176 green:0.176 blue:0.176 alpha:1.0];
    _textField.font          = [UIFont systemFontOfSize:20];
    _textField.textAlignment = NSTextAlignmentCenter;
    _textField.borderStyle   = UITextBorderStyleNone;
    _textField.backgroundColor = UIColor.clearColor;
    _textField.returnKeyType = UIReturnKeyDone;
    [self.contentView addSubview:_textField];
    _textField.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [_textField.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor],
        [_textField.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
        [_textField.leftAnchor  constraintEqualToAnchor:self.contentView.leftAnchor  constant:8],
        [_textField.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-8],
    ]];

    return self;
}

@end

// ─────────────────────────────────────────────
#pragma mark - TWLAddCropCell  ("+" button)
// ─────────────────────────────────────────────

@interface TWLAddCropCell : UICollectionViewCell
@end

@implementation TWLAddCropCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (!self) return nil;

    self.layer.cornerRadius = 13;
    self.clipsToBounds = YES;

    UIImageView *bgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cropRectangle"]];
    bgView.contentMode = UIViewContentModeScaleToFill;
    bgView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    bgView.frame = self.contentView.bounds;
    [self.contentView addSubview:bgView];

    UIImageView *addIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"iconAdd"]];
    addIcon.contentMode = UIViewContentModeScaleAspectFit;
    [self.contentView addSubview:addIcon];
    addIcon.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [addIcon.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor],
        [addIcon.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
        [addIcon.widthAnchor  constraintEqualToConstant:28],
        [addIcon.heightAnchor constraintEqualToConstant:28],
    ]];

    return self;
}

@end

// ─────────────────────────────────────────────
#pragma mark - TWLCropSectionHeaderView
// ─────────────────────────────────────────────

@interface TWLCropSectionHeaderView : UICollectionReusableView
@property (nonatomic, strong) UILabel *titleLabel;
@end

@implementation TWLCropSectionHeaderView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (!self) return nil;

    _titleLabel = [[UILabel alloc] init];
    _titleLabel.font      = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
    _titleLabel.textColor = [UIColor colorWithRed:0.176 green:0.176 blue:0.176 alpha:0.8];
    [self addSubview:_titleLabel];
    _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [_titleLabel.leftAnchor constraintEqualToAnchor:self.leftAnchor constant:0],
        [_titleLabel.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-4],
    ]];

    return self;
}

@end

// ─────────────────────────────────────────────
#pragma mark - TWLPreferenceViewController
// ─────────────────────────────────────────────

static NSString * const kCropCellID   = @"CropCell";
static NSString * const kInputCellID  = @"InputCell";
static NSString * const kAddCellID    = @"AddCell";
static NSString * const kHeaderViewID = @"HeaderView";

typedef NS_ENUM(NSInteger, TWLPrefSection) {
    TWLPrefSectionCustom    = 0,
    TWLPrefSectionGrain     = 1,   // 粮食作物
    TWLPrefSectionVegetable = 2,   // 蔬菜
    TWLPrefSectionFruit     = 3,   // 果树
};

@interface TWLPreferenceViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UITextFieldDelegate>
@property (nonatomic, strong) TWLPreferenceView *preferenceView;
@property (nonatomic, strong) NSMutableSet<NSString *> *selectedPlantNames;
@property (nonatomic, strong) NSMutableArray<NSString *> *customCrops;
@property (nonatomic, strong) NSArray<NSArray<NSString *> *> *plantSections;  // grain / veg / fruit
@property (nonatomic, copy)   NSString *currentInputText;
@end

@implementation TWLPreferenceViewController

- (void)loadView {
    self.preferenceView = [[TWLPreferenceView alloc] initWithFrame:[UIScreen mainScreen].bounds];
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
    [cv registerClass:[TWLCropCell class]        forCellWithReuseIdentifier:kCropCellID];
    [cv registerClass:[TWLCustomInputCell class] forCellWithReuseIdentifier:kInputCellID];
    [cv registerClass:[TWLAddCropCell class]     forCellWithReuseIdentifier:kAddCellID];
    [cv registerClass:[TWLCropSectionHeaderView class]
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
    if (section == TWLPrefSectionCustom) {
        return (NSInteger)_customCrops.count + 2;  // 自定义 crops + 输入框 + "+" 按钮
    }
    return (NSInteger)[_plantSections[section - 1] count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == TWLPrefSectionCustom) {
        NSInteger inputIndex = (NSInteger)_customCrops.count;
        NSInteger addIndex   = inputIndex + 1;

        if (indexPath.item < inputIndex) {
            // 已添加的自定义农作物
            TWLCropCell *cell = [cv dequeueReusableCellWithReuseIdentifier:kCropCellID forIndexPath:indexPath];
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
            TWLCustomInputCell *cell = [cv dequeueReusableCellWithReuseIdentifier:kInputCellID forIndexPath:indexPath];
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
    TWLCropCell *cell = [cv dequeueReusableCellWithReuseIdentifier:kCropCellID forIndexPath:indexPath];
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
    TWLCropSectionHeaderView *header = [cv dequeueReusableSupplementaryViewOfKind:kind
                                                               withReuseIdentifier:kHeaderViewID
                                                                      forIndexPath:indexPath];
    NSArray *titles = @[@"自定义作物", @"粮食作物", @"蔬菜", @"果树"];
    header.titleLabel.text = titles[indexPath.section];
    return header;
}

#pragma mark - UICollectionViewDelegate

- (BOOL)collectionView:(UICollectionView *)cv shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == TWLPrefSectionCustom) {
        NSInteger inputIndex = (NSInteger)_customCrops.count;
        return indexPath.item != inputIndex;  // 输入框不可"选中"
    }
    return YES;
}

- (void)collectionView:(UICollectionView *)cv didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == TWLPrefSectionCustom) {
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
    if (indexPath.section == TWLPrefSectionCustom) {
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
    NSIndexPath *newIP = [NSIndexPath indexPathForItem:insertPos inSection:TWLPrefSectionCustom];

    [cv performBatchUpdates:^{
        [cv insertItemsAtIndexPaths:@[newIP]];
    } completion:^(BOOL finished) {
        // 清空输入框并收起键盘
        NSIndexPath *inputIP = [NSIndexPath indexPathForItem:(NSInteger)self->_customCrops.count
                                                   inSection:TWLPrefSectionCustom];
        TWLCustomInputCell *inputCell = (TWLCustomInputCell *)[cv cellForItemAtIndexPath:inputIP];
        inputCell.textField.text = @"";
        [inputCell.textField resignFirstResponder];
    }];
}

#pragma mark - Actions

- (void)handleConfirm {
    NSLog(@"用户选择的农作物: %@", _selectedPlantNames);
    TLWMainTabBarController *tabBar = [[TLWMainTabBarController alloc] init];
    tabBar.modalPresentationStyle = UIModalPresentationFullScreen;
    UIWindow *window = self.view.window;
    window.rootViewController = tabBar;
    [UIView transitionWithView:window
                      duration:0.3
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:nil
                    completion:nil];
}

@end
