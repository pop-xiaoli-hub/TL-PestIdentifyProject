//
//  TLWCropCell.m
//  TL-PestIdentify
//

#import "TLWCropCell.h"

@interface TLWCropCell ()
@property (nonatomic, strong) CAGradientLayer *selectedGradient;
@end

@implementation TLWCropCell

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

    _selectedGradient = [CAGradientLayer layer];
    _selectedGradient.colors = @[
        (__bridge id)[UIColor colorWithRed:0.0 green:1.0 blue:0.588 alpha:1.0].CGColor,
        (__bridge id)[UIColor colorWithRed:0.0 green:0.812 blue:0.773 alpha:1.0].CGColor,
    ];
    _selectedGradient.startPoint = CGPointMake(0.05, 0.1);
    _selectedGradient.endPoint   = CGPointMake(1.0,  0.9);
    _selectedGradient.cornerRadius = 13;
    _selectedGradient.hidden = YES;
    [self.contentView.layer addSublayer:_selectedGradient];

    _nameLabel = [[UILabel alloc] init];
    _nameLabel.font          = [UIFont systemFontOfSize:20];
    _nameLabel.textColor     = [UIColor colorWithRed:0.176 green:0.176 blue:0.176 alpha:1.0];
    _nameLabel.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:_nameLabel];
    _nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [_nameLabel.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor],
        [_nameLabel.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
    ]];

    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _selectedGradient.frame = self.contentView.bounds;
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    _selectedGradient.hidden = !selected;
    _nameLabel.textColor = selected
        ? UIColor.whiteColor
        : [UIColor colorWithRed:0.176 green:0.176 blue:0.176 alpha:1.0];
    _nameLabel.font = selected
        ? [UIFont systemFontOfSize:20 weight:UIFontWeightBold]
        : [UIFont systemFontOfSize:20];
}

@end
