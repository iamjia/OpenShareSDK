//
//  DismissAnimator.m
//  OpenShareDemo
//
//  Created by Jia on 2017/9/4.
//  Copyright © 2017年 Jia. All rights reserved.
//

#import "DismissAnimator.h"

@implementation DismissAnimator

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext
{
    return 0.35f;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    UIView *containerView = transitionContext.containerView;
    
    UIView *fromView = nil;
    UIView *toView = nil;
    
    if ([transitionContext respondsToSelector:@selector(viewForKey:)]) {
        fromView = [transitionContext viewForKey:UITransitionContextFromViewKey];
        toView = [transitionContext viewForKey:UITransitionContextToViewKey];
    } else {
        fromView = fromVC.view;
        toView = toVC.view;
    }
    
    fromView.frame = [transitionContext initialFrameForViewController:fromVC];
    toView.frame = [transitionContext finalFrameForViewController:toVC];
    
    fromView.alpha = 1.0f;
    toView.alpha = 0.0f;
    
    [containerView addSubview:toView];
    
    containerView.backgroundColor = [UIColor clearColor];
    
    NSTimeInterval transitionDuration = [self transitionDuration:transitionContext];
    
    [UIView animateWithDuration:transitionDuration animations:^{
        fromView.alpha = 0.0f;
        toView.alpha = 1.0;
    } completion:^(BOOL finished) {
        fromView.alpha = 1.0f;
        [transitionContext completeTransition:!transitionContext.transitionWasCancelled];
    }];
}

@end
