//
//  SHSearchViewController.m
//  Hippocampus
//
//  Created by Will Schreiber on 8/27/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import "SHSearchViewController.h"
#import "SHItemTableViewCell.h"
#import "SHBucketTableViewCell.h"
#import "SHSearch.h"
#import "SHMessagesViewController.h"
#import "SHItemViewController.h"
#import "SHTagDetailViewController.h"

static NSString *itemCellIdentifier = @"SHItemTableViewCell";
static NSString *bucketCellIdentifier = @"SHBucketTableViewCell";
static NSString *itemViewControllerIdentifier = @"SHItemViewController";

@interface SHSearchViewController ()

@end

@implementation SHSearchViewController

@synthesize searchBar;
@synthesize tableView;
@synthesize backgroundView;
@synthesize sections;
@synthesize searchResults;
@synthesize bucketResultKeys;
@synthesize bucketResults;

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupSettings];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pushBucketViewController:) name:@"searchPushBucketViewController" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pushTagViewController:) name:@"searchPushTagViewController" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(presentViewController:) name:@"presentViewController" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshBlankThoughtsVC:) name:@"refreshBlankThoughtsVC" object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:NO];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.searchBar becomeFirstResponder];
    
    [[LXSession thisSession] setSearchActivated:YES];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}

- (void) setupSettings
{
    [self.tableView registerNib:[UINib nibWithNibName:itemCellIdentifier bundle:nil] forCellReuseIdentifier:itemCellIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:bucketCellIdentifier bundle:nil] forCellReuseIdentifier:bucketCellIdentifier];
    
    [self.tableView setRowHeight:UITableViewAutomaticDimension];
    [self.tableView setEstimatedRowHeight:80.0f];
    [self.tableView setTableFooterView:[[UIView alloc] initWithFrame:CGRectZero]];
}



# pragma mark search delegate

- (void) searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [self dismissView];
}

- (void) searchBar:(UISearchBar *)bar textDidChange:(NSString *)searchText
{
    [[SHSearch defaultManager] searchWithTerm:[bar text]
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
    [NSObject cancelPreviousPerformRequestsWithTarget:self.tableView];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView performSelector:@selector(reloadData) withObject:nil afterDelay:0.1];
        
    });
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    self.sections = [[NSMutableArray alloc] init];
    self.searchResults = [[SHSearch defaultManager] getCachedObjects:@"items" withTerm:[self.searchBar text]];
    //self.bucketResultKeys = [[SHSearch defaultManager] getCachedObjects:@"bucketKeys" withTerm:[self.searchBar text]];
    self.bucketResults = [[SHSearch defaultManager] getCachedObjects:@"buckets" withTerm:[self.searchBar text]];
    
    if (self.bucketResults && [self.bucketResults count] > 0 && [self.searchBar text] && [[self.searchBar text] length] > 0) {
        [self.sections addObject:@"buckets"];
    }
    if (self.searchResults && [self.searchBar text] && [[self.searchBar text] length] > 0) {
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
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"buckets"]) {
        return [self.bucketResults count];
    }
    return 0;
}

- (UITableViewCell*) tableView:(UITableView *)tV cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"blank"]) {
        return [self blankCellForIndexPath:indexPath];
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"results"]) {
        return [self tableView:tV itemCellForRowAtIndexPath:indexPath];
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"buckets"]) {
        return [self tableView:tV bucketCellForRowAtIndexPath:indexPath];
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
    [cell setShouldInvert:NO];
    [cell configureWithItemLocalKey:[[self.searchResults objectAtIndex:indexPath.row] localKey] bucketLocalKey:nil];
    [cell layoutIfNeeded];
    return cell;
}

- (UITableViewCell*) tableView:(UITableView *)tV bucketCellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SHBucketTableViewCell* cell = (SHBucketTableViewCell*)[self.tableView dequeueReusableCellWithIdentifier:bucketCellIdentifier];
    [cell configureWithBucketLocalKey:[[self.bucketResults objectAtIndex:indexPath.row] localKey] onSearch:YES];
    [cell layoutIfNeeded];
    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"blank"]) {
        [self dismissView];
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"buckets"]) {
        SHMessagesViewController* vc = (SHMessagesViewController*)[[UIStoryboard storyboardWithName:@"Seahorse" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"SHMessagesViewController"];
        [vc setLocalKey:[[self.bucketResults objectAtIndex:indexPath.row] localKey]];
        [self.navigationController pushViewController:vc animated:YES];
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"results"]) {
        UIViewController* vc = [[UIStoryboard storyboardWithName:@"Seahorse" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:itemViewControllerIdentifier];
        [(SHItemViewController*)vc setLocalKey:[[self.searchResults objectAtIndex:indexPath.row] localKey]];
        [self.navigationController pushViewController:vc animated:YES];
    }
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void) scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self resignSearchFirstResponder];
    if (([self.sections count] == 1 && [[self.sections firstObject] isEqualToString:@"blank"]) || ([self.sections count] == 2 && [[self.sections firstObject] isEqualToString:@"results"] && [self.searchResults count] == 0)) {
        [self dismissView];
    }
}




# pragma mark section headers

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if ([[self.sections objectAtIndex:section] isEqualToString:@"results"] || [[self.sections objectAtIndex:section] isEqualToString:@"buckets"])
        return 36.0f;
    return 0;
}

- (NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if ([[self.sections objectAtIndex:section] isEqualToString:@"results"])
        return [NSString stringWithFormat:@"\"%@\" in Notes  (%lu)", [[SHSearch defaultManager] getCachedResultsTermWithType:@"items" withTerm:[self.searchBar text]], (unsigned long)[self.searchResults count]];
    if ([[self.sections objectAtIndex:section] isEqualToString:@"buckets"])
        return [NSString stringWithFormat:@"\"%@\" in People  (%lu)", [[SHSearch defaultManager] getCachedResultsTermWithType:@"buckets" withTerm:[self.searchBar text]], (unsigned long)[self.searchResults count]];
        //return [NSString stringWithFormat:@"Buckets (%lu)", (unsigned long)[self.bucketResults count]];
    return nil;
}

- (UIView*) tableView:(UITableView *)tV viewForHeaderInSection:(NSInteger)section
{
    if (![[self.sections objectAtIndex:section] isEqualToString:@"results"] && ![[self.sections objectAtIndex:section] isEqualToString:@"buckets"])
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



# pragma mark actions

- (void) dismissView
{
    [self dismissViewControllerAnimated:NO completion:^(void){
        [[LXSession thisSession] setSearchActivated:NO];
    }];
}

- (void) pushBucketViewController:(NSNotification*)notification
{
    SHMessagesViewController* vc = (SHMessagesViewController*)[[UIStoryboard storyboardWithName:@"Seahorse" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"SHMessagesViewController"];
    [vc setLocalKey:[[[notification userInfo] objectForKey:@"bucket"] localKey]];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void) pushTagViewController:(NSNotification*)notification
{
    SHTagDetailViewController* vc = (SHTagDetailViewController*)[[UIStoryboard storyboardWithName:@"Seahorse" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"SHTagDetailViewController"];
    [vc setLocalKey:[[[notification userInfo] objectForKey:@"tag"] localKey]];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void) presentViewController:(NSNotification*)notification
{
    if (![self presentedViewController]) {
        [self.navigationController presentViewController:[[notification userInfo] objectForKey:@"viewController"] animated:YES completion:^(void){}];
    }
}

- (void) refreshBlankThoughtsVC:(NSNotification*)notification
{
    [self reloadScreen];
}

@end
