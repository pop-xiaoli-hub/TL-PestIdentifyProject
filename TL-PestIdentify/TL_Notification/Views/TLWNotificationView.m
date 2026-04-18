//
//  TLWNotificationView.m
//  TL-PestIdentify
//

#import "TLWNotificationView.h"
#import <Masonry/Masonry.h>

static CGFloat const kTLNotifNavOffset  = 8.0;
static CGFloat const kTLNotifNavHeight  = 48.0;

@interface TLWNotificationView ()

@property (nonatomic, strong, readwrite) UITableView         *tableView;
@property (nonatomic, strong, readwrite) NSArray<UIButton *> *tabButtons;
@property (nonatomic, assign) BOOL elderModeEnabled;

@end

@implementation TLWNotificationView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        UIWindow *window = [UIApplication sharedApplication].windows.firstObject;
        CGFloat safeTop  = window.safeAreaInsets.top;
        CGFloat navTop   = safeTop + kTLNotifNavOffset;
        CGFloat cardTop  = navTop  + kTLNotifNavHeight + 8.0;

        [self tl_setupBackground];
        [self tl_setupCardWithTop:cardTop];
    }
    return self;
}

#pragma mark - Background

- (void)tl_setupBackground {
    UIImage *bg = [UIImage imageNamed:@"hp_backView"];
    self.layer.contents = (__bridge id)bg.CGImage;
}

#pragma mark - Content Card

- (void)tl_setupCardWithTop:(CGFloat)cardTop {
    // Frosted glass card
    UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    UIVisualEffectView *blurCard = [[UIVisualEffectView alloc] initWithEffect:blur];
    blurCard.layer.cornerRadius  = 30;
    blurCard.layer.masksToBounds = YES;
    [self addSubview:blurCard];
    [blurCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(cardTop);
        make.left.equalTo(self).offset(8);
        make.right.equalTo(self).offset(-8);
        make.bottom.equalTo(self.mas_safeAreaLayoutGuideBottom);
    }];

    // White overlay for frosted tint
    UIView *whiteOverlay = [[UIView alloc] init];
    whiteOverlay.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.75];
    whiteOverlay.userInteractionEnabled = NO;
    [blurCard.contentView addSubview:whiteOverlay];
    [whiteOverlay mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(blurCard.contentView);
    }];

    // ── Tab filter row ──────────────────────────────────────────────
    UIScrollView *tabScroll = [[UIScrollView alloc] init];
    tabScroll.showsHorizontalScrollIndicator = NO;
    tabScroll.showsVerticalScrollIndicator   = NO;
    [blurCard.contentView addSubview:tabScroll];
    [tabScroll mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(blurCard.contentView).offset(17);
        make.left.equalTo(blurCard.contentView).offset(16);
        make.right.equalTo(blurCard.contentView);
        make.height.mas_equalTo(37);
    }];

    NSArray<NSString *> *titles = @[@"全部", @"系统通知", @"病害消息", @"用户调研"];
    CGFloat tabWidths[] = {74.0, 107.0, 107.0, 107.0};
    CGFloat tabGap      = 13.0;
    CGFloat tabX        = 0;
    NSMutableArray<UIButton *> *btns = [NSMutableArray array];

    UIColor *activeColor   = [UIColor colorWithRed:0.016 green:0.678 blue:0.780 alpha:1]; // #04ADC7
    UIColor *inactiveColor = [UIColor colorWithRed:0.38  green:0.38  blue:0.38  alpha:1]; // #616161

    for (NSInteger i = 0; i < 4; i++) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.tag = i;
        [btn setTitle:titles[i] forState:UIControlStateNormal];
        btn.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
        [btn setTitleColor:(i == 0 ? activeColor : inactiveColor) forState:UIControlStateNormal];
        btn.backgroundColor           = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.80];
        btn.layer.cornerRadius        = 18.5;
        btn.layer.shadowColor         = [UIColor colorWithRed:0 green:0.40 blue:0.37 alpha:1].CGColor;
        btn.layer.shadowOffset        = CGSizeMake(0, 11);
        btn.layer.shadowRadius        = 6.75;
        btn.layer.shadowOpacity       = 0.10;
        btn.frame = CGRectMake(tabX, 0, tabWidths[i], 37);
        [tabScroll addSubview:btn];
        [btns addObject:btn];
        tabX += tabWidths[i] + tabGap;
    }
    tabScroll.contentSize = CGSizeMake(tabX - tabGap + 16, 37); // +16 right padding
    _tabButtons = [btns copy];
    [self configureElderModeEnabled:NO];

    // ── Notification table view ─────────────────────────────────────
    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    _tableView.backgroundColor  = [UIColor clearColor];
    _tableView.separatorStyle   = UITableViewCellSeparatorStyleNone;
    _tableView.rowHeight        = UITableViewAutomaticDimension;
    _tableView.estimatedRowHeight = 161; // 141 card + 20 gap
    _tableView.contentInset     = UIEdgeInsetsMake(0, 0, 16, 0);
    [blurCard.contentView addSubview:_tableView];
    [_tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(tabScroll.mas_bottom).offset(20);
        make.left.right.bottom.equalTo(blurCard.contentView);
    }];
}

- (void)configureElderModeEnabled:(BOOL)enabled {
    self.elderModeEnabled = enabled;
    UIFont *tabFont = [UIFont systemFontOfSize:(enabled ? 19.0 : 16.0) weight:UIFontWeightSemibold];
    for (UIButton *button in self.tabButtons) {
        button.titleLabel.font = tabFont;
    }
}

@end
