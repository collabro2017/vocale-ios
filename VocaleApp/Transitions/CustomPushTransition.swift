//
//  CustomPushTransition.swift
//  VocaleApp
//
//  Created by Vladimir Kadurin on 5/16/16.
//  Copyright © 2016 Rayno Willem Mostert. All rights reserved.
//

import UIKit

class CustomPushTransition: NSObject, UIViewControllerAnimatedTransitioning {
    var appearing: Bool?
    
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return 0.3
    }
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView()
        
        let toViewController = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)!
        let fromViewController = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)!
        
        if appearing == true {
            
            toViewController.view.transform = CGAffineTransformMakeTranslation(-toViewController.view.frame.size.width, 0)
            //toViewController.view.frame = transitionContext.finalFrameForViewController(toViewController)
            containerView.addSubview(toViewController.view)
            
            UIView.animateWithDuration(transitionDuration(transitionContext), delay: 0, options: UIViewAnimationOptions.CurveEaseInOut, animations: {
                toViewController.view.transform = CGAffineTransformMakeTranslation(0, 0)
                }, completion: {
                    finished in
                    transitionContext.completeTransition(!transitionContext.transitionWasCancelled())
            })
        } else {
            //print("FROM", fromViewController)
            //print("TO", toViewController)
            containerView.addSubview(toViewController.view)
            UIView.animateWithDuration(transitionDuration(transitionContext), delay: 0, options: UIViewAnimationOptions.CurveEaseInOut, animations: {
                fromViewController.view.transform = CGAffineTransformMakeTranslation(-fromViewController.view.frame.size.width, 0)
                }, completion: {
                    finished in
                    
                    fromViewController.view.removeFromSuperview()
                    transitionContext.completeTransition(!transitionContext.transitionWasCancelled())
            })
        }
        
    }
}
