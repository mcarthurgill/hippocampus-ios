//
//  HCBucketTableViewController.h
//  Hippocampus
//
//  Created by Will Schreiber on 7/8/14.
//  Copyright (c) 2014 LXV. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HCBucketTableViewController : UITableViewController

@property (strong, nonatomic) HCBucket* bucket;

@property (strong, nonatomic) NSMutableArray* sections;
@property (strong, nonatomic) NSMutableArray* allItems;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *addButton;

- (IBAction)addAction:(id)sender;

@end
