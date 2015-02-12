//
//  HCContainerViewController.m
//  Hippocampus
//
//  Created by Will Schreiber on 2/11/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import "HCContainerViewController.h"

@interface HCContainerViewController ()

@end

@implementation HCContainerViewController

@synthesize pageController;

@synthesize items;
@synthesize bucket;
@synthesize item;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupPageControllerView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

# pragma mark setup views

- (void) setupPageControllerView
{
    pageController = [[HCItemPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
    [pageController.view setFrame:self.view.frame];
    
    [pageController setItems:self.items];
    [pageController setBucket:self.bucket];
    [pageController setItem:self.item];
    
    [pageController handleInitialLoad];
    
    [self addChildViewController:pageController];
    [self.view addSubview:pageController.view];
    [pageController didMoveToParentViewController:self];
}


@end
