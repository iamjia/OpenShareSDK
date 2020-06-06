//
//  ScreenCaptureManager.m
//  ScreenCaptureShare
//
//  Created by jia on 2017/5/23.
//  Copyright © 2017年 jia. All rights reserved.
//

#import "ScreenCaptureManager.h"
#import "OpenShareManager.h"

@implementation ScreenCaptureManager
{
@private
    __weak id _screenshotObserver;
}

- (void)dealloc
{
    [NSNotificationCenter.defaultCenter removeObserver:_screenshotObserver];
}

+ (instancetype)manger
{
    static ScreenCaptureManager *s_mgr = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_mgr = [[self alloc] init];
    });
    return s_mgr;
}

- (void)listenUserDidTakeScreenshotNotificationCompletion:(void (^)(UIImage *screenshot))completion
{
    [NSNotificationCenter.defaultCenter removeObserver:_screenshotObserver];
    __weak typeof(self) wSelf = self;
    _screenshotObserver = [NSNotificationCenter.defaultCenter addObserverForName:UIApplicationUserDidTakeScreenshotNotification object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification * _Nonnull note) {
        if (!wSelf.ignoreNotification && nil != completion) {
            completion(wSelf.screenShot);
        }
    }];
}

- (void)cancelListen
{
    [NSNotificationCenter.defaultCenter removeObserver:_screenshotObserver];
}

- (UIImage *)screenShot
{
    UIGraphicsBeginImageContextWithOptions(UIScreen.mainScreen.bounds.size, NO, UIScreen.mainScreen.scale);
    for (UIWindow *window in UIApplication.sharedApplication.windows) {
        [window drawViewHierarchyInRect:window.bounds afterScreenUpdates:YES];
    }
    
    @try {
        if (SYSTEM_VERSION_LESS_THAN(@"13")) {
            static NSString *const key = @"statusBar";
            NSString *kp = [key stringByAppendingString:[NSStringFromClass(UIWindow.class) substringFromIndex:2]];
            if ([UIApplication.sharedApplication respondsToSelector:NSSelectorFromString(kp)]) {
                UIView *statusBar = [[UIApplication.sharedApplication valueForKey:kp] valueForKey:key];
                [statusBar drawViewHierarchyInRect:statusBar.bounds afterScreenUpdates:YES];
            }
        }
    } @catch (NSException *exception) {
        NSLog(@"%@", exception);
    } @finally {
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return image;
    }
}

@end
