//
//  TLWSettingView.m
//  TL-PestIdentify
//

#import "TLWSettingView.h"
#import <Masonry/Masonry.h>

@interface TLWSettingView ()

@property (nonatomic, strong, readwrite) UISwitch *notificationSwitch;
@property (nonatomic, strong, readwrite) UIButton *aboutRowButton;
@property (nonatomic, strong, readwrite) UIButton *feedbackRowButton;
@property (nonatomic, strong, readwrite) UIButton *permissionRowButton;
@property (nonatomic, strong, readwrite) UIButton *agreementRowButton;
@property (nonatomic, strong, readwrite) UIButton *privacyRowButton;
@property (nonatomic, strong, readwrite) UIButton *logoutButton;

@end

@implementation TLWSettingView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) [self setupUI];
    return self;
}

- (void)setupUI {
    self.layer.contents = (__bridge id)[UIImage imageNamed:@"hp_backView"].CGImage;

    UIWindow *window = [UIApplication sharedApplication].windows.firstObject;
    CGFloat safeTop = window.safeAreaInsets.top;
    CGFloat navTop  = safeTop + 12;

    CGFloat cardTop = navTop + 44 + 12;
    [self setupCardAtTop:cardTop];
}

#pragma mark - Card

- (void)setupCardAtTop:(CGFloat)cardTop {
    UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    UIVisualEffectView *card = [[UIVisualEffectView alloc] initWithEffect:blur];
    card.layer.cornerRadius  = 20;
    card.layer.masksToBounds = YES;

    UIView *overlay = [UIView new];
    overlay.backgroundColor = [UIColor colorWithRed:0.88 green:0.94 blue:0.97 alpha:0.6];
    [card.contentView addSubview:overlay];
    [overlay mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(card.contentView);
    }];

    [self addSubview:card];
    [card mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(cardTop);
        make.left.mas_equalTo(16);
        make.right.mas_equalTo(-16);
        make.bottom.equalTo(self).priorityMedium();
    }];

    [self setupRowsInCard:card.contentView];
}

- (void)setupRowsInCard:(UIView *)container {
    // 第一行：系统消息通知 + UISwitch
    UIView *notifRow = [self buildSwitchRowWithTitle:@"系统消息通知"];
    [container addSubview:notifRow];
    [notifRow mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(16);
        make.left.mas_equalTo(16);
        make.right.mas_equalTo(-16);
        make.height.mas_equalTo(60);
    }];

    // 其余行
    NSArray *titles = @[@"关于我们", @"我要反馈", @"系统权限", @"用户协议", @"隐私政策"];
    NSMutableArray *rowButtons = [NSMutableArray array];
    UIView *prevRow = notifRow;

    for (NSString *title in titles) {
        UIButton *row = [self buildChevronRowWithTitle:title];
        [container addSubview:row];
        [row mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(prevRow.mas_bottom).offset(8);
            make.left.mas_equalTo(16);
            make.right.mas_equalTo(-16);
            make.height.mas_equalTo(60);
        }];
        [rowButtons addObject:row];
        prevRow = row;
    }

    _aboutRowButton      = rowButtons[0];
    _feedbackRowButton   = rowButtons[1];
    _permissionRowButton = rowButtons[2];
    _agreementRowButton  = rowButtons[3];
    _privacyRowButton    = rowButtons[4];

    // 退出登录按钮
    _logoutButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _logoutButton.layer.cornerRadius = 14;
    _logoutButton.clipsToBounds = YES;

    UIImage *commitBg = [[UIImage imageNamed:@"commitRectangle"]
                         resizableImageWithCapInsets:UIEdgeInsetsMake(0, 40, 0, 40)
                         resizingMode:UIImageResizingModeStretch];
    [_logoutButton setBackgroundImage:commitBg forState:UIControlStateNormal];

    UILabel *logoutLabel = [UILabel new];
    logoutLabel.text                = @"退出登录";
    logoutLabel.textColor           = UIColor.whiteColor;
    logoutLabel.font                = [UIFont systemFontOfSize:18 weight:UIFontWeightSemibold];
    logoutLabel.userInteractionEnabled = NO;
    [_logoutButton addSubview:logoutLabel];
    [logoutLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(_logoutButton);
        make.centerY.equalTo(_logoutButton).offset(-4);
    }];

    [container addSubview:_logoutButton];
    [_logoutButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(prevRow.mas_bottom).offset(20);
        make.centerX.equalTo(container);
        make.width.mas_equalTo(348);
        make.height.mas_equalTo(65);
    }];
}

#pragma mark - Row Builders

- (UIView *)buildSwitchRowWithTitle:(NSString *)title {
    UIView *row = [UIView new];
    row.backgroundColor = UIColor.whiteColor;
    row.layer.cornerRadius = 14;
    row.layer.masksToBounds = YES;

    UILabel *label = [UILabel new];
    label.text      = title;
    label.font      = [UIFont systemFontOfSize:16];
    label.textColor = [UIColor colorWithRed:0.20 green:0.20 blue:0.20 alpha:1.0];
    [row addSubview:label];
    [label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(16);
        make.centerY.equalTo(row);
    }];

    _notificationSwitch = [[UISwitch alloc] init];
    _notificationSwitch.onTintColor = [UIColor colorWithRed:0.98 green:0.68 blue:0.20 alpha:1.0];
    _notificationSwitch.on = YES;
    [row addSubview:_notificationSwitch];
    [_notificationSwitch mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(-16);
        make.centerY.equalTo(row);
    }];

    return row;
}

- (UIButton *)buildChevronRowWithTitle:(NSString *)title {
    UIButton *row = [UIButton buttonWithType:UIButtonTypeCustom];
    row.backgroundColor = UIColor.whiteColor;
    row.layer.cornerRadius = 14;
    row.layer.masksToBounds = YES;

    UILabel *label = [UILabel new];
    label.text      = title;
    label.font      = [UIFont systemFontOfSize:16];
    label.textColor = [UIColor colorWithRed:0.20 green:0.20 blue:0.20 alpha:1.0];
    label.userInteractionEnabled = NO;
    [row addSubview:label];
    [label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(16);
        make.centerY.equalTo(row);
    }];

    UIImageView *chevron = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"chevron.right"]];
    chevron.tintColor = [UIColor colorWithWhite:0.6 alpha:1.0];
    chevron.userInteractionEnabled = NO;
    [row addSubview:chevron];
    [chevron mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(-16);
        make.centerY.equalTo(row);
        make.width.mas_equalTo(8);
        make.height.mas_equalTo(14);
    }];

    return row;
}

@end
