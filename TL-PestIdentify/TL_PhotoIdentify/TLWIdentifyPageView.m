//
//  TLWIdentifyPageView.m
//  TL-PestIdentify
//
//  Created by xiaoli pop on 2026/3/11.
//

#import "TLWIdentifyPageView.h"
#import <Masonry/Masonry.h>
@interface TLWIdentifyPageView()
@property (nonatomic, strong)UIBlurEffect* blurEffect;
@property (nonatomic, strong)UIVisualEffectView* blurView;
@property (nonatomic, strong)CAShapeLayer* maskLayer;
@property (nonatomic, strong)UILabel* titleLabel;
@end

@implementation TLWIdentifyPageView

- (instancetype)initWithFrame:(CGRect)frame {
  if (self = [super initWithFrame:frame]) {
    UIImage* image = [UIImage imageNamed:@"hp_backView.png"];
    self.layer.contents = (__bridge id)image.CGImage;
    [self tl_setMaskView];
    [self tl_setupSubViews];
  }
  return self;
}

- (void)tl_setupSubViews {
  self.backButton = [UIButton buttonWithType:UIButtonTypeCustom];
  [self.backButton setImage:[UIImage imageNamed:@"lp_back.png"] forState:UIControlStateNormal];
  [self.blurView.contentView addSubview:self.backButton];
  [self.backButton mas_makeConstraints:^(MASConstraintMaker *make) {
      make.left.equalTo(self.blurView.contentView.mas_left).offset(15);
      make.top.equalTo(self.blurView.contentView.mas_top).offset(68);
      make.height.width.mas_equalTo(50);
  }];
  self.titleLabel = [[UILabel alloc] init];
  self.titleLabel.textColor = [UIColor whiteColor];
  self.titleLabel.text = @"拍照识别";
  self.titleLabel.backgroundColor = [UIColor clearColor];
  self.titleLabel.font = [UIFont systemFontOfSize:20];
  [self.blurView.contentView addSubview:self.titleLabel];
  [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
      make.centerX.equalTo(self.blurView.mas_centerX);
      make.top.equalTo(self.backButton.mas_top).offset(10);
  }];
  self.recordButton = [UIButton buttonWithType:UIButtonTypeCustom];
  [self.recordButton setImage:[UIImage imageNamed:@"lp_record.png"] forState:UIControlStateNormal];
  [self.blurView.contentView addSubview:self.recordButton];
  [self.recordButton mas_makeConstraints:^(MASConstraintMaker *make) {
      make.right.equalTo(self.blurView.contentView.mas_right).offset(8);
      make.top.equalTo(self.blurView.contentView.mas_top).offset(68);
      make.height.mas_equalTo(60);
      make.width.mas_equalTo(115);
  }];
  self.captureButton = [UIButton buttonWithType:UIButtonTypeCustom];
  [self.captureButton setImage:[UIImage imageNamed:@"lp_capture.png"] forState:UIControlStateNormal];
  [self.blurView.contentView addSubview:self.captureButton];
  [self.captureButton mas_makeConstraints:^(MASConstraintMaker *make) {
    make.centerX.equalTo(self.blurView.contentView.mas_centerX);
    make.top.equalTo(self.blurView.contentView.mas_top).offset(720);
    make.width.height.mas_equalTo(97);
  }];
  self.flashButton = [UIButton buttonWithType:UIButtonTypeCustom];
  [self.flashButton setImage:[UIImage imageNamed:@"lp_ray.png"] forState:UIControlStateNormal];
  [self.blurView.contentView addSubview:self.flashButton];
  [self.flashButton mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(self.captureButton.mas_top).offset(25);
    make.height.mas_equalTo(34);
    make.width.mas_equalTo(22);
    make.right.equalTo(self.captureButton.mas_left).offset(-60);
  }];
  self.photosButton = [UIButton buttonWithType:UIButtonTypeCustom];
  [self.photosButton setImage:[UIImage imageNamed:@"lp_photos.png"] forState:UIControlStateNormal];
  [self.blurView.contentView addSubview:self.photosButton];
  [self.photosButton mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(self.captureButton.mas_top).offset(25);
    make.height.width.mas_equalTo(34);
    make.left.equalTo(self.captureButton.mas_right).offset(60);
  }];

  UILabel* label1 = [[UILabel alloc] init];
  label1.textColor = [UIColor whiteColor];
  label1.text = @"闪光灯";
  label1.backgroundColor = [UIColor clearColor];
  label1.font = [UIFont systemFontOfSize:16];
  [self.blurView.contentView addSubview:label1];
  [label1 mas_makeConstraints:^(MASConstraintMaker *make) {
      make.bottom.equalTo(self.captureButton.mas_bottom).offset(-15);
      make.centerX.equalTo(self.flashButton.mas_centerX);
  }];

  UILabel* label2 = [[UILabel alloc] init];
  label2.textColor = [UIColor whiteColor];
  label2.text = @"相册";
  label2.backgroundColor = [UIColor clearColor];
  label2.font = [UIFont systemFontOfSize:16];
  [self.blurView.contentView addSubview:label2];
  [label2 mas_makeConstraints:^(MASConstraintMaker *make) {
      make.bottom.equalTo(self.captureButton.mas_bottom).offset(-15);
      make.centerX.equalTo(self.photosButton.mas_centerX);
  }];
}

- (void)tl_setMaskView {
  [self addSubview:self.blurView];
  UIBezierPath *path = [UIBezierPath bezierPathWithRect:self.blurView.bounds];
  // 中间需要挖空的圆角矩形
  CGRect holeRect = CGRectMake(0, 130, self.bounds.size.width , 580);
  UIBezierPath *holePath = [UIBezierPath bezierPathWithRoundedRect:holeRect cornerRadius:20];
  [path appendPath:holePath];
  self.maskLayer.fillRule = kCAFillRuleEvenOdd;
  self.maskLayer.path = path.CGPath;
  self.blurView.layer.mask = self.maskLayer;
}


- (UIBlurEffect *)blurEffect {
  if (!_blurEffect) {
    _blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
  }
  return _blurEffect;
}

- (UIVisualEffectView *)blurView {
  if (!_blurView) {
    _blurView = [[UIVisualEffectView alloc] initWithEffect:self.blurEffect];
    _blurView.frame = self.bounds;
  }
  return _blurView;
}

- (CAShapeLayer *)maskLayer {
  if (!_maskLayer) {
    _maskLayer = [CAShapeLayer layer];
  }
  return _maskLayer;
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
