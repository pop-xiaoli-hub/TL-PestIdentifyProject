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

@interface TLWCommunityController () <UICollectionViewDataSource, TLWCommunityWaterfallLayoutDelegate>

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

    // TODO: 搜索按钮、上传按钮交互后续接入
    [self.myView.uploadButton addTarget:self action:@selector(tl_upload) forControlEvents:UIControlEventTouchUpInside];

    [self tl_fetchCommunityFeed];
}

#pragma mark - Actions

- (void)tl_upload {
    // TODO: 跳转到发布帖子/上传图片页面
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

@end

