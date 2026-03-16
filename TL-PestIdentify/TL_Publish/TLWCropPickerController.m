//
//  TLWCropPickerController.m
//  TL-PestIdentify
//

#import "TLWCropPickerController.h"
#import "TLWCropPickerView.h"

static NSString * const kCropCellID        = @"PublishCropCell";
static NSString * const kInputCellID       = @"PublishCropInputCell";
static NSString * const kAddCellID         = @"PublishCropAddCell";
static NSString * const kHeaderViewID      = @"PublishCropHeaderView";

typedef NS_ENUM(NSInteger, TLWPublishCropSection) {
  TLWPublishCropSectionCustom    = 0,
  TLWPublishCropSectionGrain     = 1,
  TLWPublishCropSectionVegetable = 2,
  TLWPublishCropSectionFruit     = 3,
};

@interface TLWPublishCropCell : UICollectionViewCell
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) CAGradientLayer *selectedGradient;
@end

@implementation TLWPublishCropCell

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

@interface TLWPublishCustomInputCell : UICollectionViewCell
@property (nonatomic, strong) UITextField *textField;
@end

@implementation TLWPublishCustomInputCell

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
  _textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"请输入"
                                                                      attributes:@{
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

@interface TLWPublishAddCropCell : UICollectionViewCell
@end

@implementation TLWPublishAddCropCell

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

@interface TLWPublishCropSectionHeaderView : UICollectionReusableView
@property (nonatomic, strong) UILabel *titleLabel;
@end

@implementation TLWPublishCropSectionHeaderView

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

@interface TLWCropPickerController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UITextFieldDelegate>

@property (nonatomic, strong) TLWCropPickerView *pickerView;
@property (nonatomic, strong) NSArray<NSArray<NSString *> *> *plantSections;
@property (nonatomic, strong) NSMutableSet<NSString *> *selectedCropNames;
@property (nonatomic, strong) NSMutableArray<NSString *> *customCrops;
@property (nonatomic, copy) NSString *currentInputText;

@end

@implementation TLWCropPickerController

- (void)loadView {
  self.pickerView = [[TLWCropPickerView alloc] initWithFrame:[UIScreen mainScreen].bounds];
  self.view = self.pickerView;
}

- (void)viewDidLoad {
  [super viewDidLoad];

  self.selectedCropNames = [NSMutableSet setWithArray:self.initialSelectedCropNames ?: @[]];
  self.customCrops = [NSMutableArray array];
  self.currentInputText = @"";
  self.plantSections = @[
    @[@"小麦", @"水稻", @"玉米"],
    @[@"白菜", @"萝卜", @"莲藕", @"芋头", @"黄瓜", @"番茄", @"茄子", @"辣椒", @"香菇"],
    @[@"桃子", @"梨", @"杏树", @"葡萄", @"苹果", @"李子", @"杨梅"],
  ];

  UICollectionView *cv = self.pickerView.collectionView;
  [cv registerClass:[TLWPublishCropCell class] forCellWithReuseIdentifier:kCropCellID];
  [cv registerClass:[TLWPublishCustomInputCell class] forCellWithReuseIdentifier:kInputCellID];
  [cv registerClass:[TLWPublishAddCropCell class] forCellWithReuseIdentifier:kAddCellID];
  [cv registerClass:[TLWPublishCropSectionHeaderView class]
forSupplementaryViewOfKind:UICollectionElementKindSectionHeader
     withReuseIdentifier:kHeaderViewID];
  cv.dataSource = self;
  cv.delegate = self;
  cv.allowsMultipleSelection = YES;

  [self.pickerView.confirmButton addTarget:self
                                    action:@selector(tl_handleConfirm)
                          forControlEvents:UIControlEventTouchUpInside];

  // 点击空白处收起键盘（虽然当前没有输入框，预留交互）
  UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                        action:@selector(tl_dismissKeyboard)];
  tap.cancelsTouchesInView = NO;
  [self.view addGestureRecognizer:tap];
}

- (void)tl_dismissKeyboard {
  [self.view endEditing:YES];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
  // 自定义 + 3 个预设分组
  return 4;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
  if (section == TLWPublishCropSectionCustom) {
    // 已添加的自定义作物 + 输入框 + "+" 按钮
    return (NSInteger)self.customCrops.count + 2;
  }
  return (NSInteger)self.plantSections[section - 1].count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
  if (indexPath.section == TLWPublishCropSectionCustom) {
    NSInteger inputIndex = (NSInteger)self.customCrops.count;
    NSInteger addIndex   = inputIndex + 1;

    if (indexPath.item < inputIndex) {
      TLWPublishCropCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kCropCellID forIndexPath:indexPath];
      NSString *name = self.customCrops[indexPath.item];
      cell.nameLabel.text = name;
      BOOL sel = [self.selectedCropNames containsObject:name];
      cell.selected = sel;
      if (sel) {
        [collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
      } else {
        [collectionView deselectItemAtIndexPath:indexPath animated:NO];
      }
      return cell;

    } else if (indexPath.item == inputIndex) {
      TLWPublishCustomInputCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kInputCellID forIndexPath:indexPath];
      cell.textField.text = self.currentInputText;
      cell.textField.delegate = self;
      [cell.textField removeTarget:nil action:NULL forControlEvents:UIControlEventEditingChanged];
      [cell.textField addTarget:self action:@selector(tl_inputTextChanged:) forControlEvents:UIControlEventEditingChanged];
      return cell;

    } else {
      return [collectionView dequeueReusableCellWithReuseIdentifier:kAddCellID forIndexPath:indexPath];
    }
  }

  TLWPublishCropCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kCropCellID forIndexPath:indexPath];
  NSString *name = self.plantSections[indexPath.section - 1][indexPath.item];
  cell.nameLabel.text = name;
  BOOL sel = [self.selectedCropNames containsObject:name];
  cell.selected = sel;
  if (sel) {
    [collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
  } else {
    [collectionView deselectItemAtIndexPath:indexPath animated:NO];
  }
  return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView
           viewForSupplementaryElementOfKind:(NSString *)kind
                                 atIndexPath:(NSIndexPath *)indexPath {
  TLWPublishCropSectionHeaderView *header = [collectionView dequeueReusableSupplementaryViewOfKind:kind
                                                                               withReuseIdentifier:kHeaderViewID
                                                                                      forIndexPath:indexPath];
  NSArray *titles = @[@"自定义作物", @"粮食作物", @"蔬菜", @"果树"];
  header.titleLabel.text = titles[indexPath.section];
  return header;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
  if (indexPath.section == TLWPublishCropSectionCustom) {
    NSInteger addIndex = (NSInteger)self.customCrops.count + 1;
    if (indexPath.item == addIndex) {
      // 点击 "+" — 添加自定义作物
      [collectionView deselectItemAtIndexPath:indexPath animated:NO];
      [self tl_addCustomCrop];
      return;
    }
    if (indexPath.item < (NSInteger)self.customCrops.count) {
      NSString *name = self.customCrops[indexPath.item];
      [self.selectedCropNames addObject:name];
    }
    return;
  }

  NSString *name = self.plantSections[indexPath.section - 1][indexPath.item];
  [self.selectedCropNames addObject:name];
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
  if (indexPath.section == TLWPublishCropSectionCustom) {
    if (indexPath.item < (NSInteger)self.customCrops.count) {
      NSString *name = self.customCrops[indexPath.item];
      [self.selectedCropNames removeObject:name];
    }
    return;
  }
  NSString *name = self.plantSections[indexPath.section - 1][indexPath.item];
  [self.selectedCropNames removeObject:name];
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)layout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
  CGFloat margin  = 22.0;
  CGFloat gap     = 10.0;
  CGFloat columns = 3.0;
  CGFloat cellW = floor((collectionView.bounds.size.width - 2 * margin - (columns - 1) * gap) / columns);
  return CGSizeMake(cellW, 71);
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)layout
referenceSizeForHeaderInSection:(NSInteger)section {
  return CGSizeMake(collectionView.bounds.size.width - 44, 36);
}

#pragma mark - UITextField tracking & custom crops

- (void)tl_inputTextChanged:(UITextField *)textField {
  self.currentInputText = textField.text ?: @"";
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  [self tl_addCustomCrop];
  return YES;
}

- (void)tl_addCustomCrop {
  NSString *text = [self.currentInputText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
  if (text.length == 0) return;

  // 不允许重复：在自定义和预设中都查一遍
  if ([self.customCrops containsObject:text]) return;
  for (NSArray *section in self.plantSections) {
    if ([section containsObject:text]) return;
  }

  NSInteger insertPos = (NSInteger)self.customCrops.count; // 在输入框前插入
  [self.customCrops addObject:text];
  self.currentInputText = @"";

  UICollectionView *cv = self.pickerView.collectionView;
  NSIndexPath *newIP = [NSIndexPath indexPathForItem:insertPos inSection:TLWPublishCropSectionCustom];

  [cv performBatchUpdates:^{
    [cv insertItemsAtIndexPaths:@[newIP]];
  } completion:^(BOOL finished) {
    NSIndexPath *inputIP = [NSIndexPath indexPathForItem:(NSInteger)self.customCrops.count
                                              inSection:TLWPublishCropSectionCustom];
    TLWPublishCustomInputCell *inputCell = (TLWPublishCustomInputCell *)[cv cellForItemAtIndexPath:inputIP];
    inputCell.textField.text = @"";
    [inputCell.textField resignFirstResponder];
  }];
}

#pragma mark - Actions

- (void)tl_handleConfirm {
  NSArray<NSString *> *result = [self.selectedCropNames allObjects];
  if (self.completionHandler) {
    self.completionHandler(result);
  }
  [self dismissViewControllerAnimated:YES completion:nil];
}

@end

