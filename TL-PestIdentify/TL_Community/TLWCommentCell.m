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
@property (nonatomic, assign) BOOL elderModeEnabled;
@property (nonatomic, strong) MASConstraint *avatarSizeConstraint;
@property (nonatomic, strong) MASConstraint *likeIconSizeConstraint;
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
  self.avatarView.image = [UIImage imageNamed:@"hp_avatar"];
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
  self.likeIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cp_heart"]];
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
    self.avatarSizeConstraint = make.width.height.mas_equalTo(36);
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
    self.likeIconSizeConstraint = make.width.height.mas_equalTo(15);
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

  [self configureElderModeEnabled:NO];
}

- (void)configureElderModeEnabled:(BOOL)enabled {
  self.elderModeEnabled = enabled;
  self.nameLabel.font = [UIFont systemFontOfSize:(enabled ? 16 : 13) weight:UIFontWeightSemibold];
  self.timeLabel.font = [UIFont systemFontOfSize:(enabled ? 14 : 11)];
  self.contentLabel.font = [UIFont systemFontOfSize:(enabled ? 17 : 14)];
  self.likeLabel.font = [UIFont systemFontOfSize:(enabled ? 14 : 11)];
  self.avatarView.layer.cornerRadius = enabled ? 21.0 : 18.0;
  [self.avatarSizeConstraint setOffset:(enabled ? 42.0 : 36.0)];
  [self.likeIconSizeConstraint setOffset:(enabled ? 18.0 : 15.0)];
}

- (void)configureWithComment:(AGCommentResponseDto *)comment {
  self.nameLabel.text = comment.authorName;
  NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
  [formatter setDateFormat:@"yyyy年MM月dd日 HH:mm"];
  self.timeLabel.text = [formatter stringFromDate:comment.createdAt];
  self.contentLabel.text = comment.content;
  //self.likeLabel.text = [NSString stringWithFormat:@"%@", comment.likeCount];
  if (comment.authorAvatar.length > 0) {
    [self.avatarView sd_setImageWithURL:[NSURL URLWithString:comment.authorAvatar]
                       placeholderImage:[UIImage imageNamed:@"hp_avatar"]];
  } else {
    self.avatarView.image = [UIImage imageNamed:@"hp_avatar"];
  }
}

@end
