//
//  TLWSearchResultController.m
//  TL-PestIdentify
//

#import "TLWSearchResultController.h"
#import "TLWSearchResultView.h"
#import "TLWCommunityCell.h"
#import "TLWCommunityPost.h"
#import "TLWCommunityWaterfallLayout.h"
#import "TLWPostDetailController.h"
#import "TLWSDKManager.h"

static NSString *const kSearchResultCellID = @"TLWSearchResultCell";

@interface TLWSearchResultController () <UICollectionViewDataSource, UICollectionViewDelegate, TLWCommunityWaterfallLayoutDelegate>

@property (nonatomic, strong) TLWSearchResultView *myView;

@end

@implementation TLWSearchResultController

- (void)viewDidLoad {
  [super viewDidLoad];
  self.view = self.myView;
  self.posts = self.posts ?: [NSMutableArray array];
  self.recommendations = self.recommendations ?: @[];
  self.keywordSuggestions = self.keywordSuggestions ?: @[];

  [self.myView tl_updateQueryText:self.queryText ?: @""];
  [self.myView tl_setEmptyHidden:(self.posts.count > 0)];

  UICollectionView *collectionView = self.myView.collectionView;
  collectionView.dataSource = self;
  collectionView.delegate = self;
  [(TLWCommunityWaterfallLayout *)collectionView.collectionViewLayout setDelegate:self];
  [collectionView registerClass:[TLWCommunityCell class] forCellWithReuseIdentifier:kSearchResultCellID];

  [self.myView.closeButton addTarget:self action:@selector(tl_closeTapped) forControlEvents:UIControlEventTouchUpInside];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
  return UIStatusBarStyleLightContent;
}

- (TLWSearchResultView *)myView {
  if (!_myView) {
    _myView = [[TLWSearchResultView alloc] initWithFrame:CGRectZero];
  }
  return _myView;
}

- (TLWCommunityPost *)tl_postFromDto:(AGPostResponseDto *)dto {
  if (!dto) {
    return nil;
  }

  TLWCommunityPost *post = [TLWCommunityPost new];
  post._id = dto._id;
  post.title = dto.title ?: @"";
  post.content = dto.content ?: @"";
  post.images = dto.images ?: @[];
  post.tags = dto.tags ?: @[];
  post.authorName = dto.authorName ?: @"";
  post.authorAvatar = dto.authorAvatar ?: @"";
  post.likeCount = dto.likeCount ?: @0;
  post.isLiked = dto.isLiked.boolValue;
  post.favoriteCount = dto.favoriteCount ?: @0;
  post.createdAt = dto.createdAt;

  id imageSizes = [dto respondsToSelector:NSSelectorFromString(@"imageSizes")] ? [dto valueForKey:@"imageSizes"] : nil;
  id coverSize = [imageSizes isKindOfClass:[NSArray class]] ? [imageSizes firstObject] : nil;
  NSNumber *coverWidth = [coverSize respondsToSelector:NSSelectorFromString(@"width")] ? [coverSize valueForKey:@"width"] : nil;
  NSNumber *coverHeight = [coverSize respondsToSelector:NSSelectorFromString(@"height")] ? [coverSize valueForKey:@"height"] : nil;
  [post applyCoverAspectRatioWithWidth:coverWidth.doubleValue height:coverHeight.doubleValue];
  return post;
}

- (void)tl_applyFallbackAspectRatioToPost:(TLWCommunityPost *)post atIndex:(NSInteger)index {
  if (post.imageAspectRatio <= 0.0) {
    post.imageAspectRatio = index == 0 ? 0.60 : 0.75;
  }
}

- (void)tl_reloadPostWithId:(NSNumber *)postId {
  if (!postId) {
    return;
  }

  __weak typeof(self) weakSelf = self;
  [[TLWSDKManager shared] getPostDetailWithId:postId completionHandler:^(AGResultPostResponseDto *output, NSError *error) {
    dispatch_async(dispatch_get_main_queue(), ^{
      __strong typeof(weakSelf) strongSelf = weakSelf;
      if (!strongSelf) return;

      if (error || !output || output.code.integerValue != 200 || !output.data) {
        if ([[TLWSDKManager shared].sessionManager shouldAttemptTokenRefreshForCode:output.code error:error]) {
          [[TLWSDKManager shared].sessionManager handleUnauthorizedWithRetry:^{
            [strongSelf tl_reloadPostWithId:postId];
          }];
          return;
        }
        return;
      }

      NSInteger targetIndex = NSNotFound;
      for (NSInteger i = 0; i < strongSelf.posts.count; i++) {
        TLWCommunityPost *post = strongSelf.posts[i];
        if ([post._id isEqualToNumber:postId]) {
          targetIndex = i;
          break;
        }
      }

      if (targetIndex == NSNotFound) {
        return;
      }

      TLWCommunityPost *updatedPost = [strongSelf tl_postFromDto:output.data];
      TLWCommunityPost *oldPost = strongSelf.posts[targetIndex];
      if (updatedPost.imageAspectRatio <= 0.0) {
        updatedPost.imageAspectRatio = oldPost.imageAspectRatio;
      }
      strongSelf.posts[targetIndex] = updatedPost;

      [strongSelf.myView tl_setEmptyHidden:(strongSelf.posts.count > 0)];
      NSIndexPath *indexPath = [NSIndexPath indexPathForItem:targetIndex inSection:0];
      if ([[strongSelf.myView.collectionView indexPathsForVisibleItems] containsObject:indexPath]) {
        [strongSelf.myView.collectionView reloadItemsAtIndexPaths:@[ indexPath ]];
      } else {
        [strongSelf.myView.collectionView reloadData];
      }
    });
  }];
}

- (void)tl_closeTapped {
  [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
  return self.posts.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
  TLWCommunityCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kSearchResultCellID forIndexPath:indexPath];
  TLWCommunityPost *post = self.posts[indexPath.item];
  [self tl_applyFallbackAspectRatioToPost:post atIndex:indexPath.item];
  [cell configureWithPost:post];
  return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
  if (indexPath.item >= self.posts.count) {
    return;
  }

  TLWCommunityPost *post = self.posts[indexPath.item];
  TLWPostDetailController *detailVC = [[TLWPostDetailController alloc] init];
  detailVC._id = post._id;
  detailVC.post = post;
  detailVC.hasCollectedPosts = self.hasCollectedPosts;
  detailVC.hidesBottomBarWhenPushed = YES;

  __weak typeof(self) weakSelf = self;
  detailVC.reloadPosts = ^(NSNumber * _Nonnull postId) {
    __strong typeof(weakSelf) strongSelf = weakSelf;
    if (!strongSelf) return;
    [strongSelf tl_reloadPostWithId:postId];
  };

  [self.navigationController pushViewController:detailVC animated:YES];
}

#pragma mark - TLWCommunityWaterfallLayoutDelegate

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionView *)layout heightForItemAtIndexPath:(NSIndexPath *)indexPath itemWidth:(CGFloat)width {
  TLWCommunityPost *post = self.posts[indexPath.item];
  [self tl_applyFallbackAspectRatioToPost:post atIndex:indexPath.item];
  return [post cellHeightForWidth:width];
}

@end
