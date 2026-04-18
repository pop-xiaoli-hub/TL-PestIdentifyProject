//
//  TLWNotificationCell.m
//  TL-PestIdentify
//

#import "TLWNotificationCell.h"
#import <Masonry/Masonry.h>

@interface TLWNotificationCell ()

// Outer shadow holder (no masksToBounds so shadow shows)
@property (nonatomic, strong) UIView      *shadowView;
// Inner card clips content
@property (nonatomic, strong) UIView      *cardView;
@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UILabel     *titleLabel;
@property (nonatomic, strong) UIView      *redDot;
@property (nonatomic, strong) UILabel     *bodyLabel;
@property (nonatomic, strong) UIButton    *detailButton;
@property (nonatomic, assign) BOOL elderModeEnabled;

@end

@implementation TLWNotificationCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor clearColor];
        [self tl_setupUI];
    }
    return self;
}

- (void)tl_setupUI {
    // Shadow container — no masksToBounds so shadow is visible
    _shadowView = [[UIView alloc] init];
    _shadowView.backgroundColor = [UIColor clearColor];
    _shadowView.layer.shadowColor = [UIColor colorWithRed:0 green:0.40 blue:0.37 alpha:1].CGColor;
    _shadowView.layer.shadowOffset = CGSizeMake(0, 11);
    _shadowView.layer.shadowRadius = 13.5;
    _shadowView.layer.shadowOpacity = 0.10;
    [self.contentView addSubview:_shadowView];
    // top=0 so first cell sits flush under tab bar gap; bottom=-20 adds 20pt inter-card gap
    [_shadowView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView);
        make.left.equalTo(self.contentView).offset(16);
        make.right.equalTo(self.contentView).offset(-16);
        make.bottom.equalTo(self.contentView).offset(-20);
    }];

    // Card view — clips inner content to rounded corners
    _cardView = [[UIView alloc] init];
    _cardView.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.80];
    _cardView.layer.cornerRadius = 20;
    _cardView.layer.masksToBounds = YES;
    [_shadowView addSubview:_cardView];
    [_cardView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(_shadowView);
    }];

    // Orange alert icon
    _iconView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"iconWarning"]];
    _iconView.contentMode = UIViewContentModeScaleAspectFit;
    [_cardView addSubview:_iconView];
    [_iconView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_cardView).offset(22);
        make.top.equalTo(_cardView).offset(21);
        make.width.height.mas_equalTo(30);
    }];

    // Title label
    _titleLabel = [[UILabel alloc] init];
    _titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightSemibold];
    _titleLabel.textColor = [UIColor colorWithRed:0.125 green:0.125 blue:0.125 alpha:1];
    [_cardView addSubview:_titleLabel];
    [_titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_iconView.mas_right).offset(12);
        make.centerY.equalTo(_iconView);
        make.right.lessThanOrEqualTo(_cardView).offset(-40);
    }];

    // Red unread dot
    _redDot = [[UIView alloc] init];
    _redDot.backgroundColor = [UIColor colorWithRed:0.95 green:0.22 blue:0.22 alpha:1];
    _redDot.layer.cornerRadius = 6;
    [_cardView addSubview:_redDot];
    [_redDot mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(12);
        make.top.equalTo(_cardView).offset(12);
        make.right.equalTo(_cardView).offset(-12);
    }];

    // Body label — numberOfLines toggled in configure
    _bodyLabel = [[UILabel alloc] init];
    _bodyLabel.font = [UIFont systemFontOfSize:14];
    _bodyLabel.textColor = [UIColor blackColor];
    _bodyLabel.numberOfLines = 2;
    _bodyLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    [_cardView addSubview:_bodyLabel];
    [_bodyLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_cardView).offset(22);
        make.right.equalTo(_cardView).offset(-22);
        make.top.equalTo(_cardView).offset(55);
    }];

    // "查看详细 >" / "收起详细 ↑" toggle button
    // Pinned to bodyLabel.bottom and card.bottom → drives card height
    _detailButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_detailButton setTitleColor:[UIColor colorWithWhite:0 alpha:0.48] forState:UIControlStateNormal];
    _detailButton.titleLabel.font = [UIFont systemFontOfSize:13.5 weight:UIFontWeightMedium];
    _detailButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    [_detailButton addTarget:self action:@selector(tl_detailTapped) forControlEvents:UIControlEventTouchUpInside];
    [_cardView addSubview:_detailButton];
    [_detailButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(_cardView).offset(-16);
        make.top.equalTo(_bodyLabel.mas_bottom).offset(8);
        make.bottom.equalTo(_cardView).offset(-14);
        make.height.mas_equalTo(20);
    }];

    [self configureElderModeEnabled:NO];
}

- (void)configureElderModeEnabled:(BOOL)enabled {
    self.elderModeEnabled = enabled;
    self.titleLabel.font = [UIFont systemFontOfSize:(enabled ? 21.0 : 18.0) weight:UIFontWeightSemibold];
    self.bodyLabel.font = [UIFont systemFontOfSize:(enabled ? 17.0 : 14.0)];
    self.detailButton.titleLabel.font = [UIFont systemFontOfSize:(enabled ? 16.5 : 13.5) weight:UIFontWeightMedium];
}

- (void)configureWithItem:(TLWNotificationItem *)item {
    _titleLabel.text = item.title;
    _redDot.hidden   = !item.hasUnread;

    NSMutableParagraphStyle *ps = [[NSMutableParagraphStyle alloc] init];
    ps.lineSpacing = 5; // brings effective line height to ~22pt at 14pt font
    CGFloat bodyFontSize = self.elderModeEnabled ? 17.0 : 14.0;
    NSDictionary *attrs = @{
        NSFontAttributeName:            [UIFont systemFontOfSize:bodyFontSize],
        NSParagraphStyleAttributeName:  ps,
        NSForegroundColorAttributeName: [UIColor blackColor],
    };
    _bodyLabel.attributedText = [[NSAttributedString alloc] initWithString:item.bodyText attributes:attrs];
    _bodyLabel.numberOfLines  = item.isExpanded ? 0 : 2;

    NSString *btnTitle = item.isExpanded ? @"收起详细 ↑" : @"查看详细 >";
    [_detailButton setTitle:btnTitle forState:UIControlStateNormal];
}

- (void)tl_detailTapped {
    if (_delegate) {
        [_delegate notificationCellDidToggleExpand:self];
    }
}

@end
