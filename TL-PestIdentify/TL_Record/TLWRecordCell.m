//
//  TLWRecordCell.m
//  TL-PestIdentify
//
//  Created by Tommy on 2026/3/13.
//

#import "TLWRecordCell.h"
#import "TLWRecordModel.h"
#import <Masonry/Masonry.h>
#import <SDWebImage/UIImageView+WebCache.h>

@interface TLWRecordCell ()
@property (nonatomic, strong) CAGradientLayer *gradientLayer;
@end

@implementation TLWRecordCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // contentView 已设 masksToBounds，子视图无需重复设 clipsToBounds
        self.contentView.layer.cornerRadius = 20;
        self.contentView.layer.masksToBounds = YES;

        _photoView = [[UIImageView alloc] init];
        _photoView.contentMode = UIViewContentModeScaleAspectFill;
        // 占位背景色，图片加载成功后会被覆盖
        _photoView.backgroundColor = [UIColor colorWithRed:0.85 green:0.90 blue:0.85 alpha:1];
        [self.contentView addSubview:_photoView];
        [_photoView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.contentView);
        }];

        // 底部深色渐变，让白色病虫害名称在任何图片上都清晰可读
        _gradientLayer = [CAGradientLayer layer];
        _gradientLayer.colors = @[
            (__bridge id)[UIColor colorWithWhite:0.77 alpha:0].CGColor,
            (__bridge id)[UIColor colorWithWhite:0 alpha:0.7].CGColor
        ];
        _gradientLayer.locations = @[@0.0, @1.0];
        [self.contentView.layer addSublayer:_gradientLayer];

        _nameLabel = [[UILabel alloc] init];
        _nameLabel.textColor = [UIColor whiteColor];
        _nameLabel.font = [UIFont boldSystemFontOfSize:18];
        _nameLabel.textAlignment = NSTextAlignmentCenter;
        [self.contentView addSubview:_nameLabel];
        [_nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self.contentView);
            make.bottom.equalTo(self.contentView).offset(-12);
        }];
    }
    return self;
}

- (void)configureWithItem:(TLWRecordItem *)item {
    _nameLabel.text = item.topPestName;

    if (item.imageURL.length > 0) {
        // 图片加载成功后移除占位色，避免颜色闪烁
        [_photoView sd_setImageWithURL:[NSURL URLWithString:item.imageURL]
                      placeholderImage:nil
                             completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *url) {
            if (image) {
                self->_photoView.backgroundColor = [UIColor clearColor];
            }
        }];
    } else {
        // 无 URL 时清除上一次 cell 复用残留的图片
        [_photoView sd_cancelCurrentImageLoad];
        _photoView.image = nil;
        _photoView.backgroundColor = [UIColor colorWithRed:0.85 green:0.90 blue:0.85 alpha:1];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    // CALayer 的 frame 不跟随 Auto Layout，需在 layoutSubviews 里手动更新
    CGFloat h = self.contentView.bounds.size.height;
    CGFloat w = self.contentView.bounds.size.width;
    _gradientLayer.frame = CGRectMake(0, h * 0.5, w, h * 0.5);
}

@end
