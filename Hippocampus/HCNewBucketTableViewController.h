//
//  HCNewBucketTableViewController.h
//  Hippocampus
//
//  Created by Will Schreiber on 7/8/14.
//  Copyright (c) 2014 LXV. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HCNewBucketTableViewController : UITableViewController

@property (strong, nonatomic) IBOutlet UIBarButtonItem *cancelButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *saveButton;

@property (strong, nonatomic) HCBucket* bucket;
@property (strong, nonatomic) NSArray* bucketTypes;

- (IBAction)cancelAction:(id)sender;
- (IBAction)saveAction:(id)sender;

@end
