//
//  TLWGuideController.m
//  TL-PestIdentify
//
//  引导页 Controller
//

#import "TLWGuideController.h"
#import "TLWGuideView.h"
#import "TLWPreferenceController.h"

/// 选项枚举
typedef NS_ENUM(NSInteger, TLWGuideOption) {
    TLWGuideOptionNone   = -1,
    TLWGuideOptionNeed   =  0,   // 需要适老化
    TLWGuideOptionNoNeed =  1,   // 不需要
};

@interface TLWGuideController ()

@property (nonatomic, strong) TLWGuideView *guideView;
@property (nonatomic, assign) TLWGuideOption selectedOption;

@end

@implementation TLWGuideController

- (void)loadView {
    self.guideView = [[TLWGuideView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.view = self.guideView;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.selectedOption = TLWGuideOptionNone;

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
    self.selectedOption = TLWGuideOptionNeed;
    [self.guideView setSelectedOption:TLWGuideOptionNeed];
}

- (void)handleNoNeed {
    self.selectedOption = TLWGuideOptionNoNeed;
    [self.guideView setSelectedOption:TLWGuideOptionNoNeed];
}

- (void)handleConfirm {
    if (self.selectedOption == TLWGuideOptionNone) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                       message:@"请先选择一个选项"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"好" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }

    BOOL needElderMode = (self.selectedOption == TLWGuideOptionNeed);
    NSLog(@"用户选择适老化模式: %@", needElderMode ? @"是" : @"否");

    TLWPreferenceController *prefVC = [[TLWPreferenceController alloc] init];
    prefVC.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:prefVC animated:YES completion:nil];
}

@end
