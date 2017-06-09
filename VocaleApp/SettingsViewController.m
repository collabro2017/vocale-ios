//
//  SettingsViewController.m
//  VocaleApp
//
//  Created by Vladimir Kadurin on 6/18/16.
//  Copyright © 2016 Rayno Willem Mostert. All rights reserved.
//

#import "SettingsViewController.h"
#import "VocaleApp-Swift.h"
#import "NotificationTableViewCell.h"
#import "ContactTableViewCell.h"
#import "LegalTableViewCell.h"
#import "HeaderTableViewCell.h"
#import "WebViewController.h"
#import "Mixpanel.h"

typedef NS_ENUM(NSInteger, SectionType) {
    SectionTypeNotifications=2,
    SectionTypeContact=0,
    SectionTypeLegal=1
};

@interface SettingsViewController () <UITableViewDataSource, UITableViewDelegate, NotificationSwitchProtocol>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) UIImageView *loadingSpinner;
@property (nonatomic, strong) UIView *deleteView;

@end

@implementation SettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    
    [[Mixpanel sharedInstance] track:@"Settings (App info)"];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.title = @"App Info";
    [self.navigationController setToolbarHidden:true animated:false];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.title = @"";
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == SectionTypeNotifications) {
        return 2;
    } else if (section == SectionTypeContact) {
        return 3;
    } else {
        return 2;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == SectionTypeNotifications) {
        NotificationTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"NotificationCell" forIndexPath:indexPath];
        if (indexPath.row == 0) {
            cell.titleLabel.text = @"Responses to Posts";
            if ([[NSUserDefaults standardUserDefaults] boolForKey:@"notificationSwitchResponses"] == true) {
                cell.onButton.selected = true;
                cell.offButton.selected = false;
            } else {
                cell.onButton.selected = false;
                cell.offButton.selected = true;
            }
        } else {
            cell.titleLabel.text = @"Chat Messages";
            if ([[NSUserDefaults standardUserDefaults] boolForKey:@"notificationSwitchChat"] == true) {
                cell.onButton.selected = true;
                cell.offButton.selected = false;
            } else {
                cell.onButton.selected = false;
                cell.offButton.selected = true;
            }
        }
        cell.onButton.tag = indexPath.row;
        cell.offButton.tag = indexPath.row;
        cell.delegate = self;
        
        return cell;
    } else if (indexPath.section == SectionTypeContact) {
        ContactTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ContactCell" forIndexPath:indexPath];
        if (indexPath.row == 0) {
            cell.titleLabel.text = @"Help and Support";
        } else if (indexPath.row == 1) {
            cell.titleLabel.text = @"Give us Feedback";
        } else {
            cell.titleLabel.text = @"Share Vocale";
        }
        return cell;
    } else {
        LegalTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"LegalCell" forIndexPath:indexPath];
        if (indexPath.row == 0) {
            cell.titleLabel.text = @"Privacy Policy";
        } else if (indexPath.row == 1) {
            cell.titleLabel.text = @"Terms of Use";
        } else {
            cell.titleLabel.text = @"License";
        }
        return cell;
    }
}

#pragma mark - NotificationSwitchDelegate
- (void)notificationSwitch:(UIButton *)button enabled:(BOOL)enabled {
    if (button.tag == 0) {
        [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:@"notificationSwitchResponses"];
    } else {
        [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:@"notificationSwitchChat"];
    }
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == SectionTypeContact) {
        if (indexPath.row == 0) {
            PFObject *report = [PFObject objectWithClassName:@"ReportCase"];
            report[@"claimant"] = [PFUser currentUser];
            UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
            CustomTextInputViewController *reportController = [mainStoryboard instantiateViewControllerWithIdentifier:@"TextInputVC"];
            reportController.inputTooltipText = @"Need assistance with something? Get in touch.";
            reportController.navigationItem.title = @"Help";
            reportController.confirmationText = @"Message sent";
            reportController.confirmationDescription = @"We’ll get back to you shortly.";
            reportController.didFinishTypingWithText = ^(NSString *text, BOOL isBlocked) {
                report[@"message"] = text;
                NSString *message = @"";
                NSString *mail = @"help@vocale.io";
                
                if ([PFUser currentUser].firstName != nil) {
                    message = [NSString stringWithFormat:@"NAME: %@", [PFUser currentUser].firstName];
                }
                
                if ([PFUser currentUser].username != nil) {
                    message = [NSString stringWithFormat:@"%@\nID: %@", message, [PFUser currentUser].username];
                }
                
                if ([PFUser currentUser].email != nil) {
                    message = [NSString stringWithFormat:@"%@\nEMAIL: %@", message, [PFUser currentUser].email];
                    mail = [PFUser currentUser].email;
                }
                
                message = [NSString stringWithFormat:@"%@\nMESSAGE: %@", message, text];
                [self sendMailFrom:mail to:@"help@vocale.io" subject:@"Help" message:message];
                [report saveEventually];
                
                [[Mixpanel sharedInstance] track:@"Settings (Help)" properties:@{@"text" : message}];
            };
            [self.navigationController pushViewController:reportController animated:false];
        } else if (indexPath.row == 1) {
            PFObject *report = [PFObject objectWithClassName:@"ReportCase"];
            report[@"claimant"] = [PFUser currentUser];
            UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
            CustomTextInputViewController *reportController = [mainStoryboard instantiateViewControllerWithIdentifier:@"TextInputVC"];
            reportController.inputTooltipText = @"Have thoughts or ideas about Vocale? Let us know.";
            reportController.navigationItem.title = @"Feedback";
            reportController.confirmationText = @"Message sent";
            reportController.confirmationDescription = @"Thank you for your feedback.";
            reportController.didFinishTypingWithText = ^(NSString *text, BOOL isBlocked) {
                report[@"message"] = text;
                NSString *message = @"";
                NSString *mail = @"feedback@vocale.io";
                
                if ([PFUser currentUser].firstName != nil) {
                    message = [NSString stringWithFormat:@"NAME: %@", [PFUser currentUser].firstName];
                }
                
                if ([PFUser currentUser].username != nil) {
                    message = [NSString stringWithFormat:@"%@\nID: %@", message, [PFUser currentUser].username];
                }
                
                if ([PFUser currentUser].email != nil) {
                    message = [NSString stringWithFormat:@"%@\nEMAIL: %@", message, [PFUser currentUser].email];
                    mail = [PFUser currentUser].email;
                }
                
                message = [NSString stringWithFormat:@"%@\nMESSAGE: %@", message, text];
                [self sendMailFrom:mail to:@"feedback@vocale.io" subject:@"Feedback" message:message];
                [report saveEventually];
                
                [[Mixpanel sharedInstance] track:@"Settings (Feedback)" properties:@{@"text" : message}];
            };
            [self.navigationController pushViewController:reportController animated:false];
        } else {
            [self shareApp];
        }
    } else if (indexPath.section == SectionTypeLegal) {
        if (indexPath.row == 0) {
            WebViewController *webVC = [self.storyboard instantiateViewControllerWithIdentifier:@"WebVC"];
            webVC.isPrivacyPolicy = true;
            [self.navigationController pushViewController:webVC animated:true];
            
            [[Mixpanel sharedInstance] track:@"Settings (Privacy Policy)"];
        } else if (indexPath.row == 1) {
            WebViewController *webVC = [self.storyboard instantiateViewControllerWithIdentifier:@"WebVC"];
            webVC.isTermsAndCondtions = true;
            [self.navigationController pushViewController:webVC animated:true];
            
            [[Mixpanel sharedInstance] track:@"Settings (Terms of Service)"];
        }
    }
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

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {

    HeaderTableViewCell *header = [tableView dequeueReusableCellWithIdentifier:@"HeaderCell"];
    if (section == SectionTypeNotifications) {
        header.titleLabel.text = @"NOTIFICATIONS";
    } else if (section == SectionTypeContact) {
        header.titleLabel.text = @"CONTACT";
    } else {
        header.titleLabel.text = @"LEGAL";
    }
    return header;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 50.0f;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 1)];
    footer.backgroundColor = [UIColor vocaleIncomingBubbleViewColor];
    return footer;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 1;
}

#pragma mark - IBActions
- (IBAction)deleteAccount:(UIButton *)sender {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Delete Account" message:@"Are you sure you want to delete your account? All your posts, responses, chats and settings will be permanently deleted. You can not undo this." preferredStyle:UIAlertControllerStyleActionSheet];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {

        [[NSUserDefaults standardUserDefaults] setBool:false forKey:@"FirstLogin"];
        [[NSUserDefaults standardUserDefaults] setBool:false forKey:@"FirstRecordTapped"];
        [[NSUserDefaults standardUserDefaults] setBool:false forKey:@"PostsFirstTap"];
        [[NSUserDefaults standardUserDefaults] setBool:false forKey:@"FirstResponseTapped"];
        [[NSUserDefaults standardUserDefaults] setBool:false forKey:@"SavedPostsFirstTap"];
        [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"badgeCount"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [UIApplication sharedApplication].applicationIconBadgeNumber = 0;

        if (self.loadingSpinner == nil) {
            self.view.userInteractionEnabled = false;
            self.deleteView = [[UIView alloc] initWithFrame: CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
            self.deleteView.backgroundColor = [UIColor clearColor];
            [[UIApplication sharedApplication].keyWindow addSubview:self.deleteView];
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
        PFQuery *queryResponse = [PFQuery queryWithClassName:@"EventResponse"];
        [queryResponse whereKey:@"repsondent" equalTo:[PFUser currentUser]];
        [queryResponse findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
            for (EventResponse *response in objects) {
                [response deleteInBackground];
            }
        }];
        
        PFQuery *query = [PFQuery queryWithClassName:@"Event"];
        [query whereKey:@"owner" equalTo:[PFUser currentUser]];
        [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
            for (Event *event in objects) {
                [event deleteInBackground];
            }
            
            NSArray *participants = @[AppDelegate.layerClient.authenticatedUserID];
            LYRQuery *query = [LYRQuery queryWithQueryableClass:[LYRConversation class]];
            query.predicate = [LYRPredicate predicateWithProperty:@"participants" predicateOperator:LYRPredicateOperatorIsIn value:participants];
            
            NSError *error2 = nil;
            NSOrderedSet *conversations = [AppDelegate.layerClient executeQuery:query error:&error2];
            if (!error2) {
                for (LYRConversation *conversation in conversations) {
                    [conversation delete:2 error:NULL];
                }
            } else {
                NSLog(@"Query failed with error %@", error);
            }
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [[PFUser currentUser] deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                    [PFUser logOutInBackgroundWithBlock:^(NSError * _Nullable error) {
                        [AppDelegate.layerClient deauthenticateWithCompletion:^(BOOL success, NSError * _Nullable error) {
                            [self.loadingSpinner removeFromSuperview];
                            [self.deleteView removeFromSuperview];
                            self.view.userInteractionEnabled = true;
                            [self.navigationController popToRootViewControllerAnimated:false];
                        }];
                    }];
                }];
            });
        }];
    }]];
    
    [self presentViewController:alert animated:true completion:nil];
}

- (void)shareApp
{
    NSString *textToShare = @"Check out Vocale - The hot new app that lets you have new experiences and meet new people, right now. It's pretty awesome!";
    NSURL *myWebsite = [NSURL URLWithString:@"http://www.vocale.io/"];
    
    NSArray *objectsToShare = @[textToShare, myWebsite];
    
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:objectsToShare applicationActivities:nil];
    
    NSArray *excludeActivities = @[UIActivityTypeAirDrop,
                                   UIActivityTypePrint,
                                   UIActivityTypeAssignToContact,
                                   UIActivityTypeSaveToCameraRoll,
                                   UIActivityTypeAddToReadingList,
                                   UIActivityTypePostToVimeo];
    
    activityVC.excludedActivityTypes = excludeActivities;
    
    [self presentViewController:activityVC animated:YES completion:nil];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
