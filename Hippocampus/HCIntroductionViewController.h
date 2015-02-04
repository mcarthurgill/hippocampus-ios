//
//  HCIntroductionViewController.h
//  Hippocampus
//
//  Created by Joseph McArthur Gill on 1/30/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HCIntroductionQuestionViewController.h"

@interface HCIntroductionViewController : UIViewController <UIPageViewControllerDataSource, HCIntroductionQuestionDelegate>

@property (strong, nonatomic) UIPageViewController *pageController;
@property (strong, nonatomic) NSArray *introQuestions;
@property (assign) int flagged;

@end