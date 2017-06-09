//
//  ConversationViewController.m
//  Layer-Parse-iOS-Example
//
//  Created by Abir Majumdar on 2/28/15.
//  Copyright (c) 2015 Layer. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import <SVProgressHUD/SVProgressHUD.h>
#import <Parse/Parse.h>
#import <Bolts/Bolts.h>
#import "ConversationViewController.h"
#import "ParticipantTableViewController.h"
#import "UserManager.h"
#import "PGConversationImageViewController.h"
#import "KGStatusBar.h"
#import "VoiceNoteCollectionViewCell.h"
#import "VocaleApp-Swift.h"
#import "KGStatusBar.h"
#import "FontAwesomeKit.h"
#import "UserManager.h"
#import "DeleteConfirmationViewController.h"
#import "FadeCustomModalTransition.h"
#import "ProfileDetailViewController.h"
#import "Mixpanel.h"

@interface ConversationViewController () <ATLConversationViewControllerDataSource, ATLConversationViewControllerDelegate, ATLParticipantTableViewControllerDelegate, UIGestureRecognizerDelegate, DeleteConfirmationDelegate, UIViewControllerTransitioningDelegate>

@property (nonatomic) NSDateFormatter *dateFormatter;
@property (nonatomic) NSArray *usersArray;
@property (nonatomic) VoiceNoteRecorder *voiceNoteRecorder;
@property (nonatomic) DGActivityIndicatorView *activityIndicatorView;
@property (strong, nonatomic) UIView *errorView;
@property (nonatomic, strong) UIImageView *loadingSpinner;
@property (nonatomic) BOOL pushed;

@end


@implementation ConversationViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //TODO: CUSTOM CODE
    // Change right accessory button to a star

    [[ATLAvatarImageView appearance] setAvatarImageViewDiameter:60];
     self.messageInputToolbar.rightAccessoryImage = [UIImage imageNamed:@"recordAccessory"];
    [self.messageInputToolbar.rightAccessoryButton.imageView setContentMode:UIViewContentModeScaleAspectFit];
    [self.messageInputToolbar setBarTintColor:[UIColor vocaleBackgroundGreyColor]];
    [self.messageInputToolbar.textInputView setBackgroundColor:[UIColor colorWithRed:0.1f green:0.1f blue:0.1f alpha:1]];
    [self.messageInputToolbar.textInputView setTextColor:[UIColor vocalePlaceholderTextColor]];
    [self.messageInputToolbar setTintColor:[UIColor whiteColor]];
    [self.messageInputToolbar.textInputView setPlaceholder:@"Text Message"];
    [self.messageInputToolbar.textInputView setKeyboardAppearance:UIKeyboardAppearanceDark];
    //[self.navigationItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:@" " style:UIBarButtonItemStyleDone target:nil action:nil]];
    
    self.messageInputToolbar.leftAccessoryImage = [[FAKFontAwesome cameraIconWithSize:22] imageWithSize:CGSizeMake(self.messageInputToolbar.frame.size.height*0.9, self.messageInputToolbar.frame.size.height*0.9)];
    // Register custom cell class for star cell
    [self registerClass:[VoiceNoteCollectionViewCell class] forMessageCellWithReuseIdentifier:@"ATLMIMETypeCustomObjectReuseIdentifier"];
    //TODO: CUSTOM CODE
    
    [self.tabBarController.tabBar setHidden:true];
    self.dataSource = self;
    self.delegate = self;
    self.addressBarController.delegate = self;
    
    // Setup the dateformatter used by the dataSource.
    self.dateFormatter = [[NSDateFormatter alloc] init];
    self.dateFormatter.dateStyle = NSDateFormatterShortStyle;
    self.dateFormatter.timeStyle = NSDateFormatterShortStyle;
    
    self.messageInputToolbar.delegate = self;
    [self configureUI];
    
    UILongPressGestureRecognizer *LongPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(LongPressGesture:)];
    //[self.view addGestureRecognizer:LongPressGesture];
    
    [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"threeDots"] style:UIBarButtonItemStylePlain target:self action:@selector(rightButtonTapped)]];
}

- (void)viewWillAppear:(BOOL)animated {
    self.pushed = false;
    [self configureUI];
    //NSLog(@"HELLO1  %lu", (unsigned long)self.queryController.count);
    //NSLog(@"HELLO2  %@", [self.queryController objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]]);
    long count = (unsigned long)self.queryController.count;
    LYRMessage *message = (LYRMessage *)[self.queryController objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
    //NSLog(@"%@", message.sender.userID);
    //NSLog(@"%@", [PFUser currentUser].objectId);
    //NSLog(@"%ld", count);
    //NSLog(@"%d",[message.sender.userID isEqualToString: [PFUser currentUser].objectId]);
    //NSLog(@"%d", count == 1);
    NSString *receiver = @"";
    for (NSString *participant in self.conversation.participants.allObjects) {
        if (![participant isEqualToString:[PFUser currentUser].objectId]) {
            receiver = participant;
            break;
        }
    }
    
    NSArray *resolvedNames = [[UserManager sharedManager] resolvedNamesFromParticipants:@[receiver]];
    self.title = [resolvedNames firstObject];
    if ([message.sender.userID isEqualToString: [PFUser currentUser].objectId] && count == 1) {
        self.messageInputToolbar.alpha = 0;
        //[SVProgressHUD showErrorWithStatus:@"This user needs to respond before you can send your first message."];
        
        UIView *errorView = [[UIView alloc] initWithFrame:CGRectMake(0, self.navigationController.view.frame.size.height - 100, self.navigationController.view.frame.size.width, 100)];
        errorView.backgroundColor = [UIColor clearColor];
        errorView.hidden = YES;
        [self.navigationController.view addSubview:errorView];
        self.errorView = errorView;
        
        UILabel *textLabel = [[UILabel alloc] initWithFrame:CGRectMake(44, 10, self.navigationController.view.frame.size.width - 88, 80)];
        textLabel.font = [UIFont fontWithName:@"Raleway-Regular" size:15.0];
        textLabel.textAlignment = NSTextAlignmentCenter;
        textLabel.textColor = [UIColor vocaleTextGreyColor];
        textLabel.numberOfLines = 0;
        textLabel.text = @"You will be able to engage in a full chat with this user should they decide to respond to your message here.";
        [errorView addSubview:textLabel];
        
        errorView.transform = CGAffineTransformMakeTranslation(0, 100);
        [UIView animateWithDuration:0.4 delay:0.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            errorView.hidden = NO;
            errorView.transform = CGAffineTransformMakeTranslation(0, 0);
        } completion:^(BOOL finished) {
            
        }];
        
        /*
        for (LYRActor *actor in self.conversation.participants) {
            if (![(NSString *)actor isEqualToString: [PFUser currentUser].objectId]) {
                [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"You need to wait for %@ to respond before you can send your first message.", actor.name]];
            }
        }*/
        //[self.navigationController popViewControllerAnimated:TRUE];
    } else if (!(self.messageInputToolbar.alpha == 1)) {
        self.messageInputToolbar.alpha = 1;
    }
    
    NSArray *blockedUsers = [[NSUserDefaults standardUserDefaults] objectForKey:@"BanUsers"];
    for (NSString *blockedUser in blockedUsers) {
        if ([receiver isEqualToString:blockedUser]) {
            self.messageInputToolbar.alpha = 0;
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Warning" message:@"You are no longer able to contact this user" preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                
            }]];
            
            [self presentViewController:alert animated:true completion:nil];
        }
    }
}

- (void)rightButtonTapped {
//    [SVProgressHUD showWithStatus:@"Finding Event Details"];
//    NSString *searchID = @"";
//    for (NSString *participant in self.conversation.participants) {
//        // TODO: REMOVE comments:
//        //if (![participant isEqualToString:[PFUser currentUser].objectId]) {
//            searchID = participant;
//            break;
//        //}
//    }
//    NSLog(searchID);
//    PFUser *user = [[UserManager sharedManager] cachedUserForUserID:searchID];
//    if (!user) {
//        [[UserManager sharedManager] queryAndCacheUsersWithIDs:@[searchID] completion:^(NSArray *participants, NSError *error) {
//            if (participants && error == nil) {
//                __block PFUser *user = (PFUser *) participants.firstObject;
//                PFQuery *query = [PFQuery queryWithClassName:@"Event"];
//                [query whereKey:@"owner" equalTo:user];
//                [query getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
//                    [SVProgressHUD dismiss];
//                    NSLog(@"%@", object);
//                        if (error == NULL) {
//                             NSLog(@"NONNULL");
//                        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
//                            MessageEventTableViewController *eventController = [storyboard instantiateViewControllerWithIdentifier:@"messageEventController"];
//                            eventController.woutReturnButton = true;
//                            //eventController.shouldSwipeRight = false;
//                        eventController.event = (Event *)object;
//                            eventController.conversationListController = self.conversationListController;
//                            self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:self.navigationItem.backBarButtonItem.style target:nil action:nil];
//                        [self.navigationController pushViewController:eventController animated:true];
//                    }
//                }];
//            } else {
//                NSLog(@"Error querying for users: %@", error);
//            }
//        }];
//    } else {
//        PFQuery *query = [PFQuery queryWithClassName:@"Event"];
//        [query whereKey:@"owner" equalTo:user];
//        [query getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
//            if (error == NULL) {
//                UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
//                MessageEventTableViewController *eventController = [storyboard instantiateViewControllerWithIdentifier:@"messageEventController"];
//                eventController.woutReturnButton = true;
//                //eventController.shouldSwipeRight = false;
//                eventController.event = (Event *)object;
//                eventController.conversation = self.conversation;
//                eventController.conversationListController = self.conversationListController;
//                self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:self.navigationItem.backBarButtonItem.style target:nil action:nil];
//                [self.navigationController pushViewController:eventController animated:true];
//            }
//        }];
//    }
    [self.messageInputToolbar.textInputView endEditing:true];
    [self.messageInputToolbar.textInputView resignFirstResponder];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:@"OPTIONS" preferredStyle:UIAlertControllerStyleActionSheet];
    [alert addAction:[UIAlertAction actionWithTitle:@"Report" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        PFObject *report = [PFObject objectWithClassName:@"ReportCase"];
        report[@"claimant"] = [PFUser currentUser];
        NSString *receiver = @"";
        for (NSString *participant in self.conversation.participants.allObjects) {
            if (![participant isEqualToString:[PFUser currentUser].objectId]) {
                receiver = participant;
            }
        }
        
        __block NSString *message = @"";
        __block NSString *mail = @"report@vocale.io";
        PFUser *user = [[UserManager sharedManager] cachedUserForUserID:receiver];
        if (!user) {
            [[UserManager sharedManager] queryAndCacheUsersWithIDs:@[receiver] completion:^(NSArray *participants, NSError *error) {
                if (participants && error == nil) {
                    report[@"accused"] = [participants firstObject];
                } else {
                    NSLog(@"Error querying for users: %@", error);
                }
            }];
        } else {
            report[@"accused"] = user;
        }
        
        if (user.firstName != nil) {
            message = [NSString stringWithFormat:@"%@ \nREPORTED USER NAME: %@", message, [PFUser currentUser].firstName];
        }
        
        if (user.username != nil) {
            message = [NSString stringWithFormat:@"%@ \nREPORTED USER ID: %@", message, [PFUser currentUser].username];
        }
        
        if (user.email != nil) {
            message = [NSString stringWithFormat:@"%@ \nREPORTED USER EMAIL: %@", message, [PFUser currentUser].email];
        }
        
        UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
        CustomTextInputViewController *reportController = [mainStoryboard instantiateViewControllerWithIdentifier:@"TextInputVC"];
        reportController.inputTooltipText = @"See something you didn’t like? Tell us more.";
        reportController.navigationItem.title = @"Report";
        reportController.confirmationText = @"Message sent";
        reportController.confirmationDescription = @"Thank you for your report";
        reportController.isReport = true;
        reportController.didFinishTypingWithText = ^(NSString *text, BOOL isBlocked) {
            report[@"message"] = text;
            
            if ([PFUser currentUser].firstName != nil) {
                message = [NSString stringWithFormat:@"%@ \n\nNAME: %@", message, [PFUser currentUser].firstName];
            }
            
            if ([PFUser currentUser].username != nil) {
                message = [NSString stringWithFormat:@"%@\nID: %@", message, [PFUser currentUser].username];
            }
            
            if ([PFUser currentUser].email != nil) {
                message = [NSString stringWithFormat:@"%@\nEMAIL: %@", message, [PFUser currentUser].email];
                mail = [PFUser currentUser].email;
            }
            
            if ([PFUser currentUser].username != nil) {
                message = [NSString stringWithFormat:@"%@\nID: %@", message, [PFUser currentUser].username];
            }
            
            message = [NSString stringWithFormat:@"%@\nMESSAGE: %@", message, text];
            [self sendMailFrom:mail to:@"report@vocale.io" subject:@"Report" message:message];
            
            [report saveEventually];
            
            if ([PFUser currentUser] != nil && isBlocked == true) {
                PFUser *currentUser = [PFUser currentUser];
                PFUser *blockedUser = report[@"accused"];
                
                PFQuery *userQuery = [PFQuery queryWithClassName:@"BlockedUsers"];
                [userQuery whereKey:@"userId" equalTo:currentUser.objectId];
                [userQuery getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
                    if (error) {
                        if (error.code == 101) {
                            PFObject *user = [PFObject objectWithClassName:@"BlockedUsers"];
                            user[@"userId"] = currentUser.objectId;
                            user[@"name"] = currentUser.firstName;
                            [user addUniqueObject:blockedUser forKey:@"blockedUsers"];
                            [user saveInBackground];
                        }
                    } else {
                        PFUser *user = (PFUser *)object;
                        [user addUniqueObject:blockedUser forKey:@"blockedUsers"];
                        [user saveInBackground];
                    }
                }];
                
                PFQuery *blockedUserQuery = [PFQuery queryWithClassName:@"BlockedUsers"];
                [blockedUserQuery whereKey:@"userId" equalTo:blockedUser.objectId];
                [blockedUserQuery getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
                    if (error) {
                        if (error.code == 101) {
                            PFObject *user = [PFObject objectWithClassName:@"BlockedUsers"];
                            user[@"userId"] = blockedUser.objectId;
                            user[@"name"] = blockedUser.firstName;
                            [user addUniqueObject:currentUser forKey:@"blockedUsers"];
                            [user saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                                if (succeeded) {
                                    // The object has been saved.
                                    [[NSNotificationCenter defaultCenter] postNotificationName:@"ReportedUserNotification" object:self];
                                } else {
                                    // There was a problem, check error.description
                                }
                            }];
                        }
                    } else {
                        PFUser *user = (PFUser *)object;
                        [user addUniqueObject:currentUser forKey:@"blockedUsers"];
                        [user saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                            if (succeeded) {
                                // The object has been saved.
                                [[NSNotificationCenter defaultCenter] postNotificationName:@"ReportedUserNotification" object:self];
                            } else {
                                // There was a problem, check error.description
                            }
                        }];
                    }
                }];
            }

        };
        [self.navigationController pushViewController:reportController animated:false];

    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"End Chat" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
        UINavigationController *navCon = [mainStoryboard instantiateViewControllerWithIdentifier:@"DeleteConfirmationVC"];
        
        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
        if ([navCon.topViewController isKindOfClass:[DeleteConfirmationViewController class]]) {
            DeleteConfirmationViewController *deleteVC = (DeleteConfirmationViewController *)navCon.topViewController;
            //deleteVC.backgroundImage = [self customSnapshotFromView:self.collectionView];
            NSString *receiver = @"";
            for (NSString *participant in self.conversation.participants.allObjects) {
                if (![participant isEqualToString:[PFUser currentUser].objectId]) {
                    receiver = participant;
                }
            }
            NSArray *resolvedNames = [[UserManager sharedManager] resolvedNamesFromParticipants:@[receiver]];
            deleteVC.userName = [resolvedNames firstObject];
            deleteVC.delegate = self;
            deleteVC.conversation = self.conversation;
        }
        
        UIBlurEffect * blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        UIVisualEffectView *beView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        beView.frame =  navCon.view.bounds;
        
        navCon.view.backgroundColor = [UIColor clearColor];
        [navCon.view insertSubview:beView atIndex:0];
        
        navCon.modalPresentationStyle = UIModalPresentationCustom;
        navCon.transitioningDelegate = self;
        //navCon.modalPresentationStyle = UIModalPresentationOverCurrentContext;

        [self presentViewController:navCon animated:true completion:nil];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }]];
    
    [self presentViewController:alert animated:true completion:nil];
}

- (void)sendMailFrom:(NSString *)from to:(NSString *)to subject:(NSString *)subject message:(NSString *)message {
    NSString *body = [NSString stringWithFormat:@"to=%@&from=%@&subject=%@&message=%@", to, from, subject, message];
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfiguration];
    NSURL *url = [NSURL URLWithString:@"http://yanev.co/send.php"];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPBody = [body dataUsingEncoding:NSUTF8StringEncoding];
    request.HTTPMethod = @"POST";
    NSURLSessionDataTask *postDataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            NSLog(@"Error: %@", error);
        }
    }];
    
    [postDataTask resume];
}

#pragma mark - UIViewControllerTransitioningDelegate

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented
                                                                  presentingController:(UIViewController *)presenting
                                                                      sourceController:(UIViewController *)source
{
    id<UIViewControllerAnimatedTransitioning> animationController;
    
    if ([presented isKindOfClass:[UINavigationController class]]) {
        FadeCustomModalTransition *animator = [[FadeCustomModalTransition alloc] init];
        animator.appearing = YES;
        animator.duration = 0.35;
        animationController = animator;
    }
    return animationController;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
    id<UIViewControllerAnimatedTransitioning> animationController;
    
    if ([dismissed isKindOfClass:[UINavigationController class]]) {
        FadeCustomModalTransition *animator = [[FadeCustomModalTransition alloc] init];
        animator.appearing = NO;
        animator.duration = 0.35;
        animationController = animator;
    }
    
    return animationController;
}

- (UIImage *)customSnapshotFromView:(UIView *)inputView {
    
    UIGraphicsBeginImageContextWithOptions(inputView.bounds.size, NO, 0);
    [inputView.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    image = [self blurWithCoreImage:image withView:self.collectionView andBlurRadius:@14];
    
    return image;
}

- (UIImage *)blurWithCoreImage:(UIImage *)sourceImage withView:(UIView *)view andBlurRadius:(NSNumber *)radius {
    CIImage *inputImage = [CIImage imageWithCGImage:sourceImage.CGImage];
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    CIFilter *clampFilter = [CIFilter filterWithName:@"CIAffineClamp"];
    [clampFilter setValue:inputImage forKey:@"inputImage"];
    [clampFilter setValue:[NSValue valueWithBytes:&transform objCType:@encode(CGAffineTransform)] forKey:@"inputTransform"];
    
    CIFilter *gaussianBlurFilter = [CIFilter filterWithName: @"CIGaussianBlur"];
    [gaussianBlurFilter setValue:clampFilter.outputImage forKey: @"inputImage"];
    [gaussianBlurFilter setValue:radius forKey:@"inputRadius"];
    
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef cgImage = [context createCGImage:gaussianBlurFilter.outputImage fromRect:[inputImage extent]];
    
    UIGraphicsBeginImageContext(view.frame.size);
    CGContextRef outputContext = UIGraphicsGetCurrentContext();
    
    CGContextScaleCTM(outputContext, 1.0, -1.0);
    CGContextTranslateCTM(outputContext, 0, -view.frame.size.height);
    
    CGContextDrawImage(outputContext, view.frame, cgImage);
    CGImageRelease(cgImage);
    
    CGContextSaveGState(outputContext);
    UIColor *backgroundColor = [[UIColor vocaleBackgroundGreyColor] colorWithAlphaComponent:0.9];
    CGContextSetFillColorWithColor(outputContext, backgroundColor.CGColor);
    CGContextFillRect(outputContext, view.frame);
    CGContextRestoreGState(outputContext);
    
    UIImage *outputImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return outputImage;
}

#pragma mark - DeleteConfirmationDelegate
- (void)deleteConversation {
    [self.navigationController popViewControllerAnimated:true];
}

- (void)viewWillDisappear:(BOOL)animated {
    [SVProgressHUD dismiss];
    [super viewWillDisappear:animated];
    [self.errorView removeFromSuperview];
    [self.loadingSpinner removeFromSuperview];
    [self.conversation markAllMessagesAsRead:nil];
    
//    [UIView animateWithDuration:0.1 delay:0.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
//        self.errorView.transform = CGAffineTransformMakeTranslation(0, 100);
//    } completion:^(BOOL finished) {
//        [self.errorView removeFromSuperview];
//    }];
    
    [[ATLAvatarImageView appearance] setAvatarImageViewDiameter:45];
}

#pragma mark - UI Configuration methods

- (void)configureUI
{
    [[ATLOutgoingMessageCollectionViewCell appearance] setMessageTextColor:[UIColor vocaleTextGreyColor]];
    [[ATLOutgoingMessageCollectionViewCell appearance] setBubbleViewColor: [UIColor vocaleOutgoingBubbleViewColor]];
    [[ATLOutgoingMessageCollectionViewCell appearance] setBubbleViewCornerRadius:4];
    
    [[ATLIncomingMessageCollectionViewCell appearance] setMessageTextColor:[UIColor vocaleIncomingTextColor]];
    [[ATLIncomingMessageCollectionViewCell appearance] setBubbleViewColor: [UIColor vocaleIncomingBubbleViewColor]];
    [[ATLIncomingMessageCollectionViewCell appearance] setBubbleViewCornerRadius:4];
    
    [[ATLAvatarImageView appearance] setAvatarImageViewDiameter:60];

    [self.collectionView setBackgroundColor:[UIColor colorWithRed:33/255 green:20/255 blue:35/255 alpha:1]];
    [self.view setBackgroundColor:[UIColor colorWithRed:33/255 green:30/255 blue:35/255 alpha:1]];
    
    [self.collectionView setBackgroundColor:[UIColor colorWithRed:0.129f green:0.1176f blue:0.137f alpha:1]];
    [self.view setBackgroundColor:[UIColor colorWithRed:0.129f green:0.1176f blue:0.137f alpha:1]];
    
    self.shouldDisplayAvatarItemForOneOtherParticipant = YES;
    self.shouldDisplayAvatarItemForAuthenticatedUser = YES;
    self.avatarItemDisplayFrequency = ATLAvatarItemDisplayFrequencyAll;
}

#pragma mark - ATLConversationViewControllerDelegate methods

- (void)conversationViewController:(ATLConversationViewController *)viewController didSendMessage:(LYRMessage *)message
{
    
 
    LYRMessagePart *part = message.parts[0];
    
    // if message contains the custom mimetype, then return the custom cell reuse identifier
    if([part.MIMEType  isEqual: @"application/json+voicenoteobject"]) {
        [[Mixpanel sharedInstance] track:@"Chat Sent" properties:@{@"type" : @"voice"}];
    } else {
        [[Mixpanel sharedInstance] track:@"Chat Sent" properties:@{@"type" : @"text"}];
    }
//    for (LYRMessagePart *part in message.parts) {
//        if ([part.MIMEType isEqual:ATLMIMETypeLocation]) {
//            //[KGStatusBar showSuccessWithStatus:@"Sending Location..."];
//        }
//    }
}

- (void)conversationViewController:(ATLConversationViewController *)viewController didFailSendingMessage:(LYRMessage *)message error:(NSError *)error
{
    //[KGStatusBar showErrorWithStatus:[NSString stringWithFormat:@"Message failed: %@", error]];
    NSLog(@"Message failed to sent with error: %@", error);
}

- (void)conversationViewController:(ATLConversationViewController *)viewController didSelectMessage:(LYRMessage *)message {
    LYRMessagePart *JPEGMessagePart = ATLMessagePartForMIMEType(message, ATLMIMETypeImageJPEG);
    if (JPEGMessagePart) {
        [self presentImageViewControllerWithMessage:message];
        return;
    }
    LYRMessagePart *PNGMessagePart = ATLMessagePartForMIMEType(message, ATLMIMETypeImagePNG);
    if (PNGMessagePart) {
        [self presentImageViewControllerWithMessage:message];
    }
    LYRMessagePart *locationMessagePart = ATLMessagePartForMIMEType(message, ATLMIMETypeLocation);
    
    if (locationMessagePart) {
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Open Location" message:nil preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Maps" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            Class mapItemClass = [MKMapItem class];
            if (mapItemClass && [mapItemClass respondsToSelector:@selector(openMapsWithItems:launchOptions:)])
            {
                NSString* jsonString = [[NSString alloc] initWithData:locationMessagePart.data encoding:NSUTF8StringEncoding];
                NSData *data = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
                id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake([[json objectForKey:@"lat"] doubleValue], [[json objectForKey:@"lon"] doubleValue]);
                MKPlacemark *placemark = [[MKPlacemark alloc] initWithCoordinate:coordinate
                                                               addressDictionary:nil];
                MKMapItem *mapItem = [[MKMapItem alloc] initWithPlacemark:placemark];
                [mapItem openInMapsWithLaunchOptions:nil];
            }
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            
        }]];
        [self presentViewController:alert animated:true completion:^{
            
        }];
    }
    
    PFUser *user = [[UserManager sharedManager] cachedUserForUserID:message.sender.userID];
    if (!user) {
        [[UserManager sharedManager] queryAndCacheUsersWithIDs:@[message.sender.userID] completion:^(NSArray *participants, NSError *error) {
            if (participants && error == nil) {
                __block PFUser *user = (PFUser *) participants.firstObject;
                PFQuery *query = [PFQuery queryWithClassName:@"Event"];
                [query whereKey:@"owner" equalTo:user];
                [query getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
                    [SVProgressHUD dismiss];
                    //NSLog(@"%@", object);
                    if (error == NULL) {
                        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
//                        MessageEventTableViewController *eventController = [storyboard instantiateViewControllerWithIdentifier:@"messageEventController"];
//                        eventController.woutReturnButton = true;
//                        eventController.shouldSwipeRight = false;
//                        eventController.event = (Event *)object;
//                        eventController.profileViewMode = true;
//                        eventController.conversationListController = self.conversationListController;
//                        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:self.navigationItem.backBarButtonItem.style target:nil action:nil];
//                        //PROFILE REWORK
//                        [self.navigationController pushViewController:eventController animated:true];
                        ProfileDetailViewController *nextVC = [storyboard instantiateViewControllerWithIdentifier:@"ProfileDetails"];
                        nextVC.viewMode = true;
                        Event *event = (Event *)object;
                        if (event.owner[@"name"] != nil) {
                            nextVC.name = event.owner[@"name"];
                        }
                        
                        if (event.owner[@"birthday"] != nil) {
                            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                            [dateFormatter setDateFormat:@"dd/mm/yyyy"];
                            NSDate *birthday = [dateFormatter dateFromString:event.owner[@"birthday"]];
                            
                            NSDate *now = [NSDate date];
                            NSDateComponents *ageComponents = [[NSCalendar currentCalendar]
                                                               components:NSCalendarUnitYear
                                                               fromDate:birthday
                                                               toDate:now
                                                               options:0];
                            NSInteger age = [ageComponents year];
                            nextVC.age = [NSString stringWithFormat:@"%ld", (long)age];
                        }
                        
                        if (event.owner[@"AboutMe"] != nil) {
                            nextVC.profileDescription = event.owner[@"AboutMe"];
                        }
                        
                        if (self.loadingSpinner == nil) {
                            UIImageView *loadingSpinner = [[UIImageView alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2 - 20, self.view.frame.size.height/2 - 20, 40, 40)];
                            loadingSpinner.image = [UIImage imageNamed:@"spinner"];
                            [self.view addSubview:loadingSpinner];
                            self.loadingSpinner = loadingSpinner;
                            CABasicAnimation *rotate;
                            rotate = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
                            rotate.fromValue = [NSNumber numberWithFloat:0];
                            rotate.toValue = [NSNumber numberWithFloat:2*M_PI];
                            rotate.duration = 1;
                            rotate.repeatCount = INFINITY;
                            [self.loadingSpinner.layer addAnimation:rotate forKey:@"10"];
                        }
                        
                        NSMutableArray *imageFiles = [[NSMutableArray alloc] init];
                        NSMutableArray *downloadedImages = [[NSMutableArray alloc] init];
                        for (int i = 1; i < 7; i++) {
                            NSString *currentImage = [NSString stringWithFormat:@"UserImage%d", i];
                            if (event.owner[currentImage] != nil) {
                                [imageFiles addObject:event.owner[currentImage]];
                            }
                        }
                        
                        __block NSInteger currentCount = 0;
                        if (imageFiles.count > 0) {
                            for (PFFile *file in imageFiles) {
                                [file getDataInBackgroundWithBlock:^(NSData * _Nullable data, NSError * _Nullable error) {
                                    if (!error) {
                                        currentCount++;
                                        [downloadedImages addObject:[UIImage imageWithData:data]];
                                        if (self.pushed == false && currentCount == (imageFiles.count + 1)) {
                                            self.pushed = true;
                                            nextVC.images = [downloadedImages copy];
                                            [self.navigationController pushViewController:nextVC animated:true];
                                        }
                                    } else {
                                        [self.loadingSpinner removeFromSuperview];
                                    }
                                }];
                            }
                        }
                        
                        
                        if (event.owner[@"UserImageMain"] != nil) {
                            PFFile *file = (PFFile *)event.owner[@"UserImageMain"];
                            [file getDataInBackgroundWithBlock:^(NSData * _Nullable data, NSError * _Nullable error) {
                                [self.loadingSpinner removeFromSuperview];
                                if (!error) {
                                    currentCount++;
                                    nextVC.profileImage = [UIImage imageWithData:data];
                                    if (self.pushed == false && currentCount == (imageFiles.count + 1)) {
                                        self.pushed = true;
                                        nextVC.images = [downloadedImages copy];
                                        [self.navigationController pushViewController:nextVC animated:true];
                                    }
                                }
                            }];
                        } else if (event.owner[@"FBPictureURL"]) {
                            NSURL *url = [NSURL URLWithString:event.owner[@"FBPictureURL"]];
                            [self downloadImageWithURL:url completionBlock:^(BOOL succeeded, UIImage *image) {
                                nextVC.profileImage = image;
                                currentCount++;
                                [self.loadingSpinner removeFromSuperview];
                                if (self.pushed == false && currentCount == (imageFiles.count + 1)) {
                                    self.pushed = true;
                                    nextVC.images = [downloadedImages copy];
                                    [self.navigationController pushViewController:nextVC animated:true];
                                }
                            }];
                        }
                        
                        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:self.navigationItem.backBarButtonItem.style target:nil action:nil];
                    }
                }];
            } else {
                NSLog(@"Error querying for users: %@", error);
            }
        }];
    } else {
        PFQuery *query = [PFQuery queryWithClassName:@"Event"];
        [query whereKey:@"owner" equalTo:user];
        [query getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
            if (error == NULL) {
                UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
//                MessageEventTableViewController *eventController = [storyboard instantiateViewControllerWithIdentifier:@"messageEventController"];
//                eventController.woutReturnButton = true;
//                eventController.shouldSwipeRight = false;
//                eventController.event = (Event *)object;
//                eventController.profileViewMode = true;
//                eventController.conversationListController = self.conversationListController;
//                self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:self.navigationItem.backBarButtonItem.style target:nil action:nil];
//                //PROFILE REWORK
//                [self.navigationController pushViewController:eventController animated:true];
                ProfileDetailViewController *nextVC = [storyboard instantiateViewControllerWithIdentifier:@"ProfileDetails"];
                nextVC.viewMode = true;
                Event *event = (Event *)object;
                if (event.owner[@"name"] != nil) {
                    nextVC.name = event.owner[@"name"];
                }
                
                if (event.owner[@"birthday"] != nil) {
                    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                    [dateFormatter setDateFormat:@"dd/mm/yyyy"];
                    NSDate *birthday = [dateFormatter dateFromString:event.owner[@"birthday"]];
                    
                    NSDate *now = [NSDate date];
                    NSDateComponents *ageComponents = [[NSCalendar currentCalendar]
                                                       components:NSCalendarUnitYear
                                                       fromDate:birthday
                                                       toDate:now
                                                       options:0];
                    NSInteger age = [ageComponents year];
                    nextVC.age = [NSString stringWithFormat:@"%ld", (long)age];
                }
                
                if (event.owner[@"AboutMe"] != nil) {
                    nextVC.profileDescription = event.owner[@"AboutMe"];
                }
                
                if (self.loadingSpinner == nil) {
                    UIImageView *loadingSpinner = [[UIImageView alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2 - 20, self.view.frame.size.height/2 - 20, 40, 40)];
                    loadingSpinner.image = [UIImage imageNamed:@"spinner"];
                    [self.view addSubview:loadingSpinner];
                    self.loadingSpinner = loadingSpinner;
                    CABasicAnimation *rotate;
                    rotate = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
                    rotate.fromValue = [NSNumber numberWithFloat:0];
                    rotate.toValue = [NSNumber numberWithFloat:2*M_PI];
                    rotate.duration = 1;
                    rotate.repeatCount = INFINITY;
                    [self.loadingSpinner.layer addAnimation:rotate forKey:@"10"];
                }
                NSMutableArray *imageFiles = [[NSMutableArray alloc] init];
                NSMutableArray *downloadedImages = [[NSMutableArray alloc] init];
                for (int i = 1; i < 7; i++) {
                    NSString *currentImage = [NSString stringWithFormat:@"UserImage%d", i];
                    if (event.owner[currentImage] != nil) {
                        [imageFiles addObject:event.owner[currentImage]];
                    }
                }
                
                __block NSInteger currentCount = 0;
                if (imageFiles.count > 0) {
                    for (PFFile *file in imageFiles) {
                        [file getDataInBackgroundWithBlock:^(NSData * _Nullable data, NSError * _Nullable error) {
                            if (!error) {
                                [downloadedImages addObject:[UIImage imageWithData:data]];
                                currentCount++;
                                if (self.pushed == false && currentCount == (imageFiles.count + 1)) {
                                    self.pushed = true;
                                    nextVC.images = [downloadedImages copy];
                                    [self.navigationController pushViewController:nextVC animated:true];
                                }
                            } else {
                                [self.loadingSpinner removeFromSuperview];
                            }
                        }];
                    }
                }
                
                if (event.owner[@"UserImageMain"] != nil) {
                    PFFile *file = (PFFile *)event.owner[@"UserImageMain"];
                    [file getDataInBackgroundWithBlock:^(NSData * _Nullable data, NSError * _Nullable error) {
                        [self.loadingSpinner removeFromSuperview];
                        if (!error) {
                            currentCount++;
                            nextVC.profileImage = [UIImage imageWithData:data];
                            if (self.pushed == false && currentCount == (imageFiles.count + 1)) {
                                self.pushed = true;
                                nextVC.images = [downloadedImages copy];
                                [self.navigationController pushViewController:nextVC animated:true];
                            }
                        }
                    }];
                } else if (event.owner[@"FBPictureURL"]) {
                    NSURL *url = [NSURL URLWithString:event.owner[@"FBPictureURL"]];
                    [self downloadImageWithURL:url completionBlock:^(BOOL succeeded, UIImage *image) {
                        currentCount++;
                        nextVC.profileImage = image;
                        [self.loadingSpinner removeFromSuperview];
                        if (self.pushed == false && currentCount == (imageFiles.count + 1)) {
                            self.pushed = true;
                            nextVC.images = [downloadedImages copy];
                            [self.navigationController pushViewController:nextVC animated:true];
                        }
                    }];
                }
                
                self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:self.navigationItem.backBarButtonItem.style target:nil action:nil];
            }
        }];
    }
}

- (void)downloadImageWithURL:(NSURL *)url completionBlock:(void (^)(BOOL succeeded, UIImage *image))completionBlock
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               if ( !error )
                               {
                                   UIImage *image = [[UIImage alloc] initWithData:data];
                                   completionBlock(YES,image);
                               } else{
                                   completionBlock(NO,nil);
                               }
                           }];
}


- (UIImage *)loadLowResImageForMessage:(LYRMessage *)message {
    LYRMessagePart *lowResImagePart = ATLMessagePartForMIMEType(message, ATLMIMETypeImageJPEGPreview);
    LYRMessagePart *imageInfoPart = ATLMessagePartForMIMEType(message, ATLMIMETypeImageSize);
    
    if (!lowResImagePart) {
        // Default back to image/jpeg MIMEType
        lowResImagePart = ATLMessagePartForMIMEType(message, ATLMIMETypeImageJPEG);
    }
    
    // Retrieve low-res image from message part
    if (!(lowResImagePart.transferStatus == LYRContentTransferReadyForDownload || lowResImagePart.transferStatus == LYRContentTransferDownloading)) {
        if (lowResImagePart.fileURL) {
            return [UIImage imageWithContentsOfFile:lowResImagePart.fileURL.path];
        } else {
            return [UIImage imageWithData:lowResImagePart.data];
        }
    }
    return nil;
}

- (void)presentImageViewControllerWithMessage:(LYRMessage *)message {
    // Create image info
    JTSImageInfo *imageInfo = [[JTSImageInfo alloc] init];
    imageInfo.image = [self loadLowResImageForMessage:message];
    
    // Setup view controller
    
    
    PGConversationImageViewController *imageViewer = [[PGConversationImageViewController alloc] initWithImageInfo:imageInfo mode:JTSImageViewControllerMode_Image backgroundStyle:JTSImageViewControllerBackgroundOption_Scaled message:message];
    // Present the view controller.
    [imageViewer showFromViewController:self transition:JTSImageViewControllerTransition_FromOffscreen];
}

#pragma mark - ATLConversationViewControllerDataSource methods

- (id<ATLParticipant>)conversationViewController:(ATLConversationViewController *)conversationViewController participantForIdentifier:(NSString *)participantIdentifier
{
    if ([participantIdentifier isEqualToString:[PFUser currentUser].objectId]) return [PFUser currentUser];
    PFUser *user = [[UserManager sharedManager] cachedUserForUserID:participantIdentifier];
    if (!user) {
        [[UserManager sharedManager] queryAndCacheUsersWithIDs:@[participantIdentifier] completion:^(NSArray *participants, NSError *error) {
            if (participants && error == nil) {
                [self.addressBarController reloadView];
                // TODO: Need a good way to refresh all the messages for the refreshed participants...
                [self reloadCellsForMessagesSentByParticipantWithIdentifier:participantIdentifier];
            } else {
                NSLog(@"Error querying for users: %@", error);
            }
        }];
    }
    return user;
}

- (NSAttributedString *)conversationViewController:(ATLConversationViewController *)conversationViewController attributedStringForDisplayOfDate:(NSDate *)date
{
    NSDictionary *attributes = @{NSFontAttributeName : [UIFont fontWithName:@"Raleway-Regular" size:14],
                                 NSForegroundColorAttributeName : [UIColor grayColor] };
    return [[NSAttributedString alloc] initWithString:[self.dateFormatter stringFromDate:date] attributes:attributes];
}

- (NSAttributedString *)conversationViewController:(ATLConversationViewController *)conversationViewController attributedStringForDisplayOfRecipientStatus:(NSDictionary *)recipientStatus
{
    if (recipientStatus.count == 0) return nil;
    NSMutableAttributedString *mergedStatuses = [[NSMutableAttributedString alloc] init];
    
    [[recipientStatus allKeys] enumerateObjectsUsingBlock:^(NSString *participant, NSUInteger idx, BOOL *stop) {
        LYRRecipientStatus status = [recipientStatus[participant] unsignedIntegerValue];
        if ([participant isEqualToString:self.layerClient.authenticatedUserID]) {
            return;
        }
        
        NSString *checkmark = @"Sending";
        UIColor *textColor = [UIColor lightGrayColor];
        if (status == LYRRecipientStatusSent) {
            checkmark = @"Sent";
        } else if (status == LYRRecipientStatusDelivered) {
            checkmark = @"Delivered";
        } else if (status == LYRRecipientStatusRead) {
            checkmark = @"Read";
        }
        NSAttributedString *statusString = [[NSAttributedString alloc] initWithString:checkmark attributes:@{NSFontAttributeName : [UIFont fontWithName:@"Raleway-Regular" size:14], NSForegroundColorAttributeName: textColor}];
        [mergedStatuses appendAttributedString:statusString];
    }];
    return mergedStatuses;
}


#pragma mark - ATLAddressBarViewController Delegate methods methods

- (void)addressBarViewController:(ATLAddressBarViewController *)addressBarViewController didTapAddContactsButton:(UIButton *)addContactsButton
{
    [[UserManager sharedManager] queryForAllUsersWithCompletion:^(NSArray *users, NSError *error) {
        if (!error) {
            ParticipantTableViewController *controller = [ParticipantTableViewController participantTableViewControllerWithParticipants:[NSSet setWithArray:users] sortType:ATLParticipantPickerSortTypeFirstName];
            controller.delegate = self;
            
            UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
            [self.navigationController presentViewController:navigationController animated:YES completion:nil];
        } else {
            NSLog(@"Error querying for All Users: %@", error);
        }
    }];
}

-(void)addressBarViewController:(ATLAddressBarViewController *)addressBarViewController searchForParticipantsMatchingText:(NSString *)searchText completion:(void (^)(NSArray *))completion
{
    [[UserManager sharedManager] queryForUserWithName:searchText completion:^(NSArray *participants, NSError *error) {
        if (!error) {
            if (completion) completion(participants);
        } else {
            NSLog(@"Error search for participants: %@", error);
        }
    }];
}

#pragma mark - ATLParticipantTableViewController Delegate Methods

- (void)participantTableViewController:(ATLParticipantTableViewController *)participantTableViewController didSelectParticipant:(id<ATLParticipant>)participant
{
    //NSLog(@"participant: %@", participant);
    [self.addressBarController selectParticipant:participant];
    //NSLog(@"selectedParticipants: %@", [self.addressBarController selectedParticipants]);
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)participantTableViewController:(ATLParticipantTableViewController *)participantTableViewController didSearchWithString:(NSString *)searchText completion:(void (^)(NSSet *))completion
{
    [[UserManager sharedManager] queryForUserWithName:searchText completion:^(NSArray *participants, NSError *error) {
        if (!error) {
            if (completion) completion([NSSet setWithArray:participants]);
        } else {
            NSLog(@"Error search for participants: %@", error);
        }
    }];
}



#pragma mark - Custom Code

- (NSOrderedSet *)conversationViewController:(ATLConversationViewController *)viewController messagesForMediaAttachments:(NSArray *)mediaAttachments
{
    // If there are no mediaAttachments then we know that the Star button was pressed
    /*if (mediaAttachments.count == 0)
    {
        // Create messagepart with cell title
        NSDictionary *dataDictionary = @{@"title":@"You are a star!"};
        NSError *JSONSerializerError;
        NSData *dataDictionaryJSON = [NSJSONSerialization dataWithJSONObject:dataDictionary options:NSJSONWritingPrettyPrinted error:&JSONSerializerError];
        LYRMessagePart *dataMessagePart = [LYRMessagePart messagePartWithMIMEType:@"application/json+voicenoteobject" data:dataDictionaryJSON];
        // Create messagepart with info about cell
        NSDictionary *cellInfoDictionary = @{@"height":@"100"};
        NSData *cellInfoDictionaryJSON = [NSJSONSerialization dataWithJSONObject:cellInfoDictionary options:NSJSONWritingPrettyPrinted error:&JSONSerializerError];
        LYRMessagePart *cellInfoMessagePart = [LYRMessagePart messagePartWithMIMEType:@"application/json+voicenoteinfo" data:cellInfoDictionaryJSON];
        // Add message to ordered set.  This ordered set messages will get sent to the participants
        NSError *error;
        LYRMessage *message = [self.layerClient newMessageWithParts:@[dataMessagePart,cellInfoMessagePart] options:nil error:&error];
        NSOrderedSet *messageSet = [[NSOrderedSet alloc] initWithObject:message];
        return messageSet;
    }*/
    
    if (mediaAttachments.count == 0) {
        [self.view endEditing:YES];
        //        EventCardManager *manager = [[EventCardManager alloc] initWithFrame:CGRectMake(0,self.navigationController.view.frame.size.height - self.navigationController.view.frame.size.width + 50 ,self.navigationController.view.frame.size.width, self.navigationController.view.frame.size.width)];
        
        CGFloat height = 0;
        CGFloat yOffset = 0;
        if (self.navigationController.view.frame.size.width <= 320) {
            height = 70;
            yOffset = 26;
        } else if (self.navigationController.view.frame.size.width < 414) {
            height = 88;
            yOffset = 38;
            if (UIScreen.mainScreen.nativeScale == 2.8f) { //ZOOMED MODE
                height = 88;
                yOffset = 53;
            }
        } else {
            height = 88;
            yOffset = 53;
        }
        
        EventCardManager *manager = [[EventCardManager alloc] initWithFrame:CGRectMake(30, self.navigationController.view.frame.size.width + yOffset + 70, self.navigationController.view.frame.size.width - 60, height) screenWidth:self.navigationController.view.frame.size.width];
        
        manager.bookmarkingEnabled = false;
        manager.conversationController = self;
        manager.chatSection = true;
        manager.backgroundColor = [UIColor clearColor];
        [manager setAlpha:0];
        
        NSString *receiver = @"";
        for (NSString *participant in self.conversation.participants.allObjects) {
            if (![participant isEqualToString:[PFUser currentUser].objectId]) {
                receiver = participant;
                break;
            }
        }
        //NSString *receiver = [self.conversation.participants.allObjects firstObject];
        UIView *statusBarView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 10)];
        statusBarView.backgroundColor = [UIColor vocaleRECViewBackgroundColor];
        
        id<ATLParticipant> participant = [self conversationViewController:self participantForIdentifier:receiver];
        UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 10, self.view.frame.size.width, 60)];
        nameLabel.backgroundColor = [UIColor vocaleRECViewBackgroundColor];
        nameLabel.textColor = [UIColor vocaleGreyColor];
        nameLabel.font = [UIFont fontWithName:@"Raleway-SemiBold" size:23];
        nameLabel.textAlignment = NSTextAlignmentCenter;
        nameLabel.text = [NSString stringWithFormat:@"%@", self.title];
        
        UIImageView *profileImage = [[UIImageView alloc] initWithFrame:CGRectMake(0, 60, self.view.frame.size.width, self.view.frame.size.width)];
        
        if ([participant hasCustomProfileImage]) {
            [[participant avatarImageFile] getDataInBackgroundWithBlock:^(NSData * _Nullable data, NSError * _Nullable error) {
                if (error != nil) {
                    
                } else {
                    UIImage *image = [UIImage imageWithData:data];
                    profileImage.image = image;
                }
            }];
        } else {
            [profileImage sd_setImageWithURL:[participant avatarImageURL] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                if (image != nil) {
                    //[profileImage applyCircularMask];
                }
            }];
        }
        
        UILabel *recordingView = [[UILabel alloc] init];
        recordingView.textColor = [UIColor vocaleTextGreyColor];
        recordingView.textAlignment = NSTextAlignmentCenter;
        recordingView.font = [UIFont fontWithName:@"Raleway-Bold" size:16];
        recordingView.frame = CGRectMake(0, self.navigationController.view.frame.size.height - 40, self.view.frame.size.width, 40);
        recordingView.backgroundColor = [UIColor vocaleRECViewBackgroundColor];
        NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
        attachment.image = [UIImage imageNamed:@"redDot"];
        NSAttributedString *attachmentString = [NSAttributedString attributedStringWithAttachment:attachment];
        NSMutableAttributedString *myString = [[NSMutableAttributedString alloc] initWithString:@" REC"];
        [myString insertAttributedString:attachmentString atIndex:0];
        recordingView.attributedText = myString;
        
        UIView *containerView = [[UIView alloc] initWithFrame:self.navigationController.view.bounds];
        [containerView setBackgroundColor:[UIColor vocaleBackgroundGreyColor]];
        
        [containerView addSubview:profileImage];
        [containerView addSubview:manager];
        [containerView addSubview:nameLabel];
        [containerView addSubview:statusBarView];
        [containerView addSubview:recordingView];
        [manager recordButtonTapped];
        [manager setCancelHandler:^{
            [UIView animateWithDuration:0.6 delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0.4 options:UIViewAnimationOptionCurveEaseOut animations:^{
                containerView.alpha = 0;
                
            } completion:^(BOOL finished) {
                if (finished) {
                    self.messageInputToolbar.alpha = 1;
                    [self.collectionView reloadData];
                    //[self.messageInputToolbar setHidden:FALSE];
                    [containerView removeFromSuperview];
                   
                }
            }];
        }];
        [UIView animateWithDuration:0.6 delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0.4 options:UIViewAnimationOptionCurveEaseOut animations:^{
            manager.alpha = 1;
            
        } completion:^(BOOL finished) {
            if (finished) {
                //[self.messageInputToolbar setHidden:TRUE];
            }
        }];
        [self.view endEditing:TRUE];
        [self.navigationController.view addSubview:containerView];
    }
    
    return nil;
}

- (NSString *)conversationViewController:(ATLConversationViewController *)viewController reuseIdentifierForMessage:(LYRMessage *)message
{
    LYRMessagePart *part = message.parts[0];
    
    // if message contains the custom mimetype, then return the custom cell reuse identifier
    if([part.MIMEType  isEqual: @"application/json+voicenoteobject"])
    {
        return @"ATLMIMETypeCustomObjectReuseIdentifier";
    }
    return nil;
}

- (CGFloat)conversationViewController:(ATLConversationViewController *)viewController heightForMessage:(LYRMessage *)message withCellWidth:(CGFloat)cellWidth
{
    
    LYRMessagePart *part = message.parts[0];
    
    // if message contains the custom mimetype, then grab the cell info from the other message part
    if([part.MIMEType isEqual: @"application/json+voicenoteobject"])
    {
//        LYRMessagePart *cellMessagePart = message.parts[1];
//        NSData *data = cellMessagePart.data;
//        NSError* error;
//        NSDictionary* json = [NSJSONSerialization JSONObjectWithData:data
//                                                             options:kNilOptions
//                                                               error:&error];
//        
//        // Grab the height value from the JSON
//        NSString *height = [json objectForKey:@"height"];
//        NSInteger heightInt = [height integerValue];
//        return heightInt;
        return 90;
    }
    return 0;
}


#pragma mark - LongPressGestureRecognizer Delegate

- (void)LongPressGesture:(UILongPressGestureRecognizer *)sender{
    [self.view endEditing:true];
    [self.navigationController.navigationBar setHidden:true];
    if (sender.state == UIGestureRecognizerStateBegan){
        self.voiceNoteRecorder = [[VoiceNoteRecorder alloc] initWithFrame:CGRectMake(0, [[UIApplication sharedApplication] statusBarFrame].size.height, self.view.frame.size.width, self.view.frame.size.height-[[UIApplication sharedApplication] statusBarFrame].size.height)];
        self.voiceNoteRecorder.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.7];
        [self.view addSubview:self.voiceNoteRecorder];
        [self.voiceNoteRecorder startRecording];
        
        self.activityIndicatorView = [[DGActivityIndicatorView alloc] initWithType:DGActivityIndicatorAnimationTypeBallClipRotatePulse tintColor:[UIColor vocaleRedColor] size:140];
        [self.view addSubview:self.activityIndicatorView];
        [self.activityIndicatorView startAnimating];
        
    } else if (sender.state == UIGestureRecognizerStateEnded) {
        [self.navigationController.navigationBar setHidden:false];
        BOOL willUpload = true;
        UIButton *button = [self.voiceNoteRecorder hitTest:[sender locationOfTouch:[sender numberOfTouches]-1 inView:self.voiceNoteRecorder] withEvent:nil];
        if (button.tag == self.voiceNoteRecorder.cancelButton.tag) {
            [self.voiceNoteRecorder cancelRecordingOBJC];
            [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0.4 options:UIViewAnimationCurveEaseIn animations:^{
                self.voiceNoteRecorder.alpha = 0;
                self.activityIndicatorView.alpha = 0;
                
            } completion:^(BOOL finished) {
                [self.activityIndicatorView removeFromSuperview];
                [self.voiceNoteRecorder removeFromSuperview];
            }];
        } else {
            [self.voiceNoteRecorder stopRecordingOBJC];
            [[NSNotificationCenter defaultCenter] addObserverForName:@"recordedAudio.saved" object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
                [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0.4 options:UIViewAnimationCurveEaseIn animations:^{
                    self.voiceNoteRecorder.alpha = 0;
                    self.activityIndicatorView.alpha = 0;
                } completion:^(BOOL finished) {
                    [self.voiceNoteRecorder removeFromSuperview];
                    [self.voiceNoteRecorder removeFromSuperview];
                    while (true) {
                        if (self.voiceNoteRecorder.isRecording) {
                            
                        } else {
                            
                            [self createAndSendVoicenoteMessage];
                            break;
                        }
                    }
                }];
            }];
            /*while (true) {
             if (self.voiceNoteRecorder.isRecording) {
             
             } else {
             [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0.4 options:UIViewAnimationCurveEaseIn animations:^{
             self.voiceNoteRecorder.alpha = 0;
             } completion:^(BOOL finished) {
             [self.voiceNoteRecorder removeFromSuperview];
             }];
             break;
             }
             }*/
        }
    }
    
    [self.activityIndicatorView setCenter:[sender locationOfTouch:[sender numberOfTouches]-1 inView:self.view]];
}

- (void) createAndSendVoicenoteMessage {
    
    
    // Create messagepart with cell title
    NSDictionary *dataDictionary = @{@"title":@"You are a star!"};
    NSError *JSONSerializerError;
    NSData *dataDictionaryJSON = [NSJSONSerialization dataWithJSONObject:dataDictionary options:NSJSONWritingPrettyPrinted error:&JSONSerializerError];
    LYRMessagePart *dataMessagePart = [LYRMessagePart messagePartWithMIMEType:@"application/json+voicenoteobject" data:dataDictionaryJSON];
    // Create messagepart with info about cell
    NSDictionary *cellInfoDictionary = @{@"height":@"30"};
    NSData *cellInfoDictionaryJSON = [NSJSONSerialization dataWithJSONObject:cellInfoDictionary options:NSJSONWritingPrettyPrinted error:&JSONSerializerError];
    LYRMessagePart *cellInfoMessagePart = [LYRMessagePart messagePartWithMIMEType:@"application/json+voicenoteinfo" data:cellInfoDictionaryJSON];
    // Add message to ordered set.  This ordered set messages will get sent to the participants
    NSError *error;
    
    NSURL *url = self.voiceNoteRecorder.audioFileURL;
    NSData *data = [[NSData alloc] initWithContentsOfURL:url];
    NSString *dataType = @"application/json+voicenoteobject";
    LYRMessagePart *voiceNotePart = [LYRMessagePart messagePartWithMIMEType:dataType data:data];
    LYRMessage *message = [self.layerClient newMessageWithParts:@[dataMessagePart,cellInfoMessagePart, voiceNotePart] options:nil error:&error];
    
    [self sendMessage:message];
}


@end
