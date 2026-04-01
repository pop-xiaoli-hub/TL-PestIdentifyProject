//
//  TLWHomeCustomCell.m
//  TL-PestIdentify
//
//  Created by xiaoli pop on 2026/3/9.
//

#import "TLWHomeCustomCell.h"
#import <Masonry.h>

@interface TLWHomeCustomCell ()

@property (nonatomic, strong) UIView *roundedBackgroundView;
@property (nonatomic, strong) UIImageView *avatarImageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *locationLabel;
@property (nonatomic, strong) UIView *yieldBadgeView;
@property (nonatomic, strong) UILabel *yieldLabel;
@property (nonatomic, strong) UIImageView *yieldIconView;
@property (nonatomic, strong) UIImageView *cropImageView;

@end

@implementation TLWHomeCustomCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setupSubviews];
    }
    return self;
}

- (void)setupSubviews {
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.backgroundColor = [UIColor clearColor];
    self.contentView.backgroundColor = [UIColor clearColor];

    _roundedBackgroundView = [[UIView alloc] init];
    _roundedBackgroundView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.96];
    _roundedBackgroundView.layer.cornerRadius = 16.0;
    _roundedBackgroundView.layer.masksToBounds = YES;

    [self.contentView addSubview:_roundedBackgroundView];

    [_roundedBackgroundView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView).offset(16.0);
        make.right.equalTo(self.contentView).offset(-16.0);
        make.top.equalTo(self.contentView).offset(6.0);
        make.bottom.equalTo(self.contentView).offset(-6.0);
    }];

    // 头像
    self.avatarImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"hp_avatar.png"]];
    self.avatarImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.avatarImageView.clipsToBounds = YES;
    self.avatarImageView.layer.cornerRadius = 30.0;
    [self.roundedBackgroundView addSubview:self.avatarImageView];

    // 标题和位置
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.text = @"我的种植物";
    self.titleLabel.textColor = [UIColor colorWithWhite:0.12 alpha:1.0];
    self.titleLabel.font = [UIFont systemFontOfSize:20.0 weight:UIFontWeightSemibold];

    self.locationLabel = [[UILabel alloc] init];
    self.locationLabel.text = @"杭州";
    self.locationLabel.textColor = [UIColor colorWithWhite:0.55 alpha:1.0];
    self.locationLabel.font = [UIFont systemFontOfSize:14.0];

    [self.roundedBackgroundView addSubview:self.titleLabel];
    [self.roundedBackgroundView addSubview:self.locationLabel];

    // 右侧产量 badge
    self.yieldBadgeView = [[UIView alloc] init];
    self.yieldBadgeView.backgroundColor = [UIColor clearColor];
    self.yieldBadgeView.layer.cornerRadius = 20.0;
    self.yieldBadgeView.layer.masksToBounds = YES;

    CAGradientLayer *yieldGradient = [CAGradientLayer layer];
    yieldGradient.startPoint = CGPointMake(0.0, 0.5);
    yieldGradient.endPoint = CGPointMake(1.0, 0.5);
    yieldGradient.colors = @[
        (__bridge id)[UIColor colorWithRed:0.09 green:0.93 blue:0.70 alpha:1.0].CGColor,
        (__bridge id)[UIColor colorWithRed:0.14 green:0.83 blue:0.96 alpha:1.0].CGColor
    ];
    yieldGradient.locations = @[@0.0, @1.0];
    yieldGradient.cornerRadius = 16.0;
    [self.yieldBadgeView.layer insertSublayer:yieldGradient atIndex:0];

    self.yieldLabel = [[UILabel alloc] init];
    self.yieldLabel.text = @"5200kg/ha";
    self.yieldLabel.textColor = [UIColor whiteColor];
    self.yieldLabel.font = [UIFont systemFontOfSize:16.0 weight:UIFontWeightSemibold];

    self.yieldIconView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"hp_yield_leaf.png"]];
    self.yieldIconView.contentMode = UIViewContentModeScaleAspectFit;
    self.yieldIconView.tintColor = [UIColor whiteColor];

    [self.roundedBackgroundView addSubview:self.yieldBadgeView];
    [self.yieldBadgeView addSubview:self.yieldLabel];
    [self.yieldBadgeView addSubview:self.yieldIconView];

    // 底部作物大图
    self.cropImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"hp_eg1.jpg"]];
    self.cropImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.cropImageView.clipsToBounds = YES;
    self.cropImageView.layer.cornerRadius = 16.0;
    [self.roundedBackgroundView addSubview:self.cropImageView];

    // 约束
    [self.avatarImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.roundedBackgroundView).offset(14.0);
        make.top.equalTo(self.roundedBackgroundView).offset(10.0);
        make.width.height.mas_equalTo(60.0);
    }];

    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.avatarImageView.mas_right).offset(7.0);
        make.top.equalTo(self.avatarImageView.mas_top).offset(6.0);
        make.right.lessThanOrEqualTo(self.yieldBadgeView.mas_left).offset(-8.0);
    }];

    [self.locationLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.titleLabel);
        make.top.equalTo(self.titleLabel.mas_bottom).offset(2.0);
    }];

    [self.yieldBadgeView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.avatarImageView);
        make.right.equalTo(self.roundedBackgroundView).offset(-14.0);
        make.height.mas_equalTo(40.0);
        make.width.greaterThanOrEqualTo(@110.0);
    }];

    [self.yieldIconView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.yieldBadgeView).offset(10.0);
        make.centerY.equalTo(self.yieldBadgeView);
        make.width.height.mas_equalTo(20.0);
    }];

    [self.yieldLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.yieldIconView.mas_right).offset(6.0);
        make.centerY.equalTo(self.yieldBadgeView);
        make.right.equalTo(self.yieldBadgeView).offset(-12.0);
    }];

    [self.cropImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.roundedBackgroundView).offset(10);
        make.right.equalTo(self.roundedBackgroundView).offset(-10);
        make.top.equalTo(self.avatarImageView.mas_bottom).offset(10.0);
        make.bottom.equalTo(self.roundedBackgroundView).offset(-10);
    }];

    // 更新渐变层 frame
    dispatch_async(dispatch_get_main_queue(), ^{
        yieldGradient.frame = self.yieldBadgeView.bounds;
    });
}

@end
