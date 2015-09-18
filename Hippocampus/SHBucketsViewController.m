//
//  SHBucketsViewController.m
//  Hippocampus
//
//  Created by Will Schreiber on 8/7/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import "SHBucketsViewController.h"
#import "SHBucketTableViewCell.h"
#import "SHMessagesViewController.h"
#import "SHLoadingTableViewCell.h"
#import "SHSearch.h"

static NSString *bucketCellIdentifier = @"SHBucketTableViewCell";
static NSString *loadingCellIdentifier = @"SHLoadingTableViewCell";

@interface SHBucketsViewController ()

@end

@implementation SHBucketsViewController

@synthesize tableView;
@synthesize searchBar;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupSettings];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatedBucketLocalKeys:) name:@"updatedBucketLocalKeys" object:nil];
    
    [self beginningActions];
    
    [self performSelectorOnMainThread:@selector(reloadAndScroll) withObject:nil waitUntilDone:NO];
}

- (void) reloadAndScroll
{
    [self reloadScreen];
    if ([self.tableView numberOfRowsInSection:0] > 0) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
    }
}

- (void) setupSettings
{
    [self.tableView setRowHeight:UITableViewAutomaticDimension];
    [self.tableView setEstimatedRowHeight:91.0f];
    [self.tableView setTableFooterView:[[UIView alloc] initWithFrame:CGRectZero]];
    
    [self.tableView registerNib:[UINib nibWithNibName:bucketCellIdentifier bundle:nil] forCellReuseIdentifier:bucketCellIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:loadingCellIdentifier bundle:nil] forCellReuseIdentifier:loadingCellIdentifier];
    
    [self.tableView setContentInset:UIEdgeInsetsMake(64.0f, 0, 0, 0)];
    [self.tableView setBackgroundColor:[UIColor slightBackgroundColor]];
    
    self.searchBar.layer.borderWidth = 1.0f;
    self.searchBar.layer.borderColor = [UIColor slightBackgroundColor].CGColor;
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self reloadScreen];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void) beginningActions
{
    [NSMutableDictionary bucketKeysWithSuccess:nil failure:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}




# pragma mark notifications

- (void) updatedBucketLocalKeys:(NSNotification*)notification
{
    [self reloadScreen];
}




# pragma mark helpers

- (NSArray*) bucketKeys
{
    if ([self.searchBar text] && [[self.searchBar text] length] > 0)
        return [[SHSearch defaultManager] getCachedObjects:@"bucketKeys" withTerm:[self.searchBar text]];
    return [LXObjectManager objectWithLocalKey:@"bucketLocalKeys"];
}

- (NSArray*) recent
{
    if ([NSMutableDictionary recentBucketLocalKeys])
        return [NSMutableDictionary recentBucketLocalKeys];
    return nil;
}

- (NSMutableDictionary*) bucketAtIndexPath:(NSIndexPath*)indexPath
{
    if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"recent"]) {
        return [LXObjectManager objectWithLocalKey:[[self recent] objectAtIndex:indexPath.row]];
    } else {
        return [LXObjectManager objectWithLocalKey:[[self bucketKeys] objectAtIndex:indexPath.row]];
    }
}




# pragma mark table view delegate and data source

- (void) reloadScreen
{
    [self.tableView reloadData];
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    self.sections = [[NSMutableArray alloc] init];
    
    if (![self searchActivated] && [self recent] && [[self recent] count] > 0) {
        [self.sections addObject:@"recent"];
    }
    [self.sections addObject:@"buckets"];
    
    return [self.sections count];
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([[self.sections objectAtIndex:section] isEqualToString:@"recent"]) {
        return [[self recent] count];
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"buckets"]) {
        return [[self bucketKeys] count];
    }
    return 0;
}

- (UITableViewCell*) tableView:(UITableView *)tV cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"recent"]) {
        if ([LXObjectManager objectWithLocalKey:[[self recent] objectAtIndex:indexPath.row]]) {
            return [self tableView:tV bucketCellForRowAtIndexPath:indexPath];
        } else {
            [[LXObjectManager defaultManager] refreshObjectWithKey:[[self recent] objectAtIndex:indexPath.row]
                                                           success:^(id responseObject){
                                                               //[self.tableView reloadData];
                                                           } failure:nil
             ];
            return [self tableView:tV loadingCellForRowAtIndexPath:indexPath];
        }
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"buckets"]) {
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
    SHBucketTableViewCell* cell = (SHBucketTableViewCell*)[self.tableView dequeueReusableCellWithIdentifier:bucketCellIdentifier];
    if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"recent"]) {
        [cell configureWithBucketLocalKey:[[self recent] objectAtIndex:indexPath.row]];
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"buckets"]) {
        [cell configureWithBucketLocalKey:[[self bucketKeys] objectAtIndex:indexPath.row]];
    }
    [cell layoutIfNeeded];
    return cell;
}

- (UITableViewCell*) tableView:(UITableView *)tV loadingCellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SHLoadingTableViewCell* cell = (SHLoadingTableViewCell*)[self.tableView dequeueReusableCellWithIdentifier:loadingCellIdentifier];
    [cell configureWithResponseObject:[@{@"local_key":[[self bucketKeys] objectAtIndex:indexPath.row]} mutableCopy]];
    return cell;
}

//- (CGFloat) tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    return 80.0f;
//    if (indexPath.section >= [self.sections count]) {
//        return 44.0f;
//    }
//    if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"recent"]) {
//        if ([LXObjectManager objectWithLocalKey:[[self recent] objectAtIndex:indexPath.row]]) {
//            NSMutableDictionary* bucket = [self bucketAtIndexPath:indexPath];
//            return MIN(33.0f,([bucket cachedItemMessage] ? [[bucket cachedItemMessage] heightForTextWithWidth:([[UIScreen mainScreen] bounds].size.width-(42.0f)) font:[UIFont titleFontWithSize:14.0f]] : 0)) + ([bucket firstName] ? [[bucket firstName] heightForTextWithWidth:([[UIScreen mainScreen] bounds].size.width-(42.0f)) font:[UIFont titleFontWithSize:16.0f]] : 0) + 39.0f;
//        }
//    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"buckets"]) {
//        if ([LXObjectManager objectWithLocalKey:[[self bucketKeys] objectAtIndex:indexPath.row]]) {
//            NSMutableDictionary* bucket = [self bucketAtIndexPath:indexPath];
//            return MIN(33.0f,([bucket cachedItemMessage] ? [[bucket cachedItemMessage] heightForTextWithWidth:([[UIScreen mainScreen] bounds].size.width-(42.0f)) font:[UIFont titleFontWithSize:14.0f]] : 0)) + ([bucket firstName] ? [[bucket firstName] heightForTextWithWidth:([[UIScreen mainScreen] bounds].size.width-(42.0f)) font:[UIFont titleFontWithSize:16.0f]] : 0) + 39.0f;
//        }
//    }
//    return 44.0f;
//}

- (void) scrollViewDidScroll:(UIScrollView *)scrollView
{
    if ([self.searchBar isFirstResponder]) {
        [self.searchBar resignFirstResponder];
    }
    
    float scrollViewHeight = scrollView.frame.size.height;
    float scrollContentSizeHeight = scrollView.contentSize.height;
    float scrollOffset = scrollView.contentOffset.y;
    //NSLog(@"scrollOffset = %f", scrollOffset);
    if ((NSInteger)scrollOffset == (NSInteger)-64 && [self recent] && [[self recent] count] > 0) {
        // then we are at the top
        [self.searchBar becomeFirstResponder];
    }
    else if (scrollOffset + scrollViewHeight == scrollContentSizeHeight) {
        // then we are at the end
    }
}





# pragma mark section headers

- (NSString*) tableView:(UITableView *)tV titleForHeaderInSection:(NSInteger)section
{
    if ([[self.sections objectAtIndex:section] isEqualToString:@"buckets"]) {
        return @"All Buckets";
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"recent"]) {
        return @"Recent Buckets";
    }
    return nil;
}

- (CGFloat) tableView:(UITableView *)tV heightForHeaderInSection:(NSInteger)section
{
    if ([self tableView:tV titleForHeaderInSection:section])
        return 36.0f;
    return 0;
}

- (UIView*) tableView:(UITableView *)tV viewForHeaderInSection:(NSInteger)section
{
    if (![self tableView:tV titleForHeaderInSection:section])
        return nil;
    
    UIView* header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, [self tableView:tV heightForHeaderInSection:section])];
    [header setBackgroundColor:[UIColor SHLighterGray]];
    
    UILabel* title = [[UILabel alloc] initWithFrame:CGRectMake(16, 0, header.frame.size.width, header.frame.size.height)];
    [title setText:[[self tableView:tV titleForHeaderInSection:section] uppercaseString]];
    [title setFont:[UIFont titleFontWithSize:12.0f]];
    [title setTextColor:[UIColor lightGrayColor]];
    
    [header addSubview:title];
    
    return header;
}





# pragma mark search bar delegate

- (void) searchBar:(UISearchBar *)bar textDidChange:(NSString *)searchText
{
    [[SHSearch defaultManager] localBucketSearchWithTerm:[bar text]
                                                 success:^(id responseObject) {
                                                     [self reloadScreen];
                                                 }
                                                 failure:^(NSError* error) {
                                                 }
     ];
}

- (void) searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    if ([self.searchBar isFirstResponder]) {
        [self.searchBar resignFirstResponder];
    }
}

- (void) searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
}

- (BOOL) searchActivated
{
    return [self.searchBar text] && [[self.searchBar text] length] > 0;
}



# pragma mark actions

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    SHMessagesViewController* vc = (SHMessagesViewController*)[[UIStoryboard storyboardWithName:@"Seahorse" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"SHMessagesViewController"];
    if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"recent"]) {
        [(SHMessagesViewController*)vc setLocalKey:[[self recent] objectAtIndex:indexPath.row]];
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"buckets"]) {
        [(SHMessagesViewController*)vc setLocalKey:[[self bucketKeys] objectAtIndex:indexPath.row]];
    }
    [self.navigationController pushViewController:vc animated:YES];
}


@end
