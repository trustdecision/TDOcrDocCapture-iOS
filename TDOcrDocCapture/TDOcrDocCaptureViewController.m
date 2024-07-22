//
//  TDOcrDocCaptureViewController.m
//  TDOcrDocCapture
//
//  Created by LEE on 7/22/24.
//

#import "TDOcrDocCaptureViewController.h"

@interface TDOcrDocCaptureViewController ()

@end

@implementation TDOcrDocCaptureViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor redColor];
    
    [self setupUI];
    
    // Do any additional setup after loading the view.
}

-(void)setupUI
{
    UIView* maskView = [[UIView alloc]init];
    [self.view addSubview:maskView];
    maskView.backgroundColor = [UIColor yellowColor];
    maskView.translatesAutoresizingMaskIntoConstraints = NO;

    NSLayoutConstraint *maskViewTop2SuperViewTop = [NSLayoutConstraint constraintWithItem:maskView
                                                                               attribute:NSLayoutAttributeTop
                                                                               relatedBy:NSLayoutRelationEqual
                                                                                  toItem:self.view
                                                                               attribute:NSLayoutAttributeTop
                                                                              multiplier:1
                                                                                constant:0];
    
    NSLayoutConstraint *maskViewHeight2SuperViewHeight = [NSLayoutConstraint constraintWithItem:maskView
                                                                               attribute:NSLayoutAttributeHeight
                                                                               relatedBy:NSLayoutRelationEqual
                                                                                  toItem:self.view
                                                                               attribute:NSLayoutAttributeHeight
                                                                              multiplier:0.8
                                                                                constant:0];
    
    NSLayoutConstraint *maskViewLeft2SuperViewLeft = [NSLayoutConstraint constraintWithItem:maskView
                                                                               attribute:NSLayoutAttributeLeft
                                                                               relatedBy:NSLayoutRelationEqual
                                                                                  toItem:self.view
                                                                               attribute:NSLayoutAttributeLeft
                                                                              multiplier:1
                                                                                constant:0];
    
    NSLayoutConstraint *maskViewRight2SuperViewRight = [NSLayoutConstraint constraintWithItem:maskView
                                                                               attribute:NSLayoutAttributeRight
                                                                               relatedBy:NSLayoutRelationEqual
                                                                                  toItem:self.view
                                                                               attribute:NSLayoutAttributeRight
                                                                              multiplier:1
                                                                                constant:0];
    
    
    
    [self.view addConstraints:@[maskViewTop2SuperViewTop,maskViewHeight2SuperViewHeight,maskViewLeft2SuperViewLeft,maskViewRight2SuperViewRight]];
    
    UIView* bottomView = [[UIView alloc]init];
    [self.view addSubview:bottomView];
    bottomView.backgroundColor = [UIColor greenColor];
    bottomView.translatesAutoresizingMaskIntoConstraints = NO;

    
    
    
    NSLayoutConstraint *bottomViewTop2MaskViewBottom = [NSLayoutConstraint constraintWithItem:bottomView
                                                                               attribute:NSLayoutAttributeTop
                                                                               relatedBy:NSLayoutRelationEqual
                                                                                  toItem:maskView
                                                                               attribute:NSLayoutAttributeBottom
                                                                              multiplier:1
                                                                                constant:0];
    
    NSLayoutConstraint *bottomViewLeft2SuperViewLeft = [NSLayoutConstraint constraintWithItem:bottomView
                                                                               attribute:NSLayoutAttributeLeft
                                                                               relatedBy:NSLayoutRelationEqual
                                                                                  toItem:self.view
                                                                               attribute:NSLayoutAttributeLeft
                                                                              multiplier:1
                                                                                constant:0];
    
    NSLayoutConstraint *bottomViewRight2SuperViewRight = [NSLayoutConstraint constraintWithItem:bottomView
                                                                               attribute:NSLayoutAttributeRight
                                                                               relatedBy:NSLayoutRelationEqual
                                                                                  toItem:self.view
                                                                               attribute:NSLayoutAttributeRight
                                                                              multiplier:1
                                                                                constant:0];
    
    NSLayoutConstraint *bottomViewBottom2SuperViewBottom = [NSLayoutConstraint constraintWithItem:bottomView
                                                                               attribute:NSLayoutAttributeBottom
                                                                               relatedBy:NSLayoutRelationEqual
                                                                                  toItem:self.view
                                                                               attribute:NSLayoutAttributeBottom
                                                                              multiplier:1
                                                                                constant:0];
    
    [self.view addConstraints:@[bottomViewTop2MaskViewBottom,bottomViewLeft2SuperViewLeft,bottomViewRight2SuperViewRight,bottomViewBottom2SuperViewBottom]];

    
}


@end
