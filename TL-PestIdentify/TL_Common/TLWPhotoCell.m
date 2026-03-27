//
//  TLWPhotoCell.m
//  TL-PestIdentify
//

#import "TLWPhotoCell.h"

@implementation TLWPhotoCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _requestID = PHInvalidImageRequestID;
        _imageView = [[UIImageView alloc] initWithFrame:self.bounds];
        _imageView.contentMode         = UIViewContentModeScaleAspectFill;
        _imageView.clipsToBounds       = YES;
        _imageView.autoresizingMask    = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.contentView addSubview:_imageView];
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    if (_requestID != PHInvalidImageRequestID) {
        [[PHImageManager defaultManager] cancelImageRequest:_requestID];
        _requestID = PHInvalidImageRequestID;
    }
    _imageView.image = nil;
}

@end
