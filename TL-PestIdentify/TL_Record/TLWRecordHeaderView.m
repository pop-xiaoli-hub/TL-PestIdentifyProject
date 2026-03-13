//
//  TLWRecordHeaderView.m
//  TL-PestIdentify
//
//  Created by Tommy on 2026/3/13.
//

#import "TLWRecordHeaderView.h"
#import <Masonry/Masonry.h>

@interface TLWRecordHeaderView ()
@property (nonatomic, strong) UILabel *dateLabel;
@end

@implementation TLWRecordHeaderView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];

        _dateLabel = [[UILabel alloc] init];
        _dateLabel.textColor = [UIColor colorWithRed:0.29 green:0.29 blue:0.29 alpha:1];
        _dateLabel.font = [UIFont systemFontOfSize:20 weight:UIFontWeightSemibold];
        [self addSubview:_dateLabel];
        [_dateLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self).offset(14);
            make.centerY.equalTo(self);
        }];
    }
    return self;
}

- (void)configureWithDateString:(NSString *)dateString {
    _dateLabel.text = dateString;
}

@end
