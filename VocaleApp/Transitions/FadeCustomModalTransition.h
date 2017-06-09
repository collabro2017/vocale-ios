//
//  FadeCustomModalTransition.h
//  VocaleApp
//
//  Created by Vladimir Kadurin on 6/20/16.
//  Copyright © 2016 Rayno Willem Mostert. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface FadeCustomModalTransition : NSObject <UIViewControllerAnimatedTransitioning>

@property (nonatomic, assign, getter = isAppearing) BOOL appearing;
@property (nonatomic, assign) NSTimeInterval duration;

@end
