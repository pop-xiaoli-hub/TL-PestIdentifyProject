//
//  TLWMessageCell.m
//  TL-PestIdentify
//
//  Created by Tommy-MrWu on 2026/3/15.
//  职责：实现消息列表单元组件。
//
#import "TLWMessageCell.h"
#import <Masonry/Masonry.h>
#import <SDWebImage/SDWebImage.h>

@interface TLWMessageCell ()

@property (nonatomic, strong) UIView *cardShadowView;
@property (nonatomic, strong) UIView *cardContainerView;
@property (nonatomic, strong) UIView *cardHighlightView;
@property (nonatomic, strong) UIImageView *avatarView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) UIView *redDot;
// User-type only
@property (nonatomic, strong) UIView *thumbnailView;
@property (nonatomic, strong) UIImageView *thumbnailImageView;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, assign) BOOL elderModeEnabled;
@property (nonatomic, strong) MASConstraint *avatarSizeConstraint;
@property (nonatomic, strong) MASConstraint *avatarLeftConstraint;
@property (nonatomic, strong) MASConstraint *thumbnailSizeConstraint;
@property (nonatomic, strong) MASConstraint *thumbnailRightConstraint;
@property (nonatomic, strong) MASConstraint *redDotSizeConstraint;
@property (nonatomic, strong) MASConstraint *redDotTopConstraint;
@property (nonatomic, strong) MASConstraint *redDotRightConstraint;

@end

@implementation TLWMessageCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor clearColor];
        self.selectedBackgroundView = [[UIView alloc] init];
        self.selectedBackgroundView.backgroundColor = [UIColor clearColor];
        [self setupUI];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.cardShadowView.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.cardShadowView.bounds cornerRadius:22.0].CGPath;
}

- (void)setupUI {
    self.cardShadowView = [[UIView alloc] init];
    self.cardShadowView.backgroundColor = [UIColor clearColor];
    self.cardShadowView.layer.shadowColor = [UIColor colorWithRed:0.05 green:0.31 blue:0.28 alpha:1.0].CGColor;
    self.cardShadowView.layer.shadowOpacity = 0.18;
    self.cardShadowView.layer.shadowRadius = 18.0;
    self.cardShadowView.layer.shadowOffset = CGSizeMake(0.0, 8.0);
    [self.contentView addSubview:self.cardShadowView];

    [self.cardShadowView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView).offset(14.0);
        make.right.equalTo(self.contentView).offset(-14.0);
        make.top.equalTo(self.contentView).offset(7.0);
        make.bottom.equalTo(self.contentView).offset(-7.0);
    }];

    self.cardContainerView = [[UIView alloc] init];
    self.cardContainerView.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.90];
    self.cardContainerView.layer.cornerRadius = 22.0;
    self.cardContainerView.layer.masksToBounds = YES;
    self.cardContainerView.layer.borderWidth = 1.0;
    self.cardContainerView.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.72].CGColor;
    [self.cardShadowView addSubview:self.cardContainerView];

    [self.cardContainerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.cardShadowView);
    }];

    self.cardHighlightView = [[UIView alloc] init];
    self.cardHighlightView.userInteractionEnabled = NO;
    self.cardHighlightView.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.22];
    [self.cardContainerView addSubview:self.cardHighlightView];

    [self.cardHighlightView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.right.equalTo(self.cardContainerView);
        make.height.mas_equalTo(28.0);
    }];

    _avatarView = [[UIImageView alloc] init];
    _avatarView.layer.cornerRadius = 26;
    _avatarView.layer.masksToBounds = YES;
    _avatarView.contentMode = UIViewContentModeScaleAspectFill;
    _avatarView.layer.borderWidth = 1.0;
    _avatarView.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.9].CGColor;
    [self.cardContainerView addSubview:_avatarView];

    _titleLabel = [[UILabel alloc] init];
    _titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    _titleLabel.textColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:1];
    [self.cardContainerView addSubview:_titleLabel];

    _subtitleLabel = [[UILabel alloc] init];
    _subtitleLabel.font = [UIFont systemFontOfSize:13];
    _subtitleLabel.textColor = [UIColor colorWithWhite:0.40 alpha:1];
    [self.cardContainerView addSubview:_subtitleLabel];

    _redDot = [[UIView alloc] init];
    _redDot.backgroundColor = [UIColor colorWithRed:0.95 green:0.27 blue:0.27 alpha:1];
    _redDot.layer.cornerRadius = 5.0;
    _redDot.layer.borderWidth = 2.0;
    _redDot.layer.borderColor = [UIColor whiteColor].CGColor;
    _redDot.hidden = YES;
    [self.cardContainerView addSubview:_redDot];

    _thumbnailView = [[UIView alloc] init];
    _thumbnailView.layer.cornerRadius = 10;
    _thumbnailView.layer.masksToBounds = YES;
    _thumbnailView.backgroundColor = [UIColor colorWithRed:0.56 green:0.78 blue:0.52 alpha:1];
    _thumbnailView.hidden = YES;
    _thumbnailView.layer.borderWidth = 1.0;
    _thumbnailView.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.85].CGColor;
    _thumbnailImageView = [[UIImageView alloc] init];
    _thumbnailImageView.contentMode = UIViewContentModeScaleAspectFill;
    [_thumbnailView addSubview:_thumbnailImageView];
    [self.cardContainerView addSubview:_thumbnailView];

    _timeLabel = [[UILabel alloc] init];
    _timeLabel.font = [UIFont systemFontOfSize:11];
    _timeLabel.textColor = [UIColor colorWithWhite:0.50 alpha:1];
    _timeLabel.textAlignment = NSTextAlignmentRight;
    _timeLabel.hidden = YES;
    [self.cardContainerView addSubview:_timeLabel];

    // Avatar constraints (fixed, always visible)
    [_avatarView mas_makeConstraints:^(MASConstraintMaker *make) {
        self.avatarLeftConstraint = make.left.equalTo(self.cardContainerView).offset(16);
        make.centerY.equalTo(self.cardContainerView);
        self.avatarSizeConstraint = make.width.height.mas_equalTo(52);
    }];

    // Red dot for notification-type (top-right of cell)
    [_redDot mas_makeConstraints:^(MASConstraintMaker *make) {
        self.redDotSizeConstraint = make.width.height.mas_equalTo(10);
        self.redDotRightConstraint = make.right.equalTo(self.cardContainerView).offset(-18);
        self.redDotTopConstraint = make.top.equalTo(self.cardContainerView).offset(18);
    }];

    // Thumbnail for user-type (right side, vertically centered)
    [_thumbnailView mas_makeConstraints:^(MASConstraintMaker *make) {
        self.thumbnailRightConstraint = make.right.equalTo(self.cardContainerView).offset(-16);
        make.centerY.equalTo(self.cardContainerView);
        self.thumbnailSizeConstraint = make.width.height.mas_equalTo(48);
    }];
    [_thumbnailImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.thumbnailView);
    }];

    // Time label: above thumbnail, right aligned
    [_timeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(_thumbnailView.mas_left).offset(-8);
        make.centerY.equalTo(self.cardContainerView);
    }];

    // Title and subtitle: between avatar and right area
    [_titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_avatarView.mas_right).offset(12);
        make.right.lessThanOrEqualTo(_timeLabel.mas_left).offset(-8);
        make.bottom.equalTo(self.cardContainerView.mas_centerY).offset(-2);
    }];

    [_subtitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_titleLabel);
        make.right.lessThanOrEqualTo(_timeLabel.mas_left).offset(-8);
        make.top.equalTo(self.cardContainerView.mas_centerY).offset(2);
    }];

    [self configureElderModeEnabled:NO];
}

- (void)configureElderModeEnabled:(BOOL)enabled {
    self.elderModeEnabled = enabled;
    self.titleLabel.font = [UIFont systemFontOfSize:(enabled ? 19 : 16) weight:UIFontWeightSemibold];
    self.subtitleLabel.font = [UIFont systemFontOfSize:(enabled ? 16 : 13)];
    self.timeLabel.font = [UIFont systemFontOfSize:(enabled ? 14 : 11)];
    self.avatarView.layer.cornerRadius = enabled ? 32.0 : 26.0;
    self.thumbnailView.layer.cornerRadius = enabled ? 12.0 : 10.0;
    self.redDot.layer.cornerRadius = enabled ? 6.0 : 5.0;

    [self.avatarSizeConstraint setOffset:(enabled ? 64.0 : 52.0)];
    [self.avatarLeftConstraint setOffset:(enabled ? 18.0 : 16.0)];
    [self.thumbnailSizeConstraint setOffset:(enabled ? 58.0 : 48.0)];
    [self.thumbnailRightConstraint setOffset:(enabled ? -18.0 : -16.0)];
    [self.redDotSizeConstraint setOffset:(enabled ? 12.0 : 10.0)];
}

- (void)configureWithItem:(TLWMessageItem *)item {
    if (item.avatarUrl.length > 0) {
        [_avatarView sd_setImageWithURL:[NSURL URLWithString:item.avatarUrl]
                       placeholderImage:[UIImage imageNamed:@"forkAvatar"]];
    } else {
        _avatarView.image = [UIImage imageNamed:item.avatarImageName];
    }
    _titleLabel.text = item.title;
    _subtitleLabel.text = item.subtitle;

    BOOL isUser = (item.type == TLWMessageItemTypeUser);

    _thumbnailView.hidden = !isUser;
    _timeLabel.hidden = !isUser;
    _timeLabel.text = item.timeString;

    if (isUser) {
        // Load post cover image
        if (item.postImageUrl.length > 0) {
            [self.thumbnailImageView sd_setImageWithURL:[NSURL URLWithString:item.postImageUrl]
                                      placeholderImage:nil
                                               options:SDWebImageAvoidAutoSetImage
                                             completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                if (!image) return;
                if (cacheType == SDImageCacheTypeNone || cacheType == SDImageCacheTypeMemory) {
                    // 非内存缓存命中时淡入，避免突变闪烁
                    self.thumbnailImageView.alpha = 0;
                    self.thumbnailImageView.image = image;
                    [UIView animateWithDuration:0.2 animations:^{
                        self.thumbnailImageView.alpha = 1;
                    }];
                } else {
                    self.thumbnailImageView.image = image;
                }
            }];
        } else {
            self.thumbnailImageView.image = nil;
        }

        // Red dot goes on thumbnail corner, must be above thumbnail
        _redDot.hidden = !item.hasUnread;
        [_redDot mas_remakeConstraints:^(MASConstraintMaker *make) {
            self.redDotSizeConstraint = make.width.height.mas_equalTo(self.elderModeEnabled ? 12.0 : 10.0);
            make.right.equalTo(_thumbnailView).offset(3);
            make.top.equalTo(_thumbnailView).offset(-3);
        }];
        [self.cardContainerView bringSubviewToFront:_redDot];

        // Title/subtitle right boundary: up to timeLabel
        [_titleLabel mas_updateConstraints:^(MASConstraintMaker *make) {
            make.right.lessThanOrEqualTo(_timeLabel.mas_left).offset(-8);
        }];
    } else {
        // Red dot goes top-right of cell
        _redDot.hidden = !item.hasUnread;
        [_redDot mas_remakeConstraints:^(MASConstraintMaker *make) {
            self.redDotSizeConstraint = make.width.height.mas_equalTo(self.elderModeEnabled ? 12.0 : 10.0);
            self.redDotRightConstraint = make.right.equalTo(self.cardContainerView).offset(self.elderModeEnabled ? -20.0 : -18.0);
            self.redDotTopConstraint = make.top.equalTo(self.cardContainerView).offset(self.elderModeEnabled ? 20.0 : 18.0);
        }];
        [_titleLabel mas_updateConstraints:^(MASConstraintMaker *make) {
            make.right.lessThanOrEqualTo(_redDot.mas_left).offset(-8);
        }];
    }
}

@end
