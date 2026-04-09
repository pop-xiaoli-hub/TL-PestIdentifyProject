//
//  TLWPlantDetailPlaceholderView.m
//  TL-PestIdentify
//

#import "TLWPlantDetailPlaceholderView.h"
#import <Masonry/Masonry.h>

@interface TLWPlantDetailPlaceholderView ()

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *messageLabel;

@end

@implementation TLWPlantDetailPlaceholderView

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    self.backgroundColor = [UIColor colorWithRed:0.97 green:0.99 blue:0.99 alpha:1.0];
    self.layer.cornerRadius = 18.0;

    UIView *iconView = [[UIView alloc] init];
    iconView.backgroundColor = [UIColor colorWithRed:0.84 green:0.95 blue:0.92 alpha:1.0];
    iconView.layer.cornerRadius = 22.0;
    [self addSubview:iconView];

    UILabel *iconLabel = [[UILabel alloc] init];
    iconLabel.text = @"✦";
    iconLabel.textAlignment = NSTextAlignmentCenter;
    iconLabel.font = [UIFont systemFontOfSize:20.0 weight:UIFontWeightSemibold];
    iconLabel.textColor = [UIColor colorWithRed:0.22 green:0.72 blue:0.60 alpha:1.0];
    [iconView addSubview:iconLabel];

    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.font = [UIFont systemFontOfSize:18.0 weight:UIFontWeightSemibold];
    titleLabel.textColor = [UIColor colorWithWhite:0.22 alpha:1.0];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:titleLabel];
    self.titleLabel = titleLabel;

    UILabel *messageLabel = [[UILabel alloc] init];
    messageLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightMedium];
    messageLabel.textColor = [UIColor colorWithWhite:0.55 alpha:1.0];
    messageLabel.numberOfLines = 0;
    messageLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:messageLabel];
    self.messageLabel = messageLabel;

    [iconView mas_makeConstraints:^(MASConstraintMaker *make) {
      make.top.equalTo(self).offset(24.0);
      make.centerX.equalTo(self);
      make.width.height.mas_equalTo(44.0);
    }];

    [iconLabel mas_makeConstraints:^(MASConstraintMaker *make) {
      make.edges.equalTo(iconView);
    }];

    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
      make.top.equalTo(iconView.mas_bottom).offset(14.0);
      make.left.equalTo(self).offset(16.0);
      make.right.equalTo(self).offset(-16.0);
    }];

    [messageLabel mas_makeConstraints:^(MASConstraintMaker *make) {
      make.top.equalTo(titleLabel.mas_bottom).offset(8.0);
      make.left.equalTo(self).offset(20.0);
      make.right.equalTo(self).offset(-20.0);
      make.bottom.equalTo(self).offset(-20.0);
    }];
  }
  return self;
}

- (void)configureWithTitle:(NSString *)title message:(NSString *)message {
  self.titleLabel.text = title;
  self.messageLabel.text = message;
}

@end
