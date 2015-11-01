//
//  SHMainViewController.m
//  Hippocampus
//
//  Created by Will Schreiber on 8/7/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import "SHMainViewController.h"
#import "SHBucketsViewController.h"
#import "SHMessagesViewController.h"
#import "SHTagDetailViewController.h"
#import "SHSearchViewController.h"
#import "SHProfileViewController.h"

@interface SHMainViewController ()

@end

@implementation SHMainViewController

@synthesize segmentControl;
@synthesize containerView;
@synthesize currentPresentedViewController;
@synthesize viewControllersCached;
@synthesize paywallController;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupLogic];
    [self registerForNotifications];
    
    //[self setupSegmentedControl];
}

- (void) setupLogic
{
    self.viewControllersCached = [[NSMutableDictionary alloc] init];
}

- (void) setupSegmentedControl
{
    [self.segmentControl setContentMode:UIViewContentModeScaleAspectFit];
    
    UIImage *myNewImage = [[UIImage imageNamed:@"bucket_detail_icon.png"] resizableImageWithCapInsets:UIEdgeInsetsZero];
    
    [self.segmentControl setImage:myNewImage forSegmentAtIndex:1];
}

- (void) registerForNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pushBucketViewController:) name:@"pushBucketViewController" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pushTagViewController:) name:@"pushTagViewController" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(presentViewController:) name:@"presentViewController" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pushViewController:) name:@"pushViewController" object:nil];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self loadIfNoChildController];
    
    [self checkForPaywall];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void) loadIfNoChildController
{
    if ([[self.containerView subviews] count] == 0) {
        [self switchContainerToView:@"bucketsViewController" fromView:nil];
        [self switchContainerToView:@"thoughtsViewController" fromView:@"bucketsViewController"];
    }
}




# pragma mark user interaction actions

- (IBAction)segmentControlAction:(UISegmentedControl*)sender
{
    NSString* currentTitle = [sender titleForSegmentAtIndex:[sender selectedSegmentIndex]];
    if ([sender selectedSegmentIndex] == 0 && ![currentPresentedViewController isEqualToString:@"thoughtsViewController"]) {
        [self switchContainerToView:@"thoughtsViewController" fromView:currentPresentedViewController];
    } else if ([sender selectedSegmentIndex] == 1 && [currentPresentedViewController isEqualToString:@"thoughtsViewController"]) {
        if ([currentTitle isEqualToString:@"Buckets"]) {
            [self switchContainerToView:@"bucketsViewController" fromView:currentPresentedViewController];
        } else if ([currentTitle isEqualToString:@"Tags"]) {
            [self switchContainerToView:@"tagsViewController" fromView:currentPresentedViewController];
        }
    } else if ([sender selectedSegmentIndex] == 1 && [currentPresentedViewController isEqualToString:@"bucketsViewController"]) {
        [self switchContainerToView:@"tagsViewController" fromView:currentPresentedViewController];
    } else if ([sender selectedSegmentIndex] == 1 && [currentPresentedViewController isEqualToString:@"tagsViewController"]) {
        [self switchContainerToView:@"bucketsViewController" fromView:currentPresentedViewController];
    }
}

- (IBAction)leftBarButtonAction:(id)sender
{
    SHProfileViewController* vc = (SHProfileViewController*)[[UIStoryboard storyboardWithName:@"Seahorse" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"navigationSHProfileViewController"];
    [self presentViewController:vc animated:YES completion:^(void){}];
}

- (IBAction)rightBarButtonAction:(id)sender
{
    SHSearchViewController* vc = (SHSearchViewController*)[[UIStoryboard storyboardWithName:@"Seahorse" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"SHSearchViewController"];
    UIView* backgroundFrame = [self.view snapshotViewAfterScreenUpdates:NO];
    
    UINavigationController* nc = [[UINavigationController alloc] initWithRootViewController:vc];
    
    [self presentViewController:nc animated:NO
                     completion:^(void){
                         [vc.backgroundView addSubview:backgroundFrame];
                     }
     ];
}





# pragma mark program actions

- (void) switchContainerToView:(NSString*)toName fromView:(NSString*)fromName
{
    [self loadViewController:toName];
    
    UIViewController* vc = [self.viewControllersCached objectForKey:toName];
    
    [self addChildViewController:vc];
    [vc didMoveToParentViewController:self];
    vc.view.frame = self.containerView.bounds;
    [self.containerView addSubview:vc.view];
    if (fromName && [self.viewControllersCached objectForKey:fromName]) {
        [[self.viewControllersCached objectForKey:fromName] removeFromParentViewController];
        if ([[self.viewControllersCached objectForKey:fromName] respondsToSelector:@selector(textView)] && [[self.viewControllersCached objectForKey:fromName] textView]) {
            [[[self.viewControllersCached objectForKey:fromName] textView] resignFirstResponder];
        }
        if ([[self.viewControllersCached objectForKey:fromName] respondsToSelector:@selector(searchBar)] && [[self.viewControllersCached objectForKey:fromName] searchBar]) {
            [[[self.viewControllersCached objectForKey:fromName] searchBar] resignFirstResponder];
        }
    }
    
    if ([toName isEqualToString:@"thoughtsViewController"]) {
        [self setTitle:@"Thoughts"];
    } else if ([toName isEqualToString:@"bucketsViewController"]) {
        [self setTitle:@"Buckets"];
        [self.segmentControl setTitle:@"Buckets" forSegmentAtIndex:1];
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [[(SHBucketsViewController*)vc tableView] reloadData];
        });
    } else if ([toName isEqualToString:@"tagsViewController"]) {
        [self setTitle:@"Tags"];
        [self.segmentControl setTitle:@"Tags" forSegmentAtIndex:1];
        dispatch_async(dispatch_get_main_queue(), ^(void){
            //ATTENTION!
            //[[(SHBucketsViewController*)vc tableView] reloadData];
        });
    }
    
    [self setCurrentPresentedViewController:toName];
}

- (UIViewController*) loadViewController:(NSString*)viewControllerName
{
    UIViewController* vc = [self.viewControllersCached objectForKey:viewControllerName];
    if (!vc) {
        if ([viewControllerName isEqualToString:@"thoughtsViewController"]) {
            vc = [[UIStoryboard storyboardWithName:@"Seahorse" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"SHMessagesViewController"];
            [(SHMessagesViewController*)vc setLocalKey:[NSMutableDictionary allThoughtsLocalKey]];
        } else {
            vc = [[UIStoryboard storyboardWithName:@"Seahorse" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:viewControllerName];
        }
        [self.viewControllersCached setObject:vc forKey:viewControllerName];
    }
    return vc;
}

- (void) pushBucketViewController:(NSNotification*)notification
{
    SHMessagesViewController* vc = [[UIStoryboard storyboardWithName:@"Seahorse" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"SHMessagesViewController"];
    [vc setLocalKey:[[[notification userInfo] objectForKey:@"bucket"] localKey]];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void) pushTagViewController:(NSNotification*)notification
{
    SHTagDetailViewController* vc = [[UIStoryboard storyboardWithName:@"Seahorse" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"SHTagDetailViewController"];
    [vc setLocalKey:[[[notification userInfo] objectForKey:@"tag"] localKey]];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void) presentViewController:(NSNotification*)notification
{
    if (![self presentedViewController]) {
        [self.navigationController presentViewController:[[notification userInfo] objectForKey:@"viewController"] animated:([[notification userInfo] objectForKey:@"animated"] ? [[[notification userInfo] objectForKey:@"animated"] boolValue] : YES) completion:^(void){}];
    }
}

- (void) pushViewController:(NSNotification*)notification
{
    if ([self presentedViewController]) {
        [[self presentedViewController] dismissViewControllerAnimated:NO completion:nil];
    }
    [self.navigationController pushViewController:[[notification userInfo] objectForKey:@"viewController"] animated:([[notification userInfo] objectForKey:@"animated"] ? [[[notification userInfo] objectForKey:@"animated"] boolValue] : YES)];
}




# pragma mark paywall

- (void) checkForPaywall
{
    if (![[[LXSession thisSession] user] hasMembership]) {
        [self presentPaywall];
    }
}

- (void) presentPaywall
{
    self.paywallController = (UIViewController*)[[UIStoryboard storyboardWithName:@"Seahorse" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"SHPaywallViewController"];
    [self.navigationController pushViewController:self.paywallController animated:NO];
}


@end
