//
//  HCOnboardingPageViewController.m
//  Hippocampus
//
//  Created by Will Schreiber on 3/23/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import "HCOnboardingPageViewController.h"
#import "HCMessageViewController.h"
#import "HCLoginViewController.h"
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>

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
               @"Use Hippo to remember names, dates, and moments;",
               @"jot down important details about people in your personal and business network;",
               @"set nudges to remind you to follow up, like \"send flowers\" or \"ask how that surgery went\";",
               @"and journal your thoughts so you never forget the information that matters.",
               @"Ready to become an advanced people-person?",
               //@"Have you ever realized dogs are the only animals that don't have to work?\n\nHens lay eggs, cows give milk, and canaries sing. But a dog makes his living by giving you nothing but love.",
               //@"Names are the sweetest sound in any language. Start writing them down.",
               //@"Information not found in notes has only a 5% chance of being remembered.",
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
            NSString* identifier = [self canDevicePlaceAPhoneCall] ? @"loginNavigationViewController" : @"loginNonPhoneNavigationViewController";
            return (UINavigationController*)[[UIStoryboard storyboardWithName:@"Login" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:identifier];
        } else if ([(HCMessageViewController*)viewController index] < self.quotes.count-1) {
            return [self messageControllerWithMessage:[self.quotes objectAtIndex:([(HCMessageViewController*)viewController index]+1)] andIndex:([(HCMessageViewController*)viewController index]+1)];
        }
    }
    return nil;
}

- (void) pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed
{
    if ([[pageViewController.viewControllers firstObject] respondsToSelector:@selector(index)]) {
        [self setChildIndex:[(HCMessageViewController*)[pageViewController.viewControllers firstObject] index]];
    } else {
        [self setChildIndex:self.quotes.count];
    }
}


- (NSInteger)presentationCountForPageViewController:(UIPageViewController *)pageViewController
{
    return [self.quotes count]+1;
}

- (NSInteger)presentationIndexForPageViewController:(UIPageViewController *)pageViewController
{
    return [self childIndex];
}


- (HCMessageViewController*) messageControllerWithMessage:(NSString*)message andIndex:(NSUInteger)index
{
    HCMessageViewController* controller = (HCMessageViewController*)[[UIStoryboard storyboardWithName:@"Login" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"messageViewController"];
    
    [controller setMessage:message];
    [controller setIndex:index];
    
    return controller;
}


# pragma mark helpers

-(BOOL) canDevicePlaceAPhoneCall
{
    // Check if the device can place a phone call
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tel://"]]) {
        // Device supports phone calls, lets confirm it can place one right now
        CTTelephonyNetworkInfo *netInfo = [[CTTelephonyNetworkInfo alloc] init];
        CTCarrier *carrier = [netInfo subscriberCellularProvider];
        NSString *mnc = [carrier mobileNetworkCode];
        return !(([mnc length] == 0) || ([mnc isEqualToString:@"65535"]));
    }
    return NO;
}

@end
