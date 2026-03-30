//
//  TLWFavoriteCell.m
//  TL-PestIdentify
//

#import "TLWFavoriteCell.h"
#import <AgriPestClient/AGPostResponseDto.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import <Masonry/Masonry.h>

@interface TLWFavoriteCell ()

@property (nonatomic, strong) UIImageView *photoView;
@property (nonatomic, strong) UILabel     *titleLabel;
@property (nonatomic, strong) UIImageView *avatarView;
@property (nonatomic, strong) UILabel     *userLabel;
@property (nonatomic, strong) UIImageView *likeIconView;
@property (nonatomic, strong) UILabel     *likeLabel;

@end

@implementation TLWFavoriteCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupCellBackground];
        [self setupSubviews];
    }
    return self;
}

- (void)setupCellBackground {
    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemMaterialLight];
    UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    blurView.layer.masksToBounds = YES;
    blurView.layer.cornerRadius  = 14.0;
    [self.contentView addSubview:blurView];

    UIView *glassLayer = [UIView new];
    glassLayer.backgroundColor = [UIColor colorWithWhite:1 alpha:0.32];
    [blurView.contentView addSubview:glassLayer];

    blurView.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.55].CGColor;
    blurView.layer.borderWidth = 1.0;

    [blurView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.contentView);
    }];
    [glassLayer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(blurView.contentView);
    }];
}

- (void)setupSubviews {
    self.backgroundColor = UIColor.clearColor;
    self.contentView.backgroundColor = UIColor.clearColor;
    self.contentView.layer.cornerRadius  = 14.0;
    self.contentView.layer.masksToBounds = YES;

    self.layer.shadowColor   = [UIColor colorWithWhite:0 alpha:0.35].CGColor;
    self.layer.shadowOpacity = 1.0;
    self.layer.shadowOffset  = CGSizeMake(0, 8);
    self.layer.shadowRadius  = 12.0;
    self.layer.masksToBounds = NO;

    _photoView = [UIImageView new];
    _photoView.contentMode   = UIViewContentModeScaleAspectFill;
    _photoView.clipsToBounds = YES;
    _photoView.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];

    _titleLabel = [UILabel new];
    _titleLabel.font          = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
    _titleLabel.textColor     = UIColor.blackColor;
    _titleLabel.numberOfLines = 2;

    _avatarView = [UIImageView new];
    _avatarView.contentMode        = UIViewContentModeScaleAspectFill;
    _avatarView.clipsToBounds      = YES;
    _avatarView.layer.cornerRadius = 10.0;

    _userLabel = [UILabel new];
    _userLabel.font      = [UIFont systemFontOfSize:11];
    _userLabel.textColor  = [UIColor colorWithWhite:0.2 alpha:1.0];

    _likeIconView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"liked"]];
    _likeIconView.contentMode = UIViewContentModeScaleAspectFit;

    _likeLabel = [UILabel new];
    _likeLabel.font      = [UIFont systemFontOfSize:11];
    _likeLabel.textColor  = [UIColor colorWithWhite:0.4 alpha:1.0];

    [self.contentView addSubview:_photoView];
    [self.contentView addSubview:_titleLabel];
    [self.contentView addSubview:_avatarView];
    [self.contentView addSubview:_userLabel];
    [self.contentView addSubview:_likeIconView];
    [self.contentView addSubview:_likeLabel];

    [_photoView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.contentView);
        make.height.equalTo(self.contentView.mas_height).multipliedBy(0.65);
    }];

    [_titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_photoView.mas_bottom).offset(6);
        make.left.equalTo(self.contentView).offset(8);
        make.right.equalTo(self.contentView).offset(-8);
    }];

    [_avatarView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView).offset(8);
        make.bottom.equalTo(self.contentView).offset(-6);
        make.width.height.mas_equalTo(20);
    }];

    [_userLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_avatarView.mas_right).offset(6);
        make.centerY.equalTo(_avatarView);
    }];

    [_likeIconView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.contentView).offset(-8);
        make.centerY.equalTo(_avatarView);
        make.width.height.mas_equalTo(14);
    }];

    [_likeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(_likeIconView.mas_left).offset(-4);
        make.centerY.equalTo(_avatarView);
    }];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    _photoView.image = nil;
    _titleLabel.text = nil;
    _userLabel.text  = nil;
    _likeLabel.text  = nil;
    _avatarView.image = nil;
}

- (void)configureWithPostDto:(AGPostResponseDto *)post {
    // 图片：取第一张URL
    NSString *imageUrl = post.images.firstObject;
    if (imageUrl.length > 0) {
        [_photoView sd_setImageWithURL:[NSURL URLWithString:imageUrl]];
    }

    // 头像
    if (post.authorAvatar.length > 0) {
        [_avatarView sd_setImageWithURL:[NSURL URLWithString:post.authorAvatar]
                       placeholderImage:[UIImage imageNamed:@"avatar"]];
    } else {
        _avatarView.image = [UIImage imageNamed:@"avatar"];
    }

    _titleLabel.text = post.title.length > 0 ? post.title : post.content;
    _userLabel.text  = post.authorName ?: @"匿名用户";
    _likeLabel.text  = [NSString stringWithFormat:@"%@", post.favoriteCount ?: @(0)];
}

@end
