//
//  ConversationListViewController.m
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


#import "ConversationListViewController.h"
#import "ConversationViewController.h"
#import "VoiceNoteCollectionViewCell.h"
#import <SVProgressHUD/SVProgressHUD.h>
#import "UserManager.h"
#import "ATLConstants.h"
#import "VocaleApp-Swift.h"
#import "Mixpanel.h"

@interface ConversationListViewController () <ATLConversationListViewControllerDelegate, ATLConversationListViewControllerDataSource>
@property (nonatomic, strong) UIView *placeholderView;
@property (nonatomic) NSInteger cachedCount;
@property (nonatomic, strong) UIView *loadingView;
//@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@property (nonatomic, strong) UIImageView *loadingSpinner;
@property (nonatomic) NSInteger chatCount;
@end

@implementation ConversationListViewController

#pragma mark - Lifecycle Methods

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.cachedCount = 0;
    self.dataSource = self;
    self.delegate = self;
    self.displaysAvatarItem = TRUE;
    self.layerClient.autodownloadMIMETypes = [NSSet setWithObjects:ATLMIMETypeImageJPEGPreview, ATLMIMETypeTextPlain, @"application/json+voicenoteobject", nil];
    
  //  [self.tabBarController.tabBar setHidden:false];
    [[ATLConversationTableViewCell appearance] setBackgroundColor:[UIColor colorWithRed:0.129f green:0.1176f blue:0.137f alpha:1]];
    [[ATLConversationTableViewCell appearance] setConversationTitleLabelColor:[UIColor vocaleConversationTitleColor]];
    [[ATLConversationTableViewCell appearance] setConversationTitleLabelFont:[UIFont fontWithName:@"Raleway-Medium" size:16]];
    
    [[ATLConversationTableViewCell appearance] setLastMessageLabelColor:[UIColor vocaleFilterTextColor]];
    [[ATLConversationTableViewCell appearance] setLastMessageLabelFont:[UIFont fontWithName:@"Raleway-Regular" size:16]];
    
    [[ATLConversationTableViewCell appearance] setUnreadMessageIndicatorBackgroundColor:[UIColor vocalePushBlueColor]];
    
    [[ATLConversationTableViewCell appearance] setDateLabelFont:[UIFont fontWithName:@"Raleway-Regular" size:12]];
    [[ATLConversationTableViewCell appearance] setDateLabelColor:[UIColor vocaleConversationTitleColor]];
    
    //[[ATLAvatarImageView appearance] setAvatarImageViewDiameter:60];
    
    //self.tabBarController.view.backgroundColor = [UIColor colorWithRed:0.129f green:0.1176f blue:0.137f alpha:1];
//    self.navigationController.view.backgroundColor = [UIColor colorWithRed:0.129f green:0.1176f blue:0.137f alpha:1];
//    self.tableView.backgroundView.backgroundColor = [UIColor colorWithRed:0.129f green:0.1176f blue:0.137f alpha:1];
//    self.view.window.backgroundColor = [UIColor colorWithRed:0.129f green:0.1176f blue:0.137f alpha:1];
    [self.view setBackgroundColor:[UIColor colorWithRed:0.129f green:0.1176f blue:0.137f alpha:1]];
    //[self.tableView setBackgroundColor:[UIColor colorWithRed:0.129f green:0.1176f blue:0.137f alpha:1]];
  //  UIBarButtonItem *browseItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"browseBarButtonIcon"] style:UIBarButtonItemStylePlain target:self action:@selector(browseToolbarButtonPressed)];
   // [browseItem setTintColor:[UIColor whiteColor]];
   // [self setToolbarItems:@[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],browseItem,[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]] animated:true];
   // [self.navigationController.toolbar setBarTintColor:[UIColor colorWithRed:0.129f green:0.1176f blue:0.137f alpha:1]];
    
    //[self.navigationController setToolbarHidden:true];
    self.searchController.searchBar.hidden = true;
    [self.tableView setBounces:true];
    
    self.title = @"Chats";
    [self.navigationItem setRightBarButtonItem:self.navigationItem.leftBarButtonItem];
    [self.navigationController.navigationItem setRightBarButtonItem:self.navigationItem.leftBarButtonItem];
    [self.navigationItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:@" " style:UIBarButtonItemStyleDone target:nil action:nil]];
    [self.navigationController.navigationItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStyleDone target:nil action:nil]];
    [self.navigationItem setLeftItemsSupplementBackButton:true];
    [self.searchController.searchResultsTableView removeFromSuperview];
    [self.searchController.searchContentsController.view removeFromSuperview];
    [self.navigationItem.backBarButtonItem setTitle:@" "];
    
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
    
    [[Mixpanel sharedInstance] track:@"Chats (Screen)"];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    //[self.navigationController setToolbarHidden:true animated:false];
    self.cachedCount = 0;
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    UIView *loadingView = [[UIView alloc] initWithFrame:CGRectMake(0, 60, self.view.frame.size.width, self.view.frame.size.height)];
    loadingView.backgroundColor = [UIColor vocaleBackgroundGreyColor];
    [self.navigationController.view addSubview:loadingView];
    self.loadingView = loadingView;
//    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"chatsCached"] == true) {
//        [self.loadingView removeFromSuperview];
//    } else {
//        [[NSUserDefaults standardUserDefaults] setBool:true forKey:@"chatsCached"];
//        UIActivityIndicatorView  *spinner = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
//        spinner.center = self.tableView.center;
//        [self.loadingView addSubview:spinner];
//        spinner.hidesWhenStopped = true;
//        spinner.color = [UIColor vocalePushBlueColor];
//        self.spinner = spinner;
//        [spinner startAnimating];
    //}
    UIImageView *loadingSpinner = [[UIImageView alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2 - 20, self.view.frame.size.height/2 - 20, 40, 40)];
    loadingSpinner.image = [UIImage imageNamed:@"spinner"];
    [self.loadingView addSubview:loadingSpinner];
    self.loadingSpinner = loadingSpinner;
    CABasicAnimation *rotate;
    rotate = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
    rotate.fromValue = [NSNumber numberWithFloat:0];
    rotate.toValue = [NSNumber numberWithFloat:2*M_PI];
    rotate.duration = 1;
    rotate.repeatCount = INFINITY;
    [self.loadingSpinner.layer addAnimation:rotate forKey:@"10"];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(avatarDownloaded:) name:@"AvatarDownloadedNotification" object:nil];
    
    [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [self.navigationController setToolbarHidden:true animated:false];
    self.chatCount = self.count;
    if (self.count == 0) {
        [self.loadingView removeFromSuperview];
        [self addNoChatsView];
    }
}

- (void)addNoChatsView {
    UIView *placeholderView = [[UIView alloc] initWithFrame:CGRectMake(0, 60, self.view.frame.size.width, self.view.frame.size.height)];
    placeholderView.backgroundColor = [UIColor clearColor];
    [self.navigationController.view addSubview:placeholderView];
    self.placeholderView = placeholderView;
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2 - 25, self.view.frame.size.height/2 - 25 -60, 50, 50)];
    imageView.image = [UIImage imageNamed:@"noChatsIcon"];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    [placeholderView addSubview:imageView];
    
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = @"NO CHATS YET";
    titleLabel.textColor = [UIColor vocalePushBlueColor];
    titleLabel.font = [UIFont fontWithName:@"Raleway-SemiBold" size:23.0];
    [titleLabel sizeToFit];
    titleLabel.frame = CGRectMake(self.view.frame.size.width/2 - titleLabel.frame.size.width/2, self.view.frame.size.height/2 - 25 - 60 + 50 + 20, titleLabel.frame.size.width, titleLabel.frame.size.height);
    [placeholderView addSubview:titleLabel];
    
    UILabel *infoLabel = [[UILabel alloc] init];
    infoLabel.text = @"Respond to a few posts or create your own to get chatting with new people.";
    infoLabel.textColor = [UIColor vocaleSecondLevelTextColor];
    infoLabel.font = [UIFont fontWithName:@"Raleway-Regular" size:15.0];
    infoLabel.numberOfLines = 2;
    infoLabel.textAlignment = NSTextAlignmentCenter;
    infoLabel.frame = CGRectMake(44, self.view.frame.size.height/2 - 25 - 60 + 50 + 20 + 23 + 5, self.view.frame.size.width - 88, 40);
    [placeholderView addSubview:infoLabel];
    
    imageView.alpha = 0;
    titleLabel.alpha = 0;
    infoLabel.alpha = 0;
    [UIView animateWithDuration:0.4 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        imageView.alpha = 1;
        titleLabel.alpha = 1;
        infoLabel.alpha = 1;
    } completion:^(BOOL finished) {
        
    }];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController setToolbarHidden:true animated:true];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.placeholderView removeFromSuperview];
    [self.loadingView removeFromSuperview];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    self.cachedCount = 0;
}

- (void) browseToolbarButtonPressed {
    [self.navigationController popToRootViewControllerAnimated:true];
}

#pragma mark - ATLConversationListViewControllerDelegate Methods

- (void)conversationListViewController:(ATLConversationListViewController *)conversationListViewController didSelectConversation:(LYRConversation *)conversation
{
    ConversationViewController *controller = [ConversationViewController conversationViewControllerWithLayerClient:self.layerClient];
    controller.conversation = conversation;
    controller.conversationListController = self;
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)conversationListViewController:(ATLConversationListViewController *)conversationListViewController didDeleteConversation:(LYRConversation *)conversation deletionMode:(LYRDeletionMode)deletionMode
{
    if (self.chatCount == 1) {
        [self addNoChatsView];
    }
    NSLog(@"Conversation deleted");
}

- (void)conversationListViewController:(ATLConversationListViewController *)conversationListViewController didFailDeletingConversation:(LYRConversation *)conversation deletionMode:(LYRDeletionMode)deletionMode error:(NSError *)error
{
    NSLog(@"Failed to delete conversation with error: %@", error);
}

- (void)conversationListViewController:(ATLConversationListViewController *)conversationListViewController didSearchForText:(NSString *)searchText completion:(void (^)(NSSet *filteredParticipants))completion
{
    [[UserManager sharedManager] queryForUserWithName:searchText completion:^(NSArray *participants, NSError *error) {
        if (!error) {
            if (completion) completion([NSSet setWithArray:participants]);
        } else {
            if (completion) completion(nil);
            NSLog(@"Error searching for Users by name: %@", error);
        }
    }];
}

- (id<ATLAvatarItem>) conversationListViewController:(ATLConversationListViewController *)conversationListViewController avatarItemForConversation:(LYRConversation *)conversation {
    for (NSString *string in conversation.participants) {
        if (string != [PFUser currentUser].objectId) {
            if ( [[UserManager sharedManager] cachedUserForUserID:string] != nil ){
                return [[UserManager sharedManager] cachedUserForUserID:string];
            }
        }
    }
    return nil;
    //return [PFUser currentUser];
}

- (void)avatarDownloaded:(NSNotification *)notification {
    self.cachedCount++;
    if (self.cachedCount >= (self.count*2)) {
        [self.loadingView removeFromSuperview];
    }
}


#pragma mark - ATLConversationListViewControllerDataSource Methods

- (NSString *)conversationListViewController:(ATLConversationListViewController *)conversationListViewController titleForConversation:(LYRConversation *)conversation
{
    if ([conversation.metadata valueForKey:@"title"]){
        return [conversation.metadata valueForKey:@"title"];
    } else {
        NSArray *unresolvedParticipants = [[UserManager sharedManager] unCachedUserIDsFromParticipants:[conversation.participants allObjects]];
        NSArray *resolvedNames = [[UserManager sharedManager] resolvedNamesFromParticipants:[conversation.participants allObjects]];
        
        if ([unresolvedParticipants count]) {
            [[UserManager sharedManager] queryAndCacheUsersWithIDs:unresolvedParticipants completion:^(NSArray *participants, NSError *error) {
                if (!error) {
                    if (participants.count) {
                        [self reloadCellForConversation:conversation];
                    } else {
                        [self.loadingView removeFromSuperview];
                    }
                } else {
                    NSLog(@"Error querying for Users: %@", error);
                }
            }];
        }
        
        if ([resolvedNames count] && [unresolvedParticipants count]) {
            //return [NSString stringWithFormat:@"%@ and %lu others", [resolvedNames componentsJoinedByString:@", "], (unsigned long)[unresolvedParticipants count]];
            return [NSString stringWithFormat:@"%@", [resolvedNames componentsJoinedByString:@", "]];
        } else if ([resolvedNames count] && [unresolvedParticipants count] == 0) {
            self.cachedCount++;
            if (self.cachedCount >= (self.count*2)) {
                [self.loadingView removeFromSuperview];
            }
            return [NSString stringWithFormat:@"%@", [resolvedNames componentsJoinedByString:@", "]];
        } else {
            return [NSString stringWithFormat:@"%lu users...", (unsigned long)conversation.participants.count];
        }
    }
}

#pragma mark - Actions

- (void)composeButtonTapped:(id)sender
{
    ConversationViewController *controller = [ConversationViewController conversationViewControllerWithLayerClient:self.layerClient];
    controller.displaysAddressBar = YES;
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)logoutButtonTapped:(id)sender
{
    //NSLog(@"logOutButtonTapAction");
    
    [self.layerClient deauthenticateWithCompletion:^(BOOL success, NSError *error) {
        if (!error) {
            [PFUser logOut];
            [self.navigationController popToRootViewControllerAnimated:YES];
        } else {
            NSLog(@"Failed to deauthenticate: %@", error);
        }
    }];
}

- (NSString *)conversationListViewController:(ATLConversationListViewController *)conversationListViewController lastMessageTextForConversation:(LYRConversation *)conversation {
    LYRMessagePart *part = conversation.lastMessage.parts[0];
    
    if([part.MIMEType  isEqual: @"application/json+voicenoteobject"])
    {
        if ([[PFUser currentUser].objectId isEqualToString:conversation.lastMessage.sender.userID]) {
            return @"You sent a voice message.";
        } else {
            return @"Sent you a voice message.";
        }
    }
    return nil;
}

- (void) tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {

    cell.selectionStyle = UITableViewCellSelectionStyleNone;
//    CGFloat h = cell.bounds.size.height;
//    CGFloat y = ((cell.frame.origin.y + [[UIApplication sharedApplication] statusBarFrame].size.height + [self navigationController].navigationBar.frame.size.height)/h)*cell.frame.size.height;
//    
//    [cell setAlpha:0.0f];
//    [UIView animateWithDuration:0.5 delay:3*y/self.tableView.frame.size.height usingSpringWithDamping:0.8 initialSpringVelocity:0.4 options:UIViewAnimationOptionCurveEaseInOut animations:^{
//        [cell setAlpha:1.0f];
//    } completion:^(BOOL finished) {
//        
//    }];
}
 
@end
