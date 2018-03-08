//
//  UIView+FindFirstResponder.m
//  OTNotificationViewDemo
//
//  Created by openthread on 8/9/13.
//
//

#import "UIView+FindFirstResponder.h"
#import "TCFoundation.h"

__weak static UIView *s_statusBar = nil;

@implementation UIView (FindFirstResponder)

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
