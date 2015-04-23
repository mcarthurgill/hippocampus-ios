//
//  HCPopUpViewController.m
//  Hippocampus
//
//  Created by Joseph McArthur Gill on 4/23/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import "HCPopUpViewController.h"

@interface HCPopUpViewController ()

@end

@implementation HCPopUpViewController

@synthesize mainButton, mainImageView, mainLabel, overlayView, screenshotImageView, tintedView, imageForMainImageView, imageForScreenshotImageView, mainLabelText;

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setProperties];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void) setProperties
{
    self.overlayView.layer.cornerRadius = 5;
    [self.overlayView.layer setMasksToBounds:YES];
    [self.tintedView setBackgroundColor:[[UIColor clearColor] colorWithAlphaComponent:0.75]];
    [self.screenshotImageView setBackgroundColor:[[UIColor clearColor] colorWithAlphaComponent:0.75]];
    
    [self.screenshotImageView setImage:self.imageForScreenshotImageView];
    [self.mainImageView setImage:self.imageForMainImageView];
    [self.mainLabel setText:self.mainLabelText];
}



# pragma mark - Actions

- (IBAction)mainButtonAction:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
