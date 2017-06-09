//
//  DeleteConfirmationViewController.m
//  VocaleApp
//
//  Created by Vladimir Kadurin on 6/10/16.
//  Copyright © 2016 Rayno Willem Mostert. All rights reserved.
//

#import "DeleteConfirmationViewController.h"
#import "VocaleApp-Swift.h"
#import <LayerKit/LayerKit.h>
#import "ATLConversationListViewController.h"
#import "ATLMessagingUtilities.h"
#import <UIKit/UIKit.h>

@interface DeleteConfirmationViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIImageView *backgroundImageView;

@end

@implementation DeleteConfirmationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    //[self setupUI];
    self.title = self.userName;
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ic_exit"] style:UIBarButtonItemStylePlain target:self action:@selector(closeTapped)];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.view.backgroundColor = [UIColor clearColor];
    //self.backgroundImageView.image = self.backgroundImage;
    self.backgroundImageView.alpha = 0;
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        //self.backgroundImageView.alpha = 1;
    } completion:^(BOOL finished) {
        
    }];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Actions
- (IBAction)endChatButtonTapped:(UIButton *)sender {
    //NSError *error;
    [self.conversation delete:2 error:NULL];
    if ([self.parentViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navCon = (UINavigationController *)self.parentViewController;
        [navCon dismissViewControllerAnimated:false completion:^{
            [self.delegate deleteConversation];
        }];
    }
}

- (void)closeTapped {
    if ([self.parentViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navCon = (UINavigationController *)self.parentViewController;
        [navCon dismissViewControllerAnimated:true completion:^{

        }];
    }
}

#pragma mark - Setup
- (void)setupUI {
    self.imageView.layer.cornerRadius = self.imageView.frame.size.height/2;
    self.imageView.layer.borderWidth = 2;
    self.imageView.layer.borderColor = [UIColor vocaleFilterTextColor].CGColor;
}

@end
