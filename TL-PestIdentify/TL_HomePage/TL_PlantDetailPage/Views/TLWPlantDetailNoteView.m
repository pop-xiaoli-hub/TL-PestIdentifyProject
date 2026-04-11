//
//  TLWPlantDetailNoteView.m
//  TL-PestIdentify
//

#import "TLWPlantDetailNoteView.h"
#import "TLWPlantDetailCalendarView.h"
#import "TLWPlantDetailViewModel.h"
#import <Masonry/Masonry.h>

@interface TLWPlantNoteLegendItemView : UIView

- (void)configureWithColor:(UIColor *)color title:(NSString *)title;

@end

@interface TLWPlantNoteLegendItemView ()

@property (nonatomic, strong) UIView *surfaceView;
@property (nonatomic, strong) UIView *highlightView;
@property (nonatomic, strong) UIView *dotView;
@property (nonatomic, strong) UILabel *titleLabel;

@end

@implementation TLWPlantNoteLegendItemView

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    self.backgroundColor = [UIColor clearColor];
    self.layer.cornerRadius = 12.0;
    self.layer.shadowColor = [UIColor colorWithRed:0.57 green:0.57 blue:0.57 alpha:0.28].CGColor;
    self.layer.shadowOpacity = 1.0;
    self.layer.shadowOffset = CGSizeMake(0, 6.0);
    self.layer.shadowRadius = 12.0;

    UIView *surfaceView = [[UIView alloc] init];
    surfaceView.backgroundColor = [UIColor colorWithWhite:0.92 alpha:1.0];
    surfaceView.layer.cornerRadius = 12.0;
    surfaceView.layer.borderWidth = 1.0;
    surfaceView.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.8].CGColor;
    surfaceView.layer.masksToBounds = YES;
    [self addSubview:surfaceView];
    self.surfaceView = surfaceView;

    UIView *highlightView = [[UIView alloc] init];
    highlightView.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.55];
    highlightView.layer.cornerRadius = 9.0;
    [surfaceView addSubview:highlightView];
    self.highlightView = highlightView;

    UIView *dotView = [[UIView alloc] init];
    dotView.layer.cornerRadius = 9.0;
    [surfaceView addSubview:dotView];
    self.dotView = dotView;

    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightSemibold];
    titleLabel.textColor = [UIColor colorWithWhite:0.27 alpha:1.0];
    [surfaceView addSubview:titleLabel];
    self.titleLabel = titleLabel;

    [surfaceView mas_makeConstraints:^(MASConstraintMaker *make) {
      make.edges.equalTo(self);
    }];

    [highlightView mas_makeConstraints:^(MASConstraintMaker *make) {
      make.top.equalTo(surfaceView).offset(6.0);
      make.left.equalTo(surfaceView).offset(10.0);
      make.right.equalTo(surfaceView).offset(-10.0);
      make.height.mas_equalTo(13.0);
    }];

    [dotView mas_makeConstraints:^(MASConstraintMaker *make) {
      make.left.equalTo(surfaceView).offset(18.0);
      make.centerY.equalTo(surfaceView);
      make.width.height.mas_equalTo(18.0);
    }];

    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
      make.left.equalTo(dotView.mas_right).offset(10.0);
      make.centerY.equalTo(surfaceView);
      make.right.equalTo(surfaceView).offset(-12.0);
    }];
  }
  return self;
}

- (void)layoutSubviews {
  [super layoutSubviews];
  self.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:12.0].CGPath;
}

- (void)configureWithColor:(UIColor *)color title:(NSString *)title {
  self.dotView.backgroundColor = color;
  self.titleLabel.text = title;
}

@end

@interface TLWPlantDetailNoteView () <UITextViewDelegate>

@property (nonatomic, strong) TLWPlantDetailCalendarView *calendarView;
@property (nonatomic, strong) UIView *textContainerView;
@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, strong) UILabel *placeholderLabel;

@end

@implementation TLWPlantDetailNoteView

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    TLWPlantDetailCalendarView *calendarView = [[TLWPlantDetailCalendarView alloc] init];
    [self addSubview:calendarView];
    self.calendarView = calendarView;

    UILabel *legendTitleLabel = [[UILabel alloc] init];
    legendTitleLabel.text = @"标签";
    legendTitleLabel.font = [UIFont systemFontOfSize:16.0 weight:UIFontWeightSemibold];
    legendTitleLabel.textColor = [UIColor colorWithWhite:0.18 alpha:1.0];
    [self addSubview:legendTitleLabel];

    TLWPlantNoteLegendItemView *noteLegendView = [[TLWPlantNoteLegendItemView alloc] init];
    [noteLegendView configureWithColor:[UIColor colorWithRed:0.47 green:0.86 blue:0.79 alpha:1.0] title:@"有笔记"];
    [self addSubview:noteLegendView];

    UIView *textContainerView = [[UIView alloc] init];
    textContainerView.backgroundColor = [UIColor whiteColor];
    textContainerView.layer.cornerRadius = 12.0;
    textContainerView.layer.shadowColor = [UIColor colorWithRed:0.63 green:0.63 blue:0.63 alpha:0.18].CGColor;
    textContainerView.layer.shadowOpacity = 1.0;
    textContainerView.layer.shadowOffset = CGSizeMake(0, 4.0);
    textContainerView.layer.shadowRadius = 10.0;
    [self addSubview:textContainerView];
    self.textContainerView = textContainerView;

    UITextView *textView = [[UITextView alloc] init];
    textView.backgroundColor = [UIColor clearColor];
    textView.font = [UIFont systemFontOfSize:18.0 weight:UIFontWeightMedium];
    textView.textColor = [UIColor colorWithWhite:0.28 alpha:1.0];
    textView.delegate = self;
    textView.textContainerInset = UIEdgeInsetsMake(14.0, 12.0, 14.0, 12.0);
    [textContainerView addSubview:textView];
    self.textView = textView;

    UILabel *placeholderLabel = [[UILabel alloc] init];
    placeholderLabel.text = @"点击输入笔记内容";
    placeholderLabel.font = [UIFont systemFontOfSize:18.0 weight:UIFontWeightMedium];
    placeholderLabel.textColor = [UIColor colorWithWhite:0.72 alpha:1.0];
    [textContainerView addSubview:placeholderLabel];
    self.placeholderLabel = placeholderLabel;

    UIButton *tagButton = [self tl_actionButtonWithTitle:@"打上标签"];
    [tagButton addTarget:self action:@selector(tl_tagButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:tagButton];

    UIButton *cancelTagButton = [self tl_actionButtonWithTitle:@"取消标签"];
    [cancelTagButton addTarget:self action:@selector(tl_cancelTagButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:cancelTagButton];

    [calendarView mas_makeConstraints:^(MASConstraintMaker *make) {
      make.top.left.right.equalTo(self);
      make.height.mas_equalTo(350.0);
    }];

    [legendTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
      make.top.equalTo(calendarView.mas_bottom).offset(48.0);
      make.left.equalTo(self).offset(2.0);
    }];

    [noteLegendView mas_makeConstraints:^(MASConstraintMaker *make) {
      make.top.equalTo(legendTitleLabel.mas_bottom).offset(12.0);
      make.left.right.equalTo(self);
      make.height.mas_equalTo(42.0);
    }];

    [textContainerView mas_makeConstraints:^(MASConstraintMaker *make) {
      make.top.equalTo(noteLegendView.mas_bottom).offset(12.0);
      make.left.right.equalTo(self);
      make.height.mas_equalTo(88.0);
    }];

    [textView mas_makeConstraints:^(MASConstraintMaker *make) {
      make.edges.equalTo(textContainerView);
    }];

    [placeholderLabel mas_makeConstraints:^(MASConstraintMaker *make) {
      make.top.equalTo(textContainerView).offset(14.0);
      make.left.equalTo(textContainerView).offset(16.0);
      make.right.lessThanOrEqualTo(textContainerView).offset(-16.0);
    }];

    [tagButton mas_makeConstraints:^(MASConstraintMaker *make) {
      make.top.equalTo(textContainerView.mas_bottom).offset(22.0);
      make.left.right.equalTo(self);
      make.height.mas_equalTo(44.0);
    }];

    [cancelTagButton mas_makeConstraints:^(MASConstraintMaker *make) {
      make.top.equalTo(tagButton.mas_bottom).offset(12.0);
      make.left.right.height.equalTo(tagButton);
      make.bottom.equalTo(self);
    }];

    __weak typeof(self) weakSelf = self;
    calendarView.previousMonthBlock = ^{
      __strong typeof(weakSelf) strongSelf = weakSelf;
      if (strongSelf.previousMonthBlock) {
        strongSelf.previousMonthBlock();
      }
    };
    calendarView.nextMonthBlock = ^{
      __strong typeof(weakSelf) strongSelf = weakSelf;
      if (strongSelf.nextMonthBlock) {
        strongSelf.nextMonthBlock();
      }
    };
    calendarView.dateSelectionBlock = ^(NSDate *date) {
      __strong typeof(weakSelf) strongSelf = weakSelf;
      if (strongSelf.dateSelectionBlock) {
        strongSelf.dateSelectionBlock(date);
      }
    };
  }
  return self;
}

- (UIButton *)tl_actionButtonWithTitle:(NSString *)title {
  UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
  [button setTitle:title forState:UIControlStateNormal];
  [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
  button.titleLabel.font = [UIFont systemFontOfSize:17.0 weight:UIFontWeightSemibold];
  button.layer.shadowColor = [UIColor colorWithRed:0.89 green:0.53 blue:0.07 alpha:0.42].CGColor;
  button.layer.shadowOpacity = 1.0;
  button.layer.shadowOffset = CGSizeMake(0, 7.0);
  button.layer.shadowRadius = 12.0;
  button.layer.borderWidth = 1.0;
  button.layer.borderColor = [UIColor colorWithRed:0.98 green:0.79 blue:0.34 alpha:0.95].CGColor;

  CAGradientLayer *gradientLayer = [CAGradientLayer layer];
  gradientLayer.colors = @[
    (__bridge id)[UIColor colorWithRed:1.00 green:0.82 blue:0.31 alpha:1.0].CGColor,
    (__bridge id)[UIColor colorWithRed:0.99 green:0.63 blue:0.23 alpha:1.0].CGColor
  ];
  gradientLayer.startPoint = CGPointMake(0.0, 0.5);
  gradientLayer.endPoint = CGPointMake(1.0, 0.5);
  gradientLayer.frame = CGRectMake(0, 0, 300, 44);
  [button.layer insertSublayer:gradientLayer atIndex:0];

  CAGradientLayer *glossLayer = [CAGradientLayer layer];
  glossLayer.colors = @[
    (__bridge id)[[UIColor whiteColor] colorWithAlphaComponent:0.40].CGColor,
    (__bridge id)[[UIColor whiteColor] colorWithAlphaComponent:0.12].CGColor,
    (__bridge id)[UIColor clearColor].CGColor
  ];
  glossLayer.startPoint = CGPointMake(0.5, 0.0);
  glossLayer.endPoint = CGPointMake(0.5, 1.0);
  glossLayer.frame = CGRectMake(0, 0, 300, 20);
  [button.layer insertSublayer:glossLayer above:gradientLayer];
  return button;
}

- (void)layoutSubviews {
  [super layoutSubviews];
  for (UIView *subview in self.subviews) {
    if (![subview isKindOfClass:[UIButton class]]) {
      continue;
    }
    UIButton *button = (UIButton *)subview;
    if (button.layer.sublayers.count >= 2) {
      CALayer *gradientLayer = button.layer.sublayers[0];
      CALayer *glossLayer = button.layer.sublayers[1];
      gradientLayer.frame = button.bounds;
      gradientLayer.cornerRadius = button.bounds.size.height * 0.5;
      glossLayer.frame = CGRectMake(0, 0, button.bounds.size.width, MAX(16.0, button.bounds.size.height * 0.48));
      glossLayer.cornerRadius = button.bounds.size.height * 0.5;
    }
    button.layer.cornerRadius = button.bounds.size.height * 0.5;
    button.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:button.bounds cornerRadius:button.bounds.size.height * 0.5].CGPath;
  }
}

- (void)configureWithViewModel:(TLWPlantDetailViewModel *)viewModel {
  [self.calendarView configureWithMonthTitle:[viewModel currentMonthTitle] dayItems:[viewModel calendarItemsForTabType:TLWPlantDetailTabTypeNote]];
  self.textView.text = [viewModel noteContentForSelectedDate];
  [self tl_updatePlaceholderVisibility];
}

- (NSString *)currentNoteText {
  return self.textView.text ?: @"";
}

- (BOOL)isEditingNoteText {
  return self.textView.isFirstResponder;
}

- (CGRect)noteEditorRectInView:(UIView *)view {
  return [self.textContainerView convertRect:self.textContainerView.bounds toView:view];
}

- (void)textViewDidChange:(UITextView *)textView {
  [self tl_updatePlaceholderVisibility];
}

- (void)tl_updatePlaceholderVisibility {
  self.placeholderLabel.hidden = self.textView.text.length > 0;
}

- (void)tl_tagButtonTapped {
  if (self.tagActionBlock) {
    self.tagActionBlock();
  }
}

- (void)tl_cancelTagButtonTapped {
  if (self.cancelTagActionBlock) {
    self.cancelTagActionBlock();
  }
}

@end
