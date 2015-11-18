//
//  HCOnboardingPageViewController.h
//  Hippocampus
//
//  Created by Will Schreiber on 3/23/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HCOnboardingPageViewController : UIPageViewController <UIPageViewControllerDataSource, UIPageViewControllerDelegate>

@property (nonatomic) NSUInteger childIndex;

@property (strong, nonatomic) NSArray* quotes;

@end
