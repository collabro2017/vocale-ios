//
//  ProfileDetailViewController.h
//  VocaleApp
//
//  Created by Vladimir Kadurin on 7/5/16.
//  Copyright © 2016 Rayno Willem Mostert. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ProfileDetailViewController : UIViewController

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *age;
@property (nonatomic, strong) NSString *location;
@property (nonatomic, strong) NSString *profileDescription;
@property (nonatomic, strong) UIImage *profileImage;
@property (nonatomic, strong) NSArray *images;
@property (nonatomic) BOOL viewMode;

@property (weak, nonatomic) IBOutlet UILabel *nameAgeLabel;
@property (weak, nonatomic) IBOutlet UILabel *locationLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *descriptionViewTopConstraint;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UIView *imageEditButtonView;
@property (weak, nonatomic) IBOutlet UIView *textEditButtonView;

@end
