//
//  TLWAICallController.m
//  TL-PestIdentify
//
//  AI电话页面控制器：蓝绿渐变背景 + AI助手图标 + 语音提示 + 结束通话按钮
//

#import "TLWAICallController.h"
#import <Masonry/Masonry.h>

@interface TLWAICallController ()
@property (nonatomic, strong) CAGradientLayer *gradientLayer;
@property (nonatomic, strong) UIButton *backButton;
@property (nonatomic, strong) UILabel *navTitleLabel;
@property (nonatomic, strong) UIView *aiIconContainer;
@property (nonatomic, strong) UIImageView *aiIconImageView;
@property (nonatomic, strong) UILabel *hintLabel;
@property (nonatomic, strong) UIButton *hangUpButton;
@property (nonatomic, strong) UILabel *hangUpLabel;
@end

@implementation TLWAICallController

- (instancetype)init {
    self = [super init];
    if (self) {
        self.hideNavBar = YES;
        self.hidesBottomBarWhenPushed = YES;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self tl_setupGradientBackground];
    [self tl_setupNavBar];
    [self tl_setupAIIcon];
    [self tl_setupHintLabel];
    [self tl_setupHangUpButton];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.gradientLayer.frame = self.view.bounds;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    self.navigationController.interactivePopGestureRecognizer.delegate = nil;
}

#pragma mark - UI Setup

- (void)tl_setupGradientBackground {
    self.gradientLayer = [CAGradientLayer layer];
    self.gradientLayer.colors = @[
        (__bridge id)[UIColor colorWithRed:0.0 green:0.59 blue:0.68 alpha:1.0].CGColor,  // #0097AE
        (__bridge id)[UIColor colorWithRed:0.0 green:0.76 blue:0.72 alpha:1.0].CGColor,   // #00C2B8
        (__bridge id)[UIColor colorWithRed:0.0 green:0.83 blue:0.67 alpha:1.0].CGColor,   // #00D4AA
    ];
    self.gradientLayer.startPoint = CGPointMake(0, 0);
    self.gradientLayer.endPoint = CGPointMake(1, 1);
    self.gradientLayer.frame = self.view.bounds;
    [self.view.layer insertSublayer:self.gradientLayer atIndex:0];
}

- (void)tl_setupNavBar {
    // 返回按钮
    _backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *backImage = [UIImage imageNamed:@"iconNavBack"];
    [_backButton setImage:[backImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    _backButton.tintColor = [UIColor whiteColor];
    _backButton.contentMode = UIViewContentModeScaleAspectFit;
    [_backButton addTarget:self action:@selector(tl_back) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_backButton];
    [_backButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(8);
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(8);
        make.width.height.mas_equalTo(40);
    }];

    // 标题
    _navTitleLabel = [[UILabel alloc] init];
    _navTitleLabel.text = @"AI电话";
    _navTitleLabel.font = [UIFont systemFontOfSize:20 weight:UIFontWeightSemibold];
    _navTitleLabel.textColor = [UIColor whiteColor];
    _navTitleLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:_navTitleLabel];
    [_navTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.centerY.equalTo(self->_backButton);
    }];
}

- (void)tl_setupAIIcon {
    // 橙色圆形容器
    CGFloat iconContainerSize = 120;
    _aiIconContainer = [[UIView alloc] init];
    _aiIconContainer.backgroundColor = [UIColor colorWithRed:1.0 green:0.66 blue:0.0 alpha:1.0]; // #FFA800
    _aiIconContainer.layer.cornerRadius = iconContainerSize / 2.0;
    _aiIconContainer.layer.masksToBounds = YES;
    [self.view addSubview:_aiIconContainer];
    [_aiIconContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.centerY.equalTo(self.view).multipliedBy(0.65);
        make.width.height.mas_equalTo(iconContainerSize);
    }];

    // AI助手图标
    _aiIconImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"aiAssisstantIcon"]];
    _aiIconImageView.contentMode = UIViewContentModeScaleAspectFit;
    [_aiIconContainer addSubview:_aiIconImageView];
    [_aiIconImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self->_aiIconContainer);
        make.width.height.mas_equalTo(60);
    }];
}

- (void)tl_setupHintLabel {
    _hintLabel = [[UILabel alloc] init];
    _hintLabel.text = @"您可以开始说话...";
    _hintLabel.font = [UIFont systemFontOfSize:20 weight:UIFontWeightSemibold];
    _hintLabel.textColor = [UIColor colorWithRed:0.0 green:0.59 blue:0.68 alpha:1.0]; // #0097AE
    _hintLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:_hintLabel];
    [_hintLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-180);
    }];
}

- (void)tl_setupHangUpButton {
    CGFloat btnSize = 88;

    // 结束通话按钮
    _hangUpButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _hangUpButton.backgroundColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.8];
    _hangUpButton.layer.cornerRadius = btnSize / 2.0;
    _hangUpButton.layer.masksToBounds = YES;
    // 内发光效果
    _hangUpButton.layer.borderWidth = 2.6;
    _hangUpButton.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.9].CGColor;
    [_hangUpButton addTarget:self action:@selector(tl_hangUp) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_hangUpButton];
    [_hangUpButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-80);
        make.width.height.mas_equalTo(btnSize);
    }];

    // 结束图标（红色X）
    UIImageView *stopIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Xicon"]];
    stopIcon.contentMode = UIViewContentModeScaleAspectFit;
    [_hangUpButton addSubview:stopIcon];
    [stopIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self->_hangUpButton);
        make.width.height.mas_equalTo(36);
    }];

    // "结束通话" 文字
    _hangUpLabel = [[UILabel alloc] init];
    _hangUpLabel.text = @"结束通话";
    _hangUpLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
    _hangUpLabel.textColor = [UIColor whiteColor];
    _hangUpLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:_hangUpLabel];
    [_hangUpLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self->_hangUpButton);
        make.top.equalTo(self->_hangUpButton.mas_bottom).offset(12);
    }];
}

#pragma mark - Actions

- (void)tl_back {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)tl_hangUp {
    [self.navigationController popViewControllerAnimated:YES];
}

@end
