//
//  HCContainerViewController.h
//  Hippocampus
//
//  Created by Will Schreiber on 2/11/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HCItemPageViewController.h"

@interface HCContainerViewController : UIViewController

@property (strong, nonatomic) HCItemPageViewController* pageController;

@property (strong, nonatomic) NSMutableArray* items;
@property (strong, nonatomic) NSMutableDictionary* bucket;
@property (strong, nonatomic) NSMutableDictionary* item;

@property (strong, nonatomic) IBOutlet UIView *smallView;

- (IBAction)saveAction:(id)sender;

@end
