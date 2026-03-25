//
//  TLWEditNicknameController.m
//  TL-PestIdentify
//

#import "TLWEditNicknameController.h"
#import "TLWEditNicknameView.h"
#import "TLWSDKManager.h"
#import <Masonry/Masonry.h>

@interface TLWEditNicknameController ()
@property (nonatomic, strong) TLWEditNicknameView *myView;
@property (nonatomic, copy)   NSString            *currentNickname;
@end

@implementation TLWEditNicknameController

- (instancetype)initWithCurrentNickname:(NSString *)nickname {
    self = [super init];
    if (self) {
        _currentNickname          = nickname;
        self.hidesBottomBarWhenPushed = YES;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view addSubview:self.myView];
    [self.myView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    _myView.nicknameTextField.text = _currentNickname;
    [_myView.backButton    addTarget:self action:@selector(onBack)    forControlEvents:UIControlEventTouchUpInside];
    [_myView.confirmButton addTarget:self action:@selector(onConfirm) forControlEvents:UIControlEventTouchUpInside];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    self.navigationController.interactivePopGestureRecognizer.enabled  = YES;
    self.navigationController.interactivePopGestureRecognizer.delegate = nil;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}

- (TLWEditNicknameView *)myView {
    if (!_myView) _myView = [[TLWEditNicknameView alloc] initWithFrame:CGRectZero];
    return _myView;
}

#pragma mark - Actions

- (void)onBack {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)onConfirm {
    NSString *newName = [_myView.nicknameTextField.text stringByTrimmingCharactersInSet:
                         NSCharacterSet.whitespaceCharacterSet];
    if (newName.length == 0) return;

    AGProfileUpdateRequest *req = [[AGProfileUpdateRequest alloc] init];
    req.fullName = newName;
    [[TLWSDKManager shared].api updateProfileWithProfileUpdateRequest:req completionHandler:^(AGResultUserProfileDto *output, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error || output.code.integerValue != 200) {
                NSLog(@"修改昵称失败: %@", error.localizedDescription ?: output.message);
                return;
            }
            [self.delegate editNicknameController:self didSaveNickname:newName];
            [self.navigationController popViewControllerAnimated:YES];
        });
    }];
}

@end
