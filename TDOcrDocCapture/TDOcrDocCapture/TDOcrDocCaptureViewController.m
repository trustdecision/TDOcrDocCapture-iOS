//
//  TDOcrDocCaptureViewController.m
//  TDOcrDocCapture
//
//  Created by LEE on 7/22/24.
//

#import "TDOcrDocCaptureViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <Photos/Photos.h>

// UI
#define WIDTH [UIScreen mainScreen].bounds.size.width
#define HEIGHT [UIScreen mainScreen].bounds.size.height

//由角度转换弧度
#define kDegreesToRadian(x)      (M_PI * (x) / 180.0)

// 实际裁剪相对裁剪框尺寸的比率
#define CROPRATIO  1.1
// 裁剪后证件图片的期望大小
#define TARGET_IMAGE_KB 300


#import <UIKit/UIKit.h>
#import "TDOcrDocResultViewController.h"

#include "rwpng.h"  /* typedefs, common macros, public prototypes */
#include "libimagequant.h" /* if it fails here, run: git submodule update; ./configure; or add -Ilib to compiler flags */
#include "pngquant_opts.h"

@interface UIImage (Rotation)
/**
 Compress a UIImage to the specified ratio
 
 @param ratio The compress ratio to compress to
 
 */
- (UIImage *)compressWithCompressRatio:(CGFloat)ratio;

@end

@implementation UIImage (Rotation)

/** 将图片旋转弧度radians */
- (UIImage *)imageRotatedByRadians:(CGFloat)radians
{
    CGFloat imageWidth = self.size.width*1;
    CGFloat imageHeight = self.size.height*1;
    
    // calculate the size of the rotated view's containing box for our drawing space
    UIView *rotatedViewBox = [[UIView alloc] initWithFrame:CGRectMake(0,0,imageWidth, imageHeight)];
    CGAffineTransform t = CGAffineTransformMakeRotation(radians);
    rotatedViewBox.transform = t;
    CGSize rotatedSize = rotatedViewBox.frame.size;
    
    // Create the bitmap context
    UIGraphicsBeginImageContextWithOptions(rotatedSize, NO, self.scale);
    
    CGContextRef bitmap = UIGraphicsGetCurrentContext();
    
    // Move the origin to the middle of the image so we will rotate and scale around the center.
    CGContextTranslateCTM(bitmap, rotatedSize.width/2, rotatedSize.height/2);
    
    //   // Rotate the image context
    CGContextRotateCTM(bitmap, radians);
    
    // Now, draw the rotated/scaled image into the context
    CGContextScaleCTM(bitmap, 1.0, -1.0);
    CGContextDrawImage(bitmap, CGRectMake(-imageWidth / 2, -imageHeight / 2, imageWidth, imageHeight), [self CGImage]);
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

/** 将图片旋转角度degrees */
- (UIImage *)imageRotatedByDegrees:(CGFloat)degrees
{
    return [self imageRotatedByRadians:kDegreesToRadian(degrees)];
}


- (UIImage *)compressWithCompressRatio:(CGFloat)ratio
{
    return [self compressImageWithCompressRatio:ratio maxCompressRatio:ratio];
}

- (UIImage *)compressImageWithCompressRatio:(CGFloat)ratio maxCompressRatio:(CGFloat)maxRatio
{
    UIImage *image = self;
    //We define the max and min resolutions to shrink to
    int MIN_UPLOAD_RESOLUTION = 1136 * 640;
    int MAX_UPLOAD_SIZE = 50;
    
    float factor;
    float currentResolution = image.size.height * image.size.width;
    
    //We first shrink the image a little bit in order to compress it a little bit more
    if (currentResolution > MIN_UPLOAD_RESOLUTION) {
        factor = sqrt(currentResolution / MIN_UPLOAD_RESOLUTION) * 2;
        image = [self scaleDownWithSize:CGSizeMake(image.size.width / factor, image.size.height / factor)];
    }
    
    //Compression settings
    CGFloat compression = ratio;
    CGFloat maxCompression = maxRatio;
    
    //We loop into the image data to compress accordingly to the compression ratio
    NSData *imageData = UIImageJPEGRepresentation(image, compression);
    while ([imageData length] > MAX_UPLOAD_SIZE && compression > maxCompression) {
        compression -= 0.10;
        imageData = UIImageJPEGRepresentation(image, compression);
    }
    
    //Retuns the compressed image
    return [[UIImage alloc] initWithData:imageData];
}



- (UIImage*)scaleDownWithSize:(CGSize)newSize
{
    UIImage *image = self;
    //We prepare a bitmap with the new size
    UIGraphicsBeginImageContextWithOptions(newSize, YES, 0.0);
    
    //Draws a rect for the image
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    
    //We set the scaled image from the context
    UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return scaledImage;
}

@end


@interface TDOcrDocCaptureViewController ()<AVCapturePhotoCaptureDelegate>

@property (nonatomic, strong) AVCaptureSession *captureSession;
// 记录点击拍照按钮一瞬间，设备的方向
@property (nonatomic, assign) UIDeviceOrientation capturedOrientation;

@property (nonatomic, strong) AVCapturePhotoOutput *photoOutput;

@property (nonatomic, strong) AVCaptureDevice *torchDevice;

@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;

@property (nonatomic, strong) UIImageView* idMaskImageView;

@end

@implementation TDOcrDocCaptureViewController

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    [self refreshUI:orientation];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupCamera];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(deviceOrientationDidChange:)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
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
        
        // 创建输出对象（静态图像）
        AVCapturePhotoOutput  *photoOutput = [[AVCapturePhotoOutput  alloc] init];
        self.photoOutput = photoOutput;
        if ([self.captureSession canAddOutput:photoOutput]) {
            [self.captureSession addOutput:photoOutput];
        }
        
        // 创建 AVCaptureVideoPreviewLayer
        AVCaptureVideoPreviewLayer *previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];
        self.previewLayer = previewLayer;
        previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        previewLayer.frame = self.view.bounds;
        
        
        // 将 AVCaptureVideoPreviewLayer 添加到视图层级
        [self.view.layer addSublayer:previewLayer];
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            // 开始 AVCaptureSession
            [self.captureSession startRunning];
        });
        
        // 获取手电筒设备
        self.torchDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    }
    else {
        NSLog(@"无法获取后置摄像头设备: %@", error.localizedDescription);
    }
    
}

- (void)deviceOrientationDidChange:(NSNotification *)notification {
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    orientation = [[UIDevice currentDevice] orientation];
    [self refreshUI:orientation];
}

-(void)refreshUI:(UIDeviceOrientation)orientation
{
    CGFloat width = self.view.bounds.size.width;
    CGFloat height = self.view.bounds.size.height;
    
    
    BOOL isPortrait = width < height;
    
    if(orientation == UIDeviceOrientationLandscapeLeft || orientation == UIDeviceOrientationLandscapeRight){
        isPortrait = NO;
        if(width < height){
            self.previewLayer.frame = CGRectMake(0, 0, height, width);
        }else{
            self.previewLayer.frame = self.view.bounds;
        }
    }else if(orientation == UIDeviceOrientationPortrait){
        isPortrait = YES;
        if(width > height){
            self.previewLayer.frame = CGRectMake(0, 0, height, width);
        }else{
            self.previewLayer.frame = self.view.bounds;
            
        }
    }else if(orientation == UIDeviceOrientationPortraitUpsideDown){
        
        if(width < height){
            isPortrait = YES;
        }else{
            isPortrait = NO;
        }
        self.previewLayer.frame =  self.view.bounds;
        
    }
    
    
    [self refreshWithIsPortrait:isPortrait];
    
    if(orientation == UIDeviceOrientationLandscapeRight){
        // 设置预览图层的方向为横屏
        self.previewLayer.connection.videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
        
    }else if(orientation == UIDeviceOrientationLandscapeLeft){
        self.previewLayer.connection.videoOrientation = AVCaptureVideoOrientationLandscapeRight;
        
    }else if(orientation == UIDeviceOrientationPortrait){
        self.previewLayer.connection.videoOrientation = AVCaptureVideoOrientationPortrait;
    }
    else if(orientation == UIDeviceOrientationPortraitUpsideDown){
        if(width < height){
            self.idMaskImageView.image = [UIImage imageWithCGImage:self.idMaskImageView.image.CGImage
                                                             scale:self.idMaskImageView.image.scale
                                                       orientation:UIImageOrientationDown];
        }
        
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
    maskView.backgroundColor = [UIColor clearColor];
    maskView.translatesAutoresizingMaskIntoConstraints = NO;
    
    
    UIImageView* idMaskImageView = [[UIImageView alloc]init];
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
        
        idMaskImageView.image = [UIImage imageNamed:@"idmask_portrait_front"];
        
        
        CGFloat buttonMargin = (MIN(WIDTH,HEIGHT) - captureButtonWH) / 4.0;
        
        
        
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
        
        idMaskImageView.image = [UIImage imageNamed:@"idmask_landscape_front"];
        
        CGFloat buttonMargin = (MIN(WIDTH,HEIGHT) - captureButtonWH) / 4.0;
        
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
    self.capturedOrientation = [[UIDevice currentDevice] orientation];
    AVCapturePhotoSettings *photoSettings = [AVCapturePhotoSettings photoSettingsWithFormat:@{AVVideoCodecKey: AVVideoCodecTypeJPEG}];
    [self.photoOutput capturePhotoWithSettings:photoSettings delegate:self];
}

-(void)flashButtonClick:(UIButton*)button{
    button.selected = !button.selected;
    [self.torchDevice lockForConfiguration:nil];
    [self.torchDevice setTorchMode:button.selected ? AVCaptureTorchModeOn : AVCaptureTorchModeOff];
}

-(void)closeButtonClick:(UIButton*)button{
    exit(0);
}

/*!
 *  @brief 使图片压缩后刚好小于指定大小
 *
 *  @param image 当前要压缩的图 maxLength 压缩后的大小
 *
 *  @return 图片对象
 */
//图片质量压缩到某一范围内，如果后面用到多，可以抽成分类或者工具类,这里压缩递减比二分的运行时间长，二分可以限制下限。
- (UIImage *)compressImageSize:(UIImage *)image toByte:(NSUInteger)maxLength{
    //首先判断原图大小是否在要求内，如果满足要求则不进行压缩，over
    CGFloat compression = 1;
    NSData *data = UIImageJPEGRepresentation(image, compression);
    if (data.length < maxLength) return image;
    //原图大小超过范围，先进行“压处理”，这里 压缩比 采用二分法进行处理，6次二分后的最小压缩比是0.015625，已经够小了
    CGFloat max = 1;
    CGFloat min = 0;
    for (int i = 0; i < 6; ++i) {
        compression = (max + min) / 2;
        data = UIImageJPEGRepresentation(image, compression);
        if (data.length < maxLength * 0.9) {
            min = compression;
        } else if (data.length > maxLength) {
            max = compression;
        } else {
            break;
        }
    }
    //判断“压处理”的结果是否符合要求，符合要求就over
    UIImage *resultImage = [UIImage imageWithData:data];
    if (data.length < maxLength) return resultImage;
    
    //缩处理，直接用大小的比例作为缩处理的比例进行处理，因为有取整处理，所以一般是需要两次处理
    NSUInteger lastDataLength = 0;
    while (data.length > maxLength && data.length != lastDataLength) {
        lastDataLength = data.length;
        //获取处理后的尺寸
        CGFloat ratio = (CGFloat)maxLength / data.length;
        CGSize size = CGSizeMake((NSUInteger)(resultImage.size.width * sqrtf(ratio)),
                                 (NSUInteger)(resultImage.size.height * sqrtf(ratio)));
        //通过图片上下文进行处理图片
        UIGraphicsBeginImageContext(size);
        [resultImage drawInRect:CGRectMake(0, 0, size.width, size.height)];
        resultImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        //获取处理后图片的大小
        data = UIImageJPEGRepresentation(resultImage, compression);
    }
    
    return resultImage;
}
pngquant_error pngquant_main_internal(struct pngquant_options *options, liq_attr *liq);


#define SAVE_PNG_NAME @"capture.png"

#define SAVE_COMPRESSED_PNG_NAME @"capture_compressed.png"


-(int)compressPng:(NSString*)pngPath outPng:(NSString*)outPngPath quality:(NSUInteger)quality
{
    const char* pngPath_c = pngPath.UTF8String;
    
    const char* outPngPath_c = outPngPath.UTF8String;
    
    NSString* qualityString = [NSString stringWithFormat:@"%d-%d",quality,quality];
    
    const char* qualityString_c = qualityString.UTF8String;
    struct pngquant_options options = {
        .floyd = 0, // floyd-steinberg dithering
        .strip = true,
        .quality = qualityString_c,
        .posterize = 1,
        .fast_compression = true,
        .files = &pngPath_c,
        .num_files = 1,
        .output_file_path = outPngPath_c
    };

    liq_attr *liq = liq_attr_create();
 
    pngquant_error retval = pngquant_main_internal(&options, liq);
    liq_attr_destroy(liq);
    return retval;
}

//#define COMPRESS_PNG_USE_OC

// 从PNG图片中裁剪指定矩形框区域像素并生成PNG
- (void)cropImageAndSaveToPhotosAlbum:(UIImage*)originalImage {
    
    CGFloat originalImageScale = originalImage.scale;
    
    // 要裁剪的矩形框区域（示例为裁剪左上角100x100的区域）
    CGRect cropRect = [self.idMaskImageView convertRect:self.idMaskImageView.frame toView:self.view];
    
    CGFloat orignalW2x = cropRect.size.width * originalImageScale;
    CGFloat orignalH2x = cropRect.size.height * originalImageScale;
    CGFloat cropW = orignalW2x * CROPRATIO;
    CGFloat cropH = orignalH2x * CROPRATIO;
    
    CGFloat cropX = cropRect.origin.x / (2.0 / originalImageScale) - (cropW - orignalW2x)/2.0;
    CGFloat cropY = cropRect.origin.y / (2.0 / originalImageScale) - (cropH - orignalH2x)/2.0;
    
    CGFloat viewW = self.view.bounds.size.width;
    CGFloat viewH = self.view.bounds.size.height;
    
    CGFloat imageW = originalImage.size.width;
    CGFloat imageH = originalImage.size.height;
    
    // 计算比率
    CGFloat XRatio = cropX / viewW;
    CGFloat YRatio = cropY / viewH;
    CGFloat WRatio = cropW / viewW;
    CGFloat HRatio = cropH / viewH;
    CGRect cropRect3 = CGRectMake(XRatio * imageW, YRatio * imageH, WRatio * imageW, HRatio * imageH);
    // 根据裁剪区域创建CGImageRef
    CGImageRef imageRef = CGImageCreateWithImageInRect(originalImage.CGImage, cropRect3);
    
    // 创建UIImage对象
    __block UIImage *croppedImage = [UIImage imageWithCGImage:imageRef];
    
    // 释放CGImageRef
    CGImageRelease(imageRef);
    
    if(self.capturedOrientation == UIDeviceOrientationPortraitUpsideDown){
        croppedImage = [croppedImage imageRotatedByDegrees:180];
    }
    
    // 将 UIImage 转换为 PNG 格式的 NSData
    NSData *croppedImageData = UIImagePNGRepresentation(croppedImage);
    
    // 获取 PNG 图片占用的字节数
    NSUInteger croppedImageSizeInBytes = croppedImageData.length;
    
    CGFloat scaleRatio =   TARGET_IMAGE_KB*1024.0 / croppedImageSizeInBytes;

    
#ifdef COMPRESS_PNG_USE_OC
    if(scaleRatio < 1){
        croppedImage = [croppedImage compressWithCompressRatio:scaleRatio];
    }
#else
    
    // 将 UIImage 转换为 PNG 格式的 NSData
    croppedImageData = UIImagePNGRepresentation(croppedImage);
    
    NSArray *documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [documentPaths firstObject];
    NSLog(@"Documents目录路径: %@", documentsDirectory);
    
    NSString* capturePngPath = [documentsDirectory stringByAppendingPathComponent:SAVE_PNG_NAME];
    
    NSString* compressedCapturePngPath = [documentsDirectory stringByAppendingPathComponent:SAVE_COMPRESSED_PNG_NAME];

    NSError* error;
    
    [[NSFileManager defaultManager] removeItemAtPath:compressedCapturePngPath error:&error];
    
    BOOL isS = [croppedImageData writeToFile:capturePngPath atomically:YES];

    [self compressPng:capturePngPath outPng:compressedCapturePngPath quality:scaleRatio*100];
    
    NSData* compressedImageData = [NSData dataWithContentsOfFile:compressedCapturePngPath];
    croppedImage = [UIImage imageWithData:compressedImageData];
    
    [[NSFileManager defaultManager] removeItemAtPath:capturePngPath error:&error];
    
    [[NSFileManager defaultManager] removeItemAtPath:compressedCapturePngPath error:&error];
#endif
    
    TDOcrDocResultViewController* resultVC = [[TDOcrDocResultViewController alloc]initWithOrientation:self.capturedOrientation ContentImage:croppedImage Completion:^{
        UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
        [self refreshUI:orientation];
    }];
    // [self.navigationController pushViewController:resultVC animated:YES];
    resultVC.modalPresentationStyle = UIModalPresentationOverFullScreen;
    [self presentViewController:resultVC animated:YES completion:nil];
    // 保存裁剪后的图像到相册
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        PHAssetCreationRequest *request = [PHAssetCreationRequest creationRequestForAsset];
        [request addResourceWithType:PHAssetResourceTypePhoto data:UIImagePNGRepresentation(croppedImage) options:nil];
    } completionHandler:^(BOOL success, NSError *error) {
        if (success) {
            NSLog(@"裁剪后的图像保存成功");
        } else {
            NSLog(@"裁剪后的图像保存失败：%@", error.localizedDescription);
        }
    }];
}


#pragma mark - AVCapturePhotoCaptureDelegate

- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishProcessingPhoto:(AVCapturePhoto *)photo error:(NSError *)error {
    if (error) {
        NSLog(@"拍照出错: %@", error.localizedDescription);
        return;
    }
    
    NSData *photoData = photo.fileDataRepresentation;
    
    UIImage *image = [UIImage imageWithData:photoData];
    if (!image) {
        return;
    }
    
    // 调整图像的分辨率以匹配屏幕分辨率
    CGFloat width = image.size.width;
    CGFloat height = image.size.height;
    CGFloat scale = image.scale;
    if(width < height){
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(width, height), YES, scale);
        [image drawInRect:CGRectMake(0, 0, width, height)];
    }else{
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(height, width), YES, scale);
        [image drawInRect:CGRectMake(0, 0, height, width)];
    }
    UIImage *pngImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    if(self.capturedOrientation == UIDeviceOrientationLandscapeLeft){
        pngImage = [pngImage imageRotatedByDegrees:-90];
    }else if(self.capturedOrientation == UIDeviceOrientationLandscapeRight){
        pngImage = [pngImage imageRotatedByDegrees:90];
    }
    
    [self cropImageAndSaveToPhotosAlbum:pngImage];
    
    if(self.capturedOrientation == UIDeviceOrientationPortraitUpsideDown){
        pngImage = [pngImage imageRotatedByDegrees:180];
    }
    
    // 将UIImage对象转换为PNG格式的NSData
    NSData *pngImageData = UIImagePNGRepresentation(pngImage);
    
    // 保存图像到相册
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        PHAssetCreationRequest *request = [PHAssetCreationRequest creationRequestForAsset];
        [request addResourceWithType:PHAssetResourceTypePhoto data:pngImageData options:nil];
    } completionHandler:^(BOOL success, NSError *error) {
        if (success) {
            NSLog(@"图像保存成功");
        } else {
            NSLog(@"图像保存失败：%@", error.localizedDescription);
        }
    }];
    
}

@end



