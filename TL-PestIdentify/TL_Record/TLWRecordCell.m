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
  NSLog(@"pestName:%@", item.topPestName);


    NSString *imageURL = item.imageURL ?: @"";
    if (imageURL.length == 0) {
        [self tl_resetImagePlaceholder];
        return;
    }

    if ([imageURL hasPrefix:@"data:image"]) {
        [self tl_configureImageWithDataURL:imageURL];
        return;
    }

    NSURL *url = [NSURL URLWithString:imageURL];
    if (!url) {
        [self tl_resetImagePlaceholder];
        return;
    }

    [_photoView sd_setImageWithURL:url
                  placeholderImage:nil
                         completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *loadedURL) {
        if (image) {
            self->_photoView.backgroundColor = [UIColor clearColor];
        } else {
            [self tl_resetImagePlaceholder];
        }
    }];
}

- (void)tl_configureImageWithDataURL:(NSString *)dataURL {
    [_photoView sd_cancelCurrentImageLoad];

    NSRange commaRange = [dataURL rangeOfString:@","];
    if (commaRange.location == NSNotFound || commaRange.location >= dataURL.length - 1) {
      NSLog(@"[RecordCell] dataURL 格式异常，无法找到 base64 分隔符，length=%lu", (unsigned long)dataURL.length);
        [self tl_resetImagePlaceholder];
        return;
    }

    NSString *base64String = [dataURL substringFromIndex:commaRange.location + 1];
    NSString *prefix = [base64String substringToIndex:MIN((NSUInteger)60, base64String.length)];
    NSString *suffix = base64String.length > 60
        ? [base64String substringFromIndex:base64String.length - 60]
        : base64String;
    NSLog(@"[RecordCell] dataURL.length=%lu, base64.length=%lu",
          (unsigned long)dataURL.length,
          (unsigned long)base64String.length);
    NSLog(@"[RecordCell] base64.prefix=%@", prefix);
    NSLog(@"[RecordCell] base64.suffix=%@", suffix);

    NSData *imageData = [[NSData alloc] initWithBase64EncodedString:base64String
                                                            options:NSDataBase64DecodingIgnoreUnknownCharacters];
    NSLog(@"[RecordCell] imageData.length=%lu", (unsigned long)imageData.length);
    UIImage *image = imageData.length > 0 ? [UIImage imageWithData:imageData] : nil;
    if (!image) {
        [self tl_resetImagePlaceholder];
      NSLog(@"[RecordCell] UIImage 解码失败");
        return;
    }
    NSLog(@"[RecordCell] UIImage 解码成功 size=%@", NSStringFromCGSize(image.size));
    _photoView.image = image;
    _photoView.backgroundColor = [UIColor clearColor];
}

- (void)tl_resetImagePlaceholder {
    [_photoView sd_cancelCurrentImageLoad];
    _photoView.image = nil;
    _photoView.backgroundColor = [UIColor colorWithRed:0.85 green:0.90 blue:0.85 alpha:1];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    // CALayer 的 frame 不跟随 Auto Layout，需在 layoutSubviews 里手动更新
    CGFloat h = self.contentView.bounds.size.height;
    CGFloat w = self.contentView.bounds.size.width;
    _gradientLayer.frame = CGRectMake(0, h * 0.5, w, h * 0.5);
}

@end
