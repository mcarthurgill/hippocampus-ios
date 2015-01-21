//
//  HCNotesTableViewController.h
//  Hippocampus
//
//  Created by Will Schreiber on 7/8/14.
//  Copyright (c) 2014 LXV. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HCNotesTableViewController : UITableViewController <UISearchBarDelegate>
{
    BOOL requestMade;
}

@property (strong, nonatomic) IBOutlet UIRefreshControl *refreshControl;
@property (strong, nonatomic) IBOutlet UISearchBar *searchBar;
@property (strong, nonatomic) NSMutableArray* sections;

@property (strong, nonatomic) NSMutableArray* allItems;
@property (strong, nonatomic) NSMutableArray* outstandingItems;

- (IBAction)refreshControllerChanged:(id)sender;
- (IBAction)addAction:(id)sender;

@end
