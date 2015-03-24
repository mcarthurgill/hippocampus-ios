//
//  HCMessageViewController.m
//  Hippocampus
//
//  Created by Will Schreiber on 3/23/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import "HCMessageViewController.h"

@interface HCMessageViewController ()

@end

@implementation HCMessageViewController

@synthesize index;
@synthesize messageLabel;
@synthesize text;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupAppearance];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.messageLabel setText:self.text];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) setupAppearance
{
}

- (void) setMessage:(NSString*)message
{
    [self setText:message];
    [self.messageLabel setText:message];
}


@end
