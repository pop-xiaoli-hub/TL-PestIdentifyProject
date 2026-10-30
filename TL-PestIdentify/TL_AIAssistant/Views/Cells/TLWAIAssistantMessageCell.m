//
//  TLWAIAssistantMessageCell.m
//  TL-PestIdentify
//
//  Created by Northern Lights on 2026/4/3.
//  职责：实现AI助手消息单元视图。
//
#import "TLWAIAssistantMessageCell.h"
#import "TLWAIAssistantMessage.h"
#import "TLWAIMarkdownBodyView.h"
#import "TLWAITrace.h"
#import "TLWAIProductPolicy.h"
#import "TLWAIImageArchive.h"
#import "TLWAIGestureCoordinator.h"
#import <Masonry/Masonry.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import <math.h>

static CGFloat const kMessageVerticalInset = 6.0;
static CGFloat const kBubbleSidePad = 5.0;
@interface TLWAIAssistantMessageCell () <UIScrollViewDelegate, UITextViewDelegate, UIContextMenuInteractionDelegate>
@property (nonatomic, strong) UIView *container;
@property (nonatomic, strong) UIView *bubbleView;
@property (nonatomic, strong) TLWAIMarkdownBodyView *messageBody;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UIButton *continueButton;
// 图片条单独用横向 scrollView，后续多图、远程图回显都能共用这套布局。
@property (nonatomic, strong) UIScrollView *imageScrollView;

@property (nonatomic, strong) MASConstraint *bubbleBottomConstraint;
@property (nonatomic, strong) MASConstraint *statusLeadingConstraint;
@property (nonatomic, strong) MASConstraint *statusTrailingConstraint;
@property (nonatomic, strong) MASConstraint *statusBottomConstraint;
@property (nonatomic, strong) MASConstraint *messageTopConstraint;
@property (nonatomic, strong) MASConstraint *messageBottomConstraint;
@property (nonatomic, strong) MASConstraint *messageHeightConstraint;
@property (nonatomic, strong) MASConstraint *imageTopConstraint;
@property (nonatomic, strong) MASConstraint *imageHeightConstraint;
@property (nonatomic, weak)   TLWAIAssistantMessage *currentMessage;
@property (nonatomic, assign) CGFloat imageAreaWidth;
@property (nonatomic, copy) NSString *displayedSource;
@property (nonatomic, assign) TLWAIAssistantMessageStatus displayedStatus;
@property (nonatomic, strong) TLWAIRelayTextView *auxiliaryTextView;
@property (nonatomic, assign) CGFloat auxiliaryHeight;
@property (nonatomic, assign) BOOL auxiliaryHasImages;
@property (nonatomic, weak) TLWAIGestureCoordinator *relayCoordinator;
@property (nonatomic, weak) UITableView *outerTable;
@property (nonatomic) CGSize measuredLayoutSize;
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
        [self.bubbleView addInteraction:[[UIContextMenuInteraction alloc] initWithDelegate:self]];
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self.imageScrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    self.imageScrollView.contentSize = CGSizeZero;
    [self.messageBody applySource:@"" literal:YES selectable:NO textColor:UIColor.labelColor];
    self.displayedSource = nil;
    self.statusLabel.text = @"";
    self.statusLabel.hidden = YES;
    self.continueButton.hidden = YES;
    self.bubbleView.layer.borderWidth = 0;
    self.bubbleView.layer.borderColor = [UIColor clearColor].CGColor;
    [self.bubbleBottomConstraint deactivate];
    [self.statusBottomConstraint deactivate];
    self.currentMessage = nil;
    self.measuredLayoutSize = CGSizeZero;
}

- (void)configureWithMessage:(TLWAIAssistantMessage *)message {
    self.currentMessage = message;
    BOOL isUser = (message.role == TLWAIAssistantMessageRoleUser);

    if (isUser) {
        // 用户消息：蓝色填充背景 #48BDF9
        self.bubbleView.backgroundColor = [UIColor colorWithRed:0.282 green:0.741 blue:0.976 alpha:1.0];
        self.bubbleView.layer.borderWidth = 0;
        self.bubbleView.layer.borderColor = [UIColor clearColor].CGColor;
    } else {
        // AI 回复：白色背景 + 橙黄色描边 #FFB524 2px。
        self.bubbleView.backgroundColor = UIColor.whiteColor;
        self.bubbleView.layer.borderWidth = 2.0;
        self.bubbleView.layer.borderColor = [UIColor colorWithRed:1.0 green:0.710 blue:0.141 alpha:1.0].CGColor;
    }
    UIColor *textColor = isUser ? UIColor.whiteColor : [UIColor colorWithRed:0.153 green:0.153 blue:0.153 alpha:1.0];
    BOOL isStreamingStatus = (message.status == TLWAIAssistantMessageStatusSending ||
                               message.status == TLWAIAssistantMessageStatusWaiting ||
                               message.status == TLWAIAssistantMessageStatusRecovering);
    BOOL canSelect = !isStreamingStatus && (isUser || message.completed);
    [self.messageBody applySource:message.text ?: @"" literal:isUser selectable:canSelect textColor:textColor];
    self.displayedSource = message.text ?: @"";
    self.messageBody.accessibilityElementsHidden = isStreamingStatus && !isUser;
    self.accessibilityLabel = (!isUser && (isStreamingStatus || message.completed)) ? TLWAIAccessibilityLabel(isStreamingStatus, self.messageBody.text) : nil;

    [self.statusLeadingConstraint deactivate];
    [self.statusTrailingConstraint deactivate];
    if (isUser) {
        [self.statusTrailingConstraint activate];
    } else {
        [self.statusLeadingConstraint activate];
    }

    [self tl_configureImageStripWithMessage:message];
    [self tl_updateAuxiliaryCard];

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
    self.imageAreaWidth = imageAreaWidth;

    // 一条消息可能只有图、只有字、图文并存，所以顶部和底部约束都要动态切换。
    self.imageScrollView.hidden = !hasImages;
    self.imageHeightConstraint.offset = imageAreaHeight;
    [self.imageTopConstraint setOffset:hasImages ? 12 : 0];

    [self.messageTopConstraint uninstall];
    [self.messageBody mas_updateConstraints:^(MASConstraintMaker *make) {
        if (self.auxiliaryTextView) {
            self.messageTopConstraint = make.top.equalTo(self.auxiliaryTextView.mas_bottom).offset(hasText ? 10 : 0);
        } else if (hasImages) {
            self.messageTopConstraint = make.top.equalTo(self.imageScrollView.mas_bottom).offset(hasText ? 10 : 0);
        } else {
            self.messageTopConstraint = make.top.equalTo(self.bubbleView).offset(hasText ? 12 : 0);
        }
    }];

    self.messageBody.hidden = !hasText;
    if (hasText) {
        [self.messageHeightConstraint activate];
    } else {
        [self.messageHeightConstraint deactivate];
    }
    [self.messageBottomConstraint uninstall];
    [self.messageBody mas_updateConstraints:^(MASConstraintMaker *make) {
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
            make.width.equalTo(self.container.mas_width).offset(-kBubbleSidePad * 2);
        }
        // 有图片时给气泡设最小宽度，防止 UIScrollView 无 intrinsicContentSize 导致气泡塌缩
        if (hasImages) {
            CGFloat maxBubbleWidth = MAX(1, CGRectGetWidth(self.bounds) - kBubbleSidePad * 2);
            CGFloat minW = MIN(imageAreaWidth + 24, maxBubbleWidth);
            make.width.mas_greaterThanOrEqualTo(minW);
        }
        if (!hasImages && !hasText && !self.auxiliaryTextView) {
            make.height.mas_equalTo(44);
        } else if (hasText) {
            make.bottom.equalTo(self.messageBody.mas_bottom).offset(12);
        } else if (self.auxiliaryTextView) {
            make.bottom.equalTo(self.auxiliaryTextView.mas_bottom).offset(12);
        } else {
            make.bottom.equalTo(self.imageScrollView.mas_bottom).offset(12);
        }
    }];

    NSString *statusText = [self tl_statusTextForMessage:message];
    self.displayedStatus = message.status;
    self.statusLabel.text = statusText;
    self.statusLabel.hidden = statusText.length == 0;
    self.continueButton.hidden = !message.canContinue;
    [self.continueButton setTitle:message.canResumeJob ? @"继续接收" : @"重新生成" forState:UIControlStateNormal];
    if (message.canContinue) {
        [self.bubbleBottomConstraint deactivate];
        [self.statusBottomConstraint deactivate];
        [self.continueButton mas_remakeConstraints:^(MASConstraintMaker *make) {
            if (statusText.length) make.top.equalTo(self.statusLabel.mas_bottom).offset(2);
            else make.top.equalTo(self.bubbleView.mas_bottom).offset(4);
            make.left.equalTo(self.bubbleView);
            make.bottom.equalTo(self.container);
            make.height.mas_equalTo(28);
        }];
    } else if (statusText.length > 0) {
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

    [self tl_updateBodyHeightForCellWidth:CGRectGetWidth(self.bounds)];
    [self.contentView setNeedsLayout];
}

- (BOOL)applyStreamingText:(NSString *)text {
    CGFloat width = CGRectGetWidth(self.bounds);
    CGSize previous = self.measuredLayoutSize;
    // 宽度变化也可能改变行高，不能先用新宽度覆盖旧测量基线。
    if (width > 38 && (previous.height <= 0 || previous.width <= 38)) {
        previous = [self systemLayoutSizeFittingSize:CGSizeMake(width, UILayoutFittingCompressedSize.height)
            withHorizontalFittingPriority:UILayoutPriorityRequired verticalFittingPriority:UILayoutPriorityFittingSizeLevel];
    }
    if (self.displayedStatus != self.currentMessage.status) {
        self.displayedStatus = self.currentMessage.status;
        NSString *status = [self tl_statusTextForMessage:self.currentMessage];
        self.statusLabel.text = status;
        self.statusLabel.hidden = status.length == 0;
    }
    if ([self tl_updateAuxiliaryCard]) {
        [self.messageTopConstraint uninstall];
        [self.messageBody mas_updateConstraints:^(MASConstraintMaker *make) {
            if (self.auxiliaryTextView) self.messageTopConstraint = make.top.equalTo(self.auxiliaryTextView.mas_bottom).offset(10);
            else if (!self.imageScrollView.hidden) self.messageTopConstraint = make.top.equalTo(self.imageScrollView.mas_bottom).offset(10);
            else self.messageTopConstraint = make.top.equalTo(self.bubbleView).offset(12);
        }];
    }
    text = text ?: @"";
    NSString *old = self.displayedSource ?: @"";
    NSString *tail = [text hasPrefix:old] ? [text substringFromIndex:old.length] : text;
    self.displayedSource = text;
    BOOL isUser = self.currentMessage.role == TLWAIAssistantMessageRoleUser;
    [self.messageBody applySource:text literal:isUser selectable:NO
        textColor:isUser ? UIColor.whiteColor : [UIColor colorWithRed:0.153 green:0.153 blue:0.153 alpha:1]];
    self.accessibilityLabel = isUser ? nil : TLWAIAccessibilityLabel(YES, nil);
    self.messageBody.accessibilityElementsHidden = !isUser;
    // 首个 delta 到达前正文可能为空，不能继续保留隐藏/无高度状态。
    if (text.length && self.messageBody.hidden) {
        self.messageBody.hidden = NO;
        [self configureWithMessage:self.currentMessage];
    }
    if (self.window && self.currentMessage.hasAssistantOutput && tail.length) {
        __block NSUInteger graphemes = 0;
        [tail enumerateSubstringsInRange:NSMakeRange(0, tail.length) options:NSStringEnumerationByComposedCharacterSequences
            usingBlock:^(NSString *substring, NSRange range, NSRange enclosing, BOOL *stop) { graphemes++; }];
        [self.currentMessage.trace mark:TLWAITraceStageFirstVisible count:1];
        [self.currentMessage.trace mark:TLWAITraceStageVisibleFrame count:graphemes];
    }
    [self tl_updateBodyHeightForCellWidth:CGRectGetWidth(self.bounds)];
    [self setNeedsLayout];
    if (width <= 38) return YES;
    CGSize current = [self systemLayoutSizeFittingSize:CGSizeMake(width, UILayoutFittingCompressedSize.height)
        withHorizontalFittingPriority:UILayoutPriorityRequired verticalFittingPriority:UILayoutPriorityFittingSizeLevel];
    return fabs(current.height - previous.height) >= 0.5;
}

- (void)tl_updateBodyHeightForCellWidth:(CGFloat)width {
    if (width <= 38 || !self.currentMessage || self.messageBody.hidden) return;
    CGFloat bubbleWidth = width - kBubbleSidePad * 2;
    if (self.currentMessage.role == TLWAIAssistantMessageRoleUser) {
        CGFloat naturalWidth = ceil([self.messageBody.attributedText boundingRectWithSize:CGSizeMake(bubbleWidth - 28, CGFLOAT_MAX)
            options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size.width) + 28;
        bubbleWidth = MIN(bubbleWidth, MAX(44, MAX(naturalWidth, self.imageAreaWidth + 24)));
        [self.bubbleView mas_updateConstraints:^(MASConstraintMaker *make) { make.width.mas_equalTo(bubbleWidth); }];
    }
    CGFloat height = [self.messageBody heightForWidth:MAX(1, bubbleWidth - 28)];
    [self.messageHeightConstraint setOffset:height];
}

- (CGSize)systemLayoutSizeFittingSize:(CGSize)targetSize withHorizontalFittingPriority:(UILayoutPriority)horizontalPriority verticalFittingPriority:(UILayoutPriority)verticalPriority {
    [self tl_updateBodyHeightForCellWidth:targetSize.width];
    CGSize size = [super systemLayoutSizeFittingSize:targetSize withHorizontalFittingPriority:horizontalPriority verticalFittingPriority:verticalPriority];
    self.measuredLayoutSize = CGSizeMake(targetSize.width, size.height);
    return size;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self tl_updateBodyHeightForCellWidth:CGRectGetWidth(self.bounds)];
    if (self.window && self.currentMessage.hasAssistantOutput) [self.currentMessage.trace mark:TLWAITraceStageFirstVisible count:1];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    if (self.currentMessage && ![self.traitCollection.preferredContentSizeCategory isEqualToString:previousTraitCollection.preferredContentSizeCategory])
        [self configureWithMessage:self.currentMessage];
}

+ (CGFloat)auxiliaryHeightForMessage:(TLWAIAssistantMessage *)message {
    if (!message.auxiliaryText.length) return 0;
    return message.supplementalText.length ? 112 : 76;
}
- (BOOL)tl_updateAuxiliaryCard {
    TLWAIAssistantMessage *message = self.currentMessage;
    CGFloat height = [self.class auxiliaryHeightForMessage:message];
    BOOL hasImages = message.localImages.count + message.remoteImageURLs.count > 0;
    BOOL changed = height != self.auxiliaryHeight || (height && hasImages != self.auxiliaryHasImages);
    if (!height) {
        [self.auxiliaryTextView removeFromSuperview]; self.auxiliaryTextView = nil;
    } else {
        if (!self.auxiliaryTextView) {
            self.auxiliaryTextView = [TLWAIRelayTextView new];
            self.auxiliaryTextView.editable = NO; self.auxiliaryTextView.selectable = NO;
            self.auxiliaryTextView.scrollsToTop = NO; self.auxiliaryTextView.alwaysBounceVertical = NO;
            self.auxiliaryTextView.directionalLockEnabled = YES;
            self.auxiliaryTextView.textContainerInset = UIEdgeInsetsMake(8, 10, 8, 10);
            self.auxiliaryTextView.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
            self.auxiliaryTextView.textColor = UIColor.labelColor;
            self.auxiliaryTextView.backgroundColor = UIColor.tertiarySystemBackgroundColor;
            self.auxiliaryTextView.layer.cornerRadius = 10;
            self.auxiliaryTextView.delegate = (id<UITextViewDelegate>)self;
            self.auxiliaryTextView.accessibilityIdentifier = @"ai.diseaseCard";
            [self.bubbleView addSubview:self.auxiliaryTextView];
            if (self.outerTable) [self.relayCoordinator registerTextView:self.auxiliaryTextView outerTable:self.outerTable];
            changed = YES;
        }
        if (![self.auxiliaryTextView.text isEqualToString:message.auxiliaryText]) {
            self.auxiliaryTextView.text = message.auxiliaryText;
            [self setNeedsLayout];
        }
        if (changed) [self.auxiliaryTextView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(self.bubbleView).insets(UIEdgeInsetsMake(0, 12, 0, 12));
            if (hasImages) make.top.equalTo(self.imageScrollView.mas_bottom).offset(10);
            else make.top.equalTo(self.bubbleView).offset(12);
            make.height.mas_equalTo(height);
        }];
    }
    self.auxiliaryHeight = height; self.auxiliaryHasImages = hasImages;
    return changed;
}

- (void)registerGestureCoordinator:(TLWAIGestureCoordinator *)coordinator outerTable:(UITableView *)table {
    self.relayCoordinator = coordinator; self.outerTable = table;
    if (self.auxiliaryTextView) [coordinator registerTextView:self.auxiliaryTextView outerTable:table];
}
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView == self.auxiliaryTextView) {
        if (!self.relayCoordinator.applyingOffsets) [self.relayCoordinator correctRelayOffsets];
        return;
    }
    // 正文不再拥有纵向 contentOffset；横向图片条不参与纵向接力。
}

- (BOOL)hasDeferredUpdates { return self.messageBody.hasDeferredUpdates; }

- (BOOL)interactionActive {
    return self.messageBody.interactionActive ||
           self.imageScrollView.isTracking || self.imageScrollView.isDragging || self.imageScrollView.isDecelerating ||
           self.auxiliaryTextView.isTracking || self.auxiliaryTextView.isDragging || self.auxiliaryTextView.isDecelerating;
}
- (BOOL)stopDecelerationForExplicitJump {
    BOOL fingerDown = [self.messageBody stopDecelerationForExplicitJump];
    for (UIScrollView *scrollView in @[self.imageScrollView ?: [NSNull null], self.auxiliaryTextView ?: [NSNull null]]) {
        if (![scrollView isKindOfClass:UIScrollView.class]) continue;
        if (scrollView.isTracking || scrollView.isDragging) fingerDown = YES;
        else if (scrollView.isDecelerating) scrollView.contentOffset = scrollView.contentOffset;
    }
    return fingerDown;
}
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if (self.onInteractionChanged) self.onInteractionChanged();
}
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate && self.onInteractionChanged) self.onInteractionChanged();
}
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (self.onInteractionChanged) self.onInteractionChanged();
}

#pragma mark - Private

- (void)tl_setupViews {
    self.container = [[UIView alloc] init];
    self.container.backgroundColor = [UIColor clearColor];
    [self.contentView addSubview:self.container];
    [self.container mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView).offset(kMessageVerticalInset);
        make.left.right.equalTo(self.contentView);
        make.bottom.lessThanOrEqualTo(self.contentView).offset(-kMessageVerticalInset);
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

    self.imageScrollView = [[TLWAIHorizontalScrollView alloc] init];
    self.imageScrollView.showsHorizontalScrollIndicator = NO;
    self.imageScrollView.alwaysBounceHorizontal = NO;
    self.imageScrollView.backgroundColor = [UIColor clearColor];
    self.imageScrollView.scrollsToTop = NO;
    self.imageScrollView.directionalLockEnabled = YES;
    self.imageScrollView.delegate = self;
    [self.bubbleView addSubview:self.imageScrollView];
    [self.imageScrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        self.imageTopConstraint = make.top.equalTo(self.bubbleView).offset(12);
        make.left.equalTo(self.bubbleView).offset(12);
        make.right.equalTo(self.bubbleView).offset(-12);
        self.imageHeightConstraint = make.height.mas_equalTo(72);
    }];

    self.messageBody = [[TLWAIMarkdownBodyView alloc] init];
    self.messageBody.textDelegate = self;
    __weak typeof(self) weakSelf = self;
    self.messageBody.onInteractionChanged = ^{ if (weakSelf.onInteractionChanged) weakSelf.onInteractionChanged(); };
    [self.bubbleView addSubview:self.messageBody];
    [self.messageBody mas_makeConstraints:^(MASConstraintMaker *make) {
        self.messageTopConstraint = make.top.equalTo(self.imageScrollView.mas_bottom).offset(10);
        make.left.equalTo(self.bubbleView).offset(14);
        make.right.equalTo(self.bubbleView).offset(-14);
        self.messageHeightConstraint = make.height.mas_equalTo(22);
        self.messageBottomConstraint = make.bottom.equalTo(self.bubbleView).offset(-12);
    }];

    self.statusLabel = [[UILabel alloc] init];
    self.statusLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightMedium];
    self.statusLabel.textColor = [UIColor colorWithWhite:0.42 alpha:1.0];
    self.statusLabel.numberOfLines = 0;
    [self.container addSubview:self.statusLabel];
    [self.statusLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.bubbleView.mas_bottom).offset(4);
        self.statusLeadingConstraint = make.left.equalTo(self.bubbleView).offset(4);
        self.statusTrailingConstraint = make.right.equalTo(self.bubbleView).offset(-4);
    }];
    self.continueButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.continueButton setTitle:@"重新生成" forState:UIControlStateNormal];
    self.continueButton.hidden = YES;
    self.continueButton.exclusiveTouch = YES;
    [self.continueButton addTarget:self action:@selector(tl_continueTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.container addSubview:self.continueButton];
    [self.bubbleView mas_makeConstraints:^(MASConstraintMaker *make) {
        self.bubbleBottomConstraint = make.bottom.equalTo(self.container);
    }];
}

- (void)tl_configureImageStripWithMessage:(TLWAIAssistantMessage *)message {
    if (!message.localImages.count && message.imageRelativePaths.count) {
        NSMutableArray<UIImage *> *loaded = [NSMutableArray array];
        for (NSString *path in message.imageRelativePaths) {
            UIImage *image = [TLWAIImageArchive activeImageForRelativePath:path];
            if (image) [loaded addObject:image];
        }
        if (loaded.count) message.localImages = loaded;
    }
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
    NSInteger displayIndex = 0;

    for (UIImage *image in message.localImages) {
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(x, 0, thumbW, thumbH)];
        imageView.image = image;
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.clipsToBounds = YES;
        imageView.layer.cornerRadius = 10;
        imageView.userInteractionEnabled = YES;
        imageView.tag = 5000 + displayIndex;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tl_messageImageTapped:)];
        [imageView addGestureRecognizer:tap];
        [self.imageScrollView addSubview:imageView];
        x += thumbW + gap;
        displayIndex += 1;
    }

    for (NSString *urlString in message.remoteImageURLs) {
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(x, 0, thumbW, thumbH)];
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.clipsToBounds = YES;
        imageView.layer.cornerRadius = 10;
        imageView.backgroundColor = [UIColor colorWithWhite:0.92 alpha:1.0];
        imageView.userInteractionEnabled = YES;
        imageView.tag = 5000 + displayIndex;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tl_messageImageTapped:)];
        [imageView addGestureRecognizer:tap];
        NSURL *url = [NSURL URLWithString:urlString];
        if (url) {
            [imageView sd_setImageWithURL:url];
        }
        [self.imageScrollView addSubview:imageView];
        x += thumbW + gap;
        displayIndex += 1;
    }

    self.imageScrollView.contentSize = CGSizeMake(MAX(x - gap, thumbW), thumbH);
}

- (void)tl_messageImageTapped:(UITapGestureRecognizer *)tap {
    UIImageView *imageView = (UIImageView *)tap.view;
    if (![imageView isKindOfClass:[UIImageView class]]) return;
    // 优先用 previewImages 的高清图，没有再回退到 cell 上展示的缩略图（远程 URL 也走这条路）
    UIImage *image = nil;
    NSInteger index = imageView.tag - 5000;
    NSArray<UIImage *> *preview = self.currentMessage.previewImages;
    if (index >= 0 && index < (NSInteger)preview.count) {
        image = preview[index];
    }
    if (!image) {
        image = imageView.image;
    }
    if (!image) return;
    [self tl_presentFullscreenImage:image];
}

- (void)tl_presentFullscreenImage:(UIImage *)image {
    UIWindow *window = [self tl_activeWindow];
    if (!window) return;

    UIView *overlay = [[UIView alloc] initWithFrame:window.bounds];
    overlay.backgroundColor = [UIColor colorWithWhite:0 alpha:0.92];
    overlay.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    UIImageView *fullImageView = [[UIImageView alloc] initWithImage:image];
    fullImageView.contentMode = UIViewContentModeScaleAspectFit;
    fullImageView.frame = CGRectInset(window.bounds, 20, 80);
    fullImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [overlay addSubview:fullImageView];

    UITapGestureRecognizer *dismissTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tl_dismissFullscreenPreview:)];
    [overlay addGestureRecognizer:dismissTap];

    overlay.alpha = 0;
    [window addSubview:overlay];
    [UIView animateWithDuration:0.2 animations:^{
        overlay.alpha = 1;
    }];
}

- (void)tl_dismissFullscreenPreview:(UITapGestureRecognizer *)tap {
    UIView *overlay = tap.view;
    [UIView animateWithDuration:0.18 animations:^{
        overlay.alpha = 0;
    } completion:^(BOOL finished) {
        [overlay removeFromSuperview];
    }];
}

- (UIWindow *)tl_activeWindow {
    NSSet<UIScene *> *scenes = UIApplication.sharedApplication.connectedScenes;
    for (UIScene *scene in scenes) {
        if (![scene isKindOfClass:[UIWindowScene class]]) continue;
        UIWindowScene *windowScene = (UIWindowScene *)scene;
        for (UIWindow *window in windowScene.windows) {
            if (window.isKeyWindow) {
                return window;
            }
        }
        if (windowScene.windows.firstObject) {
            return windowScene.windows.firstObject;
        }
    }
    return UIApplication.sharedApplication.keyWindow;
}

- (NSString *)tl_statusTextForMessage:(TLWAIAssistantMessage *)message {
    NSMutableArray<NSString *> *parts = [NSMutableArray array];
    if (message.status == TLWAIAssistantMessageStatusQueued) [parts addObject:@"排队中"];
    else if (message.status == TLWAIAssistantMessageStatusWaiting) [parts addObject:@"网络较慢，等待中"];
    else if (message.status == TLWAIAssistantMessageStatusRecovering) [parts addObject:@"正在恢复连接，保留当前回复"];
    else if (message.status == TLWAIAssistantMessageStatusSending) [parts addObject:@"发送中"];
    else if (message.status == TLWAIAssistantMessageStatusFailed) [parts addObject:message.errorMessage.length ? message.errorMessage : @"发送失败"];
    BOOL streaming = message.status == TLWAIAssistantMessageStatusSending || message.status == TLWAIAssistantMessageStatusWaiting || message.status == TLWAIAssistantMessageStatusRecovering;
    if (!streaming && message.localHypothesis.length) [parts addObject:message.localHypothesis];
    if (!streaming && message.role == TLWAIAssistantMessageRoleAssistant && message.moderationNote.length) [parts addObject:message.moderationNote];
    return [parts componentsJoinedByString:@"\n"];
}

- (void)tl_continueTapped {
    if (self.onContinue) self.onContinue(self.currentMessage);
}
- (void)textViewDidChangeSelection:(UITextView *)textView {
    if (self.onInteractionChanged) self.onInteractionChanged();
}
- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange interaction:(UITextItemInteraction)interaction {
    NSArray *confirmed = [NSUserDefaults.standardUserDefaults arrayForKey:@"TLWAIConfirmedHTTPSHosts"] ?: @[];
    TLWAILinkDecision decision = TLWAIDecideLink(URL.scheme, URL.host, [confirmed containsObject:URL.host.lowercaseString ?: @""]);
    if (decision == TLWAILinkDecisionAllow) return YES;
    if (decision == TLWAILinkDecisionConfirm) {
        UIViewController *controller = nil;
        for (UIResponder *responder = self; responder; responder = responder.nextResponder) {
            if ([responder isKindOfClass:UIViewController.class]) { controller = (UIViewController *)responder; break; }
        }
        if (!controller) return NO;
        NSString *host = URL.host.lowercaseString ?: @"";
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"打开链接" message:host preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:@"打开" style:UIAlertActionStyleDefault handler:^(__kindof UIAlertAction *action) {
            NSMutableArray *hosts = [confirmed mutableCopy];
            if (host.length && ![hosts containsObject:host]) [hosts addObject:host];
            [NSUserDefaults.standardUserDefaults setObject:hosts forKey:@"TLWAIConfirmedHTTPSHosts"];
            [UIApplication.sharedApplication openURL:URL options:@{} completionHandler:nil];
        }]];
        [controller presentViewController:alert animated:YES completion:nil];
    }
    return NO;
}
- (UIContextMenuConfiguration *)contextMenuInteraction:(UIContextMenuInteraction *)interaction configurationForMenuAtLocation:(CGPoint)location {
    TLWAIAssistantMessage *message = self.currentMessage;
    BOOL streaming = message.status == TLWAIAssistantMessageStatusSending || message.status == TLWAIAssistantMessageStatusWaiting || message.status == TLWAIAssistantMessageStatusRecovering;
    if (!message || streaming || !(message.completed || message.role == TLWAIAssistantMessageRoleUser)) return nil;
    NSString *text = message.text ?: @"";
    return [UIContextMenuConfiguration configurationWithIdentifier:nil previewProvider:nil actionProvider:^UIMenu *(NSArray<UIMenuElement *> *suggested) {
        UIAction *copy = [UIAction actionWithTitle:@"复制" image:nil identifier:nil handler:^(__kindof UIAction *action) {
            UIPasteboard.generalPasteboard.string = text;
        }];
        return [UIMenu menuWithTitle:@"" children:@[copy]];
    }];
}

@end
