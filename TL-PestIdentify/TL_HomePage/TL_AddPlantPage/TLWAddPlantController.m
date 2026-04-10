//
//  TLWAddPlantController.m
//  TL-PestIdentify
//
//  Created by xiaoli pop on 2026/4/2.
//

#import "TLWAddPlantController.h"
#import "TLWAddPlantView.h"
#import "TLWImagePickerManager.h"
#import <Masonry/Masonry.h>

@interface TLWAddPlantController () <TLWImagePickerDelegate>

@property (nonatomic, strong) TLWAddPlantView *myView;
@property (nonatomic, strong) UITapGestureRecognizer *dismissKeyboardTapGesture;
@property (nonatomic, strong) TLWImagePickerManager *imagePickerManager;
@property (nonatomic, strong, nullable) UIImage *selectedPlantImage;

@end

@implementation TLWAddPlantController

- (void)viewDidLoad {
  [super viewDidLoad];
  self.view.backgroundColor = [UIColor clearColor];

  TLWAddPlantView *myView = [[TLWAddPlantView alloc] initWithFrame:CGRectZero];
  [self.view addSubview:myView];
  [myView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.edges.equalTo(self.view);
  }];
  self.myView = myView;

  [self.myView.backButton addTarget:self action:@selector(tl_backTapped) forControlEvents:UIControlEventTouchUpInside];
  [self.myView.createButton addTarget:self action:@selector(tl_createTapped) forControlEvents:UIControlEventTouchUpInside];
  [self.myView.contentCardButton addTarget:self action:@selector(tl_addImageTapped) forControlEvents:UIControlEventTouchUpInside];
  [self.myView.confirmButton addTarget:self action:@selector(tl_confirmTapped) forControlEvents:UIControlEventTouchUpInside];
  [self tl_setupDismissKeyboardGesture];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [self.navigationController setNavigationBarHidden:YES animated:animated];
  self.navigationController.interactivePopGestureRecognizer.delegate = nil;
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
}

- (void)tl_backTapped {
  if (self.navigationController) {
    [self.navigationController popViewControllerAnimated:YES];
  } else {
    [self dismissViewControllerAnimated:YES completion:nil];
  }
}

- (void)tl_createTapped {
  [self tl_openAlbum];
}

- (void)tl_addImageTapped {
  [self tl_openAlbum];
}

- (void)tl_confirmTapped {
  NSString *plantName = [self.myView.plantNameTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
  if (plantName.length == 0) {
    [self tl_showAlertWithMessage:@"请输入种植物名称"];
    return;
  }
  if (!self.selectedPlantImage) {
    [self tl_showAlertWithMessage:@"请选择种植物图片"];
    return;
  }
  if (self.onConfirmAddPlant) {
    self.onConfirmAddPlant(plantName, self.selectedPlantImage);
  }
  [self tl_backTapped];
}

- (void)tl_setupDismissKeyboardGesture {
  UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tl_dismissKeyboard)];
  tapGesture.cancelsTouchesInView = NO;
  [self.view addGestureRecognizer:tapGesture];
  self.dismissKeyboardTapGesture = tapGesture;
}

- (void)tl_dismissKeyboard {
  [self.view endEditing:YES];
}

- (void)tl_openAlbum {
  self.imagePickerManager.maxCount = 1;
  self.imagePickerManager.delegate = self;
  [self.imagePickerManager openAlbumFrom:self];
}

- (TLWImagePickerManager *)imagePickerManager {
  if (!_imagePickerManager) {
    _imagePickerManager = [[TLWImagePickerManager alloc] init];
  }
  return _imagePickerManager;
}

- (void)imagePicker:(TLWImagePickerManager *)picker didSelectImage:(UIImage *)image {
  self.selectedPlantImage = image;
  [self.myView updateSelectedPlantImage:image];
}

- (void)tl_showAlertWithMessage:(NSString *)message {
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
  [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
  [self presentViewController:alert animated:YES completion:nil];
}

@end
