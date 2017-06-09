//
//  NotificationTableViewCell.h
//  VocaleApp
//
//  Created by Vladimir Kadurin on 6/18/16.
//  Copyright © 2016 Rayno Willem Mostert. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol NotificationSwitchProtocol <NSObject>

- (void)notificationSwitch:(UIButton *)button enabled:(BOOL)enabled;

@end

@interface NotificationTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIButton *onButton;
@property (weak, nonatomic) IBOutlet UIButton *offButton;

@property (weak, nonatomic) id <NotificationSwitchProtocol> delegate;

@end
