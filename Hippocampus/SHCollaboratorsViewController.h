//
//  SHCollaboratorsViewController.h
//  Hippocampus
//
//  Created by Joseph Gill on 9/18/15.
//  Copyright © 2015 LXV. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SHCollaboratorsViewController : UIViewController
{
    BOOL isSearching; 
}

@property (strong, nonatomic) NSString *localKey;
@property (strong, nonatomic) NSMutableArray *sections;
@property (strong, nonatomic) NSMutableArray *searchResults;
@property (strong, nonatomic) NSMutableArray *contactsToInvite;

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;

- (IBAction)inviteAction:(id)sender;
- (IBAction)cancelAction:(id)sender;

@end
