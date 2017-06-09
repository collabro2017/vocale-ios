//
//  IAAPushNoteView.m
//  TLV Airport
//
//  Created by Aviel Gross on 1/29/14.
//  Copyright (c) 2014 NGSoft. All rights reserved.
//

#import "AGPushNoteView.h"
#import "VocaleApp-Swift.h"

#define APP [UIApplication sharedApplication].delegate
#define isIOS7 (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1)
#define PUSH_VIEW [AGPushNoteView sharedPushView]

#define CLOSE_PUSH_SEC 3.0
#define SHOW_ANIM_DUR 0.5
#define HIDE_ANIM_DUR 0.3

@interface AGPushNoteView()
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@property (strong, nonatomic) NSTimer *closeTimer;
@property (strong, nonatomic) NSString *currentMessage;
@property (strong, nonatomic) NSMutableArray *pendingPushArr;

@property (strong, nonatomic) void (^messageTapActionBlock)(NSString *message);
@end


@implementation AGPushNoteView

//Singleton instance
static AGPushNoteView *_sharedPushView;

+ (instancetype)sharedPushView
{
	@synchronized([self class])
	{
		if (!_sharedPushView){
            NSArray *nibArr = [[NSBundle mainBundle] loadNibNamed: @"AGPushNoteView" owner:self options:nil];
            for (id currentObject in nibArr)
            {
                if ([currentObject isKindOfClass:[AGPushNoteView class]])
                {
                    _sharedPushView = (AGPushNoteView *)currentObject;
                    break;
                }
            }
            [_sharedPushView setUpUI];
		}
		return _sharedPushView;
	}
	// to avoid compiler warning
	return nil;
}

+ (void)setDelegateForPushNote:(id<AGPushNoteViewDelegate>)delegate {
    [PUSH_VIEW setPushNoteDelegate:delegate];
}

#pragma mark - Lifecycle (of sort)
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        CGRect f = self.frame;
        CGFloat width = [UIApplication sharedApplication].keyWindow.bounds.size.width;
        self.frame = CGRectMake(f.origin.x, f.origin.y, width, f.size.height);
    }
    return self;
}

- (void)setUpUI {
    CGRect f = self.frame;
    CGFloat width = [UIApplication sharedApplication].keyWindow.bounds.size.width;
    CGFloat height = isIOS7? 54: 55;
    self.frame = CGRectMake(f.origin.x + 5, -height, width - 10, height - 10);
    
    CGRect cvF = self.containerView.frame;
    self.containerView.layer.masksToBounds = true;
    self.containerView.frame = CGRectMake(cvF.origin.x, cvF.origin.y, self.frame.size.width, cvF.size.height);
    self.containerView.layer.borderColor = [UIColor whiteColor].CGColor;
    self.containerView.layer.borderWidth = 2;
    self.containerView.layer.cornerRadius = 6;
    
    //OS Specific:
    if (isIOS7) {
        self.barTintColor = nil;
        self.translucent = YES;
        self.barStyle = UIBarStyleBlack;
    } else {
        //[self setTintColor:[UIColor colorWithRed:5 green:31 blue:75 alpha:1]];
        [self.messageLabel setTextAlignment:NSTextAlignmentCenter];
        //self.messageLabel.shadowColor = [UIColor blackColor];
    }
    
    self.layer.zPosition = MAXFLOAT;
    self.backgroundColor = [UIColor clearColor];
    self.opaque = false;
    self.multipleTouchEnabled = NO;
    self.exclusiveTouch = YES;
    
    UITapGestureRecognizer *msgTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(messageTapAction)];
    self.messageLabel.userInteractionEnabled = YES;
    [self.messageLabel addGestureRecognizer:msgTap];
    
    //:::[For debugging]:::
    //            self.containerView.backgroundColor = [UIColor yellowColor];
    //            self.closeButton.backgroundColor = [UIColor redColor];
    //            self.messageLabel.backgroundColor = [UIColor greenColor];
    
    [APP.window addSubview:PUSH_VIEW];
}

+ (void)awake {
    if (PUSH_VIEW.frame.origin.y == 0) {
        [APP.window addSubview:PUSH_VIEW];
    }
}

+ (void)showWithNotificationMessage:(NSDictionary *)message {
    //NSLog(@"%@", message);
    if (message[@"saved"] != nil) {
        PUSH_VIEW.containerView.backgroundColor = [UIColor vocaleSavedPostNotificationColor];
        PUSH_VIEW.imageView.image = [UIImage imageNamed:@"savedPostIcon"];
        [AGPushNoteView showWithNotificationMessage:[NSString stringWithFormat:@"The Post has been saved"] withName:true saved:true completion:^{
            //Nothing.
        }];
    } else {
        if (message[@"layer"] != nil) {
            PUSH_VIEW.containerView.backgroundColor = [UIColor vocalePushBlueColor];
            PUSH_VIEW.imageView.image = [UIImage imageNamed:@"messages"];
            NSDictionary *dict = message[@"aps"];
            if (dict[@"alert"] != nil) {
                NSArray* foo = [dict[@"alert"] componentsSeparatedByString: @":"];
                NSString *firstBit = [foo objectAtIndex: 0];
                if ([[NSUserDefaults standardUserDefaults] boolForKey:@"notificationSwitchChat"] == true) {
                    if (![firstBit isEqualToString:@"You have new voice message"]) {
                        [AGPushNoteView showWithNotificationMessage:[NSString stringWithFormat:@"%@ sent you a new message", firstBit] withName:true saved:false completion:^{
                            //Nothing.
                        }];
                    } else {
                        [AGPushNoteView showWithNotificationMessage:firstBit withName:false saved:false completion:^{
                            //Nothing.
                        }];
                    }
                }
            } else {
                NSDictionary *dict = message[@"aps"];
                if (dict[@"badge"] != nil) { //ignore push for read voice notes
                    [AGPushNoteView showWithNotificationMessage:[NSString stringWithFormat:@"You have new voice message."] withName:true saved:false completion:^{
                        //Nothing.
                    }];
                }
            }
        } else {
            PUSH_VIEW.containerView.backgroundColor = [UIColor vocalePushGreenColor];
            PUSH_VIEW.imageView.image = [UIImage imageNamed:@"microphone"];
            NSDictionary *dict = message[@"aps"];
            if (dict[@"alert"] != nil) {
                if ([[NSUserDefaults standardUserDefaults] boolForKey:@"notificationSwitchResponses"] == true) {
                    [AGPushNoteView showWithNotificationMessage:dict[@"alert"] withName:true saved:false completion:^{
                        //Nothing.
                    }];
                }
            }
        }
    }
}

+ (void)showWithNotificationMessage:(NSString *)message withName:(BOOL)withName saved:(BOOL)saved completion:(void (^)(void))completion {
    
    PUSH_VIEW.currentMessage = message;

    if (message) {
        [PUSH_VIEW.pendingPushArr addObject:message];
        
        if (withName) {
            NSArray* foo = [message componentsSeparatedByString: @" "];
            NSString *firstBit = [foo objectAtIndex: 0];
            NSMutableAttributedString *attr = [[NSMutableAttributedString alloc] initWithString:message];
            [attr addAttributes:@{NSForegroundColorAttributeName : [UIColor vocaleFilterTextColor], NSFontAttributeName : [UIFont boldSystemFontOfSize:17.0f]}
                          range:[message rangeOfString:firstBit]];
            
            PUSH_VIEW.messageLabel.attributedText = attr;
        } else {
            PUSH_VIEW.messageLabel.text = message;
        }
        
        if (saved) {
            NSArray* foo = [message componentsSeparatedByString: @" "];
            NSString *firstBit = [foo objectAtIndex: 0];
            NSString *secondBit = [foo objectAtIndex: 1];
            NSMutableAttributedString *attr = [[NSMutableAttributedString alloc] initWithString:message];
            [attr addAttributes:@{NSForegroundColorAttributeName : [UIColor vocaleFilterTextColor], NSFontAttributeName : [UIFont boldSystemFontOfSize:17.0f]}
                          range:[message rangeOfString:firstBit]];
            [attr addAttributes:@{NSForegroundColorAttributeName : [UIColor vocaleFilterTextColor], NSFontAttributeName : [UIFont boldSystemFontOfSize:17.0f]}
                          range:[message rangeOfString:secondBit]];
            
            PUSH_VIEW.messageLabel.attributedText = attr;
        }
        
        APP.window.windowLevel = UIWindowLevelStatusBar;
        
        CGRect f = PUSH_VIEW.frame;
        PUSH_VIEW.frame = CGRectMake(f.origin.x, -f.size.height - 10, f.size.width, f.size.height);
        [APP.window addSubview:PUSH_VIEW];
        
        //Show
        [UIView animateWithDuration:SHOW_ANIM_DUR delay:1.0 usingSpringWithDamping:0.4 initialSpringVelocity:0.4 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            CGRect f = PUSH_VIEW.frame;
            PUSH_VIEW.frame = CGRectMake(f.origin.x, 10, f.size.width, f.size.height);
        } completion:^(BOOL finished) {
            if ([PUSH_VIEW.pushNoteDelegate respondsToSelector:@selector(pushNoteDidAppear)]) {
                [PUSH_VIEW.pushNoteDelegate pushNoteDidAppear];
            }
        }];
        
        //Start timer (Currently not used to make sure user see & read the push...)
        PUSH_VIEW.closeTimer = [NSTimer scheduledTimerWithTimeInterval:CLOSE_PUSH_SEC target:[AGPushNoteView class] selector:@selector(close) userInfo:nil repeats:NO];
    }
}
+ (void)closeWitCompletion:(void (^)(void))completion {
    if ([PUSH_VIEW.pushNoteDelegate respondsToSelector:@selector(pushNoteWillDisappear)]) {
        [PUSH_VIEW.pushNoteDelegate pushNoteWillDisappear];
    }
    
    [PUSH_VIEW.closeTimer invalidate];
    
    [UIView animateWithDuration:HIDE_ANIM_DUR delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        CGRect f = PUSH_VIEW.frame;
        PUSH_VIEW.frame = CGRectMake(f.origin.x, -f.size.height - 10, f.size.width, f.size.height);
    } completion:^(BOOL finished) {
        [PUSH_VIEW handlePendingPushJumpWitCompletion:completion];
    }];
}

+ (void)close {
    [AGPushNoteView closeWitCompletion:^{
        //Nothing.
    }];
}

#pragma mark - Pending push managment
- (void)handlePendingPushJumpWitCompletion:(void (^)(void))completion {
    id lastObj = [self.pendingPushArr lastObject]; //Get myself
    if (lastObj) {
        [self.pendingPushArr removeObject:lastObj]; //Remove me from arr
        NSString *messagePendingPush = [self.pendingPushArr lastObject]; //Maybe get pending push
        if (messagePendingPush) { //If got something - remove from arr, - than show it.
            [self.pendingPushArr removeObject:messagePendingPush];
            [AGPushNoteView showWithNotificationMessage:messagePendingPush withName:false saved:false completion:completion];
        } else {
            APP.window.windowLevel = UIWindowLevelNormal;
        }
    }
}

- (NSMutableArray *)pendingPushArr {
    if (!_pendingPushArr) {
        _pendingPushArr = [[NSMutableArray alloc] init];
    }
    return _pendingPushArr;
}

#pragma mark - Actions
+ (void)setMessageAction:(void (^)(NSString *message))action {
    PUSH_VIEW.messageTapActionBlock = action;
}

- (void)messageTapAction {
    if (self.messageTapActionBlock) {
        self.messageTapActionBlock(self.currentMessage);
        [AGPushNoteView close];
    }
}

- (IBAction)closeActionItem:(UIBarButtonItem *)sender {
    [AGPushNoteView close];
}


@end
