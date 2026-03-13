//
//  TLWCommunityCell.m
//  TL-PestIdentify
//

#import "TLWCommunityCell.h"
#import "TLWCommunityPost.h"
#import <Masonry/Masonry.h>

@interface TLWCommunityCell ()

@property (nonatomic, strong) UIImageView *photoView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIImageView *avatarView;
@property (nonatomic, strong) UILabel *userLabel;
@property (nonatomic, strong) UIImageView *likeIconView;
@property (nonatomic, strong) UILabel *likeLabel;

@end

@implementation TLWCommunityCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupSubviews];
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.photoView.image = nil;
    self.titleLabel.text = nil;
    self.userLabel.text = nil;
    self.likeLabel.text = nil;
}

- (void)setupSubviews {
    self.contentView.backgroundColor = [UIColor whiteColor];
    self.contentView.layer.cornerRadius = 14.0;
    self.contentView.layer.masksToBounds = YES;

    self.photoView = [[UIImageView alloc] init];
    self.photoView.contentMode = UIViewContentModeScaleAspectFill;
    self.photoView.clipsToBounds = YES;

    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
    self.titleLabel.textColor = [UIColor blackColor];
    self.titleLabel.numberOfLines = 2;

    self.avatarView = [[UIImageView alloc] init];
    self.avatarView.contentMode = UIViewContentModeScaleAspectFill;
    self.avatarView.clipsToBounds = YES;
    self.avatarView.layer.cornerRadius = 10.0;
    self.avatarView.image = [UIImage imageNamed:@"cm_user"];

    self.userLabel = [[UILabel alloc] init];
    self.userLabel.font = [UIFont systemFontOfSize:11];
    self.userLabel.textColor = [UIColor colorWithWhite:0.2 alpha:1.0];

    self.likeIconView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cm_like"]];
    self.likeIconView.contentMode = UIViewContentModeScaleAspectFit;

    self.likeLabel = [[UILabel alloc] init];
    self.likeLabel.font = [UIFont systemFontOfSize:11];
    self.likeLabel.textColor = [UIColor colorWithWhite:0.4 alpha:1.0];

    [self.contentView addSubview:self.photoView];
    [self.contentView addSubview:self.titleLabel];
    [self.contentView addSubview:self.avatarView];
    [self.contentView addSubview:self.userLabel];
    [self.contentView addSubview:self.likeIconView];
    [self.contentView addSubview:self.likeLabel];

    [self.photoView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.contentView);
        make.height.greaterThanOrEqualTo(@80);
    }];

    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.photoView.mas_bottom).offset(6);
        make.left.equalTo(self.contentView).offset(8);
        make.right.equalTo(self.contentView).offset(-8);
    }];

    [self.avatarView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView).offset(8);
        make.bottom.equalTo(self.contentView).offset(-6);
        make.width.height.mas_equalTo(20);
    }];

    [self.userLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.avatarView.mas_right).offset(6);
        make.centerY.equalTo(self.avatarView);
    }];

    [self.likeIconView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.contentView).offset(-8);
        make.centerY.equalTo(self.avatarView);
        make.width.height.mas_equalTo(14);
    }];

    [self.likeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.likeIconView.mas_left).offset(-4);
        make.centerY.equalTo(self.avatarView);
    }];
}

- (void)configureWithPost:(TLWCommunityPost *)post {
    if (post.imageName.length > 0) {
        self.photoView.image = [UIImage imageNamed:post.imageName];
    } else {
        self.photoView.image = [UIImage imageNamed:@"cm_placeholder"];
    }

    self.titleLabel.text = post.title;
    self.userLabel.text = post.userName;
    self.likeLabel.text = [NSString stringWithFormat:@"%ld", (long)post.likeCount];
}

@end

