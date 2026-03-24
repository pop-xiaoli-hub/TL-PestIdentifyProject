//
//  TLWAddCropCell.m
//  TL-PestIdentify
//

#import "TLWAddCropCell.h"

@implementation TLWAddCropCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (!self) return nil;

    self.layer.cornerRadius = 13;
    self.clipsToBounds = YES;

    UIImageView *bgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cropRectangle"]];
    bgView.contentMode = UIViewContentModeScaleToFill;
    bgView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    bgView.frame = self.contentView.bounds;
    [self.contentView addSubview:bgView];

    UIImageView *addIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"iconAdd"]];
    addIcon.contentMode = UIViewContentModeScaleAspectFit;
    [self.contentView addSubview:addIcon];
    addIcon.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [addIcon.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor],
        [addIcon.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
        [addIcon.widthAnchor  constraintEqualToConstant:28],
        [addIcon.heightAnchor constraintEqualToConstant:28],
    ]];

    return self;
}

@end
