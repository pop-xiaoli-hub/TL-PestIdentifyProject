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
#import <Masonry/Masonry.h>

@interface TLWAIAssistantMessageListView () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIView *emptyStateView;
@property (nonatomic, strong) UILabel *emptyStateLabel;
// 展示层只维护当前要渲染的快照，不持有真正的会话源数据。
@property (nonatomic, copy) NSArray<TLWAIAssistantMessage *> *messages;
@end

@implementation TLWAIAssistantMessageListView

static CGFloat const kHorizontalInset = 12.0;

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _messages = @[];
        [self tl_setupViews];
    }
    return self;
}

- (void)displayMessages:(NSArray<TLWAIAssistantMessage *> *)messages {
    self.messages = messages ?: @[];
    self.emptyStateView.hidden = self.messages.count > 0;
    [self.tableView reloadData];
}

- (void)appendMessage:(TLWAIAssistantMessage *)message {
    if (!message) return;

    // 追加接口保留给流式/局部更新场景，但内部仍然基于当前快照维护 table 数据源。
    NSMutableArray<TLWAIAssistantMessage *> *list = [self.messages mutableCopy] ?: [NSMutableArray array];
    [list addObject:message];
    self.messages = list.copy;
    self.emptyStateView.hidden = self.messages.count > 0;

    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.messages.count - 1 inSection:0];
    [self.tableView beginUpdates];
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    [self.tableView endUpdates];
}

- (void)scrollToBottomAnimated:(BOOL)animated {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.messages.count == 0) return;
        // 等待本轮 layout 完成后再滚动，避免刚插入 cell 时 contentSize 还没更新。
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.messages.count - 1 inSection:0];
        [self.tableView layoutIfNeeded];
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:animated];
    });
}

#pragma mark - Private

- (void)tl_setupViews {
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.showsVerticalScrollIndicator = NO;
    self.tableView.alwaysBounceVertical = YES;
    self.tableView.contentInset = UIEdgeInsetsMake(16, 0, 16, 0);
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 110;
    [self.tableView registerClass:[TLWAIAssistantMessageCell class] forCellReuseIdentifier:[TLWAIAssistantMessageCell reuseIdentifier]];
    [self.tableView registerClass:[TLWAIAssistantSystemMessageCell class] forCellReuseIdentifier:[TLWAIAssistantSystemMessageCell reuseIdentifier]];
    [self addSubview:self.tableView];
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
    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return [UIView new];
}

@end
