//
//  TLWAIAssistantMessageListView.m
//  TL-PestIdentify
//
//  Created by Northern Lights on 2026/4/3.
//  职责：实现AI助手页面视图组件。
//
#import "TLWAIAssistantMessageListView.h"
#import "TLWAIAssistantMessage.h"
#import "TLWAIAssistantMessageCell.h"
#import "TLWAIAssistantSystemMessageCell.h"
#import "TLWAIGestureCoordinator.h"
#import <Masonry/Masonry.h>

@interface TLWAIAssistantMessageListView () <UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIView *emptyStateView;
@property (nonatomic, strong) UILabel *emptyStateLabel;
// 展示层只维护当前要渲染的快照，不持有真正的会话源数据。
@property (nonatomic, copy) NSArray<TLWAIAssistantMessage *> *messages;
/// 距底部 24pt 内视为贴底；非贴底时禁止流式更新改动 contentOffset。
@property (nonatomic, assign) BOOL followsBottom;
/// 用户阅读意图与程序化 offset 写入分离；只有交互结束后允许恢复跟随。
@property (nonatomic, assign) BOOL userInteracting;
@property (nonatomic, assign) CGFloat measuredWidthBucket;
@property (nonatomic, assign) BOOL pendingHeightCommit;
@property (nonatomic, assign) BOOL programmatic;
@property (nonatomic, assign) CGFloat dragBeganY;
@property (nonatomic, assign) CGFloat dragVelocityY;
@property (nonatomic, assign) BOOL pendingExplicitBottom;
@property (nonatomic, strong) UIButton *jumpToBottomButton;
@property (nonatomic, assign) BOOL animatingToBottom;
@property (nonatomic, strong) NSMutableSet<NSString *> *deferredMessages;
@property (nonatomic, strong) NSMutableSet<NSString *> *offscreenUpdates;
@property (nonatomic, copy) NSString *readingAnchorIdentifier;
@property (nonatomic, assign) CGFloat readingAnchorWithin;
@property (nonatomic, assign) CGFloat readingOffsetY;
@property (nonatomic, assign) BOOL hasReadingSnapshot;
@property (nonatomic, assign) NSUInteger bottomCorrectionGeneration;
@property (nonatomic, assign) BOOL bottomCorrectionScheduled;
@property (nonatomic, assign) NSUInteger bottomCorrectionPasses;
@property (nonatomic, assign) BOOL forceButtonJump;
@end

@implementation TLWAIAssistantMessageListView

static CGFloat const kHorizontalInset = 12.0;

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _messages = @[];
        _followsBottom = YES;
        _deferredMessages = [NSMutableSet set];
        _offscreenUpdates = [NSMutableSet set];
        [self tl_setupViews];
    }
    return self;
}

- (void)displayMessages:(NSArray<TLWAIAssistantMessage *> *)messages {
    BOOL shouldFollow = self.followsBottom;
    CGPoint preservedOffset = self.tableView.contentOffset;
    self.messages = messages ?: @[];
    [self.offscreenUpdates removeAllObjects];
    self.emptyStateView.hidden = self.messages.count > 0;
    [self.tableView reloadData];
    [self tl_finishContentUpdateFollowing:shouldFollow
                         preservedOffset:preservedOffset
                                animated:NO];
    [self tl_updateJumpButton];
}

- (void)appendMessage:(TLWAIAssistantMessage *)message {
    if (!message) return;

    BOOL shouldFollow = self.followsBottom;
    CGPoint preservedOffset = self.tableView.contentOffset;
    NSMutableArray<TLWAIAssistantMessage *> *list = [self.messages mutableCopy] ?: [NSMutableArray array];
    [list addObject:message];
    self.messages = list.copy;
    self.emptyStateView.hidden = self.messages.count > 0;

    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.messages.count - 1 inSection:0];
    [self.tableView beginUpdates];
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    [self.tableView endUpdates];
    [self tl_finishContentUpdateFollowing:shouldFollow
                         preservedOffset:preservedOffset
                                animated:NO];
    [self tl_updateJumpButton];
}

- (void)reloadMessage:(TLWAIAssistantMessage *)message {
    if (!message) return;

    // 正文与富文本仍更新；仅实际行高变化才提交自适应高度。
    NSUInteger index = [self.messages indexOfObjectPassingTest:^BOOL(TLWAIAssistantMessage *candidate, NSUInteger idx, BOOL *stop) {
        return [candidate.identifier isEqualToString:message.identifier];
    }];
    if (index == NSNotFound) return;
    [self tl_captureReadingPosition];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    TLWAIAssistantMessageCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    BOOL visible = cell && !cell.hidden && CGRectIntersectsRect([cell convertRect:cell.bounds toView:self.tableView], self.tableView.bounds);
    if (!visible) {
        [self.offscreenUpdates addObject:message.identifier];
        if (self.followsBottom) {
            self.pendingExplicitBottom = YES;
            [self tl_scrollToBottomAnimated:NO];
        }
        [self setNeedsLayout];
        return;
    }
    BOOL streaming = message.status == TLWAIAssistantMessageStatusSending || message.status == TLWAIAssistantMessageStatusWaiting || message.status == TLWAIAssistantMessageStatusRecovering;
    BOOL deferTerminalConfiguration = !streaming && cell.interactionActive;
    BOOL heightChanged;
    if (streaming || deferTerminalConfiguration) heightChanged = [cell applyStreamingText:message.text];
    else {
        CGFloat width = CGRectGetWidth(cell.bounds);
        CGSize target = CGSizeMake(width, UILayoutFittingCompressedSize.height);
        CGFloat before = [cell systemLayoutSizeFittingSize:target withHorizontalFittingPriority:UILayoutPriorityRequired
            verticalFittingPriority:UILayoutPriorityFittingSizeLevel].height;
        [cell configureWithMessage:message];
        CGFloat after = [cell systemLayoutSizeFittingSize:target withHorizontalFittingPriority:UILayoutPriorityRequired
            verticalFittingPriority:UILayoutPriorityFittingSizeLevel].height;
        heightChanged = width <= 38 || fabs(after - before) >= 0.5;
    }
    if (cell.hasDeferredUpdates || deferTerminalConfiguration) [self.deferredMessages addObject:message.identifier];
    else [self.deferredMessages removeObject:message.identifier];
    if (heightChanged) [self tl_invalidateRowHeights];
    else if (self.hasReadingSnapshot) [self setNeedsLayout];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat bucket = floor(CGRectGetWidth(self.tableView.bounds) / 4);
    if (bucket != self.measuredWidthBucket) {
        self.measuredWidthBucket = bucket;
        [self tl_invalidateRowHeights];
    }
    [self tl_commitHeightsIfPossible];
    [self tl_updateJumpButton];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    [self tl_invalidateRowHeights];
}

- (void)tl_captureReadingPosition {
    if (self.hasReadingSnapshot || self.programmatic || self.followsBottom) return;
    // UITableView 的可见行/contentSize 查询可能立即修正估算高度，先保存查询前的位置。
    CGFloat previousY = self.tableView.contentOffset.y;
    if (self.interactionActive) return;
    UIEdgeInsets inset = self.tableView.adjustedContentInset;
    CGFloat maximum = MAX(-inset.top, self.tableView.contentSize.height - self.tableView.bounds.size.height + inset.bottom);
    if (previousY < -inset.top - 0.5 || previousY > maximum + 0.5) return;
    self.readingOffsetY = previousY;
    CGFloat top = MAX(0, previousY + inset.top);
    CGPoint point = CGPointMake(1, top);
    NSIndexPath *anchor = [self.tableView indexPathForRowAtPoint:point];
    CGRect rect = anchor ? [self.tableView rectForRowAtIndexPath:anchor] : CGRectZero;
    BOOL valid = anchor && anchor.row < self.messages.count && CGRectContainsPoint(rect, point);
    self.readingAnchorIdentifier = valid ? self.messages[anchor.row].identifier : nil;
    self.readingAnchorWithin = valid ? self.readingOffsetY - CGRectGetMinY(rect) : 0;
    self.hasReadingSnapshot = YES;
}

- (void)tl_invalidateRowHeights {
    [self tl_captureReadingPosition];
    [self setNeedsLayout];
    if (self.pendingHeightCommit) return;
    self.pendingHeightCommit = YES;
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{ [weakSelf tl_commitHeightsIfPossible]; });
}

- (void)tl_commitHeightsIfPossible {
    BOOL commitHeight = self.pendingHeightCommit;
    if (!commitHeight && !self.hasReadingSnapshot) return;
    [self tl_captureReadingPosition];
    if ([self tl_isBouncing] && !self.hasReadingSnapshot) return;
    self.pendingHeightCommit = NO;
    BOOL canPreserveOffset = !self.interactionActive && self.hasReadingSnapshot;
    CGFloat previousY = self.hasReadingSnapshot ? self.readingOffsetY : self.tableView.contentOffset.y;
    NSString *anchorID = self.readingAnchorIdentifier;
    CGFloat within = self.readingAnchorWithin;
    self.hasReadingSnapshot = NO;
    self.readingAnchorIdentifier = nil;
    [UIView performWithoutAnimation:^{
        self.programmatic = YES;
        // 离屏/同高度更新也可能结算 UITableView 的估算几何，只恢复阅读锚点，不提交行高事务。
        if (commitHeight) {
            [self.tableView beginUpdates];
            [self.tableView endUpdates];
        }
        [self.tableView layoutIfNeeded];
        self.programmatic = NO;
    }];
    if (self.followsBottom) {
        if (!self.pendingExplicitBottom && !self.animatingToBottom) [self followBottomIfNeededAnimated:NO];
    } else if (canPreserveOffset) {
        NSUInteger row = anchorID ? [self.messages indexOfObjectPassingTest:^BOOL(TLWAIAssistantMessage *message, NSUInteger index, BOOL *stop) {
            return [message.identifier isEqualToString:anchorID];
        }] : NSNotFound;
        CGFloat y = row == NSNotFound ? previousY : CGRectGetMinY([self.tableView rectForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0]]) + within;
        UIEdgeInsets inset = self.tableView.adjustedContentInset;
        CGFloat maximum = MAX(-inset.top, self.tableView.contentSize.height - self.tableView.bounds.size.height + inset.bottom);
        y = MIN(maximum, MAX(-inset.top, y));
        self.programmatic = YES;
        [self.tableView setContentOffset:CGPointMake(self.tableView.contentOffset.x, y) animated:NO];
        self.programmatic = NO;
    }
    [self tl_updateJumpButton];
}

- (void)scrollToBottomAnimated:(BOOL)animated {
    self.followsBottom = YES;
    self.pendingExplicitBottom = YES;
    self.bottomCorrectionGeneration += 1;
    self.bottomCorrectionScheduled = NO;
    self.bottomCorrectionPasses = 0;
    self.animatingToBottom = NO;
    if (!self.tableView.tracking && !self.tableView.dragging) {
        self.programmatic = YES;
        [self.tableView setContentOffset:self.tableView.contentOffset animated:NO];
        self.programmatic = NO;
        self.userInteracting = NO;
    }
    [self tl_applyDeferredUpdates];
    [self tl_invalidateRowHeights];
    [self tl_commitHeightsIfPossible];
    [self tl_scrollToBottomAnimated:animated];
}

- (void)followBottomIfNeededAnimated:(BOOL)animated {
    if (!self.followsBottom) return;
    [self tl_scrollToBottomAnimated:animated];
}

- (void)tl_finishContentUpdateFollowing:(BOOL)shouldFollow
                       preservedOffset:(CGPoint)preservedOffset
                              animated:(BOOL)animated {
    if ([self tl_mustNotMutateOffset]) return;
    [self.tableView layoutIfNeeded];
    if (shouldFollow) {
        self.followsBottom = YES;
        [self tl_scrollToBottomAnimated:animated];
        return;
    }

    self.followsBottom = NO;
    [self tl_setProgrammaticOffset:preservedOffset animated:NO];
}

- (CGFloat)tl_bottomOffset {
    UIEdgeInsets inset = self.tableView.adjustedContentInset;
    if (self.messages.count == 0 || self.tableView.bounds.size.height <= 0) return -inset.top;
    NSIndexPath *last = [NSIndexPath indexPathForRow:self.messages.count - 1 inSection:0];
    CGFloat extent = MAX(self.tableView.contentSize.height, CGRectGetMaxY([self.tableView rectForRowAtIndexPath:last]));
    return MAX(-inset.top, extent - self.tableView.bounds.size.height + inset.bottom);
}
- (BOOL)tl_lastRowNeedsMeasurement {
    if (self.messages.count == 0) return NO;
    NSIndexPath *last = [NSIndexPath indexPathForRow:self.messages.count - 1 inSection:0];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:last];
    if (!cell) return YES;
    CGFloat width = CGRectGetWidth(cell.bounds);
    if (width < 1) width = CGRectGetWidth(self.tableView.bounds);
    if (width < 1) return YES;
    CGFloat fitted = ceil([cell systemLayoutSizeFittingSize:CGSizeMake(width, UILayoutFittingCompressedSize.height)
                              withHorizontalFittingPriority:UILayoutPriorityRequired
                                    verticalFittingPriority:UILayoutPriorityFittingSizeLevel].height);
    return fitted > ceil(CGRectGetHeight([self.tableView rectForRowAtIndexPath:last])) + 1;
}
- (void)tl_commitVisibleRowHeights {
    [UIView performWithoutAnimation:^{
        self.programmatic = YES;
        [self.tableView beginUpdates];
        [self.tableView endUpdates];
        [self.tableView layoutIfNeeded];
        self.programmatic = NO;
    }];
}
- (void)tl_scheduleBottomCorrection {
    if (self.bottomCorrectionScheduled || !self.pendingExplicitBottom) return;
    self.bottomCorrectionScheduled = YES;
    NSUInteger generation = self.bottomCorrectionGeneration;
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        TLWAIAssistantMessageListView *strongSelf = weakSelf;
        if (!strongSelf || strongSelf.bottomCorrectionGeneration != generation) return;
        strongSelf.bottomCorrectionScheduled = NO;
        if (!strongSelf.followsBottom || !strongSelf.pendingExplicitBottom || strongSelf.animatingToBottom) return;
        [strongSelf tl_correctMeasuredBottom];
    });
}
- (void)tl_correctMeasuredBottom {
    if (self.messages.count == 0) {
        self.pendingExplicitBottom = NO;
        [self tl_updateJumpButton];
        return;
    }
    if ([self tl_mustNotMutateOffset]) {
        self.pendingExplicitBottom = YES;
        return;
    }
    NSIndexPath *last = [NSIndexPath indexPathForRow:self.messages.count - 1 inSection:0];
    if (![self.tableView cellForRowAtIndexPath:last]) {
        [self tl_setProgrammaticOffset:CGPointMake(self.tableView.contentOffset.x, [self tl_bottomOffset]) animated:NO];
        [self.tableView layoutIfNeeded];
    }
    [[self.tableView cellForRowAtIndexPath:last] layoutIfNeeded];
    [self tl_commitVisibleRowHeights];
    [self tl_setProgrammaticOffset:CGPointMake(self.tableView.contentOffset.x, [self tl_bottomOffset]) animated:NO];
    [self.tableView layoutIfNeeded];
    [self tl_alignLastCellBottom];
    if ([self tl_lastRowNeedsMeasurement] && self.bottomCorrectionPasses < 4) {
        self.bottomCorrectionPasses += 1;
        self.pendingExplicitBottom = YES;
        [self tl_scheduleBottomCorrection];
        return;
    }
    self.pendingExplicitBottom = NO;
    self.forceButtonJump = NO;
    self.bottomCorrectionPasses = 0;
    [self tl_updateJumpButton];
}
- (void)tl_revealMeasuredBottomAnimated:(BOOL)animated {
    NSIndexPath *last = self.messages.count ? [NSIndexPath indexPathForRow:self.messages.count - 1 inSection:0] : nil;
    BOOL measured = last && [self.tableView cellForRowAtIndexPath:last] && ![self tl_lastRowNeedsMeasurement];
    CGFloat target = [self tl_bottomOffset];
    BOOL animate = measured && animated && !UIAccessibilityIsReduceMotionEnabled() && fabs(target - self.tableView.contentOffset.y) >= 0.5;
    if (animate) {
        self.animatingToBottom = YES;
        self.pendingExplicitBottom = YES;
        [self tl_setProgrammaticOffset:CGPointMake(self.tableView.contentOffset.x, target) animated:YES];
        [self tl_updateJumpButton];
        return;
    }
    [self tl_correctMeasuredBottom];
}
- (void)tl_scrollToBottomAnimated:(BOOL)animated {
    if (self.messages.count == 0) return;
    if ([self tl_mustNotMutateOffset]) {
        if (self.followsBottom) self.pendingExplicitBottom = YES;
        return;
    }
    if (self.animatingToBottom) return;
    if (self.pendingExplicitBottom) {
        [self tl_revealMeasuredBottomAnimated:animated];
        return;
    }
    [self.tableView layoutIfNeeded];
    UIEdgeInsets inset = self.tableView.adjustedContentInset;
    NSIndexPath *last = [NSIndexPath indexPathForRow:self.messages.count - 1 inSection:0];
    CGFloat bottomOffset = MAX(-inset.top,
                               CGRectGetMaxY([self.tableView rectForRowAtIndexPath:last]) - self.tableView.bounds.size.height + inset.bottom);
    BOOL animate = animated && !UIAccessibilityIsReduceMotionEnabled() && fabs(bottomOffset - self.tableView.contentOffset.y) >= 0.5;
    self.animatingToBottom = animate;
    self.programmatic = YES;
    [self.tableView scrollToRowAtIndexPath:last atScrollPosition:UITableViewScrollPositionBottom animated:animate];
    self.programmatic = NO;
    [self tl_updateJumpButton];
}
- (BOOL)tl_isNearBottom {
    UITableViewCell *cell = self.messages.count ? [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:self.messages.count - 1 inSection:0]] : nil;
    if (cell.window) {
        CGRect cellWindow = [cell convertRect:cell.bounds toView:nil];
        CGRect tableWindow = [self.tableView convertRect:self.tableView.bounds toView:nil];
        return CGRectGetMaxY(cellWindow) - (CGRectGetMaxY(tableWindow) - self.tableView.adjustedContentInset.bottom) <= 24;
    }
    CGFloat distance = [self tl_bottomOffset] - self.tableView.contentOffset.y;
    return distance >= -0.5 && distance <= 24;
}
- (void)tl_alignLastCellBottom {
    if (self.messages.count == 0) return;
    NSIndexPath *last = [NSIndexPath indexPathForRow:self.messages.count - 1 inSection:0];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:last];
    if (!cell) return;
    [cell layoutIfNeeded];
    CGRect cellWindow = [cell convertRect:cell.bounds toView:nil];
    CGRect tableWindow = [self.tableView convertRect:self.tableView.bounds toView:nil];
    CGFloat delta = CGRectGetMaxY(cellWindow) - (CGRectGetMaxY(tableWindow) - self.tableView.adjustedContentInset.bottom);
    if (delta <= 1) return;
    CGFloat wanted = self.tableView.contentOffset.y + delta;
    CGFloat maxOffset = self.tableView.contentSize.height - self.tableView.bounds.size.height + self.tableView.adjustedContentInset.bottom;
    if (wanted > maxOffset + 0.5) {
        UIView *footer = self.tableView.tableFooterView ?: [UIView new];
        footer.frame = CGRectMake(0, 0, 1, CGRectGetHeight(footer.frame) + wanted - maxOffset);
        self.tableView.tableFooterView = footer;
    }
    [self tl_setProgrammaticOffset:CGPointMake(self.tableView.contentOffset.x, wanted) animated:NO];
}

- (BOOL)tl_mustNotMutateOffset {
    if (self.forceButtonJump) {
        for (UITableViewCell *cell in self.tableView.visibleCells) {
            if ([cell isKindOfClass:TLWAIAssistantMessageCell.class]) [(TLWAIAssistantMessageCell *)cell stopDecelerationForExplicitJump];
        }
        return NO;
    }
    if (self.pendingExplicitBottom && !self.tableView.isTracking && !self.tableView.isDragging) {
        for (UITableViewCell *cell in self.tableView.visibleCells) {
            if ([cell isKindOfClass:TLWAIAssistantMessageCell.class] && [(TLWAIAssistantMessageCell *)cell stopDecelerationForExplicitJump]) return YES;
        }
        return NO;
    }
    return self.interactionActive || [self tl_isBouncing];
}
- (BOOL)tl_isBouncing {
    UIEdgeInsets inset = self.tableView.adjustedContentInset;
    CGFloat minY = -inset.top;
    CGFloat maxY = MAX(minY, self.tableView.contentSize.height - self.tableView.bounds.size.height + inset.bottom);
    return self.tableView.contentOffset.y < minY - 0.5 || self.tableView.contentOffset.y > maxY + 0.5;
}
- (void)tl_setProgrammaticOffset:(CGPoint)offset animated:(BOOL)animated {
    if ([self tl_mustNotMutateOffset] || fabs(self.tableView.contentOffset.y - offset.y) < 0.5) return;
    self.programmatic = YES;
    [self.tableView setContentOffset:offset animated:animated];
    self.programmatic = NO;
}
- (void)tl_applyDeferredUpdates {
    NSSet *identifiers = [self.deferredMessages copy];
    [self.deferredMessages removeAllObjects];
    for (TLWAIAssistantMessage *message in self.messages) {
        if ([identifiers containsObject:message.identifier]) [self reloadMessage:message];
    }
}
- (void)tl_userInteractionEnded {
    BOOL towardsBottom = self.dragVelocityY >= 0 && self.tableView.contentOffset.y >= self.dragBeganY - 0.5;
    self.followsBottom = self.pendingExplicitBottom || (towardsBottom && [self tl_isNearBottom]);
    [self tl_applyDeferredUpdates];
    [self tl_commitHeightsIfPossible];
    if (self.pendingExplicitBottom) [self tl_scrollToBottomAnimated:NO];
    [self tl_updateJumpButton];
}


- (void)setGestureCoordinator:(TLWAIGestureCoordinator *)coordinator {
    _gestureCoordinator = coordinator;
    for (UITableViewCell *cell in self.tableView.visibleCells) {
        if ([cell isKindOfClass:TLWAIAssistantMessageCell.class])
            [(TLWAIAssistantMessageCell *)cell registerGestureCoordinator:coordinator outerTable:self.tableView];
    }
}
- (UITableView *)tl_makeTableView {
    return [[TLWAIRelayTableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
}

#pragma mark - Private

- (void)tl_setupViews {
    self.tableView = [self tl_makeTableView];
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.showsVerticalScrollIndicator = NO;
    self.tableView.alwaysBounceVertical = YES;
    self.tableView.scrollsToTop = YES;
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    self.tableView.contentInset = UIEdgeInsetsMake(16, 0, 16, 0);
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 110;
    if (@available(iOS 16.0, *)) self.tableView.selfSizingInvalidation = UITableViewSelfSizingInvalidationDisabled;
    [self.tableView registerClass:[TLWAIAssistantMessageCell class] forCellReuseIdentifier:[TLWAIAssistantMessageCell reuseIdentifier]];
    [self.tableView registerClass:[TLWAIAssistantSystemMessageCell class] forCellReuseIdentifier:[TLWAIAssistantSystemMessageCell reuseIdentifier]];
    [self addSubview:self.tableView];
    self.jumpToBottomButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.jumpToBottomButton setImage:[UIImage systemImageNamed:@"arrow.down" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:18 weight:UIImageSymbolWeightSemibold]] forState:UIControlStateNormal];
    self.jumpToBottomButton.backgroundColor = UIColor.secondarySystemBackgroundColor;
    self.jumpToBottomButton.tintColor = UIColor.labelColor;
    self.jumpToBottomButton.layer.cornerRadius = 22;
    self.jumpToBottomButton.layer.borderWidth = 0.5;
    self.jumpToBottomButton.layer.borderColor = UIColor.separatorColor.CGColor;
    self.jumpToBottomButton.accessibilityIdentifier = @"ai.scrollToBottom";
    self.jumpToBottomButton.accessibilityLabel = @"滚动到最新消息";
    self.jumpToBottomButton.accessibilityHint = @"返回底部并跟随新回复";
    self.jumpToBottomButton.hidden = YES;
    [self.jumpToBottomButton addTarget:self action:@selector(tl_jumpToBottom) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.jumpToBottomButton];
    [self.jumpToBottomButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self);
        make.bottom.equalTo(self).offset(-12);
        make.width.height.mas_equalTo(44);
    }];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.equalTo(self);
        make.left.equalTo(self).offset(kHorizontalInset);
        make.right.equalTo(self).offset(-kHorizontalInset);
    }];


    self.emptyStateView = [[UIView alloc] init];
    self.emptyStateView.backgroundColor = [UIColor clearColor];
    self.emptyStateView.userInteractionEnabled = NO;
    [self addSubview:self.emptyStateView];
    [self.emptyStateView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.tableView);
    }];

    self.emptyStateLabel = [[UILabel alloc] init];
    self.emptyStateLabel.text = @"从文字、图片或语音开始提问";
    self.emptyStateLabel.textColor = [UIColor colorWithWhite:0.32 alpha:0.9];
    self.emptyStateLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    self.emptyStateLabel.textAlignment = NSTextAlignmentCenter;
    self.emptyStateLabel.numberOfLines = 0;
    [self.emptyStateView addSubview:self.emptyStateLabel];
    [self.emptyStateLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.emptyStateView);
        make.left.greaterThanOrEqualTo(self.emptyStateView).offset(32);
        make.right.lessThanOrEqualTo(self.emptyStateView).offset(-32);
    }];
    self.emptyStateView.hidden = NO;
}

- (void)tl_jumpToBottom {
    self.forceButtonJump = YES;
    self.userInteracting = NO;
    [self scrollToBottomAnimated:NO];
}

- (void)tl_updateJumpButton {
    BOOL settling = self.pendingExplicitBottom || self.animatingToBottom;
    self.jumpToBottomButton.hidden = self.messages.count == 0 || (!settling && [self tl_isNearBottom]);
}

#pragma mark - UIScrollViewDelegate

- (BOOL)interactionActive {
    if (self.userInteracting || self.tableView.isTracking || self.tableView.isDragging || self.tableView.isDecelerating) return YES;
    for (UITableViewCell *cell in self.tableView.visibleCells) {
        if ([cell isKindOfClass:TLWAIAssistantMessageCell.class] && ((TLWAIAssistantMessageCell *)cell).interactionActive) return YES;
    }
    return NO;
}



- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if (scrollView != self.tableView) return;
    self.userInteracting = YES;
    self.forceButtonJump = NO;
    self.hasReadingSnapshot = NO;
    self.readingAnchorIdentifier = nil;
    self.followsBottom = NO;
    self.pendingExplicitBottom = NO;
    self.animatingToBottom = NO;
    self.bottomCorrectionGeneration += 1;
    self.bottomCorrectionScheduled = NO;
    self.bottomCorrectionPasses = 0;
    self.dragBeganY = scrollView.contentOffset.y;
    self.dragVelocityY = 0;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView != self.tableView) return;
    [self tl_updateJumpButton];
    if (self.programmatic) return;
    if (self.gestureCoordinator.applyingOffsets) return;
    [self.gestureCoordinator correctRelayOffsets];
    if (self.userInteracting) self.followsBottom = NO;
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    if (scrollView == self.tableView) self.dragVelocityY = velocity.y;
    if (scrollView == self.tableView) [self.gestureCoordinator constrainOuterTarget:targetContentOffset velocity:velocity];
}

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView {
    self.followsBottom = NO;
    self.pendingExplicitBottom = NO;
    return YES;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (scrollView != self.tableView) return;
    if (!decelerate) self.userInteracting = NO;
    if (!decelerate) [self tl_userInteractionEnded];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (scrollView != self.tableView) return;
    self.userInteracting = NO;
    [self tl_userInteractionEnded];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    if (scrollView != self.tableView || !self.animatingToBottom) return;
    self.animatingToBottom = NO;
    if (self.followsBottom && self.pendingExplicitBottom) [self tl_correctMeasuredBottom];
    else if (self.followsBottom) [self followBottomIfNeededAnimated:NO];
    else [self tl_updateJumpButton];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.messages.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TLWAIAssistantMessage *message = self.messages[indexPath.row];
    if (message.role == TLWAIAssistantMessageRoleSystem) {
        // 系统消息和普通对话消息走不同 cell，避免一种 cell 背太多分支逻辑。
        TLWAIAssistantSystemMessageCell *cell = [tableView dequeueReusableCellWithIdentifier:[TLWAIAssistantSystemMessageCell reuseIdentifier]
                                                                                forIndexPath:indexPath];
        [cell configureWithMessage:message];
        return cell;
    }

    TLWAIAssistantMessageCell *cell = [tableView dequeueReusableCellWithIdentifier:[TLWAIAssistantMessageCell reuseIdentifier]
                                                                      forIndexPath:indexPath];
    [cell configureWithMessage:message];
    [cell registerGestureCoordinator:self.gestureCoordinator outerTable:tableView];
    __weak typeof(self) weakSelf = self;
    cell.onInteractionChanged = ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf tl_applyDeferredUpdates];
            [weakSelf tl_commitHeightsIfPossible];
            if (weakSelf.pendingExplicitBottom) [weakSelf tl_scrollToBottomAnimated:YES];
        });
    };
    cell.onContinue = ^(TLWAIAssistantMessage *item) {
        if (weakSelf.onContinueMessage) weakSelf.onContinueMessage(item);
    };
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row >= self.messages.count) return;
    NSString *identifier = self.messages[indexPath.row].identifier;
    if (![self.offscreenUpdates containsObject:identifier]) return;
    [self.offscreenUpdates removeObject:identifier];
    // UIKit 可保留离屏预取 Cell，重新出现时不保证再次调用 cellForRow。
    if ([cell isKindOfClass:TLWAIAssistantMessageCell.class]) [(TLWAIAssistantMessageCell *)cell configureWithMessage:self.messages[indexPath.row]];
    __weak typeof(self) weakSelf = self;
    __weak UITableViewCell *weakCell = cell;
    // 显示时已有最新模型；布局结束后核对一次，离屏期间不反复创建测量气泡。
    dispatch_async(dispatch_get_main_queue(), ^{
        TLWAIAssistantMessageListView *list = weakSelf;
        UITableViewCell *visibleCell = weakCell;
        if (!list || !visibleCell) return;
        NSIndexPath *current = [list.tableView indexPathForCell:visibleCell];
        if (!current || current.row >= list.messages.count ||
            ![list.messages[current.row].identifier isEqualToString:identifier]) return;
        CGFloat width = CGRectGetWidth(visibleCell.bounds);
        CGSize fitted = [visibleCell systemLayoutSizeFittingSize:CGSizeMake(width, UILayoutFittingCompressedSize.height)
            withHorizontalFittingPriority:UILayoutPriorityRequired verticalFittingPriority:UILayoutPriorityFittingSizeLevel];
        if (width <= 38 || fabs(fitted.height - CGRectGetHeight(visibleCell.bounds)) >= 0.5) [list tl_invalidateRowHeights];
    });
}


- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return [UIView new];
}

@end
