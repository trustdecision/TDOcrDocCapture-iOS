//
//  TDOcrDocResultViewController.m
//  TDOcrDocCapture
//
//  Created by LEE on 7/25/24.
//

#import "TDOcrDocResultViewController.h"
#import <Photos/Photos.h>

@interface TDOcrDocResultViewController ()

@property(nonatomic,strong)UIImage* contentImage;

@end

@implementation TDOcrDocResultViewController

- (BOOL)shouldAutorotate {
    return NO;
}

-(UIInterfaceOrientationMask)supportedInterfaceOrientations{
    return UIInterfaceOrientationMaskPortrait;
}

-(UIInterfaceOrientation)preferredInterfaceOrientationForPresentation{
    return UIInterfaceOrientationPortrait;
}

-(instancetype)initWithContentImage:(UIImage*)contentImage
{
    if(self = [super init]){
        self.contentImage = contentImage;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self setupUI];
    // Do any additional setup after loading the view.
}

-(void)setupUI
{
    
    UIImageView* contentImageView = [[UIImageView alloc]initWithImage:self.contentImage];
    contentImageView.contentMode = UIViewContentModeScaleAspectFill;
    // 创建一个 CALayer 作为边框
    contentImageView.layer.backgroundColor = [UIColor clearColor].CGColor; // 设置背景色为透明
    contentImageView.layer.cornerRadius = 20.0; // 圆角半径为 10
    contentImageView.layer.borderColor = [UIColor colorWithRed:80/255.0 green:176/255.0 blue:96/255.0 alpha:1].CGColor; // 边框颜色为绿色
    contentImageView.layer.borderWidth = 2.0; // 边框宽度为 1 像素
    

    contentImageView.layer.masksToBounds = YES;

    

    [self.view addSubview:contentImageView];
    contentImageView.translatesAutoresizingMaskIntoConstraints = NO;
    
    NSLayoutConstraint* contentImageViewCenterX2SuperViewCenterX = [NSLayoutConstraint constraintWithItem:contentImageView
                                                                                               attribute:NSLayoutAttributeCenterX
                                                                                               relatedBy:NSLayoutRelationEqual
                                                                                                  toItem:self.view
                                                                                               attribute:NSLayoutAttributeCenterX
                                                                                              multiplier:1
                                                                                                constant:0];
    
    NSLayoutConstraint* contentImageViewCenterY2SuperViewCenterY = [NSLayoutConstraint constraintWithItem:contentImageView
                                                                                               attribute:NSLayoutAttributeCenterY
                                                                                               relatedBy:NSLayoutRelationEqual
                                                                                                  toItem:self.view
                                                                                               attribute:NSLayoutAttributeCenterY
                                                                                              multiplier:1
                                                                                                constant:-100];
    
    NSLayoutConstraint* contentImageViewWidth2SuperViewWidth = [NSLayoutConstraint constraintWithItem:contentImageView
                                                                                           attribute:NSLayoutAttributeWidth
                                                                                           relatedBy:NSLayoutRelationEqual
                                                                                              toItem:self.view
                                                                                           attribute:NSLayoutAttributeWidth
                                                                                          multiplier:0.9
                                                                                            constant:0];
    
    NSLayoutConstraint* contentImageViewWithHeightRatio = [NSLayoutConstraint constraintWithItem:contentImageView
                                                                                      attribute:NSLayoutAttributeHeight
                                                                                      relatedBy:NSLayoutRelationEqual
                                                                                         toItem:contentImageView
                                                                                      attribute:NSLayoutAttributeWidth
                                                                                     multiplier:(2/3.0)
                                                                                       constant:0];
    [self.view addConstraints:@[contentImageViewWidth2SuperViewWidth,contentImageViewCenterX2SuperViewCenterX,contentImageViewCenterY2SuperViewCenterY,contentImageViewWithHeightRatio]];
    
    

    CGFloat buttonMargin = 30;
    CGFloat buttonW = (self.view.bounds.size.width - buttonMargin*3) / 2.0;
    CGFloat buttonH = 44;
    
    UIButton * retryButton = [[UIButton alloc]init];
    retryButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:retryButton];
    [retryButton setTitle:@"Retry" forState:UIControlStateNormal];
    [retryButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    retryButton.backgroundColor = [UIColor colorWithRed:212/255.0 green:211/255.0 blue:218/255.0 alpha:1];
    [retryButton addTarget:self action:@selector(retryButtonClick:) forControlEvents:UIControlEventTouchUpInside];

    retryButton.layer.cornerRadius = buttonH/2.0; // 圆角半径为 10
    retryButton.layer.masksToBounds = YES;
    
    
    
    
    NSLayoutConstraint* retryButtonLeft= [NSLayoutConstraint constraintWithItem:retryButton
                                                                                          attribute:NSLayoutAttributeLeft
                                                                                          relatedBy:NSLayoutRelationEqual
                                                                                             toItem:self.view
                                                                                          attribute:NSLayoutAttributeLeft
                                                                                         multiplier:1
                                                                                           constant:buttonMargin];
    
    NSLayoutConstraint* retryButtonBottom = [NSLayoutConstraint constraintWithItem:retryButton
                                                                                           attribute:NSLayoutAttributeBottom
                                                                                           relatedBy:NSLayoutRelationEqual
                                                                                              toItem:self.view
                                                                                           attribute:NSLayoutAttributeBottom
                                                                                          multiplier:1
                                                                                            constant:-60];
    
    
    NSLayoutConstraint* retryButtonHeight = [NSLayoutConstraint constraintWithItem:retryButton
                                                                         attribute:NSLayoutAttributeHeight
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:nil
                                                                         attribute:NSLayoutAttributeHeight
                                                                        multiplier:1.0
                                                                          constant:buttonH];
    
    [self.view addConstraints:@[retryButtonLeft,retryButtonBottom,retryButtonHeight]];
    
    UIButton * continueButton = [[UIButton alloc]init];
    continueButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:continueButton];
    
    [continueButton addTarget:self action:@selector(continueButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [continueButton setTitle:@"Continue" forState:UIControlStateNormal];
    [continueButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    continueButton.backgroundColor = [UIColor colorWithRed:80/255.0 green:176/255.0 blue:96/255.0 alpha:1];
    
    continueButton.layer.cornerRadius = buttonH/2.0; // 圆角半径为 10
    continueButton.layer.masksToBounds = YES;
    
    
    
    
    NSLayoutConstraint* continueButtonRight = [NSLayoutConstraint constraintWithItem:continueButton
                                                                                          attribute:NSLayoutAttributeRight
                                                                                          relatedBy:NSLayoutRelationEqual
                                                                                             toItem:self.view
                                                                                          attribute:NSLayoutAttributeRight
                                                                                         multiplier:1
                                                                                           constant:-buttonMargin];
    
    NSLayoutConstraint* continueButtonBottom = [NSLayoutConstraint constraintWithItem:continueButton
                                                                                           attribute:NSLayoutAttributeBottom
                                                                                           relatedBy:NSLayoutRelationEqual
                                                                                              toItem:self.view
                                                                                           attribute:NSLayoutAttributeBottom
                                                                                          multiplier:1
                                                                                            constant:-60];
    
    
    
    NSLayoutConstraint* continueButtonLeft = [NSLayoutConstraint constraintWithItem:continueButton
                                                                        attribute:NSLayoutAttributeLeft
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:retryButton
                                                                        attribute:NSLayoutAttributeRight
                                                                       multiplier:1.0
                                                                         constant:buttonMargin];
    
    NSLayoutConstraint* continueButtonWidth = [NSLayoutConstraint constraintWithItem:continueButton
                                                                         attribute:NSLayoutAttributeWidth
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:retryButton
                                                                         attribute:NSLayoutAttributeWidth
                                                                        multiplier:1.0
                                                                          constant:0];
    
    NSLayoutConstraint* continueButtonHeight = [NSLayoutConstraint constraintWithItem:continueButton
                                                                         attribute:NSLayoutAttributeHeight
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:nil
                                                                         attribute:NSLayoutAttributeHeight
                                                                        multiplier:1.0
                                                                          constant:buttonH];
    
    [self.view addConstraints:@[continueButtonLeft,continueButtonBottom,continueButtonRight,continueButtonWidth,continueButtonHeight]];
    
    
}


-(void)retryButtonClick:(UIButton*)button{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)continueButtonClick:(UIButton*)button{
    // 保存裁剪后的图像到相册
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        PHAssetCreationRequest *request = [PHAssetCreationRequest creationRequestForAsset];
        [request addResourceWithType:PHAssetResourceTypePhoto data:UIImagePNGRepresentation(self.contentImage) options:nil];
    } completionHandler:^(BOOL success, NSError *error) {
        if (success) {
            NSLog(@"裁剪后的图像保存成功");
        } else {
            NSLog(@"裁剪后的图像保存失败：%@", error.localizedDescription);
        }
    }];
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
