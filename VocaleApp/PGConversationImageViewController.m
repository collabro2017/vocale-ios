//
//  PGConversationImageViewController.m
//

#import <LayerKit/LYRMessagePart.h>
#import <Atlas/Utilities/ATLMessagingUtilities.h>
#import "PGConversationImageViewController.h"

@interface PGConversationImageViewController ()
@property(nonatomic, strong) UIImage *fullResImage;
- (void)updateInterfaceWithImage:(UIImage *)image;
@end

@implementation PGConversationImageViewController
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self downloadFullResImageIfNeeded];
}

- (id)initWithImageInfo:(JTSImageInfo *)info mode:(enum JTSImageViewControllerMode)mode backgroundStyle:(enum JTSImageViewControllerBackgroundOptions)style message:(LYRMessage *)message {
    PGConversationImageViewController *_self = [self initWithImageInfo:self.imageInfo mode:mode backgroundStyle:style];
    if (_self) {
        _self.message = message;
    }
    return _self;
}

#pragma mark - Layer Image Downloads

- (void)loadFullResImages {
    LYRMessagePart *fullResImagePart = ATLMessagePartForMIMEType(self.message, ATLMIMETypeImageJPEG);
    if (!fullResImagePart) {
        fullResImagePart = ATLMessagePartForMIMEType(self.message, ATLMIMETypeImagePNG);
    }
    
    // Retrieve hi-res image from message part
    if (!(fullResImagePart.transferStatus == LYRContentTransferReadyForDownload || fullResImagePart.transferStatus == LYRContentTransferDownloading)) {
        if (fullResImagePart.fileURL) {
            self.fullResImage = [UIImage imageWithContentsOfFile:fullResImagePart.fileURL.path];
        } else {
            self.fullResImage = [UIImage imageWithData:fullResImagePart.data];
        }
        [self updateInterfaceWithImage:self.fullResImage];
    }
}

- (void)downloadFullResImageIfNeeded {
    LYRMessagePart *fullResImagePart = ATLMessagePartForMIMEType(self.message, ATLMIMETypeImageJPEG);
    if (!fullResImagePart) {
        fullResImagePart = ATLMessagePartForMIMEType(self.message, ATLMIMETypeImagePNG);
    }
    
    // Download hi-res image from the network
    if (fullResImagePart && (fullResImagePart.transferStatus == LYRContentTransferReadyForDownload || fullResImagePart.transferStatus == LYRContentTransferDownloading)) {
        NSError *error;
        LYRProgress *downloadProgress = [fullResImagePart downloadContent:&error];
        if (!downloadProgress) {
            NSLog(@"Problem downloading full resolution photo - %@", error);
            return;
        }
        downloadProgress.delegate = self;
    } else {
        [self loadFullResImages];
    }
}

#pragma mark - LYRProgress Delegate Implementation

- (void)progressDidChange:(LYRProgress *)progress {
    // Queue UI updates onto the main thread, since LYRProgress performs
    // delegate callbacks from a background thread.
    dispatch_async(dispatch_get_main_queue(), ^{
        BOOL progressCompleted = progress.fractionCompleted == 1.0f;
        // After transfer completes, remove self for delegation.
        if (progressCompleted) {
            progress.delegate = nil;
            self.title = @"Image Downloaded";
            [self loadFullResImages];
        }
    });
}

@end
