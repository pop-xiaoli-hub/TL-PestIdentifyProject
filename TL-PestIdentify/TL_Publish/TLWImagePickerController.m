//
//  TLWImagePickerController.m
//  TL-PestIdentify
//

#import "TLWImagePickerController.h"
#import "TLWImagePickerView.h"
#import <Masonry/Masonry.h>

static NSString * const kPublishImageCellID = @"PublishImageCellID";

@interface TLWImagePickerController () <UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic, strong) TLWImagePickerView *pickerView;
@property (nonatomic, strong) NSMutableArray *mutableSelectedItems; // 预留：可以是 UIImage / 自定义模型

@end

@implementation TLWImagePickerController

- (void)loadView {
  self.pickerView = [[TLWImagePickerView alloc] initWithFrame:[UIScreen mainScreen].bounds];
  self.view = self.pickerView;
}

- (void)viewDidLoad {
  [super viewDidLoad];

  self.mutableSelectedItems = [NSMutableArray arrayWithArray:self.initialImages ?: @[]];

  UICollectionView *cv = self.pickerView.collectionView;
  [cv registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:kPublishImageCellID];
  cv.dataSource = self;
  cv.delegate = self;

  [self.pickerView.confirmButton addTarget:self
                                    action:@selector(tl_handleConfirm)
                          forControlEvents:UIControlEventTouchUpInside];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
  // 预留：目前直接展示 initialImages 数量，后续可扩展为系统相册或自定义图片源
  return self.mutableSelectedItems.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
  UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kPublishImageCellID forIndexPath:indexPath];
  for (UIView *sub in cell.contentView.subviews) {
    [sub removeFromSuperview];
  }

  UIImage *image = nil;
  id item = self.mutableSelectedItems[indexPath.item];
  if ([item isKindOfClass:[UIImage class]]) {
    image = (UIImage *)item;
  }
  // 预留：若为自定义模型，可在此解析出缩略图

  UIImageView *imageView = [[UIImageView alloc] initWithFrame:cell.contentView.bounds];
  imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  imageView.contentMode = UIViewContentModeScaleAspectFill;
  imageView.clipsToBounds = YES;
  imageView.layer.cornerRadius = 10.0;
  imageView.image = image;
  [cell.contentView addSubview:imageView];

  return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
  // 预留：可在此实现单张预览 / 删除 / 勾选逻辑
}

#pragma mark - Actions

- (void)tl_handleConfirm {
  if (self.completionHandler) {
    self.completionHandler([self.mutableSelectedItems copy]);
  }
  [self dismissViewControllerAnimated:YES completion:nil];
}

@end

