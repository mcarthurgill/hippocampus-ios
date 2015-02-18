//
//  HCBucketsTableViewController.h
//  Hippocampus
//
//  Created by Will Schreiber on 7/8/14.
//  Copyright (c) 2014 LXV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HCBucketViewController.h"

@interface HCBucketsTableViewController : UITableViewController <UISearchBarDelegate>
{
    BOOL requestMade;
}

@property (strong, nonatomic) NSString* mode;
@property (strong, nonatomic) id delegate;

@property (strong, nonatomic) IBOutlet UIRefreshControl *refreshControl;
@property (strong, nonatomic) IBOutlet UISearchBar *searchBar;

@property (strong, nonatomic) NSMutableArray* sections;
@property (strong, nonatomic) NSMutableDictionary* bucketsDictionary;
@property (strong, nonatomic) NSMutableDictionary* bucketsSearchDictionary;
@property (strong, nonatomic) NSMutableDictionary* serverSearchDictionary;
@property (strong, nonatomic) NSMutableDictionary* cachedDiskDictionary;

@property (strong, nonatomic) HCBucketViewController* composeBucketController;

- (IBAction)refreshControllerChanged:(id)sender;
- (IBAction)composeButtonClicked:(id)sender;
- (IBAction)showReminders:(id)sender;

@end
