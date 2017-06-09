//
//  DeleteConfirmationViewController.h
//  VocaleApp
//
//  Created by Vladimir Kadurin on 6/10/16.
//  Copyright © 2016 Rayno Willem Mostert. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol DeleteConfirmationDelegate <NSObject>

- (void)deleteConversation;

@end
@class LYRConversation;
@interface DeleteConfirmationViewController : UIViewController

@property (nonatomic, strong) UIImage *backgroundImage;
@property (nonatomic, strong) NSString *userName;
@property (nonatomic, weak) id <DeleteConfirmationDelegate> delegate;
@property (nonatomic, strong) LYRConversation *conversation;

@end
