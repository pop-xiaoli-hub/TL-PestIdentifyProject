//
//  TLWPublishController.m
//  TL-PestIdentify
//

#import "TLWPublishController.h"
#import "TLWPublishView.h"
#import "TLWCropPickerController.h"
#import "TLWPhotoPickerController.h"
#import <Masonry/Masonry.h>
#import <AgriPestClient/AgriPestClient.h>
#import "TLWCommunityPost.h"
#import "TLWSDKManager.h"
#import "TLWToast.h"
#import "TLWDBManager.h"

static NSString * const kTLWPublishContentPlaceholder = @"点击输入您要发布的内容";

@interface TLWPublishController ()<UIGestureRecognizerDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UITextViewDelegate>

@property (nonatomic, strong) TLWPublishView *myView;
@property (nonatomic, strong, nullable) id draftObject;
@property (nonatomic, strong) NSMutableArray<UIImage *> *selectedImages;
@property (nonatomic, strong) NSMutableArray<NSString *> *selectedCrops;
@property (nonatomic, assign) BOOL publishing;
@property (nonatomic, assign) NSUInteger publishGeneration;

@end

@implementation TLWPublishController

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [self.navigationController setNavigationBarHidden:YES animated:animated];
  self.navigationController.interactivePopGestureRecognizer.delegate = nil;
}

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
  self.myView.contentTextView.delegate = self;

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

- (void)viewDidDisappear:(BOOL)animated {
  [super viewDidDisappear:animated];
  self.publishGeneration += 1;
  [self tl_setPublishing:NO];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
  // 点击在输入框/图片列表时，不触发“收起键盘”的 tap，避免吞掉子控件事件
  if (touch.view == self.myView.titleTextField || [touch.view isDescendantOfView:self.myView.titleTextField]) {
    return NO;
  }
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

#pragma mark - UITextViewDelegate

- (void)textViewDidBeginEditing:(UITextView *)textView {
  if (textView != self.myView.contentTextView) {
    return;
  }

  if ([textView.text isEqualToString:kTLWPublishContentPlaceholder]) {
    textView.text = @"";
    textView.textColor = [UIColor darkTextColor];
  }
}

- (void)textViewDidEndEditing:(UITextView *)textView {
  if (textView != self.myView.contentTextView) {
    return;
  }

  NSString *content = [textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
  if (content.length == 0) {
    textView.text = kTLWPublishContentPlaceholder;
    textView.textColor = [UIColor lightGrayColor];
  }
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
  if (self.publishing) return;
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

  TLWPhotoPickerController *pickerVC = [[TLWPhotoPickerController alloc] init];
  pickerVC.maxCount = remainCount;
  __weak typeof(self) weakSelf = self;
  pickerVC.onSelectImages = ^(NSArray<UIImage *> *images) {
    __strong typeof(weakSelf) strongSelf = weakSelf;
    if (!strongSelf || images.count == 0) return;
    [strongSelf.selectedImages addObjectsFromArray:images];
    [strongSelf.myView.imagesCollectionView reloadData];
  };

  UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:pickerVC];
  nav.navigationBarHidden = YES;
  nav.modalPresentationStyle = UIModalPresentationFullScreen;
  [self presentViewController:nav animated:YES completion:nil];
}

#pragma mark-点击发布
- (void)tl_confirmPublishTapped {
  if (self.publishing) return;
  NSString *title = [self.myView.titleTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
  NSString* content = [self.myView.contentTextView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
  BOOL hasValidContent = content.length > 0 && ![content isEqualToString:kTLWPublishContentPlaceholder];

  if (self.selectedImages.count == 0) {
    [TLWToast show:@"请至少上传一张图片"];
    return;
  }

  if (self.selectedCrops.count == 0) {
    [TLWToast show:@"请选择要发布的作物"];
    return;
  }

  if (!title.length) {
    [TLWToast show:@"请输入帖子标题"];
    return;
  }

  if (!hasValidContent) {
    [TLWToast show:@"请输入帖子内容"];
    return;
  }

  NSArray<UIImage *> *images = [self.selectedImages copy];
  AGPostCreateRequest *request = [AGPostCreateRequest new];
  request.title = title;
  request.content = content;
  request.tags = [self.selectedCrops copy];
  NSUInteger generation = ++self.publishGeneration;
  [self.view endEditing:YES];
  [self tl_setPublishing:YES];
  __weak typeof(self) weakSelf = self;
  [[TLWSDKManager shared] uploadImages:images prefix:@"post" completion:^(NSArray<NSString *> *urls, NSError *error) {
    dispatch_async(dispatch_get_main_queue(), ^{
      __strong typeof(weakSelf) self = weakSelf;
      if (!self || generation != self.publishGeneration || !self.publishing) return;
      if (error || urls.count != images.count) {
        [self tl_failPublish:error.localizedDescription ?: @"图片上传失败，当前输入已保留" generation:generation];
        return;
      }
      request.images = urls;
      [self tl_createPost:request images:images generation:generation didRetryAuth:NO];
    });
  }];
}

- (void)tl_setPublishing:(BOOL)publishing {
  self.publishing = publishing;
  self.modalInPresentation = publishing;
  self.myView.confirmPublishButton.enabled = !publishing;
  self.myView.backButton.enabled = !publishing;
  self.myView.titleTextField.enabled = !publishing;
  self.myView.contentTextView.editable = !publishing;
  self.myView.addImageButton.enabled = !publishing;
  self.myView.cropSelectButton.enabled = !publishing;
  self.myView.imagesCollectionView.userInteractionEnabled = !publishing;
  self.myView.cropsCollectionView.userInteractionEnabled = !publishing;
  if (publishing) [self.myView tl_createBlurLoadingView];
  else [self.myView tl_dismissBlurLoadingView];
}

- (void)tl_failPublish:(NSString *)message generation:(NSUInteger)generation {
  if (generation != self.publishGeneration || !self.publishing) return;
  [self tl_setPublishing:NO];
  [TLWToast show:message];
}

- (void)tl_createPost:(AGPostCreateRequest *)request
              images:(NSArray<UIImage *> *)images
          generation:(NSUInteger)generation
        didRetryAuth:(BOOL)didRetryAuth {
  __weak typeof(self) weakSelf = self;
  TLWSDKManager *manager = [TLWSDKManager shared];
  [manager.api createPostWithPostCreateRequest:request completionHandler:^(AGResultPostResponseDto *output, NSError *error) {
    dispatch_async(dispatch_get_main_queue(), ^{
      __strong typeof(weakSelf) self = weakSelf;
      if (!self || generation != self.publishGeneration || !self.publishing) return;
      if (!didRetryAuth && [manager.sessionManager shouldAttemptTokenRefreshForCode:output.code error:error]) {
        [manager.sessionManager handleUnauthorizedWithRetry:^{
          __strong typeof(weakSelf) owner = weakSelf;
          if (owner.publishing && generation == owner.publishGeneration)
            [owner tl_createPost:request images:images generation:generation didRetryAuth:YES];
        } failure:^{
          [weakSelf tl_failPublish:@"登录状态恢复失败，当前输入已保留" generation:generation];
        }];
        return;
      }
      AGPostResponseDto *dto = output.data;
      if (error || output.code.integerValue != 200 || dto._id.longLongValue <= 0) {
        BOOL unknownResult = [error.domain isEqualToString:NSURLErrorDomain] &&
          (error.code == NSURLErrorTimedOut || error.code == NSURLErrorNetworkConnectionLost);
        NSString *message = unknownResult ? @"发布结果暂未确认，请先到“我的发布”核实后再重试；当前输入已保留" :
          (output.message.length ? output.message : @"发布未成功，当前输入已保留");
        [self tl_failPublish:message generation:generation];
        return;
      }
      dto.title = dto.title ?: request.title;
      dto.content = dto.content ?: request.content;
      dto.images = dto.images.count ? dto.images : request.images;
      dto.tags = dto.tags ?: request.tags;
      dto.authorName = dto.authorName ?: manager.sessionManager.cachedProfile.username;
      dto.authorAvatar = dto.authorAvatar ?: manager.sessionManager.cachedProfile.avatarUrl;
      dto.likeCount = dto.likeCount ?: @0;
      dto.favoriteCount = dto.favoriteCount ?: @0;
      BOOL cached = [[TLWDBManager shared] upsertMyPublishedPostFromDto:dto];
      TLWCommunityPost *post = [TLWCommunityPost new];
      post._id = dto._id;
      post.title = dto.title;
      post.content = dto.content;
      post.images = dto.images;
      post.tags = dto.tags;
      post.authorName = dto.authorName;
      post.authorAvatar = dto.authorAvatar;
      post.likeCount = dto.likeCount;
      post.favoriteCount = dto.favoriteCount;
      post.isLiked = dto.isLiked.boolValue;
      post.isCollected = dto.isFavorited.boolValue;
      post.createdAt = dto.createdAt;
      UIImage *cover = images.firstObject;
      [post applyCoverAspectRatioWithWidth:cover.size.width height:cover.size.height];
      // 先结束本次回调资格，避免同一完成回调重复插入；关闭动画期间仍禁用发布。
      self.publishGeneration += 1;
      [self.myView tl_dismissBlurLoadingView];
      if (self.onPublished) self.onPublished(post);
      [TLWToast show:cached ? @"发布成功" : @"发布成功，本地记录稍后刷新"];
      if (self.navigationController && !self.presentingViewController)
        [self.navigationController popViewControllerAnimated:YES];
      else [self dismissViewControllerAnimated:YES completion:nil];
    });
  }];
}




@end
