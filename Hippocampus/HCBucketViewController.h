//
//  HCBucketViewController.h
//  Hippocampus
//
//  Created by Joseph McArthur Gill on 2/3/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HCItemTableViewController.h"

#define NULL_TO_NIL(obj) ({ __typeof__ (obj) __obj = (obj); __obj == [NSNull null] ? nil : obj; })

#define PICTURE_HEIGHT 128
#define PICTURE_MARGIN_TOP 8

@interface HCBucketViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextViewDelegate>
{
    BOOL requestMade;
}

@property (strong, nonatomic) NSMutableDictionary* bucket;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *composeView;
@property (weak, nonatomic) IBOutlet UITextView *composeTextView;

@property (strong, nonatomic) IBOutlet UIRefreshControl *refreshControl;

@property (strong, nonatomic) NSMutableArray* sections;
@property (strong, nonatomic) NSMutableArray* allItems;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *addButton;

@property (nonatomic, strong) NSLayoutConstraint *bottomConstraint;
@property (nonatomic, strong) NSLayoutConstraint *textViewHeightConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *tableViewHeightConstraint;

- (IBAction)addAction:(id)sender;

- (IBAction)refreshControllerChanged:(id)sender;



@end
