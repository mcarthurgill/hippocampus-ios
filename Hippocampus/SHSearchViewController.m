//
//  SHSearchViewController.m
//  Hippocampus
//
//  Created by Will Schreiber on 8/27/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import "SHSearchViewController.h"
#import "SHItemTableViewCell.h"
#import "SHSearch.h"

static NSString *itemCellIdentifier = @"SHItemTableViewCell";

@interface SHSearchViewController ()

@end

@implementation SHSearchViewController

@synthesize searchBar;
@synthesize tableView;
@synthesize backgroundView;
@synthesize sections;
@synthesize searchResults;
@synthesize cachedSearchResults;

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupSettings];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.searchBar becomeFirstResponder];
}

- (void) setupSettings
{
    [self.tableView registerNib:[UINib nibWithNibName:itemCellIdentifier bundle:nil] forCellReuseIdentifier:itemCellIdentifier];
    
    [self.tableView setRowHeight:UITableViewAutomaticDimension];
    [self.tableView setEstimatedRowHeight:100.0f];
    
    self.cachedSearchResults = [[NSMutableDictionary alloc] init];
}



# pragma mark search delegate

- (void) searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [self dismissView];
}

- (void) searchBar:(UISearchBar *)bar textDidChange:(NSString *)searchText
{
    [[SHSearch defaultManager] remoteSearchWithTerm:[bar text]
                                            success:^(id responseObject){
                                                [self reloadScreen];
                                            }
                                            failure:^(NSError* error){
                                            }
     ];
}

- (void) searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [self resignSearchFirstResponder];
}

- (void) resignSearchFirstResponder
{
    [self.searchBar resignFirstResponder];
    [self enableCancelButton];
}

- (void)enableCancelButton
{
    for (UIView *view in self.searchBar.subviews) {
        for (id subview in view.subviews) {
            if ( [subview isKindOfClass:[UIButton class]] ) {
                [subview setEnabled:YES];
                return;
            }
        }
    }
}



# pragma mark tableview delegate

- (void) reloadScreen
{
    [self.tableView reloadData];
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    self.sections = [[NSMutableArray alloc] init];
    self.searchResults = [[SHSearch defaultManager] getCachedObjects:@"items" withTerm:[self.searchBar text]];
    
    if (self.searchResults && [self.searchResults count] > 0 && [self.searchBar text] && [[self.searchBar text] length] > 0) {
        [self.sections addObject:@"results"];
    }
    if ([self.sections count] == 0 || !self.searchResults || [self.searchResults count] < 3) {
        [self.sections addObject:@"blank"];
    }
    
    return [self.sections count];
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([[self.sections objectAtIndex:section] isEqualToString:@"blank"]) {
        return 1;
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"results"]) {
        return [self.searchResults count];
    }
    return 0;
}

- (UITableViewCell*) tableView:(UITableView *)tV cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"blank"]) {
        return [self blankCellForIndexPath:indexPath];
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"results"]) {
        return [self tableView:tV itemCellForRowAtIndexPath:indexPath];
    }
    return nil;
}

- (UITableViewCell*) blankCellForIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell = (UITableViewCell*)[self.tableView dequeueReusableCellWithIdentifier:@"blankCell"];
    return cell;
}

- (UITableViewCell*) tableView:(UITableView *)tV itemCellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SHItemTableViewCell* cell = (SHItemTableViewCell*)[self.tableView dequeueReusableCellWithIdentifier:itemCellIdentifier];
    //[[self.searchResults objectAtIndex:indexPath.row] assignLocalVersionIfNeeded];
    [cell setShouldInvert:NO];
    [cell configureWithItem:[self.searchResults objectAtIndex:indexPath.row] bucketLocalKey:nil];
    [cell layoutIfNeeded];
    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"blank"]) {
        [self dismissView];
    }
}

- (void) scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self resignSearchFirstResponder];
    if ([self.sections count] == 1 && [[self.sections firstObject] isEqualToString:@"blank"]) {
        [self dismissView];
    }
}



# pragma mark actions

- (void) dismissView
{
    [self dismissViewControllerAnimated:NO completion:^(void){
        
    }];
}

@end
