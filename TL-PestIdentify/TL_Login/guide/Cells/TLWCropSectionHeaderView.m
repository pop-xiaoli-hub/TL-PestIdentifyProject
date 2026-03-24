//
//  TLWCropSectionHeaderView.m
//  TL-PestIdentify
//

#import "TLWCropSectionHeaderView.h"

@implementation TLWCropSectionHeaderView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (!self) return nil;

    _titleLabel = [[UILabel alloc] init];
    _titleLabel.font      = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
    _titleLabel.textColor = [UIColor colorWithRed:0.176 green:0.176 blue:0.176 alpha:0.8];
    [self addSubview:_titleLabel];
    _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [_titleLabel.leftAnchor constraintEqualToAnchor:self.leftAnchor constant:0],
        [_titleLabel.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-4],
    ]];

    return self;
}

@end
