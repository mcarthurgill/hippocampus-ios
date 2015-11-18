//
//  SHSearchViewController.h
//  Hippocampus
//
//  Created by Will Schreiber on 8/27/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SHSearchViewController : UIViewController <UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) IBOutlet UISearchBar *searchBar;
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UIView *backgroundView;

@property (strong, nonatomic) NSMutableArray* sections;

@property (strong, nonatomic) NSMutableArray* searchResults;
@property (strong, nonatomic) NSMutableArray* bucketResultKeys;
@property (strong, nonatomic) NSMutableArray* bucketResults;

@end
