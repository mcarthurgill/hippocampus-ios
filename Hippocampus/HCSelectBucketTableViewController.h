//
//  HCSelectBucketTableViewController.h
//  Hippocampus
//
//  Created by Will Schreiber on 7/10/14.
//  Copyright (c) 2014 LXV. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HCSelectBucketTableViewController : UITableViewController <UISearchBarDelegate>

@property (strong, nonatomic) IBOutlet UIBarButtonItem *addButton;
@property (strong, nonatomic) IBOutlet UISearchBar *searchBar;

@property (strong, nonatomic) HCItem* item;
@property (strong, nonatomic) NSMutableArray* sections;
@property (strong, nonatomic) NSMutableArray* bucketsArray;
@property (strong, nonatomic) NSMutableArray* searchResultsArray;

- (IBAction)addAction:(id)sender;

@end
