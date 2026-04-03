#import "TLWAIAssistantMessageCell.h"
#import "TLWAIAssistantMessage.h"
#import "TLWSDKManager.h"
#import <Masonry/Masonry.h>
#import <SDWebImage/UIImageView+WebCache.h>

static CGFloat const kAvatarSize = 32.0;
static CGFloat const kAvatarGap = 10.0;
static CGFloat const kMessageVerticalInset = 6.0;

@interface TLWAIAssistantMessageCell ()
@property (nonatomic, strong) UIView *container;
@property (nonatomic, strong) UIImageView *avatarImageView;
@property (nonatomic, strong) UIView *bubbleView;
@property (nonatomic, strong) UILabel *messageLabel;
@property (nonatomic, strong) UILabel *statusLabel;
// 图片条单独用横向 scrollView，后续多图、远程图回显都能共用这套布局。
@property (nonatomic, strong) UIScrollView *imageScrollView;

@property (nonatomic, strong) MASConstraint *bubbleBottomConstraint;
@property (nonatomic, strong) MASConstraint *statusLeadingConstraint;
@property (nonatomic, strong) MASConstraint *statusTrailingConstraint;
@property (nonatomic, strong) MASConstraint *statusBottomConstraint;
@property (nonatomic, strong) MASConstraint *messageTopConstraint;
@property (nonatomic, strong) MASConstraint *messageBottomConstraint;
@property (nonatomic, strong) MASConstraint *imageTopConstraint;
@property (nonatomic, strong) MASConstraint *imageHeightConstraint;
@end

@implementation TLWAIAssistantMessageCell

+ (NSString *)reuseIdentifier {
    return @"TLWAIAssistantMessageCell";
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor clearColor];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        [self tl_setupViews];
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self.imageScrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    self.imageScrollView.contentSize = CGSizeZero;
    self.statusLabel.text = @"";
    self.statusLabel.hidden = YES;
    [self.avatarImageView sd_cancelCurrentImageLoad];
    self.avatarImageView.image = nil;
    self.avatarImageView.backgroundColor = [UIColor clearColor];
    [self.bubbleBottomConstraint deactivate];
    [self.statusBottomConstraint deactivate];
}

- (void)configureWithMessage:(TLWAIAssistantMessage *)message {
    BOOL isUser = (message.role == TLWAIAssistantMessageRoleUser);
    [self tl_configureAvatarForUser:isUser];

    self.bubbleView.backgroundColor = isUser
        ? [UIColor colorWithRed:0.47 green:0.78 blue:0.58 alpha:1.0]
        : [UIColor colorWithWhite:1.0 alpha:0.82];
    self.messageLabel.textColor = isUser
        ? [UIColor whiteColor]
        : [UIColor colorWithRed:0.12 green:0.16 blue:0.18 alpha:1.0];
    self.messageLabel.text = message.text;

    [self.statusLeadingConstraint deactivate];
    [self.statusTrailingConstraint deactivate];
    if (isUser) {
        [self.statusTrailingConstraint activate];
    } else {
        [self.statusLeadingConstraint activate];
    }

    [self tl_configureImageStripWithMessage:message];

    BOOL hasImages = (message.localImages.count + message.remoteImageURLs.count) > 0;
    BOOL hasText = message.text.length > 0;

    // 一条消息可能只有图、只有字、图文并存，所以顶部和底部约束都要动态切换。
    self.imageScrollView.hidden = !hasImages;
    self.imageHeightConstraint.offset = hasImages ? 72 : 0;
    [self.imageTopConstraint setOffset:hasImages ? 12 : 0];

    [self.messageTopConstraint uninstall];
    [self.messageLabel mas_updateConstraints:^(MASConstraintMaker *make) {
        if (hasImages) {
            self.messageTopConstraint = make.top.equalTo(self.imageScrollView.mas_bottom).offset(hasText ? 10 : 0);
        } else {
            self.messageTopConstraint = make.top.equalTo(self.bubbleView).offset(hasText ? 12 : 0);
        }
    }];

    self.messageLabel.hidden = !hasText;
    [self.messageBottomConstraint uninstall];
    [self.messageLabel mas_updateConstraints:^(MASConstraintMaker *make) {
        if (hasText) {
            self.messageBottomConstraint = make.bottom.equalTo(self.bubbleView).offset(-12);
        }
    }];

    [self.bubbleView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.container);
        make.width.lessThanOrEqualTo(self.container.mas_width).offset(-(kAvatarSize + kAvatarGap + 16.0));
        if (isUser) {
            make.right.equalTo(self.avatarImageView.mas_left).offset(-kAvatarGap);
        } else {
            make.left.equalTo(self.avatarImageView.mas_right).offset(kAvatarGap);
        }
        if (!hasImages && !hasText) {
            make.height.mas_equalTo(44);
        } else if (hasText) {
            make.bottom.equalTo(self.messageLabel.mas_bottom).offset(12);
        } else {
            make.bottom.equalTo(self.imageScrollView.mas_bottom).offset(12);
        }
    }];

    NSString *statusText = [self tl_statusTextForMessage:message];
    self.statusLabel.text = statusText;
    self.statusLabel.hidden = statusText.length == 0;
    if (statusText.length > 0) {
        // 有状态文案时，让整条 cell 的底部跟随状态标签，而不是气泡本身。
        [self.bubbleBottomConstraint deactivate];
        if (!self.statusBottomConstraint) {
            [self.statusLabel mas_makeConstraints:^(MASConstraintMaker *make) {
                self.statusBottomConstraint = make.bottom.equalTo(self.container);
            }];
        } else {
            [self.statusBottomConstraint activate];
        }
    } else {
        [self.statusBottomConstraint deactivate];
        [self.bubbleBottomConstraint activate];
    }

    [self.contentView setNeedsLayout];
}

#pragma mark - Private

- (void)tl_setupViews {
    self.container = [[UIView alloc] init];
    self.container.backgroundColor = [UIColor clearColor];
    [self.contentView addSubview:self.container];
    [self.container mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView).offset(kMessageVerticalInset);
        make.left.right.equalTo(self.contentView);
        make.bottom.equalTo(self.contentView).offset(-kMessageVerticalInset);
    }];

    self.avatarImageView = [[UIImageView alloc] init];
    self.avatarImageView.clipsToBounds = YES;
    self.avatarImageView.layer.cornerRadius = kAvatarSize / 2.0;
    self.avatarImageView.layer.borderWidth = 1.0;
    self.avatarImageView.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.8].CGColor;
    [self.container addSubview:self.avatarImageView];
    [self.avatarImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.container);
        make.left.equalTo(self.container);
        make.width.height.mas_equalTo(kAvatarSize);
    }];

    self.bubbleView = [[UIView alloc] init];
    self.bubbleView.layer.cornerRadius = 18;
    self.bubbleView.layer.masksToBounds = YES;
    [self.container addSubview:self.bubbleView];
    [self.bubbleView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.container);
        // 聊天气泡不铺满整行，并给头像留出明确的占位空间。
        make.width.lessThanOrEqualTo(self.container.mas_width).offset(-(kAvatarSize + kAvatarGap + 16.0));
        make.left.equalTo(self.avatarImageView.mas_right).offset(kAvatarGap);
    }];

    self.imageScrollView = [[UIScrollView alloc] init];
    self.imageScrollView.showsHorizontalScrollIndicator = NO;
    self.imageScrollView.alwaysBounceHorizontal = NO;
    self.imageScrollView.backgroundColor = [UIColor clearColor];
    [self.bubbleView addSubview:self.imageScrollView];
    [self.imageScrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        self.imageTopConstraint = make.top.equalTo(self.bubbleView).offset(12);
        make.left.equalTo(self.bubbleView).offset(12);
        make.right.equalTo(self.bubbleView).offset(-12);
        self.imageHeightConstraint = make.height.mas_equalTo(72);
    }];

    self.messageLabel = [[UILabel alloc] init];
    self.messageLabel.numberOfLines = 0;
    self.messageLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    [self.bubbleView addSubview:self.messageLabel];
    [self.messageLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        self.messageTopConstraint = make.top.equalTo(self.imageScrollView.mas_bottom).offset(10);
        make.left.equalTo(self.bubbleView).offset(14);
        make.right.equalTo(self.bubbleView).offset(-14);
        self.messageBottomConstraint = make.bottom.equalTo(self.bubbleView).offset(-12);
    }];

    self.statusLabel = [[UILabel alloc] init];
    self.statusLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightMedium];
    self.statusLabel.textColor = [UIColor colorWithWhite:0.42 alpha:1.0];
    [self.container addSubview:self.statusLabel];
    [self.statusLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.bubbleView.mas_bottom).offset(4);
        self.statusLeadingConstraint = make.left.equalTo(self.bubbleView).offset(4);
        self.statusTrailingConstraint = make.right.equalTo(self.bubbleView).offset(-4);
    }];

    [self.bubbleView mas_makeConstraints:^(MASConstraintMaker *make) {
        self.bubbleBottomConstraint = make.bottom.equalTo(self.container);
    }];
}

- (void)tl_configureAvatarForUser:(BOOL)isUser {
    [self.avatarImageView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.container);
        make.width.height.mas_equalTo(kAvatarSize);
        if (isUser) {
            make.right.equalTo(self.container);
        } else {
            make.left.equalTo(self.container);
        }
    }];

    if (isUser) {
        self.avatarImageView.contentMode = UIViewContentModeScaleAspectFill;
        self.avatarImageView.backgroundColor = [UIColor clearColor];
        NSString *avatarURLString = [TLWSDKManager shared].cachedProfile.avatarUrl;
        UIImage *placeholder = [UIImage imageNamed:@"hp_avatar.png"];
        if (avatarURLString.length > 0) {
            [self.avatarImageView sd_setImageWithURL:[NSURL URLWithString:avatarURLString]
                                    placeholderImage:placeholder];
        } else {
            self.avatarImageView.image = placeholder;
        }
    } else {
        self.avatarImageView.contentMode = UIViewContentModeScaleAspectFit;
        self.avatarImageView.image = [UIImage imageNamed:@"iconSystem"];
        self.avatarImageView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.92];
    }
}

- (void)tl_configureImageStripWithMessage:(TLWAIAssistantMessage *)message {
    [self.imageScrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];

    CGFloat thumbSize = 72;
    CGFloat gap = 8;
    CGFloat x = 0;
    NSInteger imageCount = message.localImages.count + message.remoteImageURLs.count;
    self.imageScrollView.alwaysBounceHorizontal = imageCount > 3;

    // 本地图和远程图分开渲染，分别对应草稿态和历史/上传完成态。
    for (UIImage *image in message.localImages) {
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(x, 0, thumbSize, thumbSize)];
        imageView.image = image;
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.clipsToBounds = YES;
        imageView.layer.cornerRadius = 10;
        [self.imageScrollView addSubview:imageView];
        x += thumbSize + gap;
    }

    for (NSString *urlString in message.remoteImageURLs) {
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(x, 0, thumbSize, thumbSize)];
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.clipsToBounds = YES;
        imageView.layer.cornerRadius = 10;
        imageView.backgroundColor = [UIColor colorWithWhite:0.92 alpha:1.0];
        NSURL *url = [NSURL URLWithString:urlString];
        if (url) {
            [imageView sd_setImageWithURL:url];
        }
        [self.imageScrollView addSubview:imageView];
        x += thumbSize + gap;
    }

    self.imageScrollView.contentSize = CGSizeMake(MAX(x - gap, thumbSize), thumbSize);
}

- (NSString *)tl_statusTextForMessage:(TLWAIAssistantMessage *)message {
    // 这里先收口成展示文案，业务层只需要改 message.status 和 errorMessage。
    if (message.status == TLWAIAssistantMessageStatusSending) {
        return @"发送中";
    }
    if (message.status == TLWAIAssistantMessageStatusFailed) {
        return message.errorMessage.length > 0 ? message.errorMessage : @"发送失败";
    }
    return @"";
}

@end
