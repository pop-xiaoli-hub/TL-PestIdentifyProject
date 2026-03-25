//
//  TLWPublishController.m
//  TL-PestIdentify
//

#import "TLWPublishController.h"
#import "TLWPublishView.h"
#import "TLWCropPickerController.h"
#import <Masonry/Masonry.h>
#import <PhotosUI/PhotosUI.h>
#import <AgriPestClient/AgriPestClient.h>
#import "TLWCommunityPost.h"
#import "TLWSDKManager.h"
@interface TLWPublishController ()<UIGestureRecognizerDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, PHPickerViewControllerDelegate>

@property (nonatomic, strong) TLWPublishView *myView;
@property (nonatomic, strong, nullable) id draftObject;
@property (nonatomic, strong) NSMutableArray<UIImage *> *selectedImages;
@property (nonatomic, strong) NSMutableArray<NSString *> *selectedCrops;

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

  self.myView.cropsCollectionView.dataSource = self;
  self.myView.cropsCollectionView.delegate = self;
  [self.myView.cropsCollectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"PublishCropTagCell"];

  self.selectedImages = [NSMutableArray array];
  self.selectedCrops = [NSMutableArray array];
  [self.myView tl_updateCropSelectionVisible:NO];
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
  if (touch.view == self.myView.cropsCollectionView || [touch.view isDescendantOfView:self.myView.cropsCollectionView]) {
    return NO;
  }
  return YES;
}


- (void)hideKeyboard {
  [self.myView endEditing:YES];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
  if (collectionView == self.myView.imagesCollectionView) {
    // 第 0 个为“添加图片”按钮，其余为已选图片，最多 9 个格子
    NSInteger count = self.selectedImages.count + 1;
    return MIN(count, 9);
  }
  // 顶部作物标签列表：仅展示已选作物
  return self.selectedCrops.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
  if (collectionView == self.myView.imagesCollectionView) {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"PublishImageCell" forIndexPath:indexPath];
    for (UIView *sub in cell.contentView.subviews) {
      [sub removeFromSuperview];
    }

    if (indexPath.item == 0) {
      // 添加图片按钮：暗色块 + 悬浮阴影 + 中间十字
      UIView *bgView = [[UIView alloc] initWithFrame:cell.contentView.bounds];
      bgView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
      bgView.backgroundColor = [UIColor colorWithWhite:0.85 alpha:1.0];
      bgView.layer.cornerRadius = 12.0;
    bgView.layer.shadowOpacity = 0.0;

      CGFloat crossSize = MIN(bgView.bounds.size.width, bgView.bounds.size.height) * 0.5;
      CGFloat barThickness = 3.0;
      CGRect bounds = bgView.bounds;
      CGPoint center = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds));

      UIView *horizontal = [[UIView alloc] initWithFrame:CGRectMake(0, 0, crossSize, barThickness)];
      horizontal.center = center;
      horizontal.backgroundColor = [UIColor whiteColor];
      horizontal.layer.cornerRadius = barThickness / 2.0;

      UIView *vertical = [[UIView alloc] initWithFrame:CGRectMake(0, 0, barThickness, crossSize)];
      vertical.center = center;
      vertical.backgroundColor = [UIColor whiteColor];
      vertical.layer.cornerRadius = barThickness / 2.0;

      [bgView addSubview:horizontal];
      [bgView addSubview:vertical];
      [cell.contentView addSubview:bgView];
    } else {
      UIImageView *imageView = [[UIImageView alloc] initWithFrame:cell.contentView.bounds];
      imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
      imageView.contentMode = UIViewContentModeScaleAspectFill;
      imageView.clipsToBounds = YES;
      imageView.layer.cornerRadius = 10.0;
      imageView.image = self.selectedImages[indexPath.item - 1];
      [cell.contentView addSubview:imageView];
    }
    return cell;
  }

  // 顶部作物标签 cell：绿色胶囊、立体感
  UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"PublishCropTagCell" forIndexPath:indexPath];
  for (UIView *sub in cell.contentView.subviews) {
    [sub removeFromSuperview];
  }

  UIView *bgView = [[UIView alloc] initWithFrame:cell.contentView.bounds];
  bgView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  bgView.backgroundColor = [UIColor colorWithRed:0.0 green:0.8 blue:0.55 alpha:1.0];
  bgView.layer.cornerRadius = 16.0;
  bgView.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.25].CGColor;
  bgView.layer.shadowOpacity = 0.7;
  bgView.layer.shadowRadius = 6.0;
  bgView.layer.shadowOffset = CGSizeMake(0, 3);

  UILabel *label = [[UILabel alloc] initWithFrame:CGRectInset(bgView.bounds, 12, 4)];
  label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  label.textAlignment = NSTextAlignmentCenter;
  label.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
  label.textColor = [UIColor whiteColor];
  label.text = self.selectedCrops[indexPath.item];

  [bgView addSubview:label];
  [cell.contentView addSubview:bgView];
  return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
  if (collectionView == self.myView.imagesCollectionView) {
    if (indexPath.item == 0) {
      [self tl_addImageTapped];
    } else {
      // 这里可以做预览或删除，暂时不处理
    }
    return;
  }
  // 顶部作物标签点击后也可再次进入选择页
  [self tl_cropSelectTapped];
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
- (void)tl_cropSelectTapped {
  TLWCropPickerController *vc = [[TLWCropPickerController alloc] init];
  vc.initialSelectedCropNames = [self.selectedCrops copy];
  __weak typeof(self) weakSelf = self;
  vc.completionHandler = ^(NSArray<NSString *> *selectedCropNames) {
    __strong typeof(weakSelf) strongSelf = weakSelf;
    if (!strongSelf) {
      return;
    }
    [strongSelf.selectedCrops removeAllObjects];
    [strongSelf.selectedCrops addObjectsFromArray:selectedCropNames ?: @[]];
    BOOL hasSelection = strongSelf.selectedCrops.count > 0;
    [strongSelf.myView tl_updateCropSelectionVisible:hasSelection];
    [strongSelf.myView.cropsCollectionView reloadData];
  };
  vc.modalPresentationStyle = UIModalPresentationFullScreen;
  [self presentViewController:vc animated:YES completion:nil];
}

- (void)tl_addImageTapped {
  NSInteger remainCount = MAX(0, 8 - self.selectedImages.count);
  if (remainCount <= 0) {
    return;
  }

  if (@available(iOS 14.0, *)) {
    PHPickerConfiguration *configuration = [[PHPickerConfiguration alloc] init];
    configuration.selectionLimit = remainCount;
    configuration.filter = [PHPickerFilter imagesFilter];
    PHPickerViewController *picker = [[PHPickerViewController alloc] initWithConfiguration:configuration];
    picker.delegate = self;
    picker.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:picker animated:YES completion:nil];
    return;
  }

  if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
    return;
  }
  UIImagePickerController *picker = [[UIImagePickerController alloc] init];
  picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
  picker.delegate = self;
  picker.modalPresentationStyle = UIModalPresentationFullScreen;
  [self presentViewController:picker animated:YES completion:nil];
}

- (void)picker:(PHPickerViewController *)picker didFinishPicking:(NSArray<PHPickerResult *> *)results API_AVAILABLE(ios(14.0)) {
  [picker dismissViewControllerAnimated:YES completion:nil];
  if (results.count == 0) {
    return;
  }

  NSInteger remainCount = MAX(0, 8 - self.selectedImages.count);
  if (remainCount <= 0) {
    return;
  }

  dispatch_group_t group = dispatch_group_create();
  NSMutableArray<UIImage *> *newImages = [NSMutableArray array];

  for (PHPickerResult *result in results) {
    if (newImages.count >= remainCount) {
      break;
    }
    NSItemProvider *provider = result.itemProvider;
    if (![provider canLoadObjectOfClass:[UIImage class]]) {
      continue;
    }
    dispatch_group_enter(group);
    [provider loadObjectOfClass:[UIImage class] completionHandler:^(id<NSItemProviderReading> _Nullable object, NSError * _Nullable error) {
      if (!error && [object isKindOfClass:[UIImage class]]) {
        @synchronized (newImages) {
          if (newImages.count < remainCount) {
            [newImages addObject:(UIImage *)object];
          }
        }
      }
      dispatch_group_leave(group);
    }];
  }

  dispatch_group_notify(group, dispatch_get_main_queue(), ^{
    if (newImages.count == 0) {
      return;
    }
    [self.selectedImages addObjectsFromArray:newImages];
    [self.myView.imagesCollectionView reloadData];
  });
}

#pragma mark-点击发布
/// 确认发布按钮
- (void)tl_confirmPublishTapped {
  NSString *content = [self.myView.contentTextView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
  // 校验：内容和图片至少有一项
  if (content.length == 0 && self.selectedImages.count == 0) {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:@"请输入内容或添加图片" preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
    return;
  }

  // 显示 loading
  [self.myView tl_createBlurLoadingView];

  __weak typeof(self) weakSelf = self;
  TLWSDKManager *manager = [TLWSDKManager shared];

  // Step 1: 上传图片（无图片则直接跳到 Step 2）
  [manager uploadImages:self.selectedImages prefix:@"post" completion:^(NSArray<NSString *> *urls, NSError *error) {
    __strong typeof(weakSelf) strongSelf = weakSelf;
    if (!strongSelf) return;

    if (error) {
      [strongSelf.myView tl_dismissBlurLoadingView];
      UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"上传图片失败" message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
      [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
      [strongSelf presentViewController:alert animated:YES completion:nil];
      return;
    }

    // Step 2: 构建帖子请求，调用创建接口
    AGPostCreateRequest *request = [[AGPostCreateRequest alloc] init];
    request.title = content.length > 20 ? [content substringToIndex:20] : content;
    request.content = content;
    request.images = urls ?: @[];
    request.tags = [strongSelf.selectedCrops copy] ?: @[];

    NSLog(@"[Publish] 上传图片完成，URLs: %@", urls);
    [manager.api createPostWithPostCreateRequest:request completionHandler:^(AGResultPostResponseDto *output, NSError *createError) {
      NSLog(@"[Publish] 创建帖子结果 code=%@, msg=%@, error=%@", output.code, output.message, createError);
      dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) strongSelf2 = weakSelf;
        if (!strongSelf2) return;

        [strongSelf2.myView tl_dismissBlurLoadingView];

        if (createError || !output || output.code.integerValue != 200) {
          NSString *msg = createError.localizedDescription ?: output.message ?: @"发布失败，请重试";
          UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"发布失败" message:msg preferredStyle:UIAlertControllerStyleAlert];
          [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
          [strongSelf2 presentViewController:alert animated:YES completion:nil];
          return;
        }

        // 发布成功，回调给社区页面刷新列表
        if (strongSelf2.clickPublish) {
          TLWCommunityPost *model = [[TLWCommunityPost alloc] init];
          model.content = content;
          model.images = urls ?: @[];
          model.tags = [strongSelf2.selectedCrops copy];
          model.authorName = [manager.username copy];
          strongSelf2.clickPublish(model);
        }

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:@"发布成功" preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
          [strongSelf2 dismissViewControllerAnimated:YES completion:nil];
        }]];
        [strongSelf2 presentViewController:alert animated:YES completion:nil];
      });
    }];
  }];
}





@end

/*

 -(NSURLSessionTask*) uploadFilesWithFiles: (NSArray<NSURL*>*) files
     prefix: (NSString*) prefix
     completionHandler: (void (^)(AGResultListString* output, NSError* error)) handler;
 */
