//
//  ProfileImageModalTransition.m
//  VocaleApp
//
//  Created by Vladimir Kadurin on 8/18/16.
//  Copyright © 2016 Rayno Willem Mostert. All rights reserved.
//

#import "ProfileImageModalTransition.h"
#import "ProfileDetailViewController.h"

static NSTimeInterval const kDefaultDuration = 1.0;

@implementation ProfileImageModalTransition

- (id)init
{
    self = [super init];
    if (self) {
        _duration = kDefaultDuration;
    }
    return self;
}

#pragma mark - UIViewControllerAnimatedTransitioning

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext
{
    return self.duration;
}

#pragma mark - UIViewControllerAnimatedTransitioning

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    
    if (self.appearing) {
        UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
        UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
        UIView *toView = toVC.view;
        UIView *containerView = [transitionContext containerView];
        NSTimeInterval duration = [self transitionDuration:transitionContext];
        
        [containerView addSubview:toView];
        [UIView animateWithDuration:duration animations: ^{

        } completion: ^(BOOL finished) {
            [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
        }];
    }
    else {
        UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
        UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
        UIView *fromView = fromVC.view;
        UIView *toView = toVC.view;
        UIView *containerView = [transitionContext containerView];
        NSTimeInterval duration = [self transitionDuration:transitionContext];
        
        toView.alpha = 0;
        [UIView animateWithDuration:duration animations: ^{
            toView.alpha = 1;
        } completion: ^(BOOL finished) {
            [fromView removeFromSuperview];
            [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
        }];
    }
}


@end
