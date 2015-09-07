//
//  SHAssignBucketsViewController.m
//  Hippocampus
//
//  Created by Will Schreiber on 9/6/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import "SHAssignBucketsViewController.h"
#import "SHAssignBucketTableViewCell.h"
#import "SHLoadingTableViewCell.h"
#import "SHSearch.h"

static NSString *assignCellIdentifier = @"SHAssignBucketTableViewCell";
static NSString *loadingCellIdentifier = @"SHLoadingTableViewCell";

@interface SHAssignBucketsViewController ()

@end

@implementation SHAssignBucketsViewController

@synthesize localKey;

@synthesize searchBar;
@synthesize tableView;

@synthesize sections;
@synthesize bucketResultKeys;
@synthesize bucketSelectedKeys;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.bucketSelectedKeys = [[NSMutableArray alloc] init];
    self.bucketResultKeys = [[NSMutableArray alloc] init];
    
    [self setupSettings];
    [self determineSelectedKeys];
    
    [self reloadScreen];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(assignBucketsCellSelected:) name:@"assignBucketsCellSelected" object:nil];
}

- (void) assignBucketsCellSelected:(NSNotification*)notification
{
    [self setTitle];
    [self performSelectorOnMainThread:@selector(setTitle) withObject:nil waitUntilDone:NO];
}

- (void) setTitle
{
    [self setTitle:[NSString stringWithFormat:@"Assign Buckets%@", ([[self bucketSelectedKeys] count] > 0 ? [NSString stringWithFormat:@" (%lu)", (unsigned long)[[self bucketSelectedKeys] count]] : @"")]];
}

- (void) setupSettings
{
    [self.tableView setRowHeight:UITableViewAutomaticDimension];
    [self.tableView setEstimatedRowHeight:44.0f];
    
    [self.tableView registerNib:[UINib nibWithNibName:assignCellIdentifier bundle:nil] forCellReuseIdentifier:assignCellIdentifier];
    
    [self.tableView setBackgroundColor:[UIColor slightBackgroundColor]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}




# pragma mark helpers

- (NSMutableDictionary*) item
{
    return [LXObjectManager objectWithLocalKey:self.localKey];
}

- (NSArray*) bucketKeys
{
    if ([self.searchBar text] && [[self.searchBar text] length] > 0)
        return [[SHSearch defaultManager] getCachedObjects:@"bucketKeys" withTerm:[self.searchBar text]];
    return [LXObjectManager objectWithLocalKey:@"bucketLocalKeys"];
}

- (NSMutableDictionary*) bucketAtIndexPath:(NSIndexPath*)indexPath
{
    return [LXObjectManager objectWithLocalKey:[[self bucketKeys] objectAtIndex:indexPath.row]];
}

- (void) determineSelectedKeys
{
    for (NSMutableDictionary* bucketStub in [[self item] bucketsArray]) {
        [self.bucketSelectedKeys addObject:[bucketStub localKey]];
    }
}

- (void) addKeyToSelected:(NSString*)key
{
    if (![self.bucketSelectedKeys containsObject:key]) {
        [self.bucketSelectedKeys addObject:key];
    }
}

- (void) removeKeyFromSelected:(NSString*)key
{
    [self.bucketSelectedKeys removeObject:key];
}




# pragma mark table view delegate

- (void) reloadScreen
{
    //deselect all rows
    for (NSIndexPath* selectedPath in [self.tableView indexPathsForSelectedRows]) {
        [self.tableView deselectRowAtIndexPath:selectedPath animated:NO];
    }
    [self.tableView reloadData];
    for (NSIndexPath* indexPath in [self indexPathsForKeys]) {
        [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    }
    [self setTitle];
}

- (NSMutableArray*) indexPathsForKeys
{
    NSMutableArray* tempPaths = [[NSMutableArray alloc] init];
    NSInteger inSection = [self.sections indexOfObject:@"other"];
    NSInteger i = 0;
    for (NSString* key in self.bucketSelectedKeys) {
        NSInteger index = [[self bucketKeys] indexOfObject:key];
        if (index != NSNotFound) {
            [tempPaths addObject:[NSIndexPath indexPathForRow:[[self bucketKeys] indexOfObject:key] inSection:inSection]];
        }
        if ([self.sections containsObject:@"selected"])
        {
            [tempPaths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
        }
        ++i;
    }
    return tempPaths;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    self.sections = [[NSMutableArray alloc] init];
    
    if ((![self.searchBar text] || [[self.searchBar text] length] == 0) && [self.bucketSelectedKeys count] > 0) {
        [self.sections addObject:@"selected"];
    }
    if ([self bucketKeys] && [[self bucketKeys] count] > 0) {
        [self.sections addObject:@"other"];
    }
    
    return [self.sections count];
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([[self.sections objectAtIndex:section] isEqualToString:@"selected"]) {
        return [self.bucketSelectedKeys count];
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"other"]) {
        return [[self bucketKeys] count];
    }
    return 0;
}

- (UITableViewCell*) tableView:(UITableView *)tV cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"selected"]) {
        if ([LXObjectManager objectWithLocalKey:[[self bucketKeys] objectAtIndex:indexPath.row]]) {
            return [self tableView:tV bucketCellForRowAtIndexPath:indexPath];
        } else {
            [[LXObjectManager defaultManager] refreshObjectWithKey:[self.bucketSelectedKeys objectAtIndex:indexPath.row]
                                                           success:^(id responseObject){
                                                               //[self.tableView reloadData];
                                                           } failure:nil
             ];
            return [self tableView:tV loadingCellForRowAtIndexPath:indexPath];
        }
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"other"]) {
        if ([LXObjectManager objectWithLocalKey:[[self bucketKeys] objectAtIndex:indexPath.row]]) {
            return [self tableView:tV bucketCellForRowAtIndexPath:indexPath];
        } else {
            [[LXObjectManager defaultManager] refreshObjectWithKey:[[self bucketKeys] objectAtIndex:indexPath.row]
                                                           success:^(id responseObject){
                                                               //[self.tableView reloadData];
                                                           } failure:nil
             ];
            return [self tableView:tV loadingCellForRowAtIndexPath:indexPath];
        }
    }
    return nil;
}

- (UITableViewCell*) tableView:(UITableView *)tV bucketCellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SHAssignBucketTableViewCell* cell = (SHAssignBucketTableViewCell*)[self.tableView dequeueReusableCellWithIdentifier:assignCellIdentifier];
    [cell configureWithBucketLocalKey:([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"selected"] ? [self.bucketSelectedKeys objectAtIndex:indexPath.row] : [[self bucketKeys] objectAtIndex:indexPath.row])];
    [cell layoutIfNeeded];
    return cell;
}

- (UITableViewCell*) tableView:(UITableView *)tV loadingCellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SHLoadingTableViewCell* cell = (SHLoadingTableViewCell*)[self.tableView dequeueReusableCellWithIdentifier:loadingCellIdentifier];
    [cell configureWithResponseObject:[@{@"local_key":[[self bucketKeys] objectAtIndex:indexPath.row]} mutableCopy]];
    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self addKeyToSelected:([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"selected"] ? [self.bucketSelectedKeys objectAtIndex:indexPath.row] : [[self bucketKeys] objectAtIndex:indexPath.row])];
    [self reloadScreen];
}

- (void) tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self removeKeyFromSelected:([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"selected"] ? [self.bucketSelectedKeys objectAtIndex:indexPath.row] : [[self bucketKeys] objectAtIndex:indexPath.row])];
    [self reloadScreen];
}

- (NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if ([[self.sections objectAtIndex:section] isEqualToString:@"selected"]) {
        return @"Assigned to Buckets";
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"other"]) {
        return @"Select Buckets";
    }
    return nil;
}

- (void) scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self.searchBar resignFirstResponder];
}



# pragma mark user actions

- (IBAction)rightButtonAction:(id)sender
{
    //save
    [[self item] updateBucketsWithLocalKeys:self.bucketSelectedKeys success:^(id responseObject){} failure:^(NSError* error){}];
    //dismiss
    [self dismissViewControllerAnimated:NO completion:^(void){}];
}



# pragma mark search bar delegate

- (void) searchBar:(UISearchBar *)bar textDidChange:(NSString *)searchText
{
    [[SHSearch defaultManager] localBucketSearchWithTerm:[bar text]
                                      success:^(id responseObject){
                                          [self reloadScreen];
                                      }
                                      failure:^(NSError* error){
                                      }
     ];
}

- (void) searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [self.searchBar resignFirstResponder];
}


@end
