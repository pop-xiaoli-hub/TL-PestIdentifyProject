//
//  TLWPhotoCell.m
//  TL-PestIdentify
//

#import "TLWPhotoCell.h"

NSString * const kTLWPhotoCellID = @"TLWPhotoCell";

@interface TLWPhotoCell ()

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIView *selectCircle;
@property (nonatomic, strong) UILabel *selectNumLabel;
@property (nonatomic, assign) BOOL showsSelectionIndicator;
@property (nonatomic, assign) NSInteger selectionIndex;
@property (nonatomic, assign) BOOL useCheckmarkStyle;

@end

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

        _selectCircle = [[UIView alloc] init];
        _selectCircle.layer.cornerRadius = 13;
        _selectCircle.layer.borderWidth = 2.0;
        _selectCircle.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.85].CGColor;
        _selectCircle.backgroundColor = [UIColor colorWithWhite:0 alpha:0.15];
        _selectCircle.userInteractionEnabled = NO;
        [self.contentView addSubview:_selectCircle];

        _selectNumLabel = [[UILabel alloc] init];
        _selectNumLabel.layer.cornerRadius = 13;
        _selectNumLabel.layer.masksToBounds = YES;
        _selectNumLabel.backgroundColor = [UIColor colorWithRed:0.97 green:0.60 blue:0.15 alpha:1.0];
        _selectNumLabel.textColor = UIColor.whiteColor;
        _selectNumLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightBold];
        _selectNumLabel.textAlignment = NSTextAlignmentCenter;
        _selectNumLabel.userInteractionEnabled = NO;
        [self.contentView addSubview:_selectNumLabel];

        [self setShowsSelectionIndicator:NO];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    CGFloat size = 26;
    CGFloat margin = 6;
    CGRect badgeFrame = CGRectMake(self.contentView.bounds.size.width - size - margin,
                                   margin,
                                   size,
                                   size);
    self.selectCircle.frame = badgeFrame;
    self.selectNumLabel.frame = badgeFrame;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    if (_requestID != PHInvalidImageRequestID) {
        [[PHImageManager defaultManager] cancelImageRequest:_requestID];
        _requestID = PHInvalidImageRequestID;
    }
    _imageView.image = nil;
    self.selectionIndex = 0;
    self.useCheckmarkStyle = NO;
    [self setShowsSelectionIndicator:NO];
}

- (void)setShowsSelectionIndicator:(BOOL)showsSelectionIndicator {
    _showsSelectionIndicator = showsSelectionIndicator;
    [self updateSelectionViews];
}

- (void)configureWithSelectionIndex:(NSInteger)index useCheckmarkStyle:(BOOL)useCheckmarkStyle {
    self.selectionIndex = index;
    self.useCheckmarkStyle = useCheckmarkStyle;
    [self updateSelectionViews];
}

- (void)updateSelectionViews {
    if (!self.showsSelectionIndicator) {
        self.selectCircle.hidden = YES;
        self.selectNumLabel.hidden = YES;
        return;
    }

    if (self.selectionIndex > 0) {
        self.selectCircle.hidden = YES;
        self.selectNumLabel.hidden = NO;
        self.selectNumLabel.text = self.useCheckmarkStyle ? @"✓" : [NSString stringWithFormat:@"%ld", (long)self.selectionIndex];
    } else {
        self.selectCircle.hidden = NO;
        self.selectNumLabel.hidden = YES;
        self.selectNumLabel.text = nil;
    }
}

@end
