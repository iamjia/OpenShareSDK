//
//  UIView+StatusBar.m
//  OTNotificationViewDemo
//
//  Created by openthread on 8/9/13.
//
//

#import "UIView+StatusBar.h"
#import "TCFoundation.h"


__weak static UIView *s_statusBar = nil;

@implementation UIView (StatusBar)

+ (UIView *)statusBar
{
    return s_statusBar;
}

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class statusBarClass = NSClassFromString(@"UIStatusBar");
        [statusBarClass tc_swizzle:@selector(initWithFrame:) to:@selector(openshare_initWithFrame:)];
    });
}

- (id)openshare_initWithFrame:(CGRect)frame
{
    s_statusBar = self;
    return [self openshare_initWithFrame:frame];
}

- (UIView *)findFirstResponder
{
    if (self.isFirstResponder) {
        return self;
    }
    
    for (UIView *subView in self.subviews) {
        UIView *firstResponder = [subView findFirstResponder];
        if (nil != firstResponder) {
            return firstResponder;
        }
    }
    
    return nil;
}

@end
