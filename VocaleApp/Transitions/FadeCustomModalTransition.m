//
//  FadeCustomModalTransition.m
//  VocaleApp
//
//  Created by Vladimir Kadurin on 6/20/16.
//  Copyright © 2016 Rayno Willem Mostert. All rights reserved.
//

#import "FadeCustomModalTransition.h"

static NSTimeInterval const kDefaultDuration = 1.0;

@implementation FadeCustomModalTransition

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
    UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView *fromView = fromVC.view;
    UIView *toView = toVC.view;
    UIView *containerView = [transitionContext containerView];
    NSTimeInterval duration = [self transitionDuration:transitionContext];
    
    if (self.appearing) {
        toView.alpha = 0;
        [containerView addSubview:toView];
        [UIView animateWithDuration:duration animations: ^{
            toView.alpha = 1;
        } completion: ^(BOOL finished) {
            [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
        }];
    }
    else {
        [UIView animateWithDuration:duration animations: ^{
            fromView.alpha = 0;
        } completion: ^(BOOL finished) {
            [fromView removeFromSuperview];
            [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
        }];
    }
}

@end
