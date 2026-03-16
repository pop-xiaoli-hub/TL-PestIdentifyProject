//
//  TLWPublishController.m
//  TL-PestIdentify
//

#import "TLWPublishController.h"
#import "TLWPublishView.h"
#import <Masonry/Masonry.h>

@interface TLWPublishController ()<UIGestureRecognizerDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic, strong) TLWPublishView *myView;
@property (nonatomic, strong, nullable) id draftObject;
@property (nonatomic, strong) NSMutableArray<UIImage *> *selectedImages;

@end

@implementation TLWPublishController

- (void)viewDidLoad {
  [super viewDidLoad];

  self.view.backgroundColor = [UIColor clearColor];
  self.myView = [[TLWPublishView alloc] initWithFrame:CGRectZero];
  [self.view addSubview:self.myView];
  [self.myView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.edges.equalTo(self.view);
  }];

  [self.myView.backButton addTarget:self action:@selector(tl_backButtonTapped) forControlEvents:UIControlEventTouchUpInside];
  [self.myView.cropSelectButton addTarget:self action:@selector(tl_cropSelectTapped) forControlEvents:UIControlEventTouchUpInside];
  [self.myView.addImageButton addTarget:self action:@selector(tl_addImageTapped) forControlEvents:UIControlEventTouchUpInside];
  [self.myView.confirmPublishButton addTarget:self action:@selector(tl_confirmPublishTapped) forControlEvents:UIControlEventTouchUpInside];
  self.myView.imagesCollectionView.dataSource = self;
  self.myView.imagesCollectionView.delegate = self;
  [self.myView.imagesCollectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"PublishImageCell"];
  self.selectedImages = [NSMutableArray array];
  UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc]  initWithTarget:self action:@selector(hideKeyboard)];
  tap.delegate = self;
  tap.cancelsTouchesInView = NO;
  [self.myView.middleCardView addGestureRecognizer:tap];
  if (self.draftObject) {
    [self tl_applyDraftIfNeeded];
  }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
  // 点击在输入框/图片列表时，不触发“收起键盘”的 tap，避免吞掉子控件事件
  if (touch.view == self.myView.contentTextView || [touch.view isDescendantOfView:self.myView.contentTextView]) {
    return NO;
  }
  if (touch.view == self.myView.imagesCollectionView || [touch.view isDescendantOfView:self.myView.imagesCollectionView]) {
    return NO;
  }
  return YES;
}


- (void)hideKeyboard {
  [self.myView endEditing:YES];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
  // 第 0 个为“添加图片”按钮，其余为已选图片，最多 9 个格子
  NSInteger count = self.selectedImages.count + 1;
  return MIN(count, 9);
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
  UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"PublishImageCell" forIndexPath:indexPath];
  for (UIView *sub in cell.contentView.subviews) {
    [sub removeFromSuperview];
  }

  UIImageView *imageView = [[UIImageView alloc] initWithFrame:cell.contentView.bounds];
  imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  imageView.contentMode = UIViewContentModeScaleAspectFill;
  imageView.clipsToBounds = YES;
  imageView.layer.cornerRadius = 10.0;

  if (indexPath.item == 0) {
    // 添加图片按钮样式
    imageView.image = [UIImage imageNamed:@"addPhoto"];
    imageView.backgroundColor = [UIColor colorWithWhite:0.97 alpha:1.0];
    imageView.contentMode = UIViewContentModeCenter;
  } else {
    imageView.image = self.selectedImages[indexPath.item - 1];
  }

  [cell.contentView addSubview:imageView];
  return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
  if (indexPath.item == 0) {
    [self tl_addImageTapped];
  } else {
    // 这里可以做预览或删除，暂时不处理
  }
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info {
  UIImage *image = info[UIImagePickerControllerOriginalImage];
  if (image) {
    if (self.selectedImages.count < 8) {
      [self.selectedImages addObject:image];
      [self.myView.imagesCollectionView reloadData];
    }
  }
  [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
  [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Public

- (void)tl_configureWithDraft:(nullable id)draft {
  self.draftObject = draft;
  if (self.isViewLoaded) {
    [self tl_applyDraftIfNeeded];
  }
}

#pragma mark - Draft

- (void)tl_applyDraftIfNeeded {
  // TODO: 将 draftObject 内容回显到 myView（作物名称、文本内容、图片等）
}

#pragma mark - Actions (预留接口)

/// 返回按钮点击：默认直接关闭当前控制器，外部可根据需要替换为自定义路由
- (void)tl_backButtonTapped {
  if (self.navigationController) {
    [self.navigationController popViewControllerAnimated:YES];
  } else {
    [self dismissViewControllerAnimated:YES completion:nil];
  }
}

/// 选择要发布的农作物
/// TODO: 在此处弹出作物选择器（列表 / 搜索），选择结果回写到 myView.cropSelectButton 文案
- (void)tl_cropSelectTapped {
  // 预留方法体，待后续接入业务逻辑
}

- (void)tl_addImageTapped {
  // 打开系统相册选择图片，最多支持 8 张用户图片（加上第 0 个“添加”占位，共 9 格）
  if (self.selectedImages.count >= 8) {
    return;
  }
  UIImagePickerController *picker = [[UIImagePickerController alloc] init];
  picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
  picker.allowsEditing = NO;
  picker.delegate = (id<UINavigationControllerDelegate, UIImagePickerControllerDelegate>)self;
  [self presentViewController:picker animated:YES completion:nil];
}

/// 确认发布按钮
/// TODO: 收集作物类型、文字内容、图片数组等信息，执行发布接口；根据结果提示成功 / 失败
- (void)tl_confirmPublishTapped {
  // 预留方法体，待后续接入业务逻辑
}

@end

