//
//  TLWPostDetailController.m
//  TL-PestIdentify
//

#import "TLWPostDetailController.h"
#import "TLWCommunityPost.h"
#import "TLWPostDetailHeaderView.h"
#import "TLWCommentCell.h"
#import <Masonry/Masonry.h>
#import <objc/runtime.h>
#import <AgriPestClient/AGCommentResponseDto.h>
#import "TLWSDKManager.h"

static NSString *const kCommentCellID = @"TLWCommentCell";

@interface TLWPostDetailController () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) TLWPostDetailHeaderView *headerView;
@property (nonatomic, strong) NSMutableArray<AGCommentResponseDto *> *comments;

// Nav bar reference
@property (nonatomic, strong) UIView *navBarView;

// Bottom input bar
@property (nonatomic, strong) UIView *inputBar;
@property (nonatomic, strong) UITextField *commentTextField;
@property (nonatomic, strong) UIButton *sendButton;
@property (nonatomic, strong) UIButton *likeButton;


@property (nonatomic, assign) NSInteger likeCount;
@property (nonatomic, assign) BOOL liked;

// 分页加载
@property (nonatomic, assign) NSInteger currentPage;
@property (nonatomic, assign) BOOL isLoadingComments;
@property (nonatomic, assign) BOOL hasMoreComments;
@property (nonatomic, strong) UIActivityIndicatorView *footerSpinner;

@end

@implementation TLWPostDetailController

- (void)viewDidLoad {
  [super viewDidLoad];
  [self tl_setHomePageBackView];
  self.view.backgroundColor = [UIColor whiteColor];
  [self buildNavBar];
  [self buildTableView];
  [self buildInputBar];
  [self loadComments];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChange:) name:UIKeyboardWillChangeFrameNotification object:nil];
}

- (void)tl_setHomePageBackView {
  UIImage* image = [UIImage imageNamed:@"hp_backView.png"];
  self.view.layer.contents = (__bridge id)image.CGImage;
}


- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  // 详情页使用自定义导航栏，隐藏系统 navigationBar
  [self.navigationController setNavigationBarHidden:YES animated:NO];
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  // 返回时保持隐藏，由社区页自行管理（社区页也使用自定义导航栏）
  // 不在此处调用 setNavigationBarHidden:NO，避免系统重新计算 contentInset 导致布局偏移
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Build UI

- (void)buildNavBar {
  UIView *navBar = [[UIView alloc] init];
  navBar.backgroundColor = [UIColor clearColor];
  [self.view addSubview:navBar];
  [navBar mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.left.right.equalTo(self.view);
    make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(50);
  }];

  UIButton *backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
  [backBtn setImage:[UIImage imageNamed:@"iconBack"] forState:UIControlStateNormal];
  backBtn.imageView.contentMode = UIViewContentModeScaleAspectFit;
  [backBtn addTarget:self action:@selector(backTapped) forControlEvents:UIControlEventTouchUpInside];
  [navBar addSubview:backBtn];
  [backBtn mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.equalTo(navBar).offset(12);
    make.bottom.equalTo(navBar).offset(-8);
    make.width.height.mas_equalTo(45);
  }];

  UILabel *titleLbl = [[UILabel alloc] init];
  titleLbl.text = @"帖子";
  titleLbl.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
  titleLbl.textColor = [UIColor whiteColor];
  [navBar addSubview:titleLbl];
  [titleLbl mas_makeConstraints:^(MASConstraintMaker *make) {
    make.centerX.equalTo(navBar).offset(-10);
    make.centerY.equalTo(backBtn).offset(-5);
  }];

  UIImageView* iconView = [[UIImageView alloc] init];
  iconView.image = [[UIImage imageNamed:@"cp_post.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
  [navBar addSubview:iconView];
  [iconView mas_makeConstraints:^(MASConstraintMaker *make) {
      make.left.equalTo(titleLbl.mas_right).offset(2);
      make.centerY.equalTo(titleLbl.mas_centerY);
    make.height.width.mas_equalTo(17);
  }];

  UIView *line = [[UIView alloc] init];
  line.backgroundColor = [UIColor colorWithWhite:0.92 alpha:1.0];
  [navBar addSubview:line];
  [line mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.right.bottom.equalTo(navBar);
    make.height.mas_equalTo(0.5);
  }];


  self.navBarView = navBar;
}

- (void)buildTableView {
  UIView *navBar = self.navBarView;
  self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
  self.tableView.dataSource = self;
  self.tableView.delegate = self;
  self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
  self.tableView.backgroundColor = [UIColor whiteColor];
  self.tableView.estimatedRowHeight = 80;
  self.tableView.rowHeight = UITableViewAutomaticDimension;
  [self.tableView registerClass:[TLWCommentCell class] forCellReuseIdentifier:kCommentCellID];
  [self.view addSubview:self.tableView];
  [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(navBar.mas_bottom);
    make.left.right.equalTo(self.view);
    make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-56);
  }];

  // Header view — tableHeaderView 必须用 frame 驱动，先设置正确尺寸再赋值
  CGFloat screenW = [UIScreen mainScreen].bounds.size.width;
  CGFloat headerH = self.post ? [TLWPostDetailHeaderView heightForPost:self.post] : 600;
  self.headerView = [[TLWPostDetailHeaderView alloc] initWithFrame:CGRectMake(0, 0, screenW, headerH)];
  self.headerView.translatesAutoresizingMaskIntoConstraints = YES;
  if (self.post) {
    [self.headerView configureWithPost:self.post];
    // configureWithPost 之后内容确定，重新计算精确高度并刷新 tableHeaderView
    CGFloat finalH = [TLWPostDetailHeaderView heightForPost:self.post];
    self.headerView.frame = CGRectMake(0, 0, screenW, finalH);
    self.tableView.tableHeaderView = self.headerView;
  } else {
    self.tableView.tableHeaderView = self.headerView;
  }
}

- (void)buildInputBar {
  self.inputBar = [[UIView alloc] init];
  self.inputBar.backgroundColor = [UIColor whiteColor];
  self.inputBar.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.08].CGColor;
  self.inputBar.layer.shadowOpacity = 1.0;
  self.inputBar.layer.shadowOffset = CGSizeMake(0, -1);
  self.inputBar.layer.shadowRadius = 4.0;
  self.inputBar.layer.masksToBounds = YES;
  self.inputBar.layer.cornerRadius = 28;
  [self.view addSubview:self.inputBar];
  [self.inputBar mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.equalTo(self.view.mas_left).offset(10);
    make.right.equalTo(self.view.mas_right).offset(-10);
    make.bottom.equalTo(self.view.mas_bottom).offset(-30);
    make.height.mas_equalTo(56);
  }];

  // Like button
  self.likeButton = [UIButton buttonWithType:UIButtonTypeCustom];
  [self.likeButton setImage:[UIImage imageNamed:@"cp_capture.png"] forState:UIControlStateNormal];
  self.likeButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
  [self.likeButton addTarget:self action:@selector(likeTapped) forControlEvents:UIControlEventTouchUpInside];
  [self.inputBar addSubview:self.likeButton];
  [self.likeButton mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.equalTo(self.inputBar).offset(14);
    make.centerY.equalTo(self.inputBar);
    make.width.height.mas_equalTo(32);
  }];

  // Comment field
  UIView *fieldBg = [[UIView alloc] init];
  fieldBg.backgroundColor = [UIColor colorWithWhite:0.96 alpha:1.0];
  fieldBg.layer.cornerRadius = 18.0;
  [self.inputBar addSubview:fieldBg];

  self.commentTextField = [[UITextField alloc] init];
  self.commentTextField.placeholder = @"说点什么…";
  self.commentTextField.font = [UIFont systemFontOfSize:14];
  self.commentTextField.returnKeyType = UIReturnKeySend;
  self.commentTextField.delegate = self;
  [fieldBg addSubview:self.commentTextField];

  [self.commentTextField mas_makeConstraints:^(MASConstraintMaker *make) {
    make.edges.equalTo(fieldBg).insets(UIEdgeInsetsMake(0, 14, 0, 14));
  }];

  // Send button
  self.sendButton = [UIButton buttonWithType:UIButtonTypeCustom];
  [self.sendButton setTitle:@"发送" forState:UIControlStateNormal];
  [self.sendButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
  self.sendButton.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
  self.sendButton.backgroundColor = [UIColor colorWithRed:0.18 green:0.72 blue:0.45 alpha:1.0];
  self.sendButton.layer.cornerRadius = 16.0;
  [self.sendButton addTarget:self action:@selector(sendComment) forControlEvents:UIControlEventTouchUpInside];
  [self.inputBar addSubview:self.sendButton];

  [self.sendButton mas_makeConstraints:^(MASConstraintMaker *make) {
    make.right.equalTo(self.inputBar).offset(-14);
    make.centerY.equalTo(self.inputBar);
    make.width.mas_equalTo(56);
    make.height.mas_equalTo(32);
  }];
  [fieldBg mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.equalTo(self.likeButton.mas_right).offset(10);
    make.right.equalTo(self.sendButton.mas_left).offset(-10);
    make.centerY.equalTo(self.inputBar);
    make.height.mas_equalTo(36);
  }];
}

- (void)loadComments {
  self.comments = [NSMutableArray array];
  self.currentPage = 0;
  self.hasMoreComments = YES;
  self.isLoadingComments = NO;
  [self.tableView reloadData];
  [self fetchCommentsPage:0];
}

- (void)fetchCommentsPage:(NSInteger)page {
  if (!self.post._id || self.isLoadingComments || !self.hasMoreComments) return;
  self.isLoadingComments = YES;

  // 显示底部加载指示器
  if (page > 0) {
    [self.footerSpinner startAnimating];
    self.tableView.tableFooterView = self.footerSpinner;
  }

  [[TLWSDKManager shared] getCommentsWithId:self.post._id
                                       page:@(page)
                                       size:@20
                          completionHandler:^(AGResultPageResultCommentResponseDto *output, NSError *error) {
    dispatch_async(dispatch_get_main_queue(), ^{
      self.isLoadingComments = NO;
      self.tableView.tableFooterView = nil;
      [self.footerSpinner stopAnimating];

      if (error || !output || output.code.integerValue != 200) {
        NSLog(@"[Comments] 获取评论失败: %@", error.localizedDescription ?: output.message);
        return;
      }

      NSArray *list = output.data.list;
      // 判断是否还有更多页
      self.hasMoreComments = output.data.hasNext.boolValue;

      if (list.count > 0) {
        if (page == 0) {
          [self.comments setArray:list];
          [self.tableView reloadData];
        } else {
          NSInteger oldCount = self.comments.count;
          [self.comments addObjectsFromArray:list];
          NSMutableArray<NSIndexPath *> *indexPaths = [NSMutableArray array];
          for (NSInteger i = oldCount; i < self.comments.count; i++) {
            [indexPaths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
          }
          [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
        }
        self.currentPage = page;
      } else if (page == 0) {
        [self.tableView reloadData];
      }
    });
  }];
}

- (UIActivityIndicatorView *)footerSpinner {
  if (!_footerSpinner) {
    _footerSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    _footerSpinner.frame = CGRectMake(0, 0, self.tableView.bounds.size.width, 44);
    _footerSpinner.color = [UIColor colorWithWhite:0.6 alpha:1.0];
  }
  return _footerSpinner;
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return self.comments.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  TLWCommentCell *cell = [tableView dequeueReusableCellWithIdentifier:kCommentCellID forIndexPath:indexPath];
  [cell configureWithComment:self.comments[indexPath.row]];
  return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return UITableViewAutomaticDimension;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
  CGFloat contentH = scrollView.contentSize.height;
  CGFloat offsetY  = scrollView.contentOffset.y;
  CGFloat frameH   = scrollView.bounds.size.height;
  // 距底部 80pt 时触发加载下一页
  if (contentH > frameH && offsetY > contentH - frameH - 80) {
    [self fetchCommentsPage:self.currentPage + 1];
  }
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  [self sendComment];
  return YES;
}

#pragma mark - Actions

- (void)backTapped {
  if (self.navigationController) {
    [self.navigationController popViewControllerAnimated:YES];
  } else {
    [self dismissViewControllerAnimated:YES completion:nil];
  }
}

- (void)likeTapped {
  self.liked = !self.liked;
  UIColor *activeColor = [UIColor colorWithRed:1.0 green:0.35 blue:0.35 alpha:1.0];
  UIColor *inactiveColor = [UIColor colorWithWhite:0.6 alpha:1.0];
  self.likeButton.tintColor = self.liked ? activeColor : inactiveColor;
  // Bounce animation
  [UIView animateWithDuration:0.12 animations:^{
    self.likeButton.transform = CGAffineTransformMakeScale(1.35, 1.35);
  } completion:^(BOOL fin) {
    [UIView animateWithDuration:0.12 animations:^{
      self.likeButton.transform = CGAffineTransformIdentity;
    }];
  }];
}

- (void)sendComment {
  NSString *text = [self.commentTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
  if (text.length == 0) return;

  // 禁用发送按钮，防止重复提交
  self.sendButton.enabled = NO;
  NSNumber *postId = self.post._id;
  [[TLWSDKManager shared] addCommentWithId:postId content:text completionHandler:^(AGResultCommentResponseDto *output, NSError *error) {
    dispatch_async(dispatch_get_main_queue(), ^{
      self.sendButton.enabled = YES;
      if (error || !output || output.code.integerValue != 200) {
        NSString *msg = output.message.length > 0 ? output.message : @"评论发送失败，请稍后重试";
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"发送失败" message:msg preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
      }
      // 使用服务端返回的评论对象插入列表
      AGCommentResponseDto *newComment = output.data;
      if (!newComment) {
        // 服务端未返回 data，本地构造占位
        newComment = [[AGCommentResponseDto alloc] init];
        newComment.authorName = [TLWSDKManager shared].username ?: @"我";
        newComment.content    = text;
        newComment.createdAt  = [NSDate date];
      }
      [self.comments insertObject:newComment atIndex:0];
      [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationTop];
      self.commentTextField.text = @"";
      [self.commentTextField resignFirstResponder];
      [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
    });
  }];
}

#pragma mark - Keyboard

- (void)keyboardWillChange:(NSNotification *)note {
  CGRect endFrame = [note.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
  CGFloat duration = [note.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
  CGFloat keyboardH = [UIScreen mainScreen].bounds.size.height - endFrame.origin.y;
  CGFloat safeBottom = self.view.safeAreaInsets.bottom;
  CGFloat offset = MAX(0, keyboardH - safeBottom);
  [UIView animateWithDuration:duration animations:^{
    self.inputBar.transform = CGAffineTransformMakeTranslation(0, -offset);
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, offset + 56, 0);
  }];
}

@end
