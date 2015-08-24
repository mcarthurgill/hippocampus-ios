//
//  SHMainViewController.m
//  Hippocampus
//
//  Created by Will Schreiber on 8/7/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import "SHMainViewController.h"
#import "SHBucketsViewController.h"
#import "SHSlackThoughtsViewController.h"

@interface SHMainViewController ()

@end

@implementation SHMainViewController

@synthesize segmentControl;
@synthesize containerView;
@synthesize viewControllersCached;

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupLogic];
    [self switchContainerToView:@"thoughtsViewController" fromView:nil];
}

- (void) setupLogic
{
    self.viewControllersCached = [[NSMutableDictionary alloc] init];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}




# pragma mark user interaction actions

- (IBAction)segmentControlAction:(UISegmentedControl*)sender
{
    if ([sender selectedSegmentIndex] == 0) {
        [self switchContainerToView:@"thoughtsViewController" fromView:@"bucketsViewController"];
    } else if ([sender selectedSegmentIndex] == 1) {
        [self switchContainerToView:@"bucketsViewController" fromView:@"thoughtsViewController"];
    }
}

- (IBAction)leftBarButtonAction:(id)sender
{
    UIAlertView* av = [[UIAlertView alloc] initWithTitle:@"Not yet implemented!" message:nil delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil];
    [av show];
}

- (IBAction)rightBarButtonAction:(id)sender
{
    UIAlertView* av = [[UIAlertView alloc] initWithTitle:@"Not yet implemented!" message:nil delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil];
    [av show];
}




# pragma mark program actions

- (void) switchContainerToView:(NSString*)toName fromView:(NSString*)fromName
{
    UIViewController* vc;
    
    if (![self.viewControllersCached objectForKey:toName]) {
        if ([toName isEqualToString:@"thoughtsViewController"]) {
            vc = [[SHSlackThoughtsViewController alloc] init];
            [(SHSlackThoughtsViewController*)vc setLocalKey:[NSMutableDictionary allThoughtsLocalKey]];
        } else {
            vc = [[UIStoryboard storyboardWithName:@"Seahorse" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:toName];
        }
        [self.viewControllersCached setObject:vc forKey:toName];
    } else {
        vc = [self.viewControllersCached objectForKey:toName];
    }
    
    [self addChildViewController:vc];
    [vc didMoveToParentViewController:self];
    vc.view.frame = self.containerView.bounds;
    [self.containerView addSubview:vc.view];
    if (fromName && [self.viewControllersCached objectForKey:fromName]) {
        [[self.viewControllersCached objectForKey:fromName] removeFromParentViewController];
        if ([[self.viewControllersCached objectForKey:fromName] respondsToSelector:@selector(textView)] && [[self.viewControllersCached objectForKey:fromName] textView]) {
            [[[self.viewControllersCached objectForKey:fromName] textView] resignFirstResponder];
        }
    }
}

@end
