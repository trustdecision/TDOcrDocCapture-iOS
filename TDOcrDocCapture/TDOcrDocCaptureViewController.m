//
//  TDOcrDocCaptureViewController.m
//  TDOcrDocCapture
//
//  Created by LEE on 7/22/24.
//

#import "TDOcrDocCaptureViewController.h"
#import <AVFoundation/AVFoundation.h>

// UI
#define WIDTH [UIScreen mainScreen].bounds.size.width
#define HEIGHT [UIScreen mainScreen].bounds.size.height


@interface TDOcrDocCaptureViewController ()<AVCapturePhotoCaptureDelegate>

@property (nonatomic, strong) AVCaptureSession *captureSession;

@property (nonatomic, strong) AVCapturePhotoOutput *photoOutput;

@property (nonatomic, strong) AVCaptureDevice *torchDevice;

@end

@implementation TDOcrDocCaptureViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupCamera];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(deviceOrientationDidChange:)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
    
    [self refreshUI];
    
    // Do any additional setup after loading the view.
}

-(void)setupCamera{
    
    
    // 创建 AVCaptureSession
    self.captureSession = [[AVCaptureSession alloc] init];
    
    // 获取后置摄像头设备
    AVCaptureDevice *backCamera = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    // 创建 AVCaptureDeviceInput
    NSError *error = nil;
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:backCamera error:&error];
    
    if (input) {
        // 将 AVCaptureDeviceInput 添加到 AVCaptureSession
        if ([self.captureSession canAddInput:input]) {
            [self.captureSession addInput:input];
        }
        
        // 创建 AVCapturePhotoOutput
        self.photoOutput = [[AVCapturePhotoOutput alloc] init];
        
        // 将 AVCapturePhotoOutput 添加到 AVCaptureSession
        if ([self.captureSession canAddOutput:self.photoOutput]) {
            [self.captureSession addOutput:self.photoOutput];
        }
        
        // 创建 AVCaptureVideoPreviewLayer
        AVCaptureVideoPreviewLayer *previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];
        previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        previewLayer.frame = self.view.bounds;
        
        // 将 AVCaptureVideoPreviewLayer 添加到视图层级
        [self.view.layer addSublayer:previewLayer];
        
        // 开始 AVCaptureSession
        [self.captureSession startRunning];
        
        // 获取手电筒设备
        self.torchDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    }
    else {
        NSLog(@"无法获取后置摄像头设备: %@", error.localizedDescription);
    }
    
}

- (void)deviceOrientationDidChange:(NSNotification *)notification {
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    NSLog(@"orientation---::%d",orientation);
    [self refreshUI];
    // 在这里处理方向变化
}

-(void)refreshUI
{
    [self.view.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj removeFromSuperview];
    }];
    
    [self.view removeConstraints:self.view.constraints];
    
    
    UIView* maskView = [[UIView alloc]init];
    [self.view addSubview:maskView];
    maskView.backgroundColor = [UIColor clearColor];
    maskView.translatesAutoresizingMaskIntoConstraints = NO;
    
    
    UIImageView* idMaskImageView = [[UIImageView alloc]init];
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
    
    UIView* bottomView = [[UIView alloc]init];
    [self.view addSubview:bottomView];
    bottomView.backgroundColor = [UIColor blackColor];
    bottomView.translatesAutoresizingMaskIntoConstraints = NO;
    
    
    // 处理bottomView
    
    ////  拍照按钮
    UIButton* captureButton = [[UIButton alloc]init];
    [captureButton setImage:[UIImage imageNamed:@"capture"] forState:UIControlStateNormal];
    [captureButton setImage:[UIImage imageNamed:@"capture"] forState:UIControlStateSelected];
    [captureButton addTarget:self action:@selector(captureButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    
    [bottomView addSubview:captureButton];
    captureButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    
    CGFloat captureButtonWH = 78;
    
    
    NSLayoutConstraint* captureButtonCenterX2SuperViewCenterX = [NSLayoutConstraint constraintWithItem:captureButton
                                                                                             attribute:NSLayoutAttributeCenterX
                                                                                             relatedBy:NSLayoutRelationEqual
                                                                                                toItem:bottomView
                                                                                             attribute:NSLayoutAttributeCenterX
                                                                                            multiplier:1
                                                                                              constant:0];
    
    NSLayoutConstraint* captureButtonCenterY2SuperViewCenterY = [NSLayoutConstraint constraintWithItem:captureButton
                                                                                             attribute:NSLayoutAttributeCenterY
                                                                                             relatedBy:NSLayoutRelationEqual
                                                                                                toItem:bottomView
                                                                                             attribute:NSLayoutAttributeCenterY
                                                                                            multiplier:1
                                                                                              constant:0];
    
    NSLayoutConstraint* captureButtonWidth = [NSLayoutConstraint constraintWithItem:captureButton
                                                                          attribute:NSLayoutAttributeWidth
                                                                          relatedBy:NSLayoutRelationEqual
                                                                             toItem:nil
                                                                          attribute:NSLayoutAttributeWidth
                                                                         multiplier:1.0
                                                                           constant:captureButtonWH];
    
    NSLayoutConstraint* captureButtonHeight = [NSLayoutConstraint constraintWithItem:captureButton
                                                                           attribute:NSLayoutAttributeHeight
                                                                           relatedBy:NSLayoutRelationEqual
                                                                              toItem:nil
                                                                           attribute:NSLayoutAttributeHeight
                                                                          multiplier:1.0
                                                                            constant:captureButtonWH];
    
    [bottomView addConstraints:@[captureButtonCenterX2SuperViewCenterX,captureButtonCenterY2SuperViewCenterY,captureButtonWidth,captureButtonHeight]];
    
    
    
    
    
    ////  灯光按钮
    UIButton* flashButton = [[UIButton alloc]init];
    [flashButton setImage:[UIImage imageNamed:@"flash"] forState:UIControlStateNormal];
    [flashButton setImage:[UIImage imageNamed:@"flash"] forState:UIControlStateSelected];
    [flashButton addTarget:self action:@selector(flashButtonClick:) forControlEvents:UIControlEventTouchUpInside];

    [bottomView addSubview:flashButton];
    flashButton.translatesAutoresizingMaskIntoConstraints = NO;
    CGFloat flashButtonWH = 40;
    
    
    ////  关闭按钮
    UIButton* closeButton = [[UIButton alloc]init];
    [closeButton setImage:[UIImage imageNamed:@"close"] forState:UIControlStateNormal];
    [closeButton setImage:[UIImage imageNamed:@"close"] forState:UIControlStateSelected];
    [closeButton addTarget:self action:@selector(closeButtonClick:) forControlEvents:UIControlEventTouchUpInside];

    [bottomView addSubview:closeButton];
    closeButton.translatesAutoresizingMaskIntoConstraints = NO;
    CGFloat closeButtonWH = 40;
    
    
    CGFloat width = self.view.bounds.size.width;
    CGFloat height = self.view.bounds.size.height;
    
    
    BOOL isPortrait = width < height;
    
    // 动态旋转的时候处理
    if(isPortrait){
        idMaskImageView.image = [UIImage imageNamed:@"idmask_portrait_front"];
        
        CGFloat buttonMargin = (WIDTH - captureButtonWH) / 4.0;
        
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
        
        
        NSLayoutConstraint* flashButtonRight2CaptureButtonLeft = [NSLayoutConstraint constraintWithItem:flashButton
                                                                                              attribute:NSLayoutAttributeRight
                                                                                              relatedBy:NSLayoutRelationEqual
                                                                                                 toItem:captureButton
                                                                                              attribute:NSLayoutAttributeLeft
                                                                                             multiplier:1
                                                                                               constant:-buttonMargin];
        
        NSLayoutConstraint* flashButtonCenterY2SuperViewCenterY = [NSLayoutConstraint constraintWithItem:flashButton
                                                                                               attribute:NSLayoutAttributeCenterY
                                                                                               relatedBy:NSLayoutRelationEqual
                                                                                                  toItem:bottomView
                                                                                               attribute:NSLayoutAttributeCenterY
                                                                                              multiplier:1
                                                                                                constant:0];
        
        NSLayoutConstraint* flashButtonWidth = [NSLayoutConstraint constraintWithItem:flashButton
                                                                            attribute:NSLayoutAttributeWidth
                                                                            relatedBy:NSLayoutRelationEqual
                                                                               toItem:nil
                                                                            attribute:NSLayoutAttributeWidth
                                                                           multiplier:1.0
                                                                             constant:flashButtonWH];
        
        NSLayoutConstraint* flashButtonHeight = [NSLayoutConstraint constraintWithItem:flashButton
                                                                             attribute:NSLayoutAttributeHeight
                                                                             relatedBy:NSLayoutRelationEqual
                                                                                toItem:nil
                                                                             attribute:NSLayoutAttributeHeight
                                                                            multiplier:1.0
                                                                              constant:flashButtonWH];
        
        [bottomView addConstraints:@[flashButtonRight2CaptureButtonLeft,flashButtonCenterY2SuperViewCenterY,flashButtonWidth,flashButtonHeight]];
        
        
        
        
        NSLayoutConstraint* closeButtonLeft2CaptureButtonRight = [NSLayoutConstraint constraintWithItem:closeButton
                                                                                              attribute:NSLayoutAttributeLeft
                                                                                              relatedBy:NSLayoutRelationEqual
                                                                                                 toItem:captureButton
                                                                                              attribute:NSLayoutAttributeRight
                                                                                             multiplier:1
                                                                                               constant:buttonMargin];
        
        NSLayoutConstraint* closeButtonCenterY2SuperViewCenterY = [NSLayoutConstraint constraintWithItem:closeButton
                                                                                               attribute:NSLayoutAttributeCenterY
                                                                                               relatedBy:NSLayoutRelationEqual
                                                                                                  toItem:bottomView
                                                                                               attribute:NSLayoutAttributeCenterY
                                                                                              multiplier:1
                                                                                                constant:0];
        
        NSLayoutConstraint* closeButtonWidth = [NSLayoutConstraint constraintWithItem:closeButton
                                                                            attribute:NSLayoutAttributeWidth
                                                                            relatedBy:NSLayoutRelationEqual
                                                                               toItem:nil
                                                                            attribute:NSLayoutAttributeWidth
                                                                           multiplier:1.0
                                                                             constant:closeButtonWH];
        
        NSLayoutConstraint* closeButtonHeight = [NSLayoutConstraint constraintWithItem:closeButton
                                                                             attribute:NSLayoutAttributeHeight
                                                                             relatedBy:NSLayoutRelationEqual
                                                                                toItem:nil
                                                                             attribute:NSLayoutAttributeHeight
                                                                            multiplier:1.0
                                                                              constant:closeButtonWH];
        
        [bottomView addConstraints:@[closeButtonLeft2CaptureButtonRight,closeButtonCenterY2SuperViewCenterY,closeButtonWidth,closeButtonHeight]];
        
        
        
    }else{
        
        idMaskImageView.image = [UIImage imageNamed:@"idmask_landscape_front"];
        
        CGFloat buttonMargin = (HEIGHT - captureButtonWH) / 4.0;
        
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
        
        
        
        NSLayoutConstraint* flashButtonTop2CaptureButtonBottom = [NSLayoutConstraint constraintWithItem:flashButton
                                                                                              attribute:NSLayoutAttributeTop
                                                                                              relatedBy:NSLayoutRelationEqual
                                                                                                 toItem:captureButton
                                                                                              attribute:NSLayoutAttributeBottom
                                                                                             multiplier:1
                                                                                               constant:buttonMargin];
        
        NSLayoutConstraint* flashButtonCenterY2SuperViewCenterX = [NSLayoutConstraint constraintWithItem:flashButton
                                                                                               attribute:NSLayoutAttributeCenterX
                                                                                               relatedBy:NSLayoutRelationEqual
                                                                                                  toItem:bottomView
                                                                                               attribute:NSLayoutAttributeCenterX
                                                                                              multiplier:1
                                                                                                constant:0];
        
        NSLayoutConstraint* flashButtonWidth = [NSLayoutConstraint constraintWithItem:flashButton
                                                                            attribute:NSLayoutAttributeWidth
                                                                            relatedBy:NSLayoutRelationEqual
                                                                               toItem:nil
                                                                            attribute:NSLayoutAttributeWidth
                                                                           multiplier:1.0
                                                                             constant:flashButtonWH];
        
        NSLayoutConstraint* flashButtonHeight = [NSLayoutConstraint constraintWithItem:flashButton
                                                                             attribute:NSLayoutAttributeHeight
                                                                             relatedBy:NSLayoutRelationEqual
                                                                                toItem:nil
                                                                             attribute:NSLayoutAttributeHeight
                                                                            multiplier:1.0
                                                                              constant:flashButtonWH];
        
        [bottomView addConstraints:@[flashButtonTop2CaptureButtonBottom,flashButtonCenterY2SuperViewCenterX,flashButtonWidth,flashButtonHeight]];
        
        
        
        
        NSLayoutConstraint* closeButtonBottom2CaptureButtonTop = [NSLayoutConstraint constraintWithItem:closeButton
                                                                                              attribute:NSLayoutAttributeBottom
                                                                                              relatedBy:NSLayoutRelationEqual
                                                                                                 toItem:captureButton
                                                                                              attribute:NSLayoutAttributeTop
                                                                                             multiplier:1
                                                                                               constant:-buttonMargin];
        
        NSLayoutConstraint* closeButtonCenterY2SuperViewCenterX = [NSLayoutConstraint constraintWithItem:closeButton
                                                                                               attribute:NSLayoutAttributeCenterX
                                                                                               relatedBy:NSLayoutRelationEqual
                                                                                                  toItem:bottomView
                                                                                               attribute:NSLayoutAttributeCenterX
                                                                                              multiplier:1
                                                                                                constant:0];
        
        NSLayoutConstraint* closeButtonWidth = [NSLayoutConstraint constraintWithItem:closeButton
                                                                            attribute:NSLayoutAttributeWidth
                                                                            relatedBy:NSLayoutRelationEqual
                                                                               toItem:nil
                                                                            attribute:NSLayoutAttributeWidth
                                                                           multiplier:1.0
                                                                             constant:closeButtonWH];
        
        NSLayoutConstraint* closeButtonHeight = [NSLayoutConstraint constraintWithItem:closeButton
                                                                             attribute:NSLayoutAttributeHeight
                                                                             relatedBy:NSLayoutRelationEqual
                                                                                toItem:nil
                                                                             attribute:NSLayoutAttributeHeight
                                                                            multiplier:1.0
                                                                              constant:closeButtonWH];
        
        [bottomView addConstraints:@[closeButtonBottom2CaptureButtonTop,closeButtonCenterY2SuperViewCenterX,closeButtonWidth,closeButtonHeight]];
        
    }
}

-(void)captureButtonClick:(UIButton*)button{
    AVCapturePhotoSettings *photoSettings = [AVCapturePhotoSettings photoSettingsWithFormat:@{AVVideoCodecKey: AVVideoCodecTypeJPEG}];
     [self.photoOutput capturePhotoWithSettings:photoSettings delegate:self];
}

-(void)flashButtonClick:(UIButton*)button{
    button.selected = !button.selected;
    [self.torchDevice lockForConfiguration:nil];
    [self.torchDevice setTorchMode:button.selected ? AVCaptureTorchModeOn : AVCaptureTorchModeOff];
}

-(void)closeButtonClick:(UIButton*)button{
    
}



#pragma mark - AVCapturePhotoCaptureDelegate

- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishProcessingPhoto:(AVCapturePhoto *)photo error:(NSError *)error {
    if (error) {
        NSLog(@"拍照出错: %@", error.localizedDescription);
        return;
    }
    
    NSData *photoData = photo.fileDataRepresentation;
    UIImage *image = [UIImage imageWithData:photoData];
    
    // 在这里处理拍摄到的照片，你可以保存到相册、上传服务器等操作
    
    // 示例：保存照片到相册
    UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    if (error) {
        NSLog(@"保存照片到相册出错: %@", error.localizedDescription);
    } else {
        NSLog(@"照片保存成功");
    }
}



@end
