//
//  SHAssignTagsViewController.h
//  Hippocampus
//
//  Created by Will Schreiber on 10/30/15.
//  Copyright © 2015 LXV. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SHAssignTagsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UITextFieldDelegate>

@property (strong, nonatomic) NSString* localKey;

@property (strong, nonatomic) IBOutlet UISearchBar *searchBar;
@property (strong, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) NSMutableArray* sections;
@property (strong, nonatomic) NSMutableArray* tagResultKeys;
@property (strong, nonatomic) NSMutableArray* tagSelectedKeys;

@property (strong, nonatomic) IBOutlet UILabel *topViewLabel;
@property (strong, nonatomic) IBOutlet UIView *topView;

@property (strong, nonatomic) IBOutlet UIView *topInputView;
@property (strong, nonatomic) IBOutlet UITextField *bucketTextField;
@property (strong, nonatomic) IBOutlet UIButton *inputActionButton;
- (IBAction)inputAction:(id)sender;

- (IBAction) leftButtonAction:(id)sender;
- (IBAction) rightButtonAction:(id)sender;
- (IBAction) topViewButtonAction:(id)sender;

- (void) reloadScreen;

@end
