//
//  SHDismissFeatureViewController.m
//  Hippocampus
//
//  Created by Will Schreiber on 12/11/15.
//  Copyright © 2015 LXV. All rights reserved.
//

#import "SHDismissFeatureViewController.h"

@interface SHDismissFeatureViewController ()

@end

@implementation SHDismissFeatureViewController

@synthesize label, button;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupAppearance];
}

- (void) setupAppearance
{
    [self.label setFont:[UIFont secondaryFontWithSize:18.0f]];
    [self.label setTextColor:[UIColor SHFontDarkGray]];
    
    [self.button setBackgroundColor:[UIColor SHBlue]];
    [self.button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.button.layer setCornerRadius:4.0f];
    [self.button setClipsToBounds:YES];
    [[self.button titleLabel] setFont:[UIFont titleFontWithSize:18.0f]];
    
    [self.label setText:@"Ready to crush Hippo?"];
    [self.button setTitle:@"Let's Get Started" forState:UIControlStateNormal];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)buttonAction:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:^(void){}];
}

@end
