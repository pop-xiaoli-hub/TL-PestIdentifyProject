//
//  TLWPlantDetailSegmentTabView.m
//  TL-PestIdentify
//

#import "TLWPlantDetailSegmentTabView.h"
#import <Masonry/Masonry.h>

@interface TLWPlantDetailSegmentTabView ()

@property (nonatomic, strong) UIView *backgroundContainer;
@property (nonatomic, strong) NSMutableArray<UIButton *> *tabButtons;
@property (nonatomic, assign) NSInteger selectedIndex;

@end

@implementation TLWPlantDetailSegmentTabView

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    self.tabButtons = [NSMutableArray array];

    UIView *backgroundContainer = [[UIView alloc] init];
    backgroundContainer.backgroundColor = [UIColor colorWithRed:0.95 green:0.98 blue:0.98 alpha:1.0];
    backgroundContainer.layer.cornerRadius = 14.0;
    [self addSubview:backgroundContainer];
    self.backgroundContainer = backgroundContainer;

    [backgroundContainer mas_makeConstraints:^(MASConstraintMaker *make) {
      make.edges.equalTo(self);
      make.height.mas_equalTo(42.0);
    }];
  }
  return self;
}

- (void)configureWithTitles:(NSArray<NSString *> *)titles {
  for (UIButton *button in self.tabButtons) {
    [button removeFromSuperview];
  }
  [self.tabButtons removeAllObjects];

  UIButton *previousButton = nil;
  for (NSInteger index = 0; index < titles.count; index++) {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setTitle:titles[index] forState:UIControlStateNormal];
    button.tag = index;
    button.titleLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightSemibold];
    button.layer.cornerRadius = 11.0;
    [button addTarget:self action:@selector(tl_tabTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.backgroundContainer addSubview:button];
    [self.tabButtons addObject:button];

    [button mas_makeConstraints:^(MASConstraintMaker *make) {
      make.top.bottom.equalTo(self.backgroundContainer).insets(UIEdgeInsetsMake(5.0, 0, 5.0, 0));
      if (previousButton) {
        make.left.equalTo(previousButton.mas_right).offset(6.0);
        make.width.equalTo(previousButton);
      } else {
        make.left.equalTo(self.backgroundContainer).offset(6.0);
      }
      if (index == titles.count - 1) {
        make.right.equalTo(self.backgroundContainer).offset(-6.0);
      }
    }];
    previousButton = button;
  }

  [self selectIndex:0];
}

- (void)selectIndex:(NSInteger)index {
  _selectedIndex = index;
  [self.tabButtons enumerateObjectsUsingBlock:^(UIButton * _Nonnull button, NSUInteger idx, BOOL * _Nonnull stop) {
    BOOL isSelected = (idx == index);
    button.backgroundColor = isSelected ? [UIColor colorWithRed:0.79 green:0.94 blue:0.90 alpha:1.0] : [UIColor clearColor];
    [button setTitleColor:(isSelected ? [UIColor colorWithRed:0.20 green:0.72 blue:0.58 alpha:1.0] : [UIColor colorWithWhite:0.68 alpha:1.0]) forState:UIControlStateNormal];
  }];
}

- (void)tl_tabTapped:(UIButton *)sender {
  [self selectIndex:sender.tag];
  if (self.selectionChangedBlock) {
    self.selectionChangedBlock(sender.tag);
  }
}

@end
