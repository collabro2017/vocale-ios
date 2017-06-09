//
//  NotificationTableViewCell.m
//  VocaleApp
//
//  Created by Vladimir Kadurin on 6/18/16.
//  Copyright © 2016 Rayno Willem Mostert. All rights reserved.
//

#import "NotificationTableViewCell.h"

@implementation NotificationTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (IBAction)offButtonTapped:(UIButton *)sender {
    if (self.offButton.selected) {
        self.offButton.selected = false;
        self.onButton.selected = true;
        [self.delegate notificationSwitch:sender enabled:true];
    } else {
        self.offButton.selected = true;
        self.onButton.selected = false;
        [self.delegate notificationSwitch:sender enabled:false];
    }
}

- (IBAction)onButtonTapped:(UIButton *)sender {
    if (self.onButton.selected) {
        self.onButton.selected = false;
        self.offButton.selected = true;
        [self.delegate notificationSwitch:sender enabled:false];
    } else {
        self.onButton.selected = true;
        self.offButton.selected = false;
        [self.delegate notificationSwitch:sender enabled:true];
    }
}

@end
