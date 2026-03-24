//
//  TLWCustomInputCell.m
//  TL-PestIdentify
//

#import "TLWCustomInputCell.h"

@implementation TLWCustomInputCell

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

    _textField = [[UITextField alloc] init];
    _textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"请输入" attributes:@{
        NSForegroundColorAttributeName: [UIColor colorWithRed:0.569 green:0.569 blue:0.569 alpha:1.0],
        NSFontAttributeName:            [UIFont systemFontOfSize:20],
    }];
    _textField.textColor     = [UIColor colorWithRed:0.176 green:0.176 blue:0.176 alpha:1.0];
    _textField.font          = [UIFont systemFontOfSize:20];
    _textField.textAlignment = NSTextAlignmentCenter;
    _textField.borderStyle   = UITextBorderStyleNone;
    _textField.backgroundColor = UIColor.clearColor;
    _textField.returnKeyType = UIReturnKeyDone;
    [self.contentView addSubview:_textField];
    _textField.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [_textField.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor],
        [_textField.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
        [_textField.leftAnchor  constraintEqualToAnchor:self.contentView.leftAnchor  constant:8],
        [_textField.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-8],
    ]];

    return self;
}

@end
