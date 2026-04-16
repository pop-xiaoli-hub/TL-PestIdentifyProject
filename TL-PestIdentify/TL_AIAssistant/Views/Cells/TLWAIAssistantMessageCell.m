//
//  TLWAIAssistantMessageCell.m
//  TL-PestIdentify
//
//  Created by Northern Lights on 2026/4/3.
//  职责：实现AI助手消息单元视图。
//
#import "TLWAIAssistantMessageCell.h"
#import "TLWAIAssistantMessage.h"
#import <Masonry/Masonry.h>
#import <SDWebImage/UIImageView+WebCache.h>

static CGFloat const kMessageVerticalInset = 6.0;
static CGFloat const kBubbleSidePad = 5.0;

@interface TLWAIAssistantMessageCell ()
@property (nonatomic, strong) UIView *container;
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
    self.messageLabel.attributedText = nil;
    self.statusLabel.text = @"";
    self.statusLabel.hidden = YES;
    self.bubbleView.layer.borderWidth = 0;
    self.bubbleView.layer.borderColor = [UIColor clearColor].CGColor;
    [self.bubbleBottomConstraint deactivate];
    [self.statusBottomConstraint deactivate];
}

- (void)configureWithMessage:(TLWAIAssistantMessage *)message {
    BOOL isUser = (message.role == TLWAIAssistantMessageRoleUser);

    if (isUser) {
        // 用户消息：蓝色填充背景 #48BDF9
        self.bubbleView.backgroundColor = [UIColor colorWithRed:0.282 green:0.741 blue:0.976 alpha:1.0];
        self.bubbleView.layer.borderWidth = 0;
        self.bubbleView.layer.borderColor = [UIColor clearColor].CGColor;
    } else {
        // AI 回复：白色背景 + 橙黄色描边 #FFB524 2px
        self.bubbleView.backgroundColor = [UIColor whiteColor];
        self.bubbleView.layer.borderWidth = 2.0;
        self.bubbleView.layer.borderColor = [UIColor colorWithRed:1.0 green:0.710 blue:0.141 alpha:1.0].CGColor;
    }
    UIColor *textColor = isUser
        ? [UIColor whiteColor]
        : [UIColor colorWithRed:0.153 green:0.153 blue:0.153 alpha:1.0]; // #272727
    self.messageLabel.textColor = textColor;
    NSString *preprocessed = [self tl_preprocessMarkdown:message.text];
    self.messageLabel.attributedText = [self tl_attributedStringFromText:preprocessed textColor:textColor];

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
    NSInteger imageCount = message.localImages.count + message.remoteImageURLs.count;

    // 动态计算图片区域的显示宽高
    CGFloat imageAreaHeight = 0;
    CGFloat imageAreaWidth = 0;
    if (hasImages) {
        BOOL isSingleImage = (imageCount == 1);
        if (isSingleImage) {
            CGSize originalSize = message.imageDisplaySize;
            if (originalSize.width > 0 && originalSize.height > 0) {
                CGFloat maxW = 200.0, maxH = 200.0, minH = 80.0;
                CGFloat ratio = originalSize.height / originalSize.width;
                CGFloat w = MIN(originalSize.width, maxW);
                CGFloat h = w * ratio;
                if (h > maxH) {
                    h = maxH;
                    w = h / ratio;
                }
                if (h < minH) { h = minH; }
                imageAreaHeight = h;
                imageAreaWidth = w;
            } else {
                imageAreaHeight = 120;
                imageAreaWidth = 120;
            }
        } else {
            imageAreaHeight = 120;
            imageAreaWidth = imageCount * 120.0 + (imageCount - 1) * 8.0;
        }
    }

    // 一条消息可能只有图、只有字、图文并存，所以顶部和底部约束都要动态切换。
    self.imageScrollView.hidden = !hasImages;
    self.imageHeightConstraint.offset = imageAreaHeight;
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
        make.width.lessThanOrEqualTo(self.container.mas_width).offset(-kBubbleSidePad * 2);
        if (isUser) {
            make.right.equalTo(self.container).offset(-kBubbleSidePad);
        } else {
            make.left.equalTo(self.container).offset(kBubbleSidePad);
        }
        // 有图片时给气泡设最小宽度，防止 UIScrollView 无 intrinsicContentSize 导致气泡塌缩
        if (hasImages) {
            CGFloat maxBubbleWidth = [UIScreen mainScreen].bounds.size.width - kBubbleSidePad * 2;
            CGFloat minW = MIN(imageAreaWidth + 24, maxBubbleWidth);
            make.width.mas_greaterThanOrEqualTo(minW);
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

    self.bubbleView = [[UIView alloc] init];
    self.bubbleView.layer.cornerRadius = 16;
    self.bubbleView.layer.masksToBounds = YES;
    [self.container addSubview:self.bubbleView];
    [self.bubbleView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.container);
        make.width.lessThanOrEqualTo(self.container.mas_width).offset(-kBubbleSidePad * 2);
        make.left.equalTo(self.container).offset(kBubbleSidePad);
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

- (void)tl_configureImageStripWithMessage:(TLWAIAssistantMessage *)message {
    [self.imageScrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];

    NSInteger imageCount = message.localImages.count + message.remoteImageURLs.count;
    if (imageCount == 0) return;

    // 单张图片按原始比例显示，多张图片用缩略图横向滚动
    BOOL isSingleImage = (imageCount == 1);
    CGFloat maxImageWidth = 200.0;
    CGFloat maxImageHeight = 200.0;
    CGFloat minImageHeight = 80.0;
    CGFloat fallbackSize = 120.0;

    CGFloat displayWidth;
    CGFloat displayHeight;

    if (isSingleImage) {
        CGSize originalSize = message.imageDisplaySize;
        if (originalSize.width > 0 && originalSize.height > 0) {
            // 按比例缩放：先适配最大宽度，再限制最大高度
            CGFloat ratio = originalSize.height / originalSize.width;
            displayWidth = MIN(originalSize.width, maxImageWidth);
            displayHeight = displayWidth * ratio;
            if (displayHeight > maxImageHeight) {
                displayHeight = maxImageHeight;
                displayWidth = displayHeight / ratio;
            }
            if (displayHeight < minImageHeight) {
                displayHeight = minImageHeight;
            }
        } else {
            displayWidth = fallbackSize;
            displayHeight = fallbackSize;
        }
    } else {
        displayWidth = fallbackSize;
        displayHeight = fallbackSize;
    }

    self.imageScrollView.alwaysBounceHorizontal = (!isSingleImage && imageCount > 2);
    CGFloat gap = 8;
    CGFloat x = 0;
    CGFloat thumbW = isSingleImage ? displayWidth : fallbackSize;
    CGFloat thumbH = isSingleImage ? displayHeight : fallbackSize;

    for (UIImage *image in message.localImages) {
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(x, 0, thumbW, thumbH)];
        imageView.image = image;
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.clipsToBounds = YES;
        imageView.layer.cornerRadius = 10;
        [self.imageScrollView addSubview:imageView];
        x += thumbW + gap;
    }

    for (NSString *urlString in message.remoteImageURLs) {
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(x, 0, thumbW, thumbH)];
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.clipsToBounds = YES;
        imageView.layer.cornerRadius = 10;
        imageView.backgroundColor = [UIColor colorWithWhite:0.92 alpha:1.0];
        NSURL *url = [NSURL URLWithString:urlString];
        if (url) {
            [imageView sd_setImageWithURL:url];
        }
        [self.imageScrollView addSubview:imageView];
        x += thumbW + gap;
    }

    self.imageScrollView.contentSize = CGSizeMake(MAX(x - gap, thumbW), thumbH);
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

/// 把 markdown 块级语法转成可读纯文本，保留内联语法（**bold**）供后续渲染
- (NSString *)tl_preprocessMarkdown:(NSString *)text {
    if (text.length == 0) return @"";
    NSArray<NSString *> *lines = [text componentsSeparatedByString:@"\n"];
    NSMutableArray<NSString *> *processed = [NSMutableArray arrayWithCapacity:lines.count];
    for (NSString *line in lines) {
        NSString *trimmed = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        // ## 标题 → **标题**（h1/h2 保留粗体语义，h3+ 直接去掉 #）
        if ([trimmed hasPrefix:@"#"]) {
            NSUInteger hashCount = 0;
            while (hashCount < trimmed.length && [trimmed characterAtIndex:hashCount] == '#') hashCount++;
            NSString *headerText = [[trimmed substringFromIndex:hashCount]
                                    stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            [processed addObject:(hashCount <= 2)
                ? [NSString stringWithFormat:@"**%@**", headerText]
                : headerText];
        // - 列表 / * 列表 / + 列表 → • 列表
        } else if ([trimmed hasPrefix:@"- "] || [trimmed hasPrefix:@"* "] || [trimmed hasPrefix:@"+ "]) {
            [processed addObject:[NSString stringWithFormat:@"• %@", [trimmed substringFromIndex:2]]];
        } else {
            [processed addObject:line];
        }
    }
    NSString *joined = [processed componentsJoinedByString:@"\n"];
    // 连续 3 个以上空行压缩为 2 个
    NSRegularExpression *blankLines = [NSRegularExpression regularExpressionWithPattern:@"\n{3,}" options:0 error:nil];
    return [blankLines stringByReplacingMatchesInString:joined options:0
                                                  range:NSMakeRange(0, joined.length)
                                           withTemplate:@"\n\n"];
}

/// iOS 15+ 用系统 inline markdown 渲染 **粗体**；iOS 12-14 降级纯文本清洗
- (NSAttributedString *)tl_attributedStringFromText:(NSString *)text textColor:(UIColor *)textColor {
    UIFont *baseFont = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    UIFont *boldFont = [UIFont systemFontOfSize:15 weight:UIFontWeightBold];
    NSDictionary *baseAttrs = @{ NSFontAttributeName: baseFont, NSForegroundColorAttributeName: textColor };
    if (text.length == 0) return [[NSAttributedString alloc] initWithString:@"" attributes:baseAttrs];

    if (@available(iOS 15.0, *)) {
        NSAttributedStringMarkdownParsingOptions *opts = [[NSAttributedStringMarkdownParsingOptions alloc] init];
        opts.interpretedSyntax = NSAttributedStringMarkdownInterpretedSyntaxInlineOnlyPreservingWhitespace;
        NSError *err = nil;
        NSAttributedString *attrStr = [[NSAttributedString alloc] initWithMarkdownString:text
                                                                                 options:opts
                                                                                 baseURL:nil
                                                                                   error:&err];
        if (err || !attrStr) {
            return [[NSAttributedString alloc] initWithString:text attributes:baseAttrs];
        }
        NSMutableAttributedString *mutable = [attrStr mutableCopy];
        [mutable enumerateAttributesInRange:NSMakeRange(0, mutable.length)
                                    options:0
                                 usingBlock:^(NSDictionary<NSAttributedStringKey, id> *attrs, NSRange range, BOOL *stop) {
            UIFont *existing = attrs[NSFontAttributeName];
            BOOL isBold = NO;
            if (existing) {
                UIFontDescriptorSymbolicTraits traits = existing.fontDescriptor.symbolicTraits;
                isBold = (traits & UIFontDescriptorTraitBold) != 0;
            }
            [mutable addAttribute:NSFontAttributeName value:(isBold ? boldFont : baseFont) range:range];
            [mutable addAttribute:NSForegroundColorAttributeName value:textColor range:range];
        }];
        return mutable.copy;
    }

    // iOS 12-14 降级：去掉剩余内联 markdown 符号
    return [[NSAttributedString alloc] initWithString:[self tl_stripInlineMarkdown:text] attributes:baseAttrs];
}

/// 去掉 **bold**、*italic*、`code` 的符号，保留文字内容
- (NSString *)tl_stripInlineMarkdown:(NSString *)text {
    NSMutableString *result = [text mutableCopy];
    for (NSArray *pair in @[
        @[@"\\*\\*(.+?)\\*\\*", @"$1"],  // **bold**
        @[@"\\*(.+?)\\*",       @"$1"],  // *italic*
        @[@"`(.+?)`",           @"$1"],  // `code`
    ]) {
        NSRegularExpression *re = [NSRegularExpression regularExpressionWithPattern:pair[0]
                                                                            options:NSRegularExpressionDotMatchesLineSeparators
                                                                              error:nil];
        [re replaceMatchesInString:result options:0 range:NSMakeRange(0, result.length) withTemplate:pair[1]];
    }
    return result.copy;
}

@end
