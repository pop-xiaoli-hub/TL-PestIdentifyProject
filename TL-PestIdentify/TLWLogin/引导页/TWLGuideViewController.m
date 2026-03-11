//
//  TWLGuideViewController.m
//  TL-PestIdentify
//
//  引导页 ViewController
//

#import "TWLGuideViewController.h"
#import "TWLGuideView.h"
#import "TWLPreferenceViewController.h"

/// 选项枚举
typedef NS_ENUM(NSInteger, TWLGuideOption) {
    TWLGuideOptionNone   = -1,
    TWLGuideOptionNeed   =  0,   // 需要适老化
    TWLGuideOptionNoNeed =  1,   // 不需要
};

@interface TWLGuideViewController ()

@property (nonatomic, strong) TWLGuideView *guideView;
@property (nonatomic, assign) TWLGuideOption selectedOption;

@end

@implementation TWLGuideViewController

- (void)loadView {
    self.guideView = [[TWLGuideView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.view = self.guideView;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.selectedOption = TWLGuideOptionNone;

    [self.guideView.needButton addTarget:self
                                  action:@selector(handleNeed)
                        forControlEvents:UIControlEventTouchUpInside];

    [self.guideView.noNeedButton addTarget:self
                                    action:@selector(handleNoNeed)
                          forControlEvents:UIControlEventTouchUpInside];

    [self.guideView.confirmButton addTarget:self
                                     action:@selector(handleConfirm)
                           forControlEvents:UIControlEventTouchUpInside];
}

#pragma mark - Actions

- (void)handleNeed {
    self.selectedOption = TWLGuideOptionNeed;
    [self.guideView setSelectedOption:TWLGuideOptionNeed];
}

- (void)handleNoNeed {
    self.selectedOption = TWLGuideOptionNoNeed;
    [self.guideView setSelectedOption:TWLGuideOptionNoNeed];
}

- (void)handleConfirm {
    if (self.selectedOption == TWLGuideOptionNone) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                       message:@"请先选择一个选项"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"好" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }

    BOOL needElderMode = (self.selectedOption == TWLGuideOptionNeed);
    NSLog(@"用户选择适老化模式: %@", needElderMode ? @"是" : @"否");

    TWLPreferenceViewController *prefVC = [[TWLPreferenceViewController alloc] init];
    prefVC.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:prefVC animated:YES completion:nil];
}

@end
