//
//  TLWCustomNavBar.m
//  TL-PestIdentify
//

#import "TLWCustomNavBar.h"
#import <Masonry/Masonry.h>

static CGFloat const kBackSize   = 44.0;
static CGFloat const kSidePad    = 16.0;
static CGFloat const kTopOffset  = 8.0;

@interface TLWCustomNavBar ()
@property (nonatomic, strong, readwrite) UIButton    *backButton;
@property (nonatomic, strong, readwrite) UILabel     *titleLabel;
@property (nonatomic, strong, readwrite) UIImageView *titleIcon;
@property (nonatomic, strong, readwrite) UIButton    *rightButton;
@end

@implementation TLWCustomNavBar

- (instancetype)initWithTitle:(NSString *)title {
    return [self initWithTitle:title iconName:nil];
}

- (instancetype)initWithTitle:(NSString *)title iconName:(NSString *)iconName {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        [self setupBackButton];
        [self setupTitleWithText:title iconName:iconName];
        [self setupRightButton];
    }
    return self;
}

#pragma mark - Setup

- (void)setupBackButton {
    _backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_backButton setImage:[UIImage imageNamed:@"iconBack"] forState:UIControlStateNormal];
    [self addSubview:_backButton];
    [_backButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self).offset(kSidePad);
        make.top.equalTo(self.mas_safeAreaLayoutGuideTop).offset(kTopOffset);
        make.width.height.mas_equalTo(kBackSize);
        make.bottom.equalTo(self);
    }];
}

- (void)setupTitleWithText:(NSString *)title iconName:(NSString *)iconName {
    // 标题容器（用于居中标题+图标的整体）
    UIView *titleContainer = [UIView new];
    [self addSubview:titleContainer];
    [titleContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self);
        make.centerY.equalTo(_backButton);
    }];

    _titleIcon = [UIImageView new];
    _titleIcon.contentMode = UIViewContentModeScaleAspectFit;
    [titleContainer addSubview:_titleIcon];

    if (iconName) {
        _titleIcon.image = [UIImage imageNamed:iconName];
        _titleIcon.hidden = NO;
        [_titleIcon mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(titleContainer);
            make.centerY.equalTo(titleContainer);
            make.width.height.mas_equalTo(24);
        }];
    } else {
        _titleIcon.hidden = YES;
        [_titleIcon mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(titleContainer);
            make.centerY.equalTo(titleContainer);
            make.width.height.mas_equalTo(0);
        }];
    }

    _titleLabel = [UILabel new];
    _titleLabel.text      = title;
    _titleLabel.textColor = UIColor.whiteColor;
    _titleLabel.font      = [UIFont systemFontOfSize:20 weight:UIFontWeightSemibold];
    [titleContainer addSubview:_titleLabel];
    [_titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_titleIcon.mas_right).offset(iconName ? 6 : 0);
        make.right.equalTo(titleContainer);
        make.top.bottom.equalTo(titleContainer);
    }];
}

- (void)setupRightButton {
    _rightButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _rightButton.hidden = YES;
    _rightButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    [_rightButton setTitleColor:[UIColor colorWithWhite:1.0 alpha:0.9] forState:UIControlStateNormal];
    [self addSubview:_rightButton];
    [_rightButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self).offset(-kSidePad);
        make.centerY.equalTo(_backButton);
        make.height.mas_equalTo(kBackSize);
    }];
}

#pragma mark - Public

- (void)setRightButtonTitle:(NSString *)title iconName:(NSString *)iconName {
    _rightButton.hidden = NO;
    [_rightButton setTitle:title forState:UIControlStateNormal];
    if (iconName) {
        UIImage *icon = [[UIImage imageNamed:iconName] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [_rightButton setImage:icon forState:UIControlStateNormal];
        _rightButton.tintColor = [UIColor colorWithWhite:1.0 alpha:0.9];
        _rightButton.semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;
        _rightButton.imageEdgeInsets = UIEdgeInsetsMake(0, 4, 0, -4);
        _rightButton.titleEdgeInsets = UIEdgeInsetsMake(0, -4, 0, 4);
    }
}

- (CGFloat)barHeight {
    CGFloat safeTop = UIApplication.sharedApplication.windows.firstObject.safeAreaInsets.top;
    return safeTop + kTopOffset + kBackSize;
}

@end
