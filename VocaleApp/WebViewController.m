//
//  WebViewController.m
//  VocaleApp
//
//  Created by Vladimir Kadurin on 7/24/16.
//  Copyright © 2016 Rayno Willem Mostert. All rights reserved.
//

#import "WebViewController.h"
#import <Parse.h>

@interface WebViewController () <UIWebViewDelegate>
@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (nonatomic, strong) UIImageView *loadingSpinner;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *webViewBottomConstraint;
@property (weak, nonatomic) IBOutlet UIButton *doneButton;

@end

@implementation WebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.webView.delegate = self;
    self.webView.scalesPageToFit = true;
    
    __block NSURL *url;
    
    if (self.isPrivacyPolicy) {
        self.title = @"Privacy Policy";
        PFQuery *query = [PFQuery queryWithClassName:@"Files"];
        [query whereKey:@"name" equalTo:@"PrivacyPolicy"];
        [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
            if (!object) {
                
                NSLog(@"The getFirstObject request failed.");
            } else {
                PFFile *file = object[@"document"];
                url = [NSURL URLWithString:file.url];
                NSURLRequest *request = [NSURLRequest requestWithURL:url];
                [self.webView loadRequest:request];
            }
        }];
    }
    
    if (self.isTermsAndCondtions) {
        self.title = @"Terms of Use";
        PFQuery *query = [PFQuery queryWithClassName:@"Files"];
        [query whereKey:@"name" equalTo:@"ToM"];
        [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
            if (!object) {
                
                NSLog(@"The getFirstObject request failed.");
            } else {
                PFFile *file = object[@"document"];
                url = [NSURL URLWithString:file.url];
                NSURLRequest *request = [NSURLRequest requestWithURL:url];
                [self.webView loadRequest:request];
            }
        }];    }
    
    self.webView.backgroundColor = [UIColor clearColor];
    self.webView.opaque = NO;
    
    if (!self.fromLogin) {
        self.doneButton.hidden = true;
        self.webViewBottomConstraint.constant = 0;
    }
}

- (IBAction)doneButtonTapped:(UIButton *)sender {
    [self dismissViewControllerAnimated:true completion:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UIWebViewDelegate
- (void)webViewDidStartLoad:(UIWebView *)webView {
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

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [self.loadingSpinner removeFromSuperview];
}

@end
