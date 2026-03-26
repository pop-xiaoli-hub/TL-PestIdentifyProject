//
//  TLWCommunityController.m
//  TL-PestIdentify
//

#import "TLWCommunityController.h"
#import "TLWCommunityView.h"
#import "TLWCommunityCell.h"
#import "TLWCommunityPost.h"
#import "TLWCommunityWaterfallLayout.h"
#import "TLWVoiceInputViewController.h"
#import "TLWPublishController.h"
#import "TLWSDKManager.h"
#import <Masonry/Masonry.h>

static NSString *const kCommunityCellID = @"TLWCommunityCell";

@interface TLWCommunityController () <UICollectionViewDataSource, TLWCommunityWaterfallLayoutDelegate, UITextFieldDelegate >

@property (nonatomic, strong) TLWCommunityView *myView;
@property (nonatomic, strong) NSMutableArray *posts;
@property (nonatomic, assign) BOOL tl_isFetchingFeed;

@end

@implementation TLWCommunityController


- (void)viewDidLoad {
  [super viewDidLoad];
  self.view.backgroundColor = [UIColor clearColor];
  [self.view addSubview:self.myView];
  [self.myView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.edges.equalTo(self.view);
  }];

  UICollectionView *collectionView = self.myView.collectionView;
  collectionView.dataSource = self;
  TLWCommunityWaterfallLayout *layout = (TLWCommunityWaterfallLayout *)collectionView.collectionViewLayout;
  layout.delegate = self;
  [collectionView registerClass:[TLWCommunityCell class] forCellWithReuseIdentifier:kCommunityCellID];
  UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panAction:)];
  [self.myView.publishButton addGestureRecognizer:pan];
  [self.myView.publishButton addTarget:self action:@selector(tl_publishButtonTapped) forControlEvents:UIControlEventTouchUpInside];

  [self.myView bringSubviewToFront:self.myView.publishButton];
  self.myView.searchTextField.delegate = self;
  [self.myView.voiceButton addTarget:self action:@selector(tl_voiceButtonTapped) forControlEvents:UIControlEventTouchUpInside];
  self.posts = [NSMutableArray array];
  self.tl_isFetchingFeed = NO;
  [self tl_fetchCommunityFeed];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];

}


- (void)panAction:(UIPanGestureRecognizer *)pan {
  CGPoint translation = [pan translationInView:self.myView];
  self.myView.publishButton.center = CGPointMake(self.myView.publishButton.center.x + translation.x, self.myView.publishButton.center.y + translation.y);
  [pan setTranslation:CGPointZero inView:self.myView];
  if (pan.state == UIGestureRecognizerStateEnded) {
    [self moveToEdge];
  }
}

- (void)moveToEdge {
  CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
  CGFloat targetX;
  if (self.myView.publishButton.center.x <= screenWidth / 2) {
    targetX = self.myView.publishButton.bounds.size.width / 2 + 10;
  } else {
    targetX = screenWidth - self.myView.publishButton.bounds.size.width / 2 - 10;
  }
  [UIView animateWithDuration:0.3 animations:^{
    self.myView.publishButton.center = CGPointMake(targetX, self.myView.publishButton.center.y);
  }];
}

#pragma mark - Data

/// TODO: 接口接入后替换内部实现，保持方法签名不变，方便全局调用
- (void)tl_fetchCommunityFeed {
  if (self.tl_isFetchingFeed) {
    return;
  }
  self.tl_isFetchingFeed = YES;

  // 先清空，让用户立刻看到刷新反馈
  self.posts = [NSMutableArray array];
  dispatch_async(dispatch_get_main_queue(), ^{
    [self.myView.collectionView reloadData];
  });

  TLWSDKManager *sdk = [TLWSDKManager shared];
  NSInteger pageSize = 20; // 一次拉取多少条
  NSInteger maxPages = 50; // 安全兜底：避免 hasNext 异常导致无限请求

  NSMutableArray<TLWCommunityPost *> *accumulator = [NSMutableArray array];
  __weak typeof(self) weakSelf = self;

  __block void (^fetchPageBlock)(NSInteger pageIndex);
  fetchPageBlock = ^(NSInteger pageIndex) {
    __strong typeof(weakSelf) strongSelf = weakSelf;
    if (!strongSelf) return;

    [sdk getAllPostsWithTag:nil
                           q:nil
                         page:@(pageIndex)
                         size:@(pageSize)
            completionHandler:^(AGResultPageResultPostResponseDto *output, NSError *error) {
      __strong typeof(weakSelf) s = weakSelf;
      if (!s) return;

      if (error || !output || !output.data.list) {
        dispatch_async(dispatch_get_main_queue(), ^{
          s.tl_isFetchingFeed = NO;
          // 合并本地发布的 item，避免分页完成时覆盖掉刚发布的帖子
          NSMutableArray<TLWCommunityPost *> *merged = [accumulator mutableCopy];
          for (TLWCommunityPost *localPost in s.posts) {
            if (![accumulator containsObject:localPost]) {
              [merged addObject:localPost];
            }
          }
          s.posts = merged;
          [s.myView.collectionView reloadData];
        });
        return;
      }

      for (AGPostResponseDto *dto in output.data.list) {
        TLWCommunityPost *post = [TLWCommunityPost new];
        post._id = dto._id;
        post.title = dto.title ?: @"";
        post.content = dto.content ?: @"";
        post.images = dto.images ?: @[];
        post.tags = dto.tags ?: @[];
        post.authorName = dto.authorName ?: @"";
        post.authorAvatar = dto.authorAvatar ?: @"";
        post.likeCount = @0;
        // imageAspectRatio 由瀑布流代理方法按行规则统一设置
        [accumulator addObject:post];
      }

      // 逐页渲染，减少“空白等待”感
      dispatch_async(dispatch_get_main_queue(), ^{
        // 合并本地发布的 item，避免分页刷新覆盖掉刚发布的帖子
        NSMutableArray<TLWCommunityPost *> *merged = [accumulator mutableCopy];
        for (TLWCommunityPost *localPost in s.posts) {
          if (![accumulator containsObject:localPost]) {
            [merged addObject:localPost];
          }
        }
        s.posts = merged;
        [s.myView.collectionView reloadData];
      });

      BOOL hasNext = output.data.hasNext.boolValue;
      if (hasNext && pageIndex + 1 < maxPages) {
        fetchPageBlock(pageIndex + 1);
      } else {
        dispatch_async(dispatch_get_main_queue(), ^{
          s.tl_isFetchingFeed = NO;
          // 合并本地发布的 item，避免最终结果覆盖掉刚发布的帖子
          NSMutableArray<TLWCommunityPost *> *merged = [accumulator mutableCopy];
          for (TLWCommunityPost *localPost in s.posts) {
            if (![accumulator containsObject:localPost]) {
              [merged addObject:localPost];
            }
          }
          s.posts = merged;
          [s.myView.collectionView reloadData];
        });
      }
    }];
  };

  fetchPageBlock(0);
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
  return self.posts.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
  TLWCommunityCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kCommunityCellID forIndexPath:indexPath];
  TLWCommunityPost *post = self.posts[indexPath.item];
  // 本地发布帖子的高度不要再依赖真实宽高比计算，统一使用固定比例
//  if (post.imageAspectRatio <= 0.0) {
//    post.imageAspectRatio = 0.65;
//  }
  if (indexPath.row == 0) {
    post.imageAspectRatio = 0.60;
  } else {
    post.imageAspectRatio = 0.75;
  }
  [cell configureWithPost:post];
  return cell;
}

#pragma mark - TLWCommunityWaterfallLayoutDelegate

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)layout heightForItemAtIndexPath:(NSIndexPath *)indexPath itemWidth:(CGFloat)width {
  TLWCommunityPost *post = self.posts[indexPath.item];
  // 瀑布流高度计算使用的纵横比规则应与 cell 展示保持一致
  if (indexPath.row == 0) {
    post.imageAspectRatio = 0.60;
  } else {
    post.imageAspectRatio = 0.75;
  }
  return [post cellHeightForWidth:width];
}

#pragma mark - Lazy

- (TLWCommunityView *)myView {
  if (!_myView) {
    _myView = [[TLWCommunityView alloc] initWithFrame:CGRectZero];
  }
  return _myView;
}

- (void)tl_voiceButtonTapped {
  TLWVoiceInputViewController *vc = [[TLWVoiceInputViewController alloc] init];
  vc.modalPresentationStyle = UIModalPresentationFullScreen;
  [self presentViewController:vc animated:YES completion:nil];
}

- (void)tl_publishButtonTapped {
  TLWPublishController *vc = [[TLWPublishController alloc] init];
  vc.modalPresentationStyle = UIModalPresentationFullScreen;
  __weak typeof(self) weakSelf = self;
  // 本地发布直接把 TLWCommunityPost 存入瀑布流数据源
  vc.clickPublish = ^(TLWCommunityPost * _Nonnull post) {
    __strong typeof(weakSelf) strongSelf = weakSelf;
    if (!strongSelf) {
      return;
    }
    // 本地发布帖子的高度固定，不做真实宽高比计算
    if (post.imageAspectRatio <= 0.0) {
      post.imageAspectRatio = 0.65;
    }
    [strongSelf.posts addObject:post];

    NSInteger newIndex = strongSelf.posts.count - 1;
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:newIndex inSection:0];

    // 如果正在分页拉取，分页回调会触发 reloadData；为避免数据源/插入操作冲突，此处兜底全量刷新
    if (strongSelf.tl_isFetchingFeed) {
      [strongSelf.myView.collectionView reloadData];
      return;
    }

    // 只插入新增的 1 个 item，而不是整体 reloadData
    [strongSelf.myView.collectionView performBatchUpdates:^{
      [strongSelf.myView.collectionView insertItemsAtIndexPaths:@[indexPath]];
    } completion:nil];
  };
  [self presentViewController:vc animated:YES completion:nil];
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
  // 直接点击输入框时，同样展示毛玻璃搜索面板
  [self.myView tl_showSearchOverlay];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  // 这里可以触发真正的搜索事件，暂时只收起页面
  [textField resignFirstResponder];
  [self.myView tl_hideSearchOverlay];
  return YES;
}


@end

