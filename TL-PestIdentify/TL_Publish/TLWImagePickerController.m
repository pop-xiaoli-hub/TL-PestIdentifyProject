//
//  TLWImagePickerController.m
//  TL-PestIdentify
//

#import "TLWImagePickerController.h"
#import "TLWImagePickerView.h"
#import <Masonry/Masonry.h>

static NSString * const kPublishImageCellID = @"PublishImageCellID";

@interface TLWImagePickerController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong) TLWImagePickerView *pickerView;
@property (nonatomic, strong) NSMutableArray *mutableSelectedItems; // 所有可选图片（UIImage 或模型）
@property (nonatomic, strong) NSMutableIndexSet *selectedIndexes;   // 多选状态索引

@end

@implementation TLWImagePickerController

- (void)loadView {
  self.pickerView = [[TLWImagePickerView alloc] initWithFrame:[UIScreen mainScreen].bounds];
  self.view = self.pickerView;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  UIImage* image = [UIImage imageNamed:@"hp_eg1.jpg"];
  NSMutableArray* mutableArray = [NSMutableArray array];
  for (int i = 0; i < 10; i++) {
    [mutableArray addObject:image];
  }
  self.initialImages = [NSArray arrayWithArray:mutableArray];

  self.mutableSelectedItems = [NSMutableArray arrayWithArray:self.initialImages ?: @[]];
  self.selectedIndexes = [NSMutableIndexSet indexSet];
  UICollectionView *cv = self.pickerView.collectionView;
  [cv registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:kPublishImageCellID];
  cv.dataSource = self;
  cv.delegate = self;
  cv.allowsMultipleSelection = YES;//打开多选模式

  [self.pickerView.confirmButton addTarget:self action:@selector(tl_handleConfirm) forControlEvents:UIControlEventTouchUpInside];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
  // 后续可扩展为真实相册数据，这里先用 mutableSelectedItems 驱动
  return self.mutableSelectedItems.count > 0 ? self.mutableSelectedItems.count : 10;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
  UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kPublishImageCellID forIndexPath:indexPath];
  for (UIView *sub in cell.contentView.subviews) {
    [sub removeFromSuperview];
  }

  UIImage *image = nil;
  if (self.mutableSelectedItems.count > indexPath.item) {
    id item = self.mutableSelectedItems[indexPath.item];
    if ([item isKindOfClass:[UIImage class]]) {
      image = (UIImage *)item;
    }
  }
  if (!image) {
    image = [UIImage imageNamed:@"hp_eg1.jpg"];
  }
  // 预留：若为自定义模型，可在此解析出缩略图

  UIImageView *imageView = [[UIImageView alloc] initWithFrame:cell.contentView.bounds];
  imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  imageView.contentMode = UIViewContentModeScaleAspectFill;
  imageView.clipsToBounds = YES;
  imageView.layer.cornerRadius = 10.0;
  imageView.image = image;
  [cell.contentView addSubview:imageView];

  // 右上角多选小圆圈
  BOOL selected = [self.selectedIndexes containsIndex:(NSUInteger)indexPath.item];
  CGFloat circleSize = 22.0;
  UIView *circleBg = [[UIView alloc] initWithFrame:CGRectMake(cell.contentView.bounds.size.width - circleSize - 6,
                                                              6,
                                                              circleSize,
                                                              circleSize)];
  circleBg.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
  circleBg.layer.cornerRadius = circleSize / 2.0;
  circleBg.layer.borderWidth = 2.0;
  circleBg.layer.borderColor = [UIColor colorWithRed:0.0 green:0.8 blue:0.55 alpha:1.0].CGColor;
  circleBg.backgroundColor = selected ? [UIColor colorWithRed:0.0 green:0.8 blue:0.55 alpha:1.0] : [UIColor colorWithWhite:1 alpha:0.85];

  if (selected) {
    UILabel *checkLabel = [[UILabel alloc] initWithFrame:circleBg.bounds];
    checkLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    checkLabel.textAlignment = NSTextAlignmentCenter;
    checkLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightBold];
    checkLabel.textColor = [UIColor whiteColor];
    checkLabel.text = @"✓";
    [circleBg addSubview:checkLabel];
  }

  [cell.contentView addSubview:circleBg];

  return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
  [self.selectedIndexes addIndex:(NSUInteger)indexPath.item];
  [collectionView reloadItemsAtIndexPaths:@[indexPath]];
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
  [self.selectedIndexes removeIndex:(NSUInteger)indexPath.item];
  [collectionView reloadItemsAtIndexPaths:@[indexPath]];
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)layout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
  CGFloat margin  = 22.0;
  CGFloat gap     = 10.0;
  CGFloat columns = 4.0;
  CGFloat width = collectionView.bounds.size.width;
  CGFloat cellW = floor((width - 2 * margin - (columns - 1) * gap) / columns);
  return CGSizeMake(cellW, cellW);
}

#pragma mark - Actions

- (void)tl_handleConfirm {
  if (self.completionHandler) {
    NSMutableArray *result = [NSMutableArray array];
    [self.selectedIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
      if (idx < self.mutableSelectedItems.count) {
        [result addObject:self.mutableSelectedItems[idx]];
      }
    }];
    self.completionHandler([result copy]);
  }
  [self dismissViewControllerAnimated:YES completion:nil];
}

@end

