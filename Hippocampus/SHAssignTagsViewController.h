//
//  SHAssignTagsViewController.h
//  Hippocampus
//
//  Created by Will Schreiber on 10/30/15.
//  Copyright © 2015 LXV. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SHAssignTagsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UITextFieldDelegate, UIAlertViewDelegate>

@property (strong, nonatomic) NSString* localKey;

@property (strong, nonatomic) IBOutlet UISearchBar *searchBar;
@property (strong, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) NSMutableArray* sections;
@property (strong, nonatomic) NSMutableArray* tagResultKeys;
@property (strong, nonatomic) NSMutableArray* tagSelectedKeys;

- (IBAction) leftButtonAction:(id)sender;
- (IBAction) rightButtonAction:(id)sender;

- (void) reloadScreen;

@end
