//
//  TLWCommunityPost.m
//  TL-PestIdentify
//

#import "TLWCommunityPost.h"

@interface TLWCommunityPost ()
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *cellHeightCache;
@end

@implementation TLWCommunityPost

- (instancetype)init {
    self = [super init];
    if (self) {
        _cellHeightCache = [NSMutableDictionary dictionary];
    }
    return self;
}

- (BOOL)applyCoverAspectRatioWithWidth:(CGFloat)width height:(CGFloat)height {
    if (width <= 0.0 || height <= 0.0) {
        return NO;
    }
    CGFloat ratio = height / width;
    if (self.imageAspectRatio != ratio) {
        [self.cellHeightCache removeAllObjects];
    }
    self.imageAspectRatio = ratio;
    return YES;
}

- (CGFloat)cellHeightForWidth:(CGFloat)width {
    CGFloat ratio = self.imageAspectRatio;//图片的高度除以宽度
    if (ratio <= 0.0) {
        ratio = 4.0 / 3.0;
    }

    NSString *cacheKey = [NSString stringWithFormat:@"%.17g|%.17g", (double)width, (double)ratio];
    NSNumber *cachedHeight = self.cellHeightCache[cacheKey];
    if (cachedHeight != nil) {
        return cachedHeight.doubleValue;
    }

    CGFloat imageHeight = width * ratio;//根据比例计算图片高度

    //标题和底部信息区域的预估高度，配合 Auto Layout 可获得较好的视觉效果
    CGFloat titleHeight = 40.0;//标题显示高度预留40
    CGFloat bottomInfoHeight = 32.0;
    CGFloat verticalPadding = 16.0;

    CGFloat cellHeight = imageHeight + titleHeight + bottomInfoHeight + verticalPadding;
    self.cellHeightCache[cacheKey] = @(cellHeight);
    return cellHeight;
}

+ (instancetype)postWithDictionary:(NSDictionary *)dict {
    TLWCommunityPost *post = [[TLWCommunityPost alloc] init];
    post.title = dict[@"title"] ?: @"";
    post.authorName = dict[@"userName"] ?: @"";
    post.likeCount = @(0);
    post.isLiked = NO;

    NSNumber *ratioNumber = dict[@"imageAspectRatio"];
    if (ratioNumber && ratioNumber.floatValue > 0.0) {
        post.imageAspectRatio = ratioNumber.floatValue;
    } else {
        post.imageAspectRatio = 0.75;
    }
    return post;
}



@end
