//
//  HCSearchTableViewController.h
//  Hippocampus
//
//  Created by Will Schreiber on 7/8/14.
//  Copyright (c) 2014 LXV. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HCSearchTableViewController : UITableViewController <UISearchBarDelegate>
{
    BOOL requestMade;
}

@property (strong, nonatomic) IBOutlet UISearchBar *searchBar;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *doneButton;

@property (strong, nonatomic) NSMutableArray* sections;
@property (strong, nonatomic) NSMutableArray* bucketsArray;
@property (strong, nonatomic) NSMutableArray* itemsArray;

- (IBAction)doneAction:(id)sender;

@end
