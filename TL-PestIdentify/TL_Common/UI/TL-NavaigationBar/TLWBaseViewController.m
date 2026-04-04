//
//  TLWBaseViewController.m
//  TL-PestIdentify
//

#import "TLWBaseViewController.h"
#import <Masonry/Masonry.h>

@interface TLWBaseViewController ()
@property (nonatomic, strong, readwrite) TLWCustomNavBar *navBar;
@property (nonatomic, strong, readwrite) UIView          *contentView;
@end

@implementation TLWBaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;

    _contentView = [UIView new];
    [self.view addSubview:_contentView];

    if (!_hideNavBar) {
        NSString *title = [self navTitle];
        NSString *icon  = [self navTitleIconName];
        _navBar = [[TLWCustomNavBar alloc] initWithTitle:title ?: @"" iconName:icon];
        [self.view addSubview:_navBar];
        [_navBar mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.left.right.equalTo(self.view);
        }];

        [_contentView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_navBar.mas_bottom);
            make.left.right.bottom.equalTo(self.view);
        }];

        [_navBar.backButton addTarget:self
                               action:@selector(onBackAction)
                     forControlEvents:UIControlEventTouchUpInside];
    } else {
        [_contentView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.view);
        }];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];

    BOOL canPop = self.navigationController.viewControllers.count > 1;
    self.navigationController.interactivePopGestureRecognizer.enabled = canPop;

    if (self.navBar) {
        self.navBar.backButton.hidden = !canPop;
        self.navBar.backButton.userInteractionEnabled = canPop;
    }
}

#pragma mark - Override Points

- (NSString *)navTitle         { return nil; }
- (NSString *)navTitleIconName { return nil; }

- (void)onBackAction {
    [self.navigationController popViewControllerAnimated:YES];
}

@end
