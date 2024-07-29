//
//  TDOcrDocResultViewController.h
//  TDOcrDocCapture
//
//  Created by LEE on 7/25/24.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^CompletionBlock)(void);

@interface TDOcrDocResultViewController : UIViewController

-(instancetype)initWithContentImage:(UIImage*)contentImage Completion:(CompletionBlock)completionBlock;

@end

NS_ASSUME_NONNULL_END
