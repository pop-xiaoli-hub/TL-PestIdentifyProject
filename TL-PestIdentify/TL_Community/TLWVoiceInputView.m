//
//  TLWVoiceInputView.m
//  TL-PestIdentify
//

#import "TLWVoiceInputView.h"
#import <Masonry/Masonry.h>

static CGFloat const kHeaderHeight = 56.0;
static CGFloat const kCenterCircleSize = 254.0;
static CGFloat const kEqualizerBarWidth = 8.0;
static CGFloat const kEqualizerBarSpacing = 12.0;
static CGFloat const kEqualizerBarMaxHeight = 48.0;

@interface TLWVoiceInputView ()

@property (nonatomic, strong, readwrite) UIButton *backButton;
@property (nonatomic, strong, readwrite) UITextField *searchTextField;
@property (nonatomic, strong, readwrite) UIButton *longPressMicButton;
@property (nonatomic, strong) UIView *headerGradientContainer;
@property (nonatomic, strong) UIView *centerCircleContainer;
@property (nonatomic, strong) NSArray<UIView *> *equalizerBars;
@property (nonatomic, strong) UILabel *inputtingLabel;

@end

@implementation TLWVoiceInputView

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    [self tl_setupBackground];
    [self tl_setupHeader];
    [self tl_setupCenterIndicator];
    [self tl_setupBottomHint];
  }
  return self;
}

- (void)layoutSubviews {
  [super layoutSubviews];
  CGFloat topInset = 0;
  if (@available(iOS 11.0, *)) {
    topInset = self.safeAreaInsets.top;
  }
  CGFloat headerH = topInset + kHeaderHeight;
  [self.headerGradientContainer mas_updateConstraints:^(MASConstraintMaker *make) {
    make.height.mas_equalTo(headerH);
  }];
  [self tl_updateHeaderGradient];
  [self tl_updateCenterGradient];
}

- (void)didMoveToWindow {
  [super didMoveToWindow];
  if (self.window) {
    [self tl_startEqualizerAnimation];
  } else {
    [self tl_stopEqualizerAnimation];
  }
}

#pragma mark - Setup

- (void)tl_setupBackground {
  UIImage* image = [UIImage imageNamed:@"cp_backView.png"];
  self.layer.contents = (__bridge id)image.CGImage;
}

- (void)tl_setupHeader {
  UIView *header = [[UIView alloc] init];
  header.backgroundColor = [UIColor clearColor];
  [self addSubview:header];
  self.headerGradientContainer = header;
  [header mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.right.top.equalTo(self);
    make.height.mas_equalTo(kHeaderHeight);
  }];

  UIButton *backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
  backBtn.clipsToBounds = YES;
  UIImage *backImage = [UIImage imageNamed:@"iconBack"];
  if (backImage) {
    [backBtn setImage:backImage forState:UIControlStateNormal];
  } else {
    [backBtn setTitle:@"<" forState:UIControlStateNormal];
    [backBtn setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
  }
  backBtn.tintColor = [UIColor darkGrayColor];
  [header addSubview:backBtn];
  self.backButton = backBtn;

  UIView *searchBg = [[UIView alloc] init];
  searchBg.backgroundColor = [UIColor colorWithWhite:0.92 alpha:0.98];
  searchBg.layer.cornerRadius = 20.0;
  searchBg.clipsToBounds = YES;
  [header addSubview:searchBg];

  UIImageView *searchIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cp_search.png"]];
  searchIcon.contentMode = UIViewContentModeScaleAspectFit;
  [searchBg addSubview:searchIcon];

  UITextField *tf = [[UITextField alloc] init];
  tf.placeholder = @"请输入关键词";
  tf.font = [UIFont systemFontOfSize:14];
  tf.textColor = [UIColor darkTextColor];
  tf.returnKeyType = UIReturnKeySearch;
  [searchBg addSubview:tf];
  self.searchTextField = tf;

  UIImageView *micIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cp_voice.png"]];
  micIcon.contentMode = UIViewContentModeScaleAspectFit;
  [searchBg addSubview:micIcon];

  [backBtn mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.equalTo(header).offset(16);
    make.bottom.equalTo(header).offset(-8);
    make.width.height.mas_equalTo(40);
  }];
  [searchBg mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.equalTo(backBtn.mas_right).offset(12);
    make.right.equalTo(header).offset(-16);
    make.centerY.equalTo(backBtn);
    make.height.mas_equalTo(40);
  }];
  [searchIcon mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.equalTo(searchBg).offset(12);
    make.centerY.equalTo(searchBg);
    make.width.height.mas_equalTo(18);
  }];
  [micIcon mas_makeConstraints:^(MASConstraintMaker *make) {
    make.right.equalTo(searchBg).offset(-12);
    make.centerY.equalTo(searchBg);
    make.width.height.mas_equalTo(18);
  }];
  [tf mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.equalTo(searchIcon.mas_right).offset(8);
    make.right.equalTo(micIcon.mas_left).offset(-8);
    make.centerY.equalTo(searchBg);
    make.height.mas_equalTo(32);
  }];
}

- (void)tl_updateHeaderGradient {
  // 顶部背景改为透明：移除已有渐变图层，不再叠加新的背景
  if (!self.headerGradientContainer) return;
  NSArray<CALayer *> *sublayers = [self.headerGradientContainer.layer.sublayers copy];
  for (CALayer *layer in sublayers) {
    if ([layer isKindOfClass:[CAGradientLayer class]]) {
      [layer removeFromSuperlayer];
    }
  }
}

- (void)tl_setupCenterIndicator {
  UIView *container = [[UIView alloc] init];
  container.backgroundColor = [UIColor clearColor];
  [self addSubview:container];
  self.centerCircleContainer = container;

  UIImageView* circleBg = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cp_voiceload.png"]];
  [container addSubview:circleBg];

  NSMutableArray<UIView *> *bars = [NSMutableArray arrayWithCapacity:4];
  for (NSInteger i = 0; i < 4; i++) {
    UIView *bar = [[UIView alloc] init];
    bar.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.9];
    bar.layer.cornerRadius = kEqualizerBarWidth / 2.0;
    bar.clipsToBounds = YES;
    [container addSubview:bar];
    [bars addObject:bar];
  }
  self.equalizerBars = [bars copy];

  UILabel *label = [[UILabel alloc] init];
  label.text = @"正在输入";
  label.textColor = [UIColor whiteColor];
  label.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
  [container addSubview:label];
  self.inputtingLabel = label;

  [container mas_makeConstraints:^(MASConstraintMaker *make) {
    make.centerX.equalTo(self);
    make.centerY.equalTo(self).offset(-20);
    make.width.height.mas_equalTo(kCenterCircleSize);
  }];
  [circleBg mas_makeConstraints:^(MASConstraintMaker *make) {
    make.edges.equalTo(container);
  }];
  CGFloat totalBarsWidth = 4 * kEqualizerBarWidth + 3 * kEqualizerBarSpacing;
  CGFloat startX = (kCenterCircleSize - totalBarsWidth) / 2.0 + kEqualizerBarWidth / 2.0 + kEqualizerBarSpacing / 2.0;
  for (NSInteger i = 0; i < bars.count; i++) {
    UIView *bar = bars[i];
    CGFloat x = startX + i * (kEqualizerBarWidth + kEqualizerBarSpacing);
    [bar mas_makeConstraints:^(MASConstraintMaker *make) {
      make.centerX.equalTo(container.mas_left).offset(x - 6);
      make.centerY.equalTo(container).offset(-12);
      make.width.mas_equalTo(kEqualizerBarWidth);
      make.height.mas_equalTo(kEqualizerBarMaxHeight * (0.4 + (i % 3) * 0.25));
    }];
  }
  [label mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(container.mas_centerY).offset(12);
    make.centerX.equalTo(container);
  }];
}

- (void)tl_updateCenterGradient {
  UIView *circleBg = [self.centerCircleContainer viewWithTag:100];
  if (!circleBg || circleBg.bounds.size.width < 1) return;
  for (CALayer *layer in circleBg.layer.sublayers) {
    if ([layer isKindOfClass:[CAGradientLayer class]]) {
      [layer removeFromSuperlayer];
      break;
    }
  }
  CAGradientLayer *gradient = [CAGradientLayer layer];
  gradient.frame = circleBg.bounds;
  gradient.cornerRadius = circleBg.layer.cornerRadius;
  gradient.colors = @[
    (id)[UIColor colorWithRed:0.2 green:0.7 blue:0.55 alpha:1.0].CGColor,
    (id)[UIColor colorWithRed:0.35 green:0.8 blue:0.65 alpha:1.0].CGColor
  ];
  gradient.startPoint = CGPointMake(0.2, 0);
  gradient.endPoint = CGPointMake(0.8, 1);
  [circleBg.layer insertSublayer:gradient atIndex:0];
}

- (void)tl_startEqualizerAnimation {
  if (self.equalizerBars.count == 0) {
    return;
  }
  [self tl_animateEqualizerBarAtIndex:0];
}

- (void)tl_animateEqualizerBarAtIndex:(NSInteger)index {
  if (index >= (NSInteger)self.equalizerBars.count || !self.window) return;
  UIView *bar = self.equalizerBars[index];
  CGFloat targetH = kEqualizerBarMaxHeight * (0.3 + (arc4random_uniform(70) / 100.0));
  [bar mas_updateConstraints:^(MASConstraintMaker *make) {
    make.height.mas_equalTo(targetH);
  }];
  [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
    [bar.superview layoutIfNeeded];
  } completion:^(BOOL finished) {
    NSInteger next = (index + 1) % self.equalizerBars.count;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.08 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
      [self tl_animateEqualizerBarAtIndex:next];
    });
  }];
}

- (void)tl_stopEqualizerAnimation {
  // 可在此取消动画，当前用 didMoveToWindow 里判断 window 为 nil 时不再继续
}

- (void)tl_setupBottomHint {
  UIButton *micBtn = [UIButton buttonWithType:UIButtonTypeCustom];
  micBtn.clipsToBounds = YES;
  UIImage *micImg = [UIImage imageNamed:@"cp_voiceInput.png"];
  if (micImg) {
    [micBtn setImage:micImg forState:UIControlStateNormal];
    micBtn.tintColor = [UIColor darkGrayColor];
  } else {
    [micBtn setTitle:@"🎤" forState:UIControlStateNormal];
  }
  [self addSubview:micBtn];
  self.longPressMicButton = micBtn;

  [micBtn mas_makeConstraints:^(MASConstraintMaker *make) {
    make.centerX.equalTo(self);
    make.bottom.equalTo(self.mas_safeAreaLayoutGuideBottom).offset(-56);
    make.height.mas_equalTo(131.63);
    make.width.mas_equalTo(101.37);
  }];
}

@end
