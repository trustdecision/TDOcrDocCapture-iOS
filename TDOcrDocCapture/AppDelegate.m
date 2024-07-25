//
//  AppDelegate.m
//  TDOcrDocCapture
//
//  Created by LEE on 7/22/24.
//

#import "AppDelegate.h"
#import "TDOcrDocCaptureViewController.h"
@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)initRootVC {
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    TDOcrDocCaptureViewController * captureVC = [[TDOcrDocCaptureViewController alloc]init];
    UINavigationController* navVC = [[UINavigationController alloc]initWithRootViewController:captureVC];
    self.window.rootViewController = navVC;
    [self.window makeKeyAndVisible];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [self initRootVC];
    return YES;
}



@end
