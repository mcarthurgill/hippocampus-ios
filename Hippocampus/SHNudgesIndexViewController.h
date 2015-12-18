//
//  SHAllNudgesViewController.h
//  Hippocampus
//
//  Created by Joseph Gill on 12/8/15.
//  Copyright © 2015 LXV. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SHNudgesIndexViewController : UIViewController
{
    BOOL requesting;
    MBProgressHUD* hud;
}

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSMutableArray *reminderDates; 

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tableViewToTopLayoutGuideConstraint;
@end
