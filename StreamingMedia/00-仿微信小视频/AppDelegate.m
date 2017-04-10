//
//  AppDelegate.m
//  00-仿微信小视频
//
//  Created by admin on 16/9/11.
//  Copyright © 2016年 静持大师. All rights reserved.
//

#import "AppDelegate.h"
#import "JCRootViewController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    // 1.创建窗口
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.backgroundColor = [UIColor whiteColor];
    
    // 3.显示窗口
    [self.window makeKeyAndVisible];
    
    // 2.设置窗口的根控制器
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:[[JCRootViewController alloc] init]];
    
    self.window.rootViewController = nav;
    
    return YES;

    
}


@end
