//
//  TLWCommunitySuggestionCell.m
//  TL-PestIdentify
//
//  Created by xiaoli pop on 2026/4/1.
//

#import "TLWCommunitySuggestionCell.h"
#import <Masonry/Masonry.h>
@interface TLWCommunitySuggestionCell()

@property (nonatomic, strong) UIView *cardView;
@property (nonatomic, strong) UIView *dividerView;
@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIView* highlightView;
@end

@implementation TLWCommunitySuggestionCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (self) {
    self.backgroundColor = [UIColor clearColor];
    self.selectionStyle = UITableViewCellSelectionStyleNone;

    UIView *selectedBackground = [[UIView alloc] init];
    selectedBackground.backgroundColor = [UIColor clearColor];
    self.selectedBackgroundView = selectedBackground;

    UIView *cardView = [[UIView alloc] init];
    cardView.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.18];
    cardView.layer.cornerRadius = 16.0;
    cardView.layer.borderWidth = 1.0;
    cardView.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.36].CGColor;
    cardView.layer.shadowColor = [UIColor colorWithRed:0.12 green:0.18 blue:0.31 alpha:0.14].CGColor;
    cardView.layer.shadowOpacity = 1.0;
    cardView.layer.shadowRadius = 12.0;
    cardView.layer.shadowOffset = CGSizeMake(0, 6);
    [self.contentView addSubview:cardView];
    _cardView = cardView;

    UIView *highlightView = [[UIView alloc] init];
    highlightView.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.12];
    highlightView.userInteractionEnabled = NO;
    highlightView.layer.cornerRadius = 16.0;
    [cardView addSubview:highlightView];
    _highlightView = highlightView;

    UIImage *iconImage = nil;
    if (@available(iOS 13.0, *)) {
      UIImageSymbolConfiguration *symbolConfig = [UIImageSymbolConfiguration configurationWithPointSize:14 weight:UIImageSymbolWeightSemibold];
      iconImage = [UIImage systemImageNamed:@"magnifyingglass" withConfiguration:symbolConfig];
    }
    UIImageView *iconView = [[UIImageView alloc] initWithImage:iconImage];
    iconView.tintColor = [UIColor colorWithRed:0.20 green:0.42 blue:0.94 alpha:0.95];
    iconView.contentMode = UIViewContentModeScaleAspectFit;
    [cardView addSubview:iconView];
    _iconView = iconView;

    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    titleLabel.textColor = [UIColor colorWithWhite:0.12 alpha:1.0];
    [cardView addSubview:titleLabel];
    _titleLabel = titleLabel;

    UIView *dividerView = [[UIView alloc] init];
    dividerView.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.26];
    [cardView addSubview:dividerView];
    _dividerView = dividerView;

    [_cardView mas_makeConstraints:^(MASConstraintMaker *make) {
      make.top.equalTo(self.contentView).offset(4);
      make.bottom.equalTo(self.contentView).offset(-4);
      make.left.right.equalTo(self.contentView);
    }];

    [_highlightView mas_makeConstraints:^(MASConstraintMaker *make) {
      make.top.left.right.equalTo(_cardView);
      make.height.mas_equalTo(24);
    }];

    [_iconView mas_makeConstraints:^(MASConstraintMaker *make) {
      make.left.equalTo(_cardView).offset(14);
      make.centerY.equalTo(_cardView);
      make.width.height.mas_equalTo(16);
    }];

    [_titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
      make.left.equalTo(_iconView.mas_right).offset(10);
      make.centerY.equalTo(_cardView);
      make.right.equalTo(_cardView).offset(-14);
    }];

    [_dividerView mas_makeConstraints:^(MASConstraintMaker *make) {
      make.left.equalTo(_titleLabel);
      make.right.equalTo(_cardView).offset(-14);
      make.bottom.equalTo(_cardView);
      make.height.mas_equalTo(1);
    }];
  }
  return self;
}

- (void)tl_configureWithText:(NSString *)text showsDivider:(BOOL)showsDivider {
  _titleLabel.text = text;
  _dividerView.hidden = !showsDivider;
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
  [super setHighlighted:highlighted animated:animated];

  CGFloat targetAlpha = highlighted ? 0.30 : 0.18;
  UIColor *targetBorderColor = [UIColor colorWithWhite:1 alpha:(highlighted ? 0.52 : 0.36)];
  [UIView animateWithDuration:(animated ? 0.18 : 0.0) animations:^{
    self->_cardView.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:targetAlpha];
    self->_cardView.layer.borderColor = targetBorderColor.CGColor;
  }];
}


- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
