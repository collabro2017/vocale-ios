//
//  PGConversationImageViewController.h
//

#import "JTSImageViewController.h"

@interface PGConversationImageViewController : JTSImageViewController <LYRProgressDelegate>
@property(nonatomic, strong) LYRMessage *message;

- (id)initWithImageInfo:(JTSImageInfo *)info mode:(enum JTSImageViewControllerMode)mode backgroundStyle:(enum JTSImageViewControllerBackgroundOptions)style message:(LYRMessage *)message;
@end