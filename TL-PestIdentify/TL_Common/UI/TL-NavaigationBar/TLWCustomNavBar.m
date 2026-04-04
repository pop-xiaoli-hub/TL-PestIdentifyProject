//
//  TLWCustomNavBar.m
//  TL-PestIdentify
//
//  Created by Northern Lights on 2026/4/4.
//  职责：实现组件化顶部导航栏视图。
//
#import "TLWCustomNavBar.h"
#import <Masonry/Masonry.h>

static CGFloat const kBackSize = 44.0;
static CGFloat const kSidePad = 16.0;
static CGFloat const kTopOffset = 8.0;
static CGFloat const kTitleIconSize = 24.0;
static CGFloat const kTitleIconGap = 6.0;
static CGFloat const kRightButtonIconGap = 4.0;

@interface TLWCustomNavBar ()
@property (nonatomic, strong, readwrite) UIButton    *backButton;
@property (nonatomic, strong, readwrite) UILabel     *titleLabel;
@property (nonatomic, strong, readwrite) UIImageView *titleIcon;
@property (nonatomic, strong, readwrite) UIButton    *rightButton;
@property (nonatomic, strong) UIView *titleContainer;
@property (nonatomic, assign) BOOL didSetup;
@end

@implementation TLWCustomNavBar

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithTitle:(NSString *)title {
    return [self initWithTitle:title iconName:nil];
}

- (instancetype)initWithTitle:(NSString *)title iconName:(nullable NSString *)iconName {
    self = [self initWithFrame:CGRectZero];
    if (self) {
        [self applyTitle:title iconName:iconName];
    }
    return self;
}

#pragma mark - Setup

- (void)commonInit {
    if (self.didSetup) {
        return;
    }
    self.didSetup = YES;

    self.backgroundColor = UIColor.clearColor;
    [self setupBackButton];
    [self setupTitleWithText:@"" iconName:nil];
    [self setupRightButton];
}

- (void)setupBackButton {
    _backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_backButton setImage:[UIImage imageNamed:@"iconBack"] forState:UIControlStateNormal];
    _backButton.accessibilityLabel = @"返回";
    _backButton.accessibilityHint = @"返回上一页";
    _backButton.accessibilityIdentifier = @"tl_nav_back_button";
    [self addSubview:_backButton];
    [_backButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self).offset(kSidePad);
        make.top.equalTo(self.mas_safeAreaLayoutGuideTop).offset(kTopOffset);
        make.width.height.mas_equalTo(kBackSize);
        make.bottom.equalTo(self);
    }];
}

- (void)setupTitleWithText:(NSString *)title iconName:(nullable NSString *)iconName {
    // 标题容器（用于居中标题+图标的整体）
    _titleContainer = [UIView new];
    [self addSubview:_titleContainer];
    [_titleContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self);
        make.centerY.equalTo(_backButton);
    }];

    _titleIcon = [UIImageView new];
    _titleIcon.contentMode = UIViewContentModeScaleAspectFit;
    [_titleContainer addSubview:_titleIcon];
    [_titleIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_titleContainer);
        make.centerY.equalTo(_titleContainer);
        make.width.height.mas_equalTo(0);
    }];

    _titleLabel = [UILabel new];
    _titleLabel.text      = title;
    _titleLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.96];
    _titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    _titleLabel.adjustsFontForContentSizeCategory = YES;
    _titleLabel.accessibilityTraits = UIAccessibilityTraitHeader;
    [_titleContainer addSubview:_titleLabel];
    [_titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_titleIcon.mas_right).offset(0);
        make.right.equalTo(_titleContainer);
        make.top.bottom.equalTo(_titleContainer);
    }];

    [self applyTitle:title iconName:iconName];
}

- (void)setupRightButton {
    _rightButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _rightButton.hidden = YES;
    _rightButton.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    _rightButton.titleLabel.adjustsFontForContentSizeCategory = YES;
    [_rightButton setTitleColor:[UIColor colorWithWhite:1.0 alpha:0.90] forState:UIControlStateNormal];
    _rightButton.accessibilityIdentifier = @"tl_nav_right_button";
    [self addSubview:_rightButton];
    [_rightButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self).offset(-kSidePad);
        make.centerY.equalTo(_backButton);
        make.height.mas_equalTo(kBackSize);
    }];
}

#pragma mark - Public

- (void)setRightButtonTitle:(NSString *)title iconName:(nullable NSString *)iconName {
    BOOL hasTitle = title.length > 0;
    _rightButton.hidden = !hasTitle;
    [_rightButton setTitle:title ?: @"" forState:UIControlStateNormal];
    _rightButton.accessibilityLabel = hasTitle ? title : nil;
    if (iconName.length > 0) {
        UIImage *icon = [[UIImage imageNamed:iconName] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [_rightButton setImage:icon forState:UIControlStateNormal];
        _rightButton.tintColor = [UIColor colorWithWhite:1.0 alpha:0.90];
        _rightButton.semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;
        _rightButton.imageEdgeInsets = UIEdgeInsetsMake(0, kRightButtonIconGap, 0, -kRightButtonIconGap);
        _rightButton.titleEdgeInsets = UIEdgeInsetsMake(0, -kRightButtonIconGap, 0, kRightButtonIconGap);
    } else {
        [_rightButton setImage:nil forState:UIControlStateNormal];
        _rightButton.semanticContentAttribute = UISemanticContentAttributeUnspecified;
        _rightButton.imageEdgeInsets = UIEdgeInsetsZero;
        _rightButton.titleEdgeInsets = UIEdgeInsetsZero;
    }
}

- (CGFloat)barHeight {
    [self layoutIfNeeded];
    CGFloat measuredHeight = CGRectGetMaxY(self.backButton.frame);
    if (measuredHeight > 0) {
        return measuredHeight;
    }
    CGFloat safeTop = self.window ? self.window.safeAreaInsets.top : self.safeAreaInsets.top;
    return safeTop + kTopOffset + kBackSize;
}

#pragma mark - Private

- (void)applyTitle:(NSString *)title iconName:(nullable NSString *)iconName {
    self.titleLabel.text = title ?: @"";
    self.titleLabel.accessibilityLabel = self.titleLabel.text;

    BOOL hasIcon = iconName.length > 0;
    self.titleIcon.hidden = !hasIcon;
    self.titleIcon.image = hasIcon ? [UIImage imageNamed:iconName] : nil;

    [self.titleIcon mas_updateConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(hasIcon ? kTitleIconSize : 0);
    }];
    [self.titleLabel mas_updateConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.titleIcon.mas_right).offset(hasIcon ? kTitleIconGap : 0);
    }];
}

@end
