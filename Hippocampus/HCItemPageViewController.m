//
//  HCItemPageViewController.m
//  Hippocampus
//
//  Created by Will Schreiber on 2/11/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import "HCItemPageViewController.h"
#import "HCItemTableViewController.h"
#import "HCContainerViewController.h"
#import "HCBucketViewController.h"

@interface HCItemPageViewController ()

@end

@implementation HCItemPageViewController 

@synthesize items;
@synthesize bucket;
@synthesize item;

@synthesize navItem;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setDataSource:self];
    [self setDelegate:self];
    
    [self disableTapGesture];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



# pragma mark page view controller data source

- (void) disableTapGesture
{
    for (UIGestureRecognizer *recognizer in self.gestureRecognizers) {
        if ([recognizer isKindOfClass:[UITapGestureRecognizer class]]) {
            recognizer.enabled = NO;
        }
    }
}

- (void) handleInitialLoad
{
    [self goToItem:self.item animated:NO];
}

- (void) saveAction:(id)sender
{
    [(HCItemPageViewController*)self.viewControllers.lastObject saveAction:sender];
}


- (void) goToItem:(NSMutableDictionary*)i animated:(BOOL)animated
{
    [self setViewControllers:@[[self itemViewWithItem:i]] direction:UIPageViewControllerNavigationDirectionForward animated:animated
                  completion:^(BOOL finished) {
                  }
     ];
}

- (UIViewController*) pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    int index = [self indexForViewController:viewController];
    if (index > 0 && index < self.items.count) {
        return [self itemViewWithItem:[self.items objectAtIndex:(index-1)]];
    }
    return nil;
}

- (UIViewController*) pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    int index = [self indexForViewController:viewController];
    if (index+1 < self.items.count) {
        return [self itemViewWithItem:[self.items objectAtIndex:(index+1)]];
    }
    return nil;
}

- (void) pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed
{
    //NSInteger beforeIndex = [(FBFlipViewController*)previousViewControllers.lastObject index];
    //NSInteger afterIndex = [(FBFlipViewController*)pageViewController.viewControllers.lastObject index];
    int index = [self indexForItem:pageViewController.viewControllers.lastObject];
    NSLog(@"index: %i", index);
}

- (HCItemTableViewController*) itemViewWithItem:(NSMutableDictionary*)i
{
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Messages" bundle:[NSBundle mainBundle]];
    HCItemTableViewController* itvc = (HCItemTableViewController*)[storyboard instantiateViewControllerWithIdentifier:@"itemTableViewController"];
    [itvc setItem:i];
    [itvc setPageControllerDelegate:self];
    return itvc;
}

- (int) indexForViewController:(id)vc
{
    return [self indexForItem:[(HCItemTableViewController*)vc originalItem]];
}

- (int) indexForItem:(NSMutableDictionary*)i
{
    return (int)[self.items indexOfObject:i];
}

- (void) updateItemsArrayWithOriginal:(NSMutableDictionary*)original new:(NSMutableDictionary*)n
{
    int index = (int)[self.items indexOfObject:original];
    if (index && index < self.items.count) {
        if ([self.items respondsToSelector:@selector(replaceObjectAtIndex:withObject:)]) {
            [self.items replaceObjectAtIndex:index withObject:n];
        }
    }
    if ([[(HCContainerViewController*)[self parentViewController] delegate] respondsToSelector:@selector(updateItemsArrayWithOriginal:new:)]) {
        [[(HCContainerViewController*)[self parentViewController] delegate] updateItemsArrayWithOriginal:original new:n];
    }
}

@end
