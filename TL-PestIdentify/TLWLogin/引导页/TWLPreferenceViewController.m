//
//  TWLPreferenceViewController.m
//  TL-PestIdentify
//

#import "TWLPreferenceViewController.h"
#import "TWLPreferenceView.h"
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

    UIImageView *bgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Subtract"]];
    bgView.contentMode = UIViewContentModeScaleAspectFill;
    bgView.clipsToBounds = YES;
    bgView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    bgView.frame = self.contentView.bounds;
    [self.contentView addSubview:bgView];

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

@interface TWLPreferenceViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>
@property (nonatomic, strong) TWLPreferenceView *preferenceView;
@property (nonatomic, strong) NSMutableSet<NSIndexPath *> *selectedIndexPaths;
@property (nonatomic, strong) NSArray<NSArray<NSString *> *> *plantSections;  // index 0=grain, 1=veg, 2=fruit
@end

@implementation TWLPreferenceViewController

- (void)loadView {
    self.preferenceView = [[TWLPreferenceView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.view = self.preferenceView;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    _selectedIndexPaths = [NSMutableSet set];

    // Plant data: grain / vegetable / fruit
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
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)cv {
    return 4; // custom + grain + vegetable + fruit
}

- (NSInteger)collectionView:(UICollectionView *)cv numberOfItemsInSection:(NSInteger)section {
    if (section == TWLPrefSectionCustom) return 2;  // input + add
    return (NSInteger)[_plantSections[section - 1] count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == TWLPrefSectionCustom) {
        if (indexPath.item == 0) {
            return [cv dequeueReusableCellWithReuseIdentifier:kInputCellID forIndexPath:indexPath];
        } else {
            return [cv dequeueReusableCellWithReuseIdentifier:kAddCellID forIndexPath:indexPath];
        }
    }
    TWLCropCell *cell = [cv dequeueReusableCellWithReuseIdentifier:kCropCellID forIndexPath:indexPath];
    NSString *name = _plantSections[indexPath.section - 1][indexPath.item];
    cell.nameLabel.text = name;
    // Restore selection state
    cell.selected = [_selectedIndexPaths containsObject:indexPath];
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
    return (indexPath.section != TWLPrefSectionCustom);
}

- (void)collectionView:(UICollectionView *)cv didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [_selectedIndexPaths addObject:indexPath];
}

- (void)collectionView:(UICollectionView *)cv didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    [_selectedIndexPaths removeObject:indexPath];
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

#pragma mark - Actions

- (void)handleConfirm {
    // Collect selected plant names
    NSMutableArray *selected = [NSMutableArray array];
    for (NSIndexPath *ip in _selectedIndexPaths) {
        if (ip.section != TWLPrefSectionCustom) {
            [selected addObject:_plantSections[ip.section - 1][ip.item]];
        }
    }
    NSLog(@"用户选择的农作物: %@", selected);
    // TODO: 保存偏好并跳转到主页
}

@end
