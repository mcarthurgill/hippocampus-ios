//
//  SHMainViewController.h
//  Hippocampus
//
//  Created by Will Schreiber on 8/7/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SHMainViewController : UIViewController

@property (strong, nonatomic) IBOutlet UISegmentedControl *segmentControl;
@property (strong, nonatomic) IBOutlet UIView *containerView;
@property (strong, nonatomic) NSMutableDictionary* viewControllersCached;
@property (strong, nonatomic) id paywallController;

- (IBAction)segmentControlAction:(UISegmentedControl*)sender;
- (IBAction)leftBarButtonAction:(id)sender;
- (IBAction)rightBarButtonAction:(id)sender;

@end
