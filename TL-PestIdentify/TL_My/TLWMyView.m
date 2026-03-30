//
//  TLWMyView.m
//  TL-PestIdentify
//

#import "TLWMyView.h"
#import <Masonry/Masonry.h>

@interface TLWMyView ()

@property (nonatomic, strong, readwrite) UIImageView *avatarImageView;
@property (nonatomic, strong, readwrite) UILabel     *userNameLabel;
@property (nonatomic, strong, readwrite) UILabel     *favCountLabel;
@property (nonatomic, strong, readwrite) UIView      *favStatView;
@property (nonatomic, strong, readwrite) UILabel     *recordCountLabel;
@property (nonatomic, strong, readwrite) UIButton    *editProfileButton;
@property (nonatomic, strong, readwrite) UIButton    *settingButton;
@property (nonatomic, strong, readwrite) UIButton    *shareButton;
@property (nonatomic, strong, readwrite) UIImageView *postAvatarImageView;
@property (nonatomic, strong, readwrite) UILabel     *_postNameLabelLabel;

@end

@implementation TLWMyView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) [self setupUI];
    return self;
}

- (void)setupUI {
    // 与识别记录页相同的背景
    self.layer.contents = (__bridge id)[UIImage imageNamed:@"hp_backView"].CGImage;

    [self setupIcons];
    UIView *statsRow = [self setupHeader];
    [self setupCardBelowStatsRow:statsRow];
}

#pragma mark - 顶部图标

- (void)setupIcons {
    _settingButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_settingButton setImage:[UIImage imageNamed:@"iconSetting"] forState:UIControlStateNormal];
    _settingButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self addSubview:_settingButton];
    [_settingButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.mas_safeAreaLayoutGuideTop).offset(12);
        make.right.equalTo(self).offset(-58);
        make.width.height.mas_equalTo(28);
    }];

    _shareButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_shareButton setImage:[UIImage imageNamed:@"iconTransmit"] forState:UIControlStateNormal];
    _shareButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self addSubview:_shareButton];
    [_shareButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(_settingButton);
        make.right.equalTo(self).offset(-16);
        make.width.height.mas_equalTo(28);
    }];
}

#pragma mark - 头像 / 昵称 / 统计行

- (UIView *)setupHeader {
    _avatarImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"avatar"]];
    _avatarImageView.contentMode      = UIViewContentModeScaleAspectFill;
    _avatarImageView.clipsToBounds    = YES;
    _avatarImageView.layer.cornerRadius = 42;
    _avatarImageView.layer.borderWidth  = 3;
    _avatarImageView.layer.borderColor  = [UIColor colorWithWhite:1.0 alpha:0.9].CGColor;
    [self addSubview:_avatarImageView];
    [_avatarImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.mas_safeAreaLayoutGuideTop).offset(20);
        make.centerX.equalTo(self);
        make.width.height.mas_equalTo(84);
    }];

    _userNameLabel = [UILabel new];
    _userNameLabel.font      = [UIFont systemFontOfSize:22 weight:UIFontWeightSemibold];
    _userNameLabel.textColor = UIColor.whiteColor;
    [self addSubview:_userNameLabel];
    [_userNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_avatarImageView.mas_bottom).offset(12);
        make.centerX.equalTo(self);
    }];

    UIView *statsRow = [UIView new];
    [self addSubview:statsRow];
    [statsRow mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_userNameLabel.mas_bottom).offset(16);
        make.left.equalTo(self).offset(16);
        make.right.equalTo(self).offset(-16);
        make.height.mas_equalTo(50);
    }];

    UILabel *l1, *l2;
    UIView *stat1 = [self statViewWithDesc:@"我的收藏" countLabel:&l1];
    UIView *stat2 = [self statViewWithDesc:@"识别记录"  countLabel:&l2];
    _favCountLabel    = l1;
    _favStatView      = stat1;
    _recordCountLabel = l2;

    stat1.userInteractionEnabled = YES;
    [statsRow addSubview:stat1];
    [statsRow addSubview:stat2];
    [stat1 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.bottom.equalTo(statsRow);
        make.width.mas_equalTo(100);
    }];
    [stat2 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(stat1.mas_right).offset(24);
        make.top.bottom.equalTo(statsRow);
        make.width.mas_equalTo(100);
    }];

    _editProfileButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_editProfileButton setImage:[UIImage imageNamed:@"editProfile"] forState:UIControlStateNormal];
    _editProfileButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [statsRow addSubview:_editProfileButton];
    [_editProfileButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self).offset(38);
        make.centerY.equalTo(statsRow).offset(10);
        make.width.mas_equalTo(216);
        make.height.mas_equalTo(72);
    }];

    return statsRow;
}

- (UIView *)statViewWithDesc:(NSString *)desc countLabel:(UILabel *__autoreleasing *)outLabel {
    UIView *view = [UIView new];

    UILabel *countLabel = [UILabel new];
    countLabel.font          = [UIFont systemFontOfSize:26 weight:UIFontWeightBold];
    countLabel.textColor     = UIColor.whiteColor;
    countLabel.textAlignment = NSTextAlignmentCenter;
    [view addSubview:countLabel];
    [countLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(view);
        make.centerX.equalTo(view);
    }];

    UILabel *descLabel = [UILabel new];
    descLabel.text          = desc;
    descLabel.font          = [UIFont systemFontOfSize:12];
    descLabel.textColor     = [UIColor colorWithWhite:1.0 alpha:0.88];
    descLabel.textAlignment = NSTextAlignmentCenter;
    [view addSubview:descLabel];
    [descLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(countLabel.mas_bottom).offset(4);
        make.centerX.equalTo(view);
        make.bottom.lessThanOrEqualTo(view);
    }];

    if (outLabel) *outLabel = countLabel;
    return view;
}

#pragma mark - 毛玻璃卡片（同 RecordView 风格）

- (void)setupCardBelowStatsRow:(UIView *)statsRow {
    UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    UIVisualEffectView *card = [[UIVisualEffectView alloc] initWithEffect:blur];
    card.layer.cornerRadius  = 22;
    card.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
    card.layer.masksToBounds = YES;

    // 白色半透明叠层，同 RecordView 的磨砂玻璃效果
    UIView *overlay = [UIView new];
    overlay.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.65];
    [card.contentView addSubview:overlay];
    [overlay mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(card.contentView);
    }];

    [self addSubview:card];
    [card mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(statsRow.mas_bottom).offset(22);
        make.left.right.bottom.equalTo(self);
    }];

    // 标题
    UILabel *titleLabel = [UILabel new];
    titleLabel.text      = @"我的帖子";
    titleLabel.font      = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
    titleLabel.textColor = [UIColor colorWithRed:0.13 green:0.13 blue:0.13 alpha:1.0];
    [card.contentView addSubview:titleLabel];
    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(card.contentView).offset(24);
        make.left.equalTo(card.contentView).offset(16);
    }];

    // 可滚动的帖子列表
    UIScrollView *sv = [UIScrollView new];
    sv.showsVerticalScrollIndicator = NO;
    [card.contentView addSubview:sv];
    [sv mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(titleLabel.mas_bottom).offset(12);
        make.left.right.bottom.equalTo(card.contentView);
    }];

    UIView *svContent = [UIView new];
    [sv addSubview:svContent];
    [svContent mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(sv);
        make.width.equalTo(sv);
    }];

    UIView *post = [self buildPostItem];
    [svContent addSubview:post];
    [post mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(svContent).offset(4);
        make.left.equalTo(svContent).offset(16);
        make.right.equalTo(svContent).offset(-16);
        make.bottom.equalTo(svContent).offset(-80);
    }];
}

#pragma mark - 帖子内容（Mock）

- (UIView *)buildPostItem {
    UIView *item = [UIView new];

    _postAvatarImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"avatar"]];
    _postAvatarImageView.contentMode      = UIViewContentModeScaleAspectFill;
    _postAvatarImageView.clipsToBounds    = YES;
    _postAvatarImageView.layer.cornerRadius = 20;
    [item addSubview:_postAvatarImageView];
    [_postAvatarImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.equalTo(item);
        make.width.height.mas_equalTo(40);
    }];

    _postNameLabel = [UILabel new];
    _postNameLabel.font      = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    _postNameLabel.textColor = [UIColor colorWithRed:0.13 green:0.13 blue:0.13 alpha:1.0];
    [item addSubview:_postNameLabel];
    [_postNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_postAvatarImageView).offset(2);
        make.left.equalTo(_postAvatarImageView.mas_right).offset(10);
    }];

    UILabel *cropLabel = [UILabel new];
    cropLabel.text      = @"关注作物：水稻、小麦";
    cropLabel.font      = [UIFont systemFontOfSize:12];
    cropLabel.textColor = [UIColor colorWithRed:0.60 green:0.60 blue:0.60 alpha:1.0];
    [item addSubview:cropLabel];
    [cropLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_postNameLabel.mas_bottom).offset(2);
        make.left.equalTo(_postNameLabel);
    }];

    UIImageView *img1 = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"avatar"]];
    img1.contentMode      = UIViewContentModeScaleAspectFill;
    img1.clipsToBounds    = YES;
    img1.layer.cornerRadius = 8;
    [item addSubview:img1];
    [img1 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_postAvatarImageView.mas_bottom).offset(14);
        make.left.equalTo(item);
        make.right.equalTo(item.mas_centerX).offset(-4);
        make.height.mas_equalTo(148);
    }];

    UIImageView *img2 = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"avatar"]];
    img2.contentMode      = UIViewContentModeScaleAspectFill;
    img2.clipsToBounds    = YES;
    img2.layer.cornerRadius = 8;
    img2.backgroundColor  = [UIColor colorWithRed:0.55 green:0.68 blue:0.55 alpha:1.0];
    [item addSubview:img2];
    [img2 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.height.equalTo(img1);
        make.left.equalTo(item.mas_centerX).offset(4);
        make.right.equalTo(item);
    }];

    UILabel *bodyLabel = [UILabel new];
    bodyLabel.text          = @"我家麦子上面有这样的橙黄色粉末，请广大农友帮我看看这是得了什么病？";
    bodyLabel.font          = [UIFont systemFontOfSize:15];
    bodyLabel.textColor     = [UIColor colorWithRed:0.20 green:0.20 blue:0.20 alpha:1.0];
    bodyLabel.numberOfLines = 0;
    [item addSubview:bodyLabel];
    [bodyLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(img1.mas_bottom).offset(12);
        make.left.right.equalTo(item);
    }];

    UIImageView *fav1 = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"avatar"]];
    fav1.contentMode      = UIViewContentModeScaleAspectFill;
    fav1.clipsToBounds    = YES;
    fav1.layer.cornerRadius = 12;
    fav1.layer.borderWidth  = 1.5;
    fav1.layer.borderColor  = UIColor.whiteColor.CGColor;
    [item addSubview:fav1];
    [fav1 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(bodyLabel.mas_bottom).offset(14);
        make.left.equalTo(item);
        make.width.height.mas_equalTo(24);
        make.bottom.equalTo(item);
    }];

    UIImageView *fav2 = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"avatar"]];
    fav2.contentMode      = UIViewContentModeScaleAspectFill;
    fav2.clipsToBounds    = YES;
    fav2.layer.cornerRadius = 12;
    fav2.layer.borderWidth  = 1.5;
    fav2.layer.borderColor  = UIColor.whiteColor.CGColor;
    [item addSubview:fav2];
    [fav2 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(fav1);
        make.left.equalTo(fav1).offset(16);
        make.width.height.mas_equalTo(24);
    }];

    UILabel *favLabel = [UILabel new];
    favLabel.text      = @"+25收藏";
    favLabel.font      = [UIFont systemFontOfSize:12];
    favLabel.textColor = [UIColor colorWithRed:0.50 green:0.50 blue:0.50 alpha:1.0];
    [item addSubview:favLabel];
    [favLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(fav1);
        make.left.equalTo(fav2.mas_right).offset(6);
    }];

    UILabel *timeLabel = [UILabel new];
    timeLabel.text      = @"3天前";
    timeLabel.font      = [UIFont systemFontOfSize:12];
    timeLabel.textColor = [UIColor colorWithRed:0.60 green:0.60 blue:0.60 alpha:1.0];
    [item addSubview:timeLabel];
    [timeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(fav1);
        make.right.equalTo(item);
    }];

    return item;
}

@end
