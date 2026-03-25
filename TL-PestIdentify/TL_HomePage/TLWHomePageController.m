//
//  TLWHomePageController.m
//  TL-PestIdentify
//
//  Created by xiaoli pop on 2026/3/9.
//

#import "TLWHomePageController.h"
#import "TLWHomePageView.h"
#import "TLWHomeCardCell.h"
#import "TLWHomeCustomCell.h"
#import "TLWIdentifyPageController.h"
#import "TLWRecordController.h"
#import "TLWAIAssistantController.h"
#import "TLWWarningModel.h"
#import "TLWSDKManager.h"
#import <Masonry.h>
#import <SDWebImage/SDWebImage.h>

extern NSString * const TLWAvatarDidUpdateNotification;

@interface TLWHomePageController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) TLWHomePageView *homePageView;
@property (nonatomic, assign) BOOL warningExpanded;

@end

@implementation TLWHomePageController


- (void)viewDidLoad {
  [super viewDidLoad];
  [self tl_setHomePageBackView];
  [self tl_setupHomePageView];
  [self fetchUserProfile];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(onAvatarUpdated:)
                                               name:TLWAvatarDidUpdateNotification
                                             object:nil];
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)fetchUserProfile {
  [[TLWSDKManager shared].api getCurrentUserProfileWithCompletionHandler:^(AGResultUserProfileDto *output, NSError *error) {
    dispatch_async(dispatch_get_main_queue(), ^{
      NSString *name = output.data.fullName ?: output.data.username ?: [TLWSDKManager shared].username;
      [self.homePageView configureWithUserName:name];
      if (output.data.avatarUrl.length > 0) {
        [self.homePageView.userAvatarImageView sd_setImageWithURL:[NSURL URLWithString:output.data.avatarUrl]];
      }
    });
  }];
}

- (void)onAvatarUpdated:(NSNotification *)noti {
  UIImage *avatar = noti.userInfo[@"avatar"];
  if (avatar) self.homePageView.userAvatarImageView.image = avatar;
}

- (void)tl_setHomePageBackView {
  UIImage* image = [UIImage imageNamed:@"hp_backView.png"];
  self.view.layer.contents = (__bridge id)image.CGImage;
}

- (void)tl_setupHomePageView {
  self.homePageView.backgroundColor = [UIColor clearColor];
  [self.view addSubview:self.homePageView];
  [self.homePageView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.edges.equalTo(self.view);
  }];
  UITableView *tableView = self.homePageView.tableView;
  tableView.delegate = self;
  tableView.dataSource = self;
  tableView.estimatedRowHeight = 180;
  [tableView registerClass:[TLWHomeCardCell class] forCellReuseIdentifier:@"kTLWHomeCardCellIdentifier1"];
  [tableView registerClass:[TLWHomeCardCell class] forCellReuseIdentifier:@"kTLWHomeCardCellIdentifier2"];
  [tableView registerClass:[TLWHomeCustomCell class] forCellReuseIdentifier:@"kTLWHomeCustomCellIdentifier"];
  tableView.estimatedRowHeight = 160.0;
}

- (TLWHomePageView *)homePageView {
  if (!_homePageView) {
    _homePageView = [[TLWHomePageView alloc] initWithFrame:CGRectZero];
  }
  return _homePageView;
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return 4;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  if (indexPath.row == 0) {
    TLWHomeCardCell *cell = [tableView dequeueReusableCellWithIdentifier:@"kTLWHomeCardCellIdentifier1" forIndexPath:indexPath];
    NSString* str = @"预计24小时内,我区地面最低温将降至-5℃以下,农作物面临严重冻害风险。请农户立即…面最低预计24小时内,我区地面最低温将降至-5℃以下,农作物面临严重冻害风险。请农户立即…面最低预计24小时内,我区地面最低温将降至-5℃以下,农作物面临严重冻害风险。请农户立即…面最低预计24小时内,我区地面最低温将降至-5℃以下,农作物面临严重冻害风险。请农户立即…面最低";
    TLWWarningModel* textModel = [[TLWWarningModel alloc] init];
    textModel.string = str;
    // 注意：此时 cell 还没布局，bodyLabel.frame.width 为 0，不能直接使用
    // 用 tableView 宽度减去左右内边距，近似计算 bodyLabel 可用宽度
    CGFloat tableWidth = CGRectGetWidth(tableView.bounds);
    // contentView 左右各 16，正文内部左 16、右 8，对应 TLWHomeCardCell 中的约束
    CGFloat bodyWidth = tableWidth - 16.0 - 16.0 - 16.0 - 8.0;
    textModel.shouldExpand = [self isTextViewExceedThreeLines:str width:bodyWidth];
    [cell tl_configureWithWarning:textModel];
    [cell tl_configureWarningExpanded:self.warningExpanded];
    __weak typeof(self) weakSelf = self;
    cell.clickWarningDetail = ^{
      __strong typeof(weakSelf) strongSelf = weakSelf;
      if (!strongSelf) {
        return;
      }
      strongSelf.warningExpanded = !strongSelf.warningExpanded;
      NSIndexPath *ip = [NSIndexPath indexPathForRow:0 inSection:0];
      [tableView beginUpdates];
      [tableView reloadRowsAtIndexPaths:@[ip] withRowAnimation:UITableViewRowAnimationNone];
      [tableView endUpdates];
    };
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
  } else if (indexPath.row == 1) {
    TLWHomeCardCell *cell = [tableView dequeueReusableCellWithIdentifier:@"kTLWHomeCardCellIdentifier2" forIndexPath:indexPath];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    __weak typeof(self) weakSelf = self;
    cell.clickPhotoIdentification = ^{
      TLWIdentifyPageController* identifyViewController = [[TLWIdentifyPageController alloc] init];
      identifyViewController.hidesBottomBarWhenPushed = YES;
      [weakSelf.navigationController pushViewController:identifyViewController animated:YES];
    };
    cell.clickRecordCard = ^{
      TLWRecordController *recordVC = [[TLWRecordController alloc] init];
      recordVC.hidesBottomBarWhenPushed = YES;
      [weakSelf.navigationController pushViewController:recordVC animated:YES];
    };
    cell.clickAIAssistant = ^{
      TLWAIAssistantController *aiVC = [[TLWAIAssistantController alloc] initWithInitialQuestion:nil];
      [weakSelf.navigationController pushViewController:aiVC animated:YES];
    };
    return cell;
  }
  TLWHomeCustomCell *cell = [tableView dequeueReusableCellWithIdentifier:@"kTLWHomeCustomCellIdentifier" forIndexPath:indexPath];
  return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  if (indexPath.row == 0) {
    return UITableViewAutomaticDimension;
  } else if (indexPath.row == 1) {
    // 功能入口卡片（拍照识别区域需要更高，保证正方形比例和留白）
    return 210.0;
  } else {
    // 其他自定义 cell
    return 300.0;
  }
}


- (BOOL)isTextViewExceedThreeLines:(NSString *)text width:(CGFloat)width {
  NSTextStorage *storage = [[NSTextStorage alloc] initWithString:text attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:16]}];//管理文本内容和属性
  NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];//将字符转换为字形，管理文本的布局过程
  NSTextContainer *container = [[NSTextContainer alloc] initWithSize:CGSizeMake(width, CGFLOAT_MAX)];//定义文本的可占据区域
  container.lineFragmentPadding = 0;
  [layoutManager addTextContainer:container];
  [storage addLayoutManager:layoutManager];
  NSUInteger glyphCount = [layoutManager numberOfGlyphs];
  __block NSInteger lines = 0;
  [layoutManager enumerateLineFragmentsForGlyphRange:NSMakeRange(0, glyphCount) usingBlock:^(CGRect rect, CGRect usedRect, NSTextContainer * _Nonnull textContainer, NSRange glyphRange, BOOL * _Nonnull stop) {
    lines++;
    if (lines > 3) {
      *stop = YES;
    }
  }];
  return lines > 3;
}


/*
 #pragma mark - Navigation

 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
