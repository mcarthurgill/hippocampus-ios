//
//  SHAllNudgesViewController.h
//  Hippocampus
//
//  Created by Joseph Gill on 12/8/15.
//  Copyright © 2015 LXV. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SHNudgesIndexViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSMutableArray *reminderDates; 

@end
