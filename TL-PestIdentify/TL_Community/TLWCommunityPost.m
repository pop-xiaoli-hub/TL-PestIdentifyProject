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
    post.title = dict[@"title"] ?: @"";
    post.authorName = dict[@"userName"] ?: @"";
    post.likeCount = @(0);
    post.favoriteCount = @(0);
    post.isLiked = NO;
    post.isFavorited = NO;

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



@end
