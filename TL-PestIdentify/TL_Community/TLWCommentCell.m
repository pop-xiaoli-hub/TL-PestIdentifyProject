//
//  TLWCommentCell.m
//  TL-PestIdentify
//

#import "TLWCommentCell.h"
#import <Masonry/Masonry.h>
#import <SDWebImage/UIImageView+WebCache.h>

#pragma mark - TLWCommentModel

@implementation TLWCommentModel
@end

#pragma mark - TLWCommentCell

@interface TLWCommentCell ()
@property (nonatomic, strong) UIImageView *avatarView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) UILabel *contentLabel;
@property (nonatomic, strong) UILabel *likeLabel;
@property (nonatomic, strong) UIImageView *likeIcon;
@end

@implementation TLWCommentCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        [self setupSubviews];
    }
    return self;
}

- (void)setupSubviews {
    // Avatar
    self.avatarView = [[UIImageView alloc] init];
    self.avatarView.contentMode = UIViewContentModeScaleAspectFill;
    self.avatarView.clipsToBounds = YES;
    self.avatarView.layer.cornerRadius = 18.0;
    self.avatarView.backgroundColor = [UIColor colorWithWhite:0.88 alpha:1.0];
    self.avatarView.image = [UIImage imageNamed:@"hp_avator.png"];
    [self.contentView addSubview:self.avatarView];

    // Name
    self.nameLabel = [[UILabel alloc] init];
    self.nameLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
    self.nameLabel.textColor = [UIColor colorWithWhite:0.15 alpha:1.0];
    [self.contentView addSubview:self.nameLabel];

    // Time
    self.timeLabel = [[UILabel alloc] init];
    self.timeLabel.font = [UIFont systemFontOfSize:11];
    self.timeLabel.textColor = [UIColor colorWithWhite:0.55 alpha:1.0];
    [self.contentView addSubview:self.timeLabel];

    // Content
    self.contentLabel = [[UILabel alloc] init];
    self.contentLabel.font = [UIFont systemFontOfSize:14];
    self.contentLabel.textColor = [UIColor colorWithWhite:0.2 alpha:1.0];
    self.contentLabel.numberOfLines = 0;
    [self.contentView addSubview:self.contentLabel];

    // Like icon
    self.likeIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cp_heart.png"]];
    self.likeIcon.contentMode = UIViewContentModeScaleAspectFit;
    self.likeIcon.tintColor = [UIColor colorWithRed:1.0 green:0.35 blue:0.35 alpha:1.0];
    [self.contentView addSubview:self.likeIcon];

    // Like count
    self.likeLabel = [[UILabel alloc] init];
    self.likeLabel.font = [UIFont systemFontOfSize:11];
    self.likeLabel.textColor = [UIColor colorWithWhite:0.5 alpha:1.0];
    [self.contentView addSubview:self.likeLabel];

    // Separator line
    UIView *separator = [[UIView alloc] init];
    separator.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
    [self.contentView addSubview:separator];

    // Layout
    [self.avatarView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView).offset(14);
        make.left.equalTo(self.contentView).offset(16);
        make.width.height.mas_equalTo(36);
    }];

    [self.nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.avatarView);
        make.left.equalTo(self.avatarView.mas_right).offset(10);
        make.right.lessThanOrEqualTo(self.likeIcon.mas_left).offset(-8);
    }];

    [self.timeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.nameLabel.mas_bottom).offset(2);
        make.left.equalTo(self.nameLabel);
    }];

    [self.likeIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.avatarView);
        make.right.equalTo(self.likeLabel.mas_left).offset(-4);
        make.width.height.mas_equalTo(15);
    }];

    [self.likeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.avatarView);
        make.right.equalTo(self.contentView).offset(-16);
    }];

    [self.contentLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.avatarView.mas_bottom).offset(8);
        make.left.equalTo(self.contentView).offset(16);
        make.right.equalTo(self.contentView).offset(-16);
        make.bottom.equalTo(self.contentView).offset(-14);
    }];

    [separator mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView).offset(16);
        make.right.equalTo(self.contentView).offset(-16);
        make.bottom.equalTo(self.contentView);
        make.height.mas_equalTo(0.5);
    }];
}

- (void)configureWithComment:(TLWCommentModel *)comment {
    self.nameLabel.text = comment.username;
    self.timeLabel.text = comment.timeString;
    self.contentLabel.text = comment.content;
    self.likeLabel.text = [NSString stringWithFormat:@"%ld", (long)comment.likeCount];
    if (comment.avatarUrl.length > 0) {
        [self.avatarView sd_setImageWithURL:[NSURL URLWithString:comment.avatarUrl]
                          placeholderImage:[UIImage imageNamed:@"hp_avator.png"]];
    } else {
        self.avatarView.image = [UIImage imageNamed:@"hp_avator.png"];
    }
}

@end
