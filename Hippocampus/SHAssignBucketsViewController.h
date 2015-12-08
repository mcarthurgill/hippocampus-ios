//
//  SHAssignBucketsViewController.h
//  Hippocampus
//
//  Created by Will Schreiber on 9/6/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SHAssignBucketsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UITextFieldDelegate>

@property (strong, nonatomic) NSString* localKey;

@property (strong, nonatomic) IBOutlet UISearchBar *searchBar;
@property (strong, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) NSMutableArray* sections;
@property (strong, nonatomic) NSMutableArray* bucketResultKeys;
@property (strong, nonatomic) NSMutableArray* bucketSelectedKeys;
@property (strong, nonatomic) NSMutableArray* contactsSelected;

- (IBAction) leftButtonAction:(id)sender;
- (IBAction) rightButtonAction:(id)sender;

- (void) reloadScreen;

@end
