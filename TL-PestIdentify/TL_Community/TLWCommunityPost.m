//
//  TLWCommunityPost.m
//  TL-PestIdentify
//

#import "TLWCommunityPost.h"

@implementation TLWCommunityPost

- (CGFloat)cellHeightForWidth:(CGFloat)width {
    CGFloat ratio = self.imageAspectRatio;//图片的高度除以宽度
    if (ratio <= 0.0) {
        ratio = 4.0 / 3.0;
    }
    CGFloat imageHeight = width * ratio;//根据比例计算图片高度

    //标题和底部信息区域的预估高度，配合 Auto Layout 可获得较好的视觉效果
    CGFloat titleHeight = 40.0;//标题显示高度预留40
    CGFloat bottomInfoHeight = 32.0;
    CGFloat verticalPadding = 16.0;

    return imageHeight + titleHeight + bottomInfoHeight + verticalPadding;
}

+ (instancetype)postWithDictionary:(NSDictionary *)dict {
    TLWCommunityPost *post = [[TLWCommunityPost alloc] init];
    post.imageName = dict[@"imageUrl"] ?: @"";
    post.title = dict[@"title"] ?: @"";
    post.userName = dict[@"userName"] ?: @"";
    post.likeCount = [dict[@"likeCount"] integerValue];

    NSNumber *ratioNumber = dict[@"imageAspectRatio"];
    if (ratioNumber) {
        post.imageAspectRatio = ratioNumber.floatValue;
    } else {
        // 接口未返回时，给一个轻微随机的纵横比，让瀑布流更自然
        CGFloat base = 4.0 / 3.0;
        //CGFloat delta = ((arc4random_uniform(40) - 20) / 100.0f); // -0.2 ~ +0.2
      CGFloat delta = 0;
        post.imageAspectRatio = MAX(0.9, base + delta);
    }
    return post;
}

+ (NSArray<TLWCommunityPost *> *)mockPosts {
    NSMutableArray<TLWCommunityPost *> *array = [NSMutableArray array];

    NSArray *titles = @[
        @"菜心被蚜虫像蜂窝煤",
        @"叶片出现小黄点是不是病害？",
        @"番茄叶片卷曲发黄怎么办",
        @"柑橘叶片黑斑疑似炭疽病",
        @"辣椒叶子发黑干枯求助",
        @"白菜叶子被咬得千疮百孔"
    ];

    NSArray *users = @[
        @"王建军",
        @"用户2759",
        @"用户0867",
        @"用户498",
        @"用户0798",
        @"用户1203"
    ];

    NSArray<NSNumber *> *likes = @[@23, @16, @42, @89, @56, @35];
    NSArray<NSNumber *> *ratios = @[@0.8, @1.2, @0.95, @1.3, @0.9, @1.05];
  //NSArray<NSNumber *> *ratios = @[@0.8, @0.8, @0.8, @0.8, @0.8, @0.8];

    for (NSInteger i = 0; i < titles.count; i++) {
        TLWCommunityPost *post = [[TLWCommunityPost alloc] init];
        post.imageName = @"cm_placeholder"; // 占位图，后续可换成网络图片
        post.title = titles[i];
        post.userName = users[i];
        post.likeCount = likes[i].integerValue;
        post.imageAspectRatio = ratios[i].floatValue;
        [array addObject:post];
    }

    return array.copy;
}

@end

