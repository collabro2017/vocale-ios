//
//  ProfileDetailViewController.m
//  VocaleApp
//
//  Created by Vladimir Kadurin on 7/5/16.
//  Copyright © 2016 Rayno Willem Mostert. All rights reserved.
//

#import "ProfileDetailViewController.h"
#import "ProfileCollectionViewCell.h"
#import "VocaleApp-Swift.h"
#import "FadeCustomModalTransition.h"
#import "ProfileImageModalTransition.h"

@interface ProfileDetailViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIViewControllerTransitioningDelegate, UserPhotosDelegate>

@property (strong, nonatomic) NSIndexPath *currentIndexPath;
@property (strong, nonatomic) UIScrollView *scrollView;
@property (strong, nonatomic) UIView *scrollViewContentView;

@end

@implementation ProfileDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    if (self.viewMode) {
        self.title = @"Profile";
        self.imageEditButtonView.hidden = true;
        self.textEditButtonView.hidden = true;
    } else {
        self.title = @"Edit Profile";
    }
    if (self.age.length > 0) {
        //self.nameAgeLabel.text = [NSString stringWithFormat:@"%@, %@", self.name, self.age];
        UIFont *nameFont = [UIFont fontWithName:@"Raleway-Bold" size:23.0];
        NSDictionary *nameDict = [NSDictionary dictionaryWithObject: nameFont forKey:NSFontAttributeName];
        NSMutableAttributedString *nAttrString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@, ", self.name] attributes: nameDict];
        
        UIFont *ageFont = [UIFont fontWithName:@"Raleway-Medium" size:23.0];
        NSDictionary *ageDict = [NSDictionary dictionaryWithObject:ageFont forKey:NSFontAttributeName];
        NSMutableAttributedString *aAttrString = [[NSMutableAttributedString alloc]initWithString: self.age attributes:ageDict];
        
         [nAttrString appendAttributedString:aAttrString];
        self.nameAgeLabel.attributedText = nAttrString;
    } else {
        self.nameAgeLabel.text = [NSString stringWithFormat:@"%@", self.name];
    }
    
    if (self.location.length > 0) {
        self.locationLabel.text = self.location;
    } else {
        self.locationLabel.text = @"";
    }
    
    if (self.profileDescription.length > 0) {
        self.descriptionLabel.text = self.profileDescription;
    } else {
        self.descriptionLabel.hidden = true;
    }
    
    if (self.profileImage != nil) {

    }
    
    [self setupViews];
    
    [self.navigationController setToolbarHidden:true];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setToolbarHidden:true animated:false];
    if (self.location == nil) {
        self.descriptionViewTopConstraint.constant = -28;
        [self.view layoutIfNeeded];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.collectionView reloadData];
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.images.count + 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ProfileCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"ProfileCell" forIndexPath:indexPath];
    self.currentIndexPath = indexPath;
    if (indexPath.row == 0) {
        cell.profileImageView.image = self.profileImage;
    } else {
        cell.profileImageView.image = self.images[indexPath.row - 1];
    }
    return cell;
}

#pragma mark - UICollectionViewDelegate
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(self.view.frame.size.width, self.view.frame.size.width);
}

#pragma mark - IBActions
- (IBAction)imageEditButtonTapped:(UIButton *)sender {
        UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        UINavigationController *nextVC = [mainStoryboard instantiateViewControllerWithIdentifier:@"PhotosNavCon"];
    if ([nextVC.topViewController isKindOfClass:[UserPhotosTableViewController class]]) {
        UserPhotosTableViewController *photosVC = (UserPhotosTableViewController *)nextVC.topViewController;
        photosVC.delegate = self;
        if (self.currentIndexPath.row == 0) {
            photosVC.tempImage = self.profileImage;
        } else {
            photosVC.tempImage = self.images[self.currentIndexPath.row - 1];
        }
    }
        nextVC.modalPresentationStyle = UIModalPresentationCustom;
        nextVC.transitioningDelegate = self;
        [self presentViewController:nextVC animated:false completion:nil];
}

- (IBAction)textEditButtonTapped:(UIButton *)sender {
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
    __weak CustomTextInputViewController *reportController = [mainStoryboard instantiateViewControllerWithIdentifier:@"TextInputVC"];
    reportController.inputTooltipText = @"Tell people a little more about who you are and what you like.";
    reportController.navigationItem.title = @"About You";
    reportController.existingText = self.descriptionLabel.text;
    reportController.didFinishTypingWithText = ^(NSString *text, BOOL isBlocked) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            PFUser *user = [PFUser currentUser];
            user[@"AboutMe"] = text;
            [user saveInBackground];
        });
        self.descriptionLabel.text = text;
    };
    [self.navigationController pushViewController:reportController animated:false];

}

#pragma mark - UserPhotosDelegate
- (void)profileImageChanged:(UIImage *)image {
    self.profileImage = image;
    [self.collectionView reloadData];
}

#pragma mark - Helpers
- (void)setupViews {
    self.imageEditButtonView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.imageEditButtonView.layer.shadowOpacity = 0.8;
}

#pragma mark - UIViewControllerTransitioningDelegate

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented
                                                                  presentingController:(UIViewController *)presenting
                                                                      sourceController:(UIViewController *)source
{
    id<UIViewControllerAnimatedTransitioning> animationController;
    
    if ([presented isKindOfClass:[UINavigationController class]]) {
        UINavigationController *presentedNavCon = (UINavigationController *)presented;
        if ([presentedNavCon.topViewController isKindOfClass:[UserPhotosTableViewController class]]) {
            ProfileImageModalTransition *animator = [[ProfileImageModalTransition alloc] init];
            animator.appearing = YES;
            animator.duration = 0.3;
            animationController = animator;
        } else {
            FadeCustomModalTransition *animator = [[FadeCustomModalTransition alloc] init];
            animator.appearing = YES;
            animator.duration = 0.35;
            animationController = animator;
        }
        

    }
    return animationController;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
    id<UIViewControllerAnimatedTransitioning> animationController;
    
    if ([dismissed isKindOfClass:[UINavigationController class]]) {
        UINavigationController *dissmissedNavCon = (UINavigationController *)dismissed;
        if ([dissmissedNavCon.topViewController isKindOfClass:[UserPhotosTableViewController class]]) {
            ProfileImageModalTransition *animator = [[ProfileImageModalTransition alloc] init];
            animator.appearing = NO;
            animator.duration = 0.3;
            animationController = animator;
        } else {
            FadeCustomModalTransition *animator = [[FadeCustomModalTransition alloc] init];
            animator.appearing = NO;
            animator.duration = 0.35;
            animationController = animator;
        }
    }
    
    return animationController;
}


@end
