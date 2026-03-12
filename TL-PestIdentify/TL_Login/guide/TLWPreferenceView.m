//
//  TLWPreferenceView.m
//  TL-PestIdentify
//

#import "TLWPreferenceView.h"
#import <Masonry/Masonry.h>

@interface TLWPreferenceView ()
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong, readwrite) UICollectionView *collectionView;
@property (nonatomic, strong, readwrite) UIButton *confirmButton;
@end

@implementation TLWPreferenceView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) [self setupView];
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) [self setupView];
    return self;
}

- (void)setupView {
    [self setupBackground];
    [self setupHeader];
    [self setupCollectionView];
    [self setupConfirmButton];
}

- (void)setupBackground {
    UIImageView *bg = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bgGradient"]];
    bg.contentMode = UIViewContentModeScaleAspectFill;
    bg.clipsToBounds = YES;
    [self addSubview:bg];
    [bg mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];

    UIImageView *card = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bgCard"]];
    card.contentMode = UIViewContentModeScaleToFill;
    [self addSubview:card];
    [card mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self);
        make.height.mas_equalTo(792);
    }];
}

- (void)setupHeader {
    _titleLabel = [[UILabel alloc] init];
    _titleLabel.text = @"偏好";
    _titleLabel.font = [UIFont systemFontOfSize:20 weight:UIFontWeightSemibold];
    _titleLabel.textColor = UIColor.whiteColor;
    [self addSubview:_titleLabel];
    [_titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.mas_safeAreaLayoutGuideTop).offset(12);
        make.centerX.equalTo(self).offset(-14);
    }];

    UIImageView *prefIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"iconPrefer"]];
    prefIcon.contentMode = UIViewContentModeScaleAspectFit;
    [self addSubview:prefIcon];
    [prefIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_titleLabel.mas_right).offset(4);
        make.centerY.equalTo(_titleLabel);
        make.width.height.mas_equalTo(22);
    }];

    _subtitleLabel = [[UILabel alloc] init];
    _subtitleLabel.text = @"请选择您关注的农作物";
    _subtitleLabel.font = [UIFont systemFontOfSize:22 weight:UIFontWeightMedium];
    _subtitleLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.8];
    [self addSubview:_subtitleLabel];
    [_subtitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_titleLabel.mas_bottom).offset(18);
        make.left.equalTo(self).offset(22);
    }];
}

- (void)setupCollectionView {
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionVertical;
    layout.minimumInteritemSpacing = 10;
    layout.minimumLineSpacing = 10;
    layout.sectionInset = UIEdgeInsetsMake(8, 22, 20, 22);
    layout.headerReferenceSize = CGSizeMake(0, 36);

    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    _collectionView.backgroundColor = UIColor.clearColor;
    _collectionView.showsVerticalScrollIndicator = NO;
    _collectionView.contentInset = UIEdgeInsetsMake(0, 0, 120, 0);
    [self addSubview:_collectionView];

    [_collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_subtitleLabel.mas_bottom).offset(12);
        make.left.equalTo(self).offset(10);
        make.right.bottom.equalTo(self);
    }];
}

- (void)setupConfirmButton {
    _confirmButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _confirmButton.layer.cornerRadius = 14;
    _confirmButton.clipsToBounds = YES;
    UIImage *commitBg = [[UIImage imageNamed:@"commitRectangle"]
                         resizableImageWithCapInsets:UIEdgeInsetsMake(0, 40, 0, 40)
                         resizingMode:UIImageResizingModeStretch];
    [_confirmButton setBackgroundImage:commitBg forState:UIControlStateNormal];
    NSMutableAttributedString *btnTitle = [[NSMutableAttributedString alloc] initWithString:@"确认" attributes:@{
        NSFontAttributeName:            [UIFont systemFontOfSize:21 weight:UIFontWeightSemibold],
        NSForegroundColorAttributeName: UIColor.whiteColor,
        NSKernAttributeName:            @(1.05),
    }];
    [_confirmButton setAttributedTitle:btnTitle forState:UIControlStateNormal];
    [self addSubview:_confirmButton];
    [_confirmButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.mas_safeAreaLayoutGuideBottom).offset(-30);
        make.left.equalTo(self.mas_safeAreaLayoutGuideLeft).offset(22);
        make.right.equalTo(self.mas_safeAreaLayoutGuideRight).offset(-22);
        make.height.mas_equalTo(54);
    }];
}

@end
