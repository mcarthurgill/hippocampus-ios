//
//  SHPaywallViewController.m
//  Hippocampus
//
//  Created by Will Schreiber on 9/30/15.
//  Copyright © 2015 LXV. All rights reserved.
//

#import "SHPaywallViewController.h"

@interface SHPaywallViewController ()

@end

@implementation SHPaywallViewController

@synthesize titleImage;
@synthesize messageLabel;
@synthesize actionButton;
@synthesize secondaryActionButton;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupAppearance];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshedObject:) name:@"refreshedObject" object:nil];
}

- (void) setupAppearance
{
    [self.navigationController setNavigationBarHidden:YES];
    
    [self.titleImage setImage:[UIImage imageNamed:@"60x60.png"]];
    
    [self.messageLabel setFont:[UIFont titleFontWithSize:18.0f]];
    [self.messageLabel setTextColor:[UIColor SHFontDarkGray]];
    
    [self.messageLabel setText:@"Hey there.\n\nWe initially built Hippo to remember details about investors we were meeting, although over the past two years Hippo has changed our lives.\n\nHippo has become an assistant for our brains. It helps us advance our careers, improve our relationships, and close more deals.\n\nHippo is so important to us that we'll never raise money for it, never sell it, never sell your data, never stop working on it and never shut it down.\n\nSet a nudge for 50 years from now and you will receive it.\n\nHippo is $8/month. For the price of a coffee meeting, you can remember those tiny details about people that make all the difference.\n\nWe believe Hippo will change your life. If it doesn’t, we'll give your money back.\n\nWith love,\nMcArthur Gill + Will Schreiber"];
    
    [self.actionButton.layer setCornerRadius:4.0f];
    [self.actionButton setClipsToBounds:YES];
    [[self.actionButton titleLabel] setFont:[UIFont titleFontWithSize:16.0f]];
    [self.actionButton setBackgroundColor:[UIColor SHColorBlue]];
    [self.actionButton setTintColor:[UIColor whiteColor]];
    [self.actionButton setTitle:@"$8/month" forState:UIControlStateNormal];
    
    [[self.secondaryActionButton titleLabel] setFont:[UIFont secondaryFontWithSize:13.0f]];
    [self.secondaryActionButton setTintColor:[UIColor SHFontDarkGray]];
    [self.secondaryActionButton setTitle:@"I'm already a paying user >" forState:UIControlStateNormal];
}

- (void) refreshedObject:(NSNotification*)notification
{
    NSLog(@"refreshedObject on paywall: %@", [notification userInfo]);
    if ([[notification userInfo] objectForKey:@"object_type"] && [[[notification userInfo] objectForKey:@"object_type"] isEqualToString:@"user"]) {
        if ([[[LXSession thisSession] user] hasMembership]) {
            [self dismissView];
        }
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



- (void) dismissView
{
    [self.navigationController popToRootViewControllerAnimated:NO];
}


# pragma mark actions

- (IBAction)action:(id)sender
{
    
}

- (IBAction)secondaryAction:(id)sender
{
    
}



# pragma mark status bar

- (BOOL) prefersStatusBarHidden
{
    return YES;
}


@end
