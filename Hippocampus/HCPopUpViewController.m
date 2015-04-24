//
//  HCPopUpViewController.m
//  Hippocampus
//
//  Created by Joseph McArthur Gill on 4/23/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import "HCPopUpViewController.h"

#define ANIMATION_TIME 0.4f

@interface HCPopUpViewController ()

@end

@implementation HCPopUpViewController

@synthesize mainButton;
@synthesize mainImageView;
@synthesize mainLabel;
@synthesize overlayView;
@synthesize screenshotImageView;
@synthesize tintedView;
@synthesize imageForMainImageView;
@synthesize imageForScreenshotImageView;
@synthesize mainLabelText;

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setProperties];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [UIView animateWithDuration:ANIMATION_TIME delay:0.0f options:UIViewAnimationOptionCurveLinear
                     animations:^(void){
                         [self.tintedView setBackgroundColor:[[UIColor clearColor] colorWithAlphaComponent:0.5]];
                         [self.overlayView setAlpha:1.0f];
                     }
                     completion:^(BOOL finished){
                     }
     ];
}


- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void) setProperties
{
    [self.mainButton.layer setCornerRadius:4.0f];
    [self.mainButton setClipsToBounds:YES];
    
    self.overlayView.layer.cornerRadius = 5;
    [self.overlayView.layer setMasksToBounds:YES];
    [self.tintedView setBackgroundColor:[[UIColor clearColor] colorWithAlphaComponent:0.0]];
    //[self.screenshotImageView setBackgroundColor:[[UIColor clearColor] colorWithAlphaComponent:0.75]];
    
    [self.screenshotImageView setImage:self.imageForScreenshotImageView];
    [self.mainImageView setImage:self.imageForMainImageView];
    [self.mainLabel setText:self.mainLabelText];
    
    [self.overlayView setAlpha:0.0f];
}



# pragma mark - Actions

- (IBAction)mainButtonAction:(id)sender
{
    [self dismissView:NO];
}

- (IBAction)backgroundButtonAction:(id)sender
{
    [self dismissView:NO];
}


- (void) dismissView:(BOOL)animated
{
    [UIView animateWithDuration:(animated ? ANIMATION_TIME : 0.0f) delay:0.0f options:UIViewAnimationOptionCurveLinear
                     animations:^(void){
                         [self.overlayView setAlpha:0.0f];
                     }
                     completion:^(BOOL finished){
                         [self dismissViewControllerAnimated:NO completion:nil];
                     }
     ];
}



@end
