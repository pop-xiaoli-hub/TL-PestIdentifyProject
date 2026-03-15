//
//  TLWCommunityController.m
//  TL-PestIdentify
//

#import "TLWCommunityController.h"
#import "TLWCommunityView.h"
#import "TLWCommunityCell.h"
#import "TLWCommunityPost.h"
#import "TLWCommunityWaterfallLayout.h"
#import <Masonry/Masonry.h>

static NSString *const kCommunityCellID = @"TLWCommunityCell";

@interface TLWCommunityController () <UICollectionViewDataSource, TLWCommunityWaterfallLayoutDelegate, UITextFieldDelegate>

@property (nonatomic, strong) TLWCommunityView *myView;
@property (nonatomic, strong) NSArray<TLWCommunityPost *> *posts;

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
  [self.myView bringSubviewToFront:self.myView.publishButton];
  self.myView.searchTextField.delegate = self;
  [self tl_fetchCommunityFeed];
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
/// 预期接口返回格式：
/// [{
///   "imageUrl": "https://...",
///   "title": "菜心被蚜虫像蜂窝煤",
///   "userName": "用户2759",
///   "likeCount": 16
/// }]
- (void)tl_fetchCommunityFeed {
  // 接口未接入前，先用本地 Mock 数据驱动 UI
  self.posts = [TLWCommunityPost mockPosts];
  [self.myView.collectionView reloadData];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
  return self.posts.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
  TLWCommunityCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kCommunityCellID forIndexPath:indexPath];
  TLWCommunityPost *post = self.posts[indexPath.item];
  [cell configureWithPost:post];
  return cell;
}

#pragma mark - TLWCommunityWaterfallLayoutDelegate

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)layout heightForItemAtIndexPath:(NSIndexPath *)indexPath itemWidth:(CGFloat)width {
  TLWCommunityPost *post = self.posts[indexPath.item];
  return [post cellHeightForWidth:width];
}

#pragma mark - Lazy

- (TLWCommunityView *)myView {
  if (!_myView) {
    _myView = [[TLWCommunityView alloc] initWithFrame:CGRectZero];
  }
  return _myView;
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

