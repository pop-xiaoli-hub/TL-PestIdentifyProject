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

@property (nonatomic, strong) UIImageView *avatarView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) UIView *redDot;
// User-type only
@property (nonatomic, strong) UIView *thumbnailView;
@property (nonatomic, strong) UIImageView *thumbnailImageView;
@property (nonatomic, strong) UILabel *timeLabel;

@end

@implementation TLWMessageCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor clearColor];
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    _avatarView = [[UIImageView alloc] init];
    _avatarView.layer.cornerRadius = 25;
    _avatarView.layer.masksToBounds = YES;
    _avatarView.contentMode = UIViewContentModeScaleAspectFill;
    [self.contentView addSubview:_avatarView];

    _titleLabel = [[UILabel alloc] init];
    _titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    _titleLabel.textColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:1];
    [self.contentView addSubview:_titleLabel];

    _subtitleLabel = [[UILabel alloc] init];
    _subtitleLabel.font = [UIFont systemFontOfSize:13];
    _subtitleLabel.textColor = [UIColor colorWithWhite:0.55 alpha:1];
    [self.contentView addSubview:_subtitleLabel];

    _redDot = [[UIView alloc] init];
    _redDot.backgroundColor = [UIColor colorWithRed:0.95 green:0.27 blue:0.27 alpha:1];
    _redDot.layer.cornerRadius = 4.5;
    _redDot.hidden = YES;
    [self.contentView addSubview:_redDot];

    _thumbnailView = [[UIView alloc] init];
    _thumbnailView.layer.cornerRadius = 6;
    _thumbnailView.layer.masksToBounds = YES;
    _thumbnailView.backgroundColor = [UIColor colorWithRed:0.56 green:0.78 blue:0.52 alpha:1];
    _thumbnailView.hidden = YES;
    _thumbnailImageView = [[UIImageView alloc] init];
    _thumbnailImageView.contentMode = UIViewContentModeScaleAspectFill;
    [_thumbnailView addSubview:_thumbnailImageView];
    [self.contentView addSubview:_thumbnailView];

    _timeLabel = [[UILabel alloc] init];
    _timeLabel.font = [UIFont systemFontOfSize:11];
    _timeLabel.textColor = [UIColor colorWithWhite:0.65 alpha:1];
    _timeLabel.textAlignment = NSTextAlignmentRight;
    _timeLabel.hidden = YES;
    [self.contentView addSubview:_timeLabel];

    // Avatar constraints (fixed, always visible)
    [_avatarView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView).offset(16);
        make.centerY.equalTo(self.contentView);
        make.width.height.mas_equalTo(50);
    }];

    // Red dot for notification-type (top-right of cell)
    [_redDot mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(9);
        make.right.equalTo(self.contentView).offset(-16);
        make.top.equalTo(self.contentView).offset(16);
    }];

    // Thumbnail for user-type (right side, vertically centered)
    [_thumbnailView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.contentView).offset(-16);
        make.centerY.equalTo(self.contentView);
        make.width.height.mas_equalTo(44);
    }];
    [_thumbnailImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.thumbnailView);
    }];

    // Time label: above thumbnail, right aligned
    [_timeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(_thumbnailView.mas_left).offset(-8);
        make.centerY.equalTo(self.contentView);
    }];

    // Title and subtitle: between avatar and right area
    [_titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_avatarView.mas_right).offset(12);
        make.right.lessThanOrEqualTo(_timeLabel.mas_left).offset(-8);
        make.bottom.equalTo(self.contentView.mas_centerY).offset(-2);
    }];

    [_subtitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_titleLabel);
        make.right.lessThanOrEqualTo(_timeLabel.mas_left).offset(-8);
        make.top.equalTo(self.contentView.mas_centerY).offset(2);
    }];
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
                                       placeholderImage:nil];
        } else {
            self.thumbnailImageView.image = nil;
        }

        // Red dot goes on thumbnail corner, must be above thumbnail
        _redDot.hidden = !item.hasUnread;
        [_redDot mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.width.height.mas_equalTo(9);
            make.right.equalTo(_thumbnailView).offset(3);
            make.top.equalTo(_thumbnailView).offset(-3);
        }];
        [self.contentView bringSubviewToFront:_redDot];

        // Title/subtitle right boundary: up to timeLabel
        [_titleLabel mas_updateConstraints:^(MASConstraintMaker *make) {
            make.right.lessThanOrEqualTo(_timeLabel.mas_left).offset(-8);
        }];
    } else {
        // Red dot goes top-right of cell
        _redDot.hidden = !item.hasUnread;
        [_redDot mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.width.height.mas_equalTo(9);
            make.right.equalTo(self.contentView).offset(-16);
            make.top.equalTo(self.contentView).offset(16);
        }];
        [_titleLabel mas_updateConstraints:^(MASConstraintMaker *make) {
            make.right.lessThanOrEqualTo(_redDot.mas_left).offset(-8);
        }];
    }
}

@end
