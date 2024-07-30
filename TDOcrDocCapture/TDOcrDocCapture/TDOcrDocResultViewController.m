//
//  TDOcrDocResultViewController.m
//  TDOcrDocCapture
//
//  Created by LEE on 7/22/24.
//

#import "TDOcrDocResultViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <Photos/Photos.h>

// UI
#define WIDTH [UIScreen mainScreen].bounds.size.width
#define HEIGHT [UIScreen mainScreen].bounds.size.height

//由角度转换弧度
#define kDegreesToRadian(x)      (M_PI * (x) / 180.0)

@interface TDOcrDocResultViewController ()<AVCapturePhotoCaptureDelegate>

@property(nonatomic, strong) UIImage* contentImage;

@property (nonatomic, copy) CompletionBlock completionBlock;

@property (nonatomic, assign) UIDeviceOrientation capturedOrientation;

@property (nonatomic, strong) UIImageView* idMaskImageView;

@end

@implementation TDOcrDocResultViewController

-(instancetype)initWithOrientation:(UIDeviceOrientation)orientation ContentImage:(UIImage*)contentImage Completion:(nonnull CompletionBlock)completionBlock
{
    if(self = [super init]){
        self.capturedOrientation = orientation;
        self.contentImage = contentImage;
        self.completionBlock = completionBlock;
    }
    return self;
}

-(BOOL)shouldAutorotate{
    return NO;
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self refreshUI:self.capturedOrientation];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
}

-(void)refreshUI:(UIDeviceOrientation)orientation
{
    CGFloat width = self.view.bounds.size.width;
    CGFloat height = self.view.bounds.size.height;
    
    
    BOOL isPortrait = width < height;
    
    if(orientation == UIDeviceOrientationLandscapeLeft || orientation == UIDeviceOrientationLandscapeRight){
        isPortrait = NO;
        
    }else if(orientation == UIDeviceOrientationPortrait){
        isPortrait = YES;
        
    }else if(orientation == UIDeviceOrientationPortraitUpsideDown){
        
        if(width < height){
            isPortrait = YES;
        }else{
            isPortrait = NO;
        }
        
    }
    
    
    [self refreshWithIsPortrait:isPortrait];
    
    if(orientation == UIDeviceOrientationLandscapeRight){
        // 设置预览图层的方向为横屏
        
    }else if(orientation == UIDeviceOrientationLandscapeLeft){
        
    }else if(orientation == UIDeviceOrientationPortrait){
    }
    else if(orientation == UIDeviceOrientationPortraitUpsideDown){

    }else{
        
    }
    
}

-(void)refreshWithIsPortrait:(BOOL)isPortrait{
    [self.view.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj removeFromSuperview];
    }];
    
    [self.view removeConstraints:self.view.constraints];
    
    
    
    UIView* maskView = [[UIView alloc]init];
    [self.view addSubview:maskView];
    maskView.translatesAutoresizingMaskIntoConstraints = NO;
    
    
    UIImageView* idMaskImageView = [[UIImageView alloc]initWithImage:self.contentImage];
    idMaskImageView.contentMode = UIViewContentModeScaleAspectFill;
    // 创建一个 CALayer 作为边框
    idMaskImageView.layer.backgroundColor = [UIColor clearColor].CGColor; // 设置背景色为透明
    idMaskImageView.layer.cornerRadius = 20.0; // 圆角半径为 10
    idMaskImageView.layer.borderColor = [UIColor colorWithRed:80/255.0 green:176/255.0 blue:96/255.0 alpha:1].CGColor; // 边框颜色为绿色
    idMaskImageView.layer.borderWidth = 2.0; // 边框宽度为 1 像素
    idMaskImageView.layer.masksToBounds = YES;


    
    self.idMaskImageView = idMaskImageView;
    [maskView addSubview:idMaskImageView];
    idMaskImageView.translatesAutoresizingMaskIntoConstraints = NO;
    
    NSLayoutConstraint* idMaskImageViewCenterX2SuperViewCenterX = [NSLayoutConstraint constraintWithItem:idMaskImageView
                                                                                               attribute:NSLayoutAttributeCenterX
                                                                                               relatedBy:NSLayoutRelationEqual
                                                                                                  toItem:maskView
                                                                                               attribute:NSLayoutAttributeCenterX
                                                                                              multiplier:1
                                                                                                constant:0];
    
    NSLayoutConstraint* idMaskImageViewCenterY2SuperViewCenterY = [NSLayoutConstraint constraintWithItem:idMaskImageView
                                                                                               attribute:NSLayoutAttributeCenterY
                                                                                               relatedBy:NSLayoutRelationEqual
                                                                                                  toItem:maskView
                                                                                               attribute:NSLayoutAttributeCenterY
                                                                                              multiplier:1
                                                                                                constant:0];
    
    UIView* bottomView = [[UIView alloc]init];
    [self.view addSubview:bottomView];
    bottomView.translatesAutoresizingMaskIntoConstraints = NO;
    

    
    CGFloat buttonMargin = 30;
    CGFloat buttonH = 44;
    
    UIButton * retryButton = [[UIButton alloc]init];
    retryButton.translatesAutoresizingMaskIntoConstraints = NO;
    [bottomView addSubview:retryButton];
    [retryButton setTitle:@"Retry" forState:UIControlStateNormal];
    [retryButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    retryButton.backgroundColor = [UIColor colorWithRed:212/255.0 green:211/255.0 blue:218/255.0 alpha:1];
    [retryButton addTarget:self action:@selector(retryButtonClick:) forControlEvents:UIControlEventTouchUpInside];

    retryButton.layer.cornerRadius = buttonH/2.0; // 圆角半径为 10
    retryButton.layer.masksToBounds = YES;
    
    
    UIButton * continueButton = [[UIButton alloc]init];
    continueButton.translatesAutoresizingMaskIntoConstraints = NO;
    [bottomView addSubview:continueButton];
    
    [continueButton addTarget:self action:@selector(continueButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [continueButton setTitle:@"Continue" forState:UIControlStateNormal];
    [continueButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    continueButton.backgroundColor = [UIColor colorWithRed:80/255.0 green:176/255.0 blue:96/255.0 alpha:1];
    
    continueButton.layer.cornerRadius = buttonH/2.0; // 圆角半径为 10
    continueButton.layer.masksToBounds = YES;
    
    
    // 动态旋转的时候处理
    if(isPortrait){
        
        NSLayoutConstraint* idMaskImageViewWidth2SuperViewWidth = [NSLayoutConstraint constraintWithItem:idMaskImageView
                                                                                               attribute:NSLayoutAttributeWidth
                                                                                               relatedBy:NSLayoutRelationEqual
                                                                                                  toItem:maskView
                                                                                               attribute:NSLayoutAttributeWidth
                                                                                              multiplier:0.9
                                                                                                constant:0];
        
        NSLayoutConstraint* idMaskImageViewWithHeightRatio = [NSLayoutConstraint constraintWithItem:idMaskImageView
                                                                                          attribute:NSLayoutAttributeHeight
                                                                                          relatedBy:NSLayoutRelationEqual
                                                                                             toItem:idMaskImageView
                                                                                          attribute:NSLayoutAttributeWidth
                                                                                         multiplier:(2/3.0)
                                                                                           constant:0];
        [maskView addConstraints:@[idMaskImageViewWidth2SuperViewWidth,idMaskImageViewCenterX2SuperViewCenterX,idMaskImageViewCenterY2SuperViewCenterY,idMaskImageViewWithHeightRatio]];
                
                
        
        
        NSLayoutConstraint* maskViewTop2SuperViewTop = [NSLayoutConstraint constraintWithItem:maskView
                                                                                    attribute:NSLayoutAttributeTop
                                                                                    relatedBy:NSLayoutRelationEqual
                                                                                       toItem:self.view
                                                                                    attribute:NSLayoutAttributeTop
                                                                                   multiplier:1
                                                                                     constant:0];
        
        NSLayoutConstraint* maskViewHeight2SuperViewHeight = [NSLayoutConstraint constraintWithItem:maskView
                                                                                          attribute:NSLayoutAttributeHeight
                                                                                          relatedBy:NSLayoutRelationEqual
                                                                                             toItem:self.view
                                                                                          attribute:NSLayoutAttributeHeight
                                                                                         multiplier:0.8
                                                                                           constant:0];
        
        NSLayoutConstraint* maskViewLeft2SuperViewLeft = [NSLayoutConstraint constraintWithItem:maskView
                                                                                      attribute:NSLayoutAttributeLeft
                                                                                      relatedBy:NSLayoutRelationEqual
                                                                                         toItem:self.view
                                                                                      attribute:NSLayoutAttributeLeft
                                                                                     multiplier:1
                                                                                       constant:0];
        
        NSLayoutConstraint* maskViewRight2SuperViewRight = [NSLayoutConstraint constraintWithItem:maskView
                                                                                        attribute:NSLayoutAttributeRight
                                                                                        relatedBy:NSLayoutRelationEqual
                                                                                           toItem:self.view
                                                                                        attribute:NSLayoutAttributeRight
                                                                                       multiplier:1
                                                                                         constant:0];
        [self.view addConstraints:@[maskViewTop2SuperViewTop,maskViewHeight2SuperViewHeight,maskViewLeft2SuperViewLeft,maskViewRight2SuperViewRight]];
        
        
        NSLayoutConstraint* bottomViewTop2MaskViewBottom = [NSLayoutConstraint constraintWithItem:bottomView
                                                                                        attribute:NSLayoutAttributeTop
                                                                                        relatedBy:NSLayoutRelationEqual
                                                                                           toItem:maskView
                                                                                        attribute:NSLayoutAttributeBottom
                                                                                       multiplier:1
                                                                                         constant:0];
        
        NSLayoutConstraint* bottomViewLeft2SuperViewLeft = [NSLayoutConstraint constraintWithItem:bottomView
                                                                                        attribute:NSLayoutAttributeLeft
                                                                                        relatedBy:NSLayoutRelationEqual
                                                                                           toItem:self.view
                                                                                        attribute:NSLayoutAttributeLeft
                                                                                       multiplier:1
                                                                                         constant:0];
        
        NSLayoutConstraint* bottomViewRight2SuperViewRight = [NSLayoutConstraint constraintWithItem:bottomView
                                                                                          attribute:NSLayoutAttributeRight
                                                                                          relatedBy:NSLayoutRelationEqual
                                                                                             toItem:self.view
                                                                                          attribute:NSLayoutAttributeRight
                                                                                         multiplier:1
                                                                                           constant:0];
        
        NSLayoutConstraint* bottomViewBottom2SuperViewBottom = [NSLayoutConstraint constraintWithItem:bottomView
                                                                                            attribute:NSLayoutAttributeBottom
                                                                                            relatedBy:NSLayoutRelationEqual
                                                                                               toItem:self.view
                                                                                            attribute:NSLayoutAttributeBottom
                                                                                           multiplier:1
                                                                                             constant:0];
        
        [self.view addConstraints:@[bottomViewTop2MaskViewBottom,bottomViewLeft2SuperViewLeft,bottomViewRight2SuperViewRight,bottomViewBottom2SuperViewBottom]];
        
        
        NSLayoutConstraint* retryButtonLeft= [NSLayoutConstraint constraintWithItem:retryButton
                                                                                              attribute:NSLayoutAttributeLeft
                                                                                              relatedBy:NSLayoutRelationEqual
                                                                                                 toItem:bottomView
                                                                                              attribute:NSLayoutAttributeLeft
                                                                                             multiplier:1
                                                                                               constant:buttonMargin];
        
        NSLayoutConstraint* retryButtonBottom = [NSLayoutConstraint constraintWithItem:retryButton
                                                                                               attribute:NSLayoutAttributeBottom
                                                                                               relatedBy:NSLayoutRelationEqual
                                                                                                  toItem:bottomView
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
        
        [bottomView addConstraints:@[retryButtonLeft,retryButtonBottom,retryButtonHeight]];
        
        NSLayoutConstraint* continueButtonRight = [NSLayoutConstraint constraintWithItem:continueButton
                                                                                              attribute:NSLayoutAttributeRight
                                                                                              relatedBy:NSLayoutRelationEqual
                                                                                                 toItem:bottomView
                                                                                              attribute:NSLayoutAttributeRight
                                                                                             multiplier:1
                                                                                               constant:-buttonMargin];
        
        NSLayoutConstraint* continueButtonBottom = [NSLayoutConstraint constraintWithItem:continueButton
                                                                                               attribute:NSLayoutAttributeBottom
                                                                                               relatedBy:NSLayoutRelationEqual
                                                                                                  toItem:bottomView
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
        
        [bottomView addConstraints:@[continueButtonLeft,continueButtonBottom,continueButtonRight,continueButtonWidth,continueButtonHeight]];
        
    }else{
        
        NSLayoutConstraint* idMaskImageViewWidth2SuperViewWidth = [NSLayoutConstraint constraintWithItem:idMaskImageView
                                                                                               attribute:NSLayoutAttributeHeight
                                                                                               relatedBy:NSLayoutRelationEqual
                                                                                                  toItem:maskView
                                                                                               attribute:NSLayoutAttributeHeight
                                                                                              multiplier:0.9
                                                                                                constant:0];
        
        NSLayoutConstraint* idMaskImageViewWithHeightRatio = [NSLayoutConstraint constraintWithItem:idMaskImageView
                                                                                          attribute:NSLayoutAttributeHeight
                                                                                          relatedBy:NSLayoutRelationEqual
                                                                                             toItem:idMaskImageView
                                                                                          attribute:NSLayoutAttributeWidth
                                                                                         multiplier:(2/3.0)
                                                                                           constant:0];
        [maskView addConstraints:@[idMaskImageViewWidth2SuperViewWidth,idMaskImageViewCenterX2SuperViewCenterX,idMaskImageViewCenterY2SuperViewCenterY,idMaskImageViewWithHeightRatio]];
                
        
        NSLayoutConstraint* maskViewTop2SuperViewTop = [NSLayoutConstraint constraintWithItem:maskView
                                                                                    attribute:NSLayoutAttributeTop
                                                                                    relatedBy:NSLayoutRelationEqual
                                                                                       toItem:self.view
                                                                                    attribute:NSLayoutAttributeTop
                                                                                   multiplier:1
                                                                                     constant:0];
        
        NSLayoutConstraint* maskViewBottom2SuperViewBottom = [NSLayoutConstraint constraintWithItem:maskView
                                                                                          attribute:NSLayoutAttributeBottom
                                                                                          relatedBy:NSLayoutRelationEqual
                                                                                             toItem:self.view
                                                                                          attribute:NSLayoutAttributeBottom
                                                                                         multiplier:1
                                                                                           constant:0];
        
        NSLayoutConstraint* maskViewLeft2SuperViewLeft = [NSLayoutConstraint constraintWithItem:maskView
                                                                                      attribute:NSLayoutAttributeLeft
                                                                                      relatedBy:NSLayoutRelationEqual
                                                                                         toItem:self.view
                                                                                      attribute:NSLayoutAttributeLeft
                                                                                     multiplier:1
                                                                                       constant:0];
        
        NSLayoutConstraint* maskViewWidth2SuperViewWidth = [NSLayoutConstraint constraintWithItem:maskView
                                                                                        attribute:NSLayoutAttributeWidth
                                                                                        relatedBy:NSLayoutRelationEqual
                                                                                           toItem:self.view
                                                                                        attribute:NSLayoutAttributeWidth
                                                                                       multiplier:0.8
                                                                                         constant:0];
        [self.view addConstraints:@[maskViewTop2SuperViewTop,maskViewBottom2SuperViewBottom,maskViewLeft2SuperViewLeft,maskViewWidth2SuperViewWidth]];
        
        
        NSLayoutConstraint* bottomViewTop2SuperViewTop = [NSLayoutConstraint constraintWithItem:bottomView
                                                                                      attribute:NSLayoutAttributeTop
                                                                                      relatedBy:NSLayoutRelationEqual
                                                                                         toItem:self.view
                                                                                      attribute:NSLayoutAttributeTop
                                                                                     multiplier:1
                                                                                       constant:0];
        
        NSLayoutConstraint* bottomViewBottom2SuperViewBottom = [NSLayoutConstraint constraintWithItem:bottomView
                                                                                            attribute:NSLayoutAttributeBottom
                                                                                            relatedBy:NSLayoutRelationEqual
                                                                                               toItem:self.view
                                                                                            attribute:NSLayoutAttributeBottom
                                                                                           multiplier:1
                                                                                             constant:0];
        
        
        NSLayoutConstraint* bottomViewLeft2SuperViewLeft = [NSLayoutConstraint constraintWithItem:bottomView
                                                                                        attribute:NSLayoutAttributeLeft
                                                                                        relatedBy:NSLayoutRelationEqual
                                                                                           toItem:maskView
                                                                                        attribute:NSLayoutAttributeRight
                                                                                       multiplier:1
                                                                                         constant:0];
        
        NSLayoutConstraint* bottomViewRight2SuperViewRight = [NSLayoutConstraint constraintWithItem:bottomView
                                                                                          attribute:NSLayoutAttributeRight
                                                                                          relatedBy:NSLayoutRelationEqual
                                                                                             toItem:self.view
                                                                                          attribute:NSLayoutAttributeRight
                                                                                         multiplier:1
                                                                                           constant:0];
        
        
        [self.view addConstraints:@[bottomViewTop2SuperViewTop,bottomViewLeft2SuperViewLeft,bottomViewRight2SuperViewRight,bottomViewBottom2SuperViewBottom]];
        
        
        NSLayoutConstraint* retryButtonCenterX= [NSLayoutConstraint constraintWithItem:retryButton
                                                                                              attribute:NSLayoutAttributeCenterX
                                                                                              relatedBy:NSLayoutRelationEqual
                                                                                                 toItem:bottomView
                                                                                              attribute:NSLayoutAttributeCenterX
                                                                                             multiplier:1
                                                                                               constant:0];
        
        NSLayoutConstraint* retryButtonCenterY = [NSLayoutConstraint constraintWithItem:retryButton
                                                                                               attribute:NSLayoutAttributeCenterY
                                                                                               relatedBy:NSLayoutRelationEqual
                                                                                                  toItem:bottomView
                                                                                               attribute:NSLayoutAttributeCenterY
                                                                                              multiplier:1
                                                                                                constant:2*buttonMargin];
        
        
        NSLayoutConstraint* retryButtonWidth = [NSLayoutConstraint constraintWithItem:retryButton
                                                                             attribute:NSLayoutAttributeWidth
                                                                             relatedBy:NSLayoutRelationEqual
                                                                                toItem:bottomView
                                                                             attribute:NSLayoutAttributeWidth
                                                                            multiplier:1.0
                                                                              constant:0];
        
        NSLayoutConstraint* retryButtonHeight = [NSLayoutConstraint constraintWithItem:retryButton
                                                                             attribute:NSLayoutAttributeHeight
                                                                             relatedBy:NSLayoutRelationEqual
                                                                                toItem:nil
                                                                             attribute:NSLayoutAttributeHeight
                                                                            multiplier:1.0
                                                                              constant:buttonH];
        
        [bottomView addConstraints:@[retryButtonCenterX,retryButtonCenterY,retryButtonWidth,retryButtonHeight]];
        
        NSLayoutConstraint* continueButtonCenterX= [NSLayoutConstraint constraintWithItem:continueButton
                                                                                              attribute:NSLayoutAttributeCenterX
                                                                                              relatedBy:NSLayoutRelationEqual
                                                                                                 toItem:bottomView
                                                                                              attribute:NSLayoutAttributeCenterX
                                                                                             multiplier:1
                                                                                               constant:0];
        
        NSLayoutConstraint* continueButtonCenterY = [NSLayoutConstraint constraintWithItem:continueButton
                                                                                               attribute:NSLayoutAttributeCenterY
                                                                                               relatedBy:NSLayoutRelationEqual
                                                                                                  toItem:bottomView
                                                                                               attribute:NSLayoutAttributeCenterY
                                                                                              multiplier:1
                                                                                                constant:-2*buttonMargin];
        
        
        NSLayoutConstraint* continueButtonWidth = [NSLayoutConstraint constraintWithItem:continueButton
                                                                             attribute:NSLayoutAttributeWidth
                                                                             relatedBy:NSLayoutRelationEqual
                                                                                toItem:bottomView
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
        
        [bottomView addConstraints:@[continueButtonCenterX,continueButtonCenterY,continueButtonWidth,continueButtonHeight]];
        
        
    }
}

-(void)retryButtonClick:(UIButton*)button{
    self.completionBlock();
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

@end



