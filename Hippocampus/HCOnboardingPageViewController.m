//
//  HCOnboardingPageViewController.m
//  Hippocampus
//
//  Created by Will Schreiber on 3/23/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import "HCOnboardingPageViewController.h"
#import "HCMessageViewController.h"

@interface HCOnboardingPageViewController ()

@end

@implementation HCOnboardingPageViewController

@synthesize childIndex;
@synthesize quotes;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.childIndex = 0;
    
    [self setDelegate:self];
    [self setDataSource:self];
    
    UIPageControl *pageControlAppearance = [UIPageControl appearanceWhenContainedIn:[UIPageViewController class], nil];
    pageControlAppearance.pageIndicatorTintColor = [UIColor lightGrayColor];
    pageControlAppearance.currentPageIndicatorTintColor = [UIColor darkGrayColor];
    
    quotes = @[
               @"\"To be interesting, be interested.\" Dale Carnegie",
               @"\"Did you ever stop to think that a dog is the only animal that doesn’t have to work for a living? A hen has to lay eggs, a cow has to give milk, and a canary has to sing. But a dog makes his living by giving you nothing but love.\"",
               @"Information not found in notes has only a five percent chance of being remembered.",
               @"\"Names are the sweetest and most important sound in any language.\" Dale Carnegie",
              ];
    
    [self setViewControllers:@[[self messageControllerWithMessage:[self.quotes firstObject] andIndex:0]] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:^(BOOL finished) {
    }];
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIViewController*) pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    if ([viewController respondsToSelector:@selector(index)]) {
        if ([(HCMessageViewController*)viewController index] > 0) {
            return [self messageControllerWithMessage:[self.quotes objectAtIndex:([(HCMessageViewController*)viewController index]-1)] andIndex:([(HCMessageViewController*)viewController index]-1)];
        }
    }
    return nil;
}

- (UIViewController*) pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    if ([viewController respondsToSelector:@selector(index)]) {
        if ([(HCMessageViewController*)viewController index] == self.quotes.count-1) {
            return (UINavigationController*)[[UIStoryboard storyboardWithName:@"Login" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"loginNavigationViewController"];
        } else if ([(HCMessageViewController*)viewController index] < self.quotes.count-1) {
            return [self messageControllerWithMessage:[self.quotes objectAtIndex:([(HCMessageViewController*)viewController index]+1)] andIndex:([(HCMessageViewController*)viewController index]+1)];
        }
    }
    return nil;
}

- (void) pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed
{
    if ([[pageViewController.viewControllers firstObject] respondsToSelector:@selector(index)]) {
        [self setChildIndex:[[pageViewController.viewControllers firstObject] index]];
    } else {
        [self setChildIndex:self.quotes.count];
    }
}


- (NSInteger)presentationCountForPageViewController:(UIPageViewController *)pageViewController {
    return [self.quotes count]+1;
}

- (NSInteger)presentationIndexForPageViewController:(UIPageViewController *)pageViewController {
    return [self childIndex];
}


- (HCMessageViewController*) messageControllerWithMessage:(NSString*)message andIndex:(NSUInteger)index
{
    HCMessageViewController* controller = (HCMessageViewController*)[[UIStoryboard storyboardWithName:@"Login" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"messageViewController"];
    
    [controller setMessage:message];
    [controller setIndex:index];
    
    return controller;
}

@end
