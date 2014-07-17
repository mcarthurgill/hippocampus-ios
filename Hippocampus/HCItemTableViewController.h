//
//  HCItemTableViewController.h
//  Hippocampus
//
//  Created by Will Schreiber on 7/8/14.
//  Copyright (c) 2014 LXV. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HCItemTableViewController : UITableViewController

@property (strong, nonatomic) HCItem* item;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *saveButton;
@property (strong, nonatomic) NSMutableArray* sections;

- (IBAction)saveAction:(id)sender;

- (void) saveReminder:(NSString*)reminder;
- (void) saveUpdatedMessage:(NSString *)updatedMessage; 

@end
