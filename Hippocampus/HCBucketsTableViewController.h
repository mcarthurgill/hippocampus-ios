//
//  HCBucketsTableViewController.h
//  Hippocampus
//
//  Created by Will Schreiber on 7/8/14.
//  Copyright (c) 2014 LXV. All rights reserved.
//

#import <UIKit/UIKit.h>

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

- (IBAction)refreshControllerChanged:(id)sender;
- (IBAction)addAction:(id)sender;

@end
