//
//  HCPermissionViewController.m
//  Hippocampus
//
//  Created by Joseph McArthur Gill on 4/24/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import "HCPermissionViewController.h"
#import "LXAppDelegate.h"

#define ANIMATION_TIME 0.4f

@interface HCPermissionViewController ()

@end

@implementation HCPermissionViewController

@synthesize mainLabel, mainImageView, overlayView, screenshotImageView, tintedView, imageForMainImageView, imageForScreenshotImageView, mainLabelText, grantPermissionButton, delegate, permissionType;

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
    [self.grantPermissionButton.layer setCornerRadius:4.0f];
    [self.grantPermissionButton setClipsToBounds:YES];
    
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


- (IBAction)grantPermissionAction:(id)sender {
    if (permissionType && permissionType.length > 0) {
        if ([permissionType isEqualToString:@"contacts"]) {
            [[LXAddressBook thisBook] requestAccess:^(BOOL success) {
                [self.delegate permissionsDelegate];
            }];
        } else if ([permissionType isEqualToString:@"location"]) {
            [[LXSession thisSession] startLocationUpdates];
            [self.delegate permissionsDelegate];
        } else if ([permissionType isEqualToString:@"notifications"]) {
            LXAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
            [appDelegate getPushNotificationPermission];
        }
    }
    [self dismissView:NO];
}

@end
