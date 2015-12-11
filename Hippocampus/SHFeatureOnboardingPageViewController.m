//
//  SHFeatureOnboardingPageViewController.m
//  Hippocampus
//
//  Created by Joseph Gill on 12/10/15.
//  Copyright © 2015 LXV. All rights reserved.
//

#import "SHFeatureOnboardingPageViewController.h"
#import "SHFeaturePreviewViewController.h"

@interface SHFeatureOnboardingPageViewController ()

@end

@implementation SHFeatureOnboardingPageViewController

@synthesize childIndex;
@synthesize descriptions;
@synthesize resourceNames;

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.childIndex = 0;
    
    [self setDelegate:self];
    [self setDataSource:self];
    
    UIPageControl *pageControlAppearance = [UIPageControl appearanceWhenContainedIn:[UIPageViewController class], nil];
    pageControlAppearance.pageIndicatorTintColor = [UIColor lightGrayColor];
    pageControlAppearance.currentPageIndicatorTintColor= [UIColor darkGrayColor];

    self.descriptions = @[
               @"Create a person",
               @"Add a note to a person",
               @"Set a nudge to get reminded about a note",
               ];
    self.resourceNames = @[
                          @"create_person",
                          @"add_note",
                          @"add_nudge",
                          ];
    
    [self setViewControllers:@[[self featureControllerWithDescription:[self.descriptions firstObject] andResourceName:[self.resourceNames firstObject] andIndex:0]] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:^(BOOL finished) {
    }];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (UIViewController*) pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    if ([viewController respondsToSelector:@selector(index)]) {
        if ([(SHFeaturePreviewViewController*)viewController index] > 0) {
            return [self featureControllerWithDescription:[self.descriptions objectAtIndex:([(SHFeaturePreviewViewController*)viewController index]-1)] andResourceName:[self.resourceNames objectAtIndex:([(SHFeaturePreviewViewController*)viewController index]-1)] andIndex:([(SHFeaturePreviewViewController*)viewController index]-1)];
        }
    }
    return nil;
}

- (UIViewController*) pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    if ([viewController respondsToSelector:@selector(index)]) {
        if ([(SHFeaturePreviewViewController*)viewController index] == self.descriptions.count-1) {
            return (UINavigationController*)[[UIStoryboard storyboardWithName:@"Seahorse" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"SHDismissFeatureViewController"];
        } else if ([(SHFeaturePreviewViewController*)viewController index] < self.descriptions.count-1) {
            return [self featureControllerWithDescription:[self.descriptions objectAtIndex:([(SHFeaturePreviewViewController*)viewController index]+1)] andResourceName:[self.resourceNames objectAtIndex:([(SHFeaturePreviewViewController*)viewController index]+1)] andIndex:([(SHFeaturePreviewViewController*)viewController index]+1)];
        }
    }
    return nil;
}

- (void) pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed
{
    if ([[pageViewController.viewControllers firstObject] respondsToSelector:@selector(index)]) {
        [self setChildIndex:[(SHFeaturePreviewViewController*)[pageViewController.viewControllers firstObject] index]];
    } else {
        [self setChildIndex:self.descriptions.count];
    }
}

- (NSInteger)presentationCountForPageViewController:(UIPageViewController *)pageViewController
{
    return [self.descriptions count]+1;
}

- (NSInteger)presentationIndexForPageViewController:(UIPageViewController *)pageViewController
{
    return [self childIndex];
}

- (SHFeaturePreviewViewController*) featureControllerWithDescription:(NSString*)description andResourceName:(NSString *)resourceName andIndex:(NSUInteger)index
{
    SHFeaturePreviewViewController* controller = (SHFeaturePreviewViewController*)[[UIStoryboard storyboardWithName:@"Seahorse" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"SHFeaturePreviewViewController"];
    
    [controller setResourceName:resourceName];
    [controller setDescriptionText:description];
    [controller setIndex:index];
    
    return controller;
}



- (BOOL) prefersStatusBarHidden
{
    return YES;
}

@end
