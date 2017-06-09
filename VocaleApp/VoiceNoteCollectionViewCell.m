//
//  VoiceNoteMessageCollectionViewCell.m
//  VocaleApp
//
//  Created by Rayno Willem Mostert on 2016/01/18.
//  Copyright © 2016 Rayno Willem Mostert. All rights reserved.
//

#import "VoiceNoteCollectionViewCell.h"
#import "Parse.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "VocaleApp-Swift.h"

@interface VoiceNoteCollectionViewCell ()
@property (strong,nonatomic) UILabel *title;
@property (strong,nonatomic) UIButton *button;
@property (strong, nonatomic) AVAudioPlayer *player;
@property (strong, nonatomic) NSData *voiceNoteData;
@property (strong, nonatomic) AVURLAsset *voiceNoteDataAsset;
@property (strong,nonatomic) LYRMessage *message;
@property (strong, nonatomic) UIImageView *leftAvatarImageView;
@property (strong, nonatomic) UIImageView *rightAvatarImageView;
@property (strong, nonatomic) CircularPlayButton *playerView;
@property (strong, nonatomic) NSLayoutConstraint *leftConstraint;
@property (strong, nonatomic) NSLayoutConstraint *rightConstraint;

@property (nonatomic) BOOL isIncoming;

@end

@implementation VoiceNoteCollectionViewCell


-(instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self)
    {
        self.isIncoming = false;
        // Configure Label
        _title = [[UILabel alloc] init];
        _title.translatesAutoresizingMaskIntoConstraints = NO;
        // [self addSubview:_title];
        //
        self.backgroundColor = [UIColor clearColor];
        
        // Configure Button
        _button = [UIButton buttonWithType:UIButtonTypeCustom];
        [_button setImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
        [_button setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateSelected];
        [[_button imageView] setContentMode:UIViewContentModeScaleAspectFit];
        [_button addTarget:self
                    action:@selector(buttonTapped:)
          forControlEvents:UIControlEventTouchUpInside];
        _button.translatesAutoresizingMaskIntoConstraints = NO;
        [_button setFrame:CGRectMake(self.frame.size.width/2 - 45, 0, 90, 90)];
        
        self.leftAvatarImageView = [[UIImageView alloc] init];
//        self.leftAvatarImageView.layer.borderWidth = 3;
//        self.leftAvatarImageView.layer.borderColor = [UIColor lightGrayColor].CGColor;
        [self.leftAvatarImageView setContentMode:UIViewContentModeScaleAspectFit];
        self.leftAvatarImageView.translatesAutoresizingMaskIntoConstraints = NO;
        
        self.rightAvatarImageView = [[UIImageView alloc] init];
//        self.rightAvatarImageView.layer.borderWidth = 3;
//        self.rightAvatarImageView.layer.borderColor = [UIColor lightGrayColor].CGColor;
        [self.rightAvatarImageView setContentMode:UIViewContentModeScaleAspectFit];
        self.rightAvatarImageView.translatesAutoresizingMaskIntoConstraints = NO;
        
//        if (self.voiceNoteDataAsset != nil) {
//            [self.playerView removeFromSuperview];
//           // _playerView = [[SYWaveformPlayerView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height) asset:self.voiceNoteDataAsset color:[UIColor lightTextColor] progressColor:[UIColor colorWithRed:1 green:0.2 blue:0.2 alpha:1]];
//            _playerView = [[CircularPlayButton alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.height-20, self.frame.size.height-20) asset:self.voiceNoteDataAsset];
//            _playerView.translatesAutoresizingMaskIntoConstraints = NO;
//            [self.contentView addSubview:_playerView];
//        }
        self.playerView = [[CircularPlayButton alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.height-20, self.frame.size.height-20) asset:self.voiceNoteDataAsset];
        self.playerView.translatesAutoresizingMaskIntoConstraints = NO;
        self.playerView.clockwise = false;
        self.playerView.startAngle = 270;
        [self.contentView addSubview:self.playerView];
        
        [self addSubview:self.leftAvatarImageView];
        [self addSubview:self.rightAvatarImageView];
        [self configureConstraints];
    }
    return self;
}

- (void)buttonTapped:(id)sender {
    
    if (!_button.isSelected)
    {
        [_button setSelected:true];
        // Show message identifer in Alert Dialog
        [self.player play];
        [self activateProximitySensor];
        [_button startProgressView:self.player.duration fromDuration:self.player.currentTime];
    } else {
        [_button setSelected:false];
        [self.player pause];
        [self deactivateProximitySensor];
        [_button pauseProgressView];
        
    }
}

- (void) proximityChanged:(NSNotification *)notification {
    if (self.player) {
        if ([self.player isPlaying]) {
            if ((UIDevice *)notification.object) {
                if ([((UIDevice *)notification.object) proximityState] ) {
                    [self.player stop];
                    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
                    [self.player play];
                } else {
                    [self.player stop];
                    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
                    [self.player play];
                }
            }
        }
    }
}

- (void)willMoveToWindow:(UIWindow *)newWindow {
    [super willMoveToWindow:newWindow];
    [self deactivateProximitySensor];
}

-(void)deactivateProximitySensor {
    if ([UIDevice currentDevice].proximityMonitoringEnabled) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"UIDeviceProximityStateDidChangeNotification" object:[UIDevice currentDevice]];
        [[UIDevice currentDevice] setProximityMonitoringEnabled:NO];
    }
}

-(void)activateProximitySensor {
    if (![UIDevice currentDevice].proximityMonitoringEnabled) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(proximityChanged:) name:@"UIDeviceProximityStateDidChangeNotification" object:[UIDevice currentDevice]];
        [[UIDevice currentDevice] setProximityMonitoringEnabled:YES];
    }
}


- (void)configureConstraints {
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.leftAvatarImageView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:60]];
    NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:self.leftAvatarImageView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:60];
    [self addConstraint:heightConstraint];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.leftAvatarImageView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
    NSLayoutConstraint *leftConstraint = [NSLayoutConstraint constraintWithItem:self.leftAvatarImageView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeading multiplier:1.0f constant:10];
    [self addConstraint:leftConstraint];
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.rightAvatarImageView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:60]];
    NSLayoutConstraint *rightHeightConstraint = [NSLayoutConstraint constraintWithItem:self.rightAvatarImageView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:60];
    [self addConstraint:rightHeightConstraint];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.rightAvatarImageView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
    
    NSLayoutConstraint *rightConstraint = [NSLayoutConstraint constraintWithItem:self.rightAvatarImageView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTrailing multiplier:1.0f constant:-10];
    [self addConstraint:rightConstraint];
//    [self addConstraint:leftConstraint];
//    [self addConstraint:rightConstraint];
    
//    if (self.isIncoming) {
//        [self removeConstraint:rightConstraint];
//    } else {
//        [self removeConstraint:leftConstraint];
//    }
    
    if (self.playerView != nil) {
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.playerView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeCenterX multiplier:1.0f constant:0]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.playerView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:60]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.playerView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:60]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.playerView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeCenterY multiplier:1.0f constant:0]];
        
    }
    [self setNeedsLayout];
}


- (void)updateWithSender:(id<ATLParticipant>)sender{
    NSLog(@"%@, %@", [sender participantIdentifier], [AppDelegate layerClient].authenticatedUserID);
    
    self.isIncoming = false;
    if (![[sender participantIdentifier] isEqualToString:[AppDelegate layerClient].authenticatedUserID]) {
        self.isIncoming = true;
    }

    if (self.isIncoming) {
        self.rightAvatarImageView.hidden = YES;
        self.leftAvatarImageView.hidden = NO;
    } else {
        self.leftAvatarImageView.hidden = YES;
        self.rightAvatarImageView.hidden = NO;
    }
    
    if ([sender hasCustomProfileImage]) {
        [[sender avatarImageFile] getDataInBackgroundWithBlock:^(NSData * _Nullable data, NSError * _Nullable error) {
            if (error != nil) {
                
            } else {
                UIImage *image = [UIImage imageWithData:data];
                [self.leftAvatarImageView setImage:[image circularImageWithBorderDark]];
                [self.rightAvatarImageView setImage:[image circularImageWithBorderDark]];
            }
        }];
    } else {
        [self.leftAvatarImageView sd_setImageWithURL:[sender avatarImageURL] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
            
            [self.leftAvatarImageView setImage:[image circularImageWithBorderDark]];
            [self.rightAvatarImageView setImage:[image circularImageWithBorderDark]];
        }];
    }
    
    return;
}

- (void)shouldDisplayAvatarItem:(BOOL)shouldDisplayAvatarItem{return;}


- (void)presentMessage:(LYRMessage *)message {
    self.message = message;
    LYRMessagePart *part = message.parts[2];

    // if message contains custom mime type then get the text from the MessagePart JSON
    if([part.MIMEType isEqual: @"application/json+voicenoteobject"])
    {
        NSData *data = part.data;
        self.voiceNoteData = data;
        
        //Create AVURLAsset for waveform creation and audio playback
        NSString *tempFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%lu.m4a", (unsigned long)[NSDate date].hash]];
        NSFileManager *manager = [NSFileManager defaultManager];
        [manager createFileAtPath:tempFilePath contents:self.voiceNoteData attributes:nil];
        
        self.voiceNoteDataAsset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:tempFilePath] options:nil];
        
        [self.playerView removeFromSuperview];
        _playerView = [[CircularPlayButton alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.height-20, self.frame.size.height-20) asset:self.voiceNoteDataAsset];
        _playerView.translatesAutoresizingMaskIntoConstraints = NO;
        _playerView.clockwise = false;
        _playerView.startAngle = 270;
        [self.contentView addSubview:_playerView];
        [self configureConstraints];
        
        if (self.playerView != nil){
            if (!self.message.isUnread) {
                [[_playerView progressView] setAngle:360];
            }
        }
        
        if (self.playerView != nil){
            
        }
        //Initialize view, set AVURLAsset, frame, color
    }
}


@end
