//
//  TLWMessageView.m
//  TL-PestIdentify
//
//  Created by Tommy-MrWu on 2026/3/15.
//  职责：实现消息页面主视图组件。
//
#import "TLWMessageView.h"
#import <Masonry/Masonry.h>

@interface TLWMessageView ()

@property (nonatomic, strong, readwrite) UITableView *tableView;

@end

@implementation TLWMessageView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.layer.contents = (__bridge id)[UIImage imageNamed:@"hp_backView"].CGImage;

    // Nav title row
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = @"消息";
    titleLabel.font = [UIFont systemFontOfSize:20 weight:UIFontWeightSemibold];
    titleLabel.textColor = [UIColor whiteColor];
    [self addSubview:titleLabel];

    UIImageView *titleIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"iconMessage"]];
    titleIcon.contentMode = UIViewContentModeScaleAspectFit;
    [self addSubview:titleIcon];

    [titleIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(22);
        make.centerY.equalTo(titleLabel);
        make.left.equalTo(titleLabel.mas_right).offset(6);
    }];

    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.mas_safeAreaLayoutGuideTop).offset(12);
        make.centerX.equalTo(self).offset(-14);
    }];

    // Card container
    UIView *card = [[UIView alloc] init];
    card.backgroundColor = [UIColor colorWithRed:0.96 green:0.98 blue:0.97 alpha:0.92];
    card.layer.cornerRadius = 18;
    card.layer.masksToBounds = YES;
    [self addSubview:card];

    [card mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(titleLabel.mas_bottom).offset(16);
        make.left.equalTo(self).offset(12);
        make.right.equalTo(self).offset(-12);
        make.bottom.equalTo(self.mas_safeAreaLayoutGuideBottom).offset(-12);
    }];

    // TableView inside card
    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    _tableView.backgroundColor = [UIColor clearColor];
    _tableView.separatorColor = [UIColor colorWithWhite:0.88 alpha:1];
    _tableView.separatorInset = UIEdgeInsetsMake(0, 78, 0, 0);
    _tableView.rowHeight = 72;
    _tableView.scrollEnabled = NO;
    _tableView.tableFooterView = [[UIView alloc] init];
    [card addSubview:_tableView];

    [_tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(card);
    }];
}

@end
