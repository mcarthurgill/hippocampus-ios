//
//  SHFeaturePreviewInitialViewController.m
//  Hippocampus
//
//  Created by Joseph Gill on 12/11/15.
//  Copyright © 2015 LXV. All rights reserved.
//

#import "SHFeaturePreviewInitialViewController.h"

@interface SHFeaturePreviewInitialViewController ()

@end

@implementation SHFeaturePreviewInitialViewController

@synthesize pageController;

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBar.hidden = YES;
}

- (void) setupView
{
    pageController = [[SHFeatureOnboardingPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
    [pageController.view setFrame:self.view.frame];
    
    [self addChildViewController:pageController];
    [self.view addSubview:pageController.view];
    [pageController didMoveToParentViewController:self];
}


- (BOOL) prefersStatusBarHidden
{
    return YES;
}

@end
