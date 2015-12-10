//
//  SHFeatureOnboardingPageViewController.h
//  Hippocampus
//
//  Created by Joseph Gill on 12/10/15.
//  Copyright © 2015 LXV. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SHFeatureOnboardingPageViewController : UIPageViewController <UIPageViewControllerDataSource, UIPageViewControllerDelegate>

@property (nonatomic) NSUInteger childIndex;

@property (strong, nonatomic) NSArray* descriptions;
@property (strong, nonatomic) NSArray* resourceNames;

@end
