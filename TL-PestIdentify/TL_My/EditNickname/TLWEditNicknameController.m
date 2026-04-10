//
//  TLWEditNicknameController.m
//  TL-PestIdentify
//

#import "TLWEditNicknameController.h"
#import "TLWEditNicknameView.h"
#import "TLWSDKManager.h"
#import <Masonry/Masonry.h>

extern NSString * const TLWProfileDidUpdateNotification;

@interface TLWEditNicknameController ()
@property (nonatomic, strong) TLWEditNicknameView *myView;
@property (nonatomic, copy)   NSString            *currentNickname;
@end

@implementation TLWEditNicknameController

- (instancetype)initWithCurrentNickname:(NSString *)nickname {
    self = [super init];
    if (self) {
        _currentNickname = nickname;
        self.hidesBottomBarWhenPushed = YES;
    }
    return self;
}

- (NSString *)navTitle { return @"修改昵称"; }

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view addSubview:self.myView];
    [self.myView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    [self.view bringSubviewToFront:self.navBar];
    _myView.nicknameTextField.text = _currentNickname;
    [_myView.confirmButton addTarget:self action:@selector(onConfirm) forControlEvents:UIControlEventTouchUpInside];
}

- (TLWEditNicknameView *)myView {
    if (!_myView) _myView = [[TLWEditNicknameView alloc] initWithFrame:CGRectZero];
    return _myView;
}

#pragma mark - Actions

- (void)onConfirm {
    NSString *newName = [_myView.nicknameTextField.text stringByTrimmingCharactersInSet:
                         NSCharacterSet.whitespaceCharacterSet];
    if (newName.length == 0) return;

    _myView.confirmButton.enabled = NO;
    AGProfileUpdateRequest *req = [[AGProfileUpdateRequest alloc] init];
    req.fullName = newName;
    [[TLWSDKManager shared].api updateProfileWithProfileUpdateRequest:req completionHandler:^(AGResultUserProfileDto *output, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self->_myView.confirmButton.enabled = YES;
            if (error || output.code.integerValue != 200) {
                if (!error && output.code.integerValue == 401) {
                    [[TLWSDKManager shared].sessionManager handleUnauthorizedWithRetry:^{ [self onConfirm]; }];
                    return;
                }
                NSLog(@"修改昵称失败: %@", error.localizedDescription ?: output.message);
                return;
            }
            // 直接改缓存，立刻通知所有页面
            [TLWSDKManager shared].sessionManager.cachedProfile.fullName = newName;
            [[NSNotificationCenter defaultCenter] postNotificationName:TLWProfileDidUpdateNotification object:nil];
            [self.delegate editNicknameController:self didSaveNickname:newName];
            [self.navigationController popViewControllerAnimated:YES];
        });
    }];
}

@end
