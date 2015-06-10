//
//  HCContainerViewController.m
//  Hippocampus
//
//  Created by Will Schreiber on 2/11/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import "HCContainerViewController.h"
#import "HCPopUpViewController.h"

@interface HCContainerViewController ()

@end

@implementation HCContainerViewController

@synthesize delegate;

@synthesize pageController;

@synthesize items;
@synthesize bucket;
@synthesize item;

@synthesize smallView;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupPageControllerView];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if ([[LXSetup theSetup] visitedThisScreen:self]) {
        //NSLog(@"already visited item table view controller");
    } else {
        //NSLog(@"have not visited item table view controller");
        UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Messages" bundle:[NSBundle mainBundle]];
        HCPopUpViewController* vc = [storyboard instantiateViewControllerWithIdentifier:@"popUpViewController"];
        [vc setImageForScreenshotImageView:[[LXSetup theSetup] takeScreenshot]];
        [vc setImageForMainImageView:[UIImage imageNamed:@"item-screen.jpg"]];
        [vc setMainLabelText:@"Add this thought to a bucket. Or set it to nudge you later (like a reminder)."];
        [self.navigationController.visibleViewController presentViewController:vc animated:NO completion:nil];
    }
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

# pragma mark setup views

- (void) setupPageControllerView
{
    pageController = [[HCItemPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
    [pageController.view setFrame:CGRectMake(0, 0, self.smallView.frame.size.width, self.smallView.frame.size.height)];
    
    [pageController setItems:self.items];
    [pageController setBucket:self.bucket];
    [pageController setItem:self.item];
    [pageController setNavItem:self.navigationItem];
    
    [pageController handleInitialLoad];
    
    [self addChildViewController:pageController];
    [self.smallView addSubview:pageController.view];
    [pageController didMoveToParentViewController:self];
}



- (IBAction)saveAction:(id)sender
{
    [pageController saveAction:sender];
}


@end
