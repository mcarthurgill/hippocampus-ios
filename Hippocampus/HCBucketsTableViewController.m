//
//  HCBucketsTableViewController.m
//  Hippocampus
//
//  Created by Will Schreiber on 7/8/14.
//  Copyright (c) 2014 LXV. All rights reserved.
//

#import "HCBucketsTableViewController.h"
#import "HCBucketTableViewController.h"
#import "HCItemTableViewController.h"
#import "HCNewBucketIITableViewController.h"

#define NULL_TO_NIL(obj) ({ __typeof__ (obj) __obj = (obj); __obj == [NSNull null] ? nil : obj; })

@interface HCBucketsTableViewController ()

@end

@implementation HCBucketsTableViewController

@synthesize mode;
@synthesize delegate;

@synthesize refreshControl;
@synthesize searchBar;
@synthesize sections;
@synthesize bucketsDictionary;
@synthesize bucketsSearchDictionary;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.bucketsSearchDictionary = [[NSMutableDictionary alloc] init];
    
    requestMade = NO;
    
    [self refreshChange];
}

- (void) viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    if ([self assignMode]) {
        //[self.navigationController.navigationBar.topItem setTitle:@"Add to Stack"];
        [self setTitle:@"Add to Stack"];
        [self.navigationItem setRightBarButtonItem:nil];
    }
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self reloadScreen];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (void) reloadScreen
{
    [self.refreshControl endRefreshing];
    [self.tableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    self.sections = [[NSMutableArray alloc] init];
    
    if ([self assignMode]) {
        [self.sections addObject:@"new"];
    }
    
    if (requestMade && !self.refreshControl.isRefreshing) {
        [self.sections addObject:@"requesting"];
    }
    
    if ([[self currentDictionary] objectForKey:@"Recent"] && [[[self currentDictionary] objectForKey:@"Recent"] count] > 0) {
        [self.sections addObject:@"Recent"];
    }
    if ([[self currentDictionary] objectForKey:@"Other"] && [[[self currentDictionary] objectForKey:@"Other"] count] > 0) {
        [self.sections addObject:@"Other"];
    }
    if ([[self currentDictionary] objectForKey:@"Person"] && [[[self currentDictionary] objectForKey:@"Person"] count] > 0) {
        [self.sections addObject:@"Person"];
    }
    if ([[self currentDictionary] objectForKey:@"Event"] && [[[self currentDictionary] objectForKey:@"Event"] count] > 0) {
        [self.sections addObject:@"Event"];
    }
    if ([[self currentDictionary] objectForKey:@"Place"] && [[[self currentDictionary] objectForKey:@"Place"] count] > 0) {
        [self.sections addObject:@"Place"];
    }
    if ([[self currentDictionary] objectForKey:@"Journal"] && [[[self currentDictionary] objectForKey:@"Journal"] count] > 0) {
        [self.sections addObject:@"Journal"];
    }
    
    // Return the number of sections.
    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([[self.sections objectAtIndex:section] isEqualToString:@"new"]) {
        return 1;
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"Recent"]) {
        return [[[self currentDictionary] objectForKey:@"Recent"] count];
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"Other"]) {
        return [[[self currentDictionary] objectForKey:@"Other"] count];
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"Person"]) {
        return [[[self currentDictionary] objectForKey:@"Person"] count];
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"Event"]) {
        return [[[self currentDictionary] objectForKey:@"Event"] count];
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"Place"]) {
        return [[[self currentDictionary] objectForKey:@"Place"] count];
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"Journal"]) {
        return [[[self currentDictionary] objectForKey:@"Journal"] count];
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"requesting"]) {
        return 1;
    }
    // Return the number of rows in the section.
    return 0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"requesting"]) {
        return [self indicatorCellForTableView:tableView cellForRowAtIndexPath:indexPath];
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"new"]) {
        return [self newCellForTableView:tableView cellForRowAtIndexPath:indexPath];
    }
    return [self bucketCellForTableView:tableView cellForRowAtIndexPath:indexPath];
}

- (UITableViewCell*) indicatorCellForTableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"indicatorCell" forIndexPath:indexPath];
    UIActivityIndicatorView* iav = (UIActivityIndicatorView*) [cell.contentView viewWithTag:10];
    [iav startAnimating];
    return cell;
}

- (UITableViewCell*) newCellForTableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"newCell" forIndexPath:indexPath];
    UILabel* label = (UILabel*) [cell.contentView viewWithTag:1];
    [label setText:@"+ New Stack"];
    return cell;
}

- (UITableViewCell*) bucketCellForTableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    NSDictionary* bucket = [[[self currentDictionary] objectForKey:[self.sections objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row];
    
    NSString* identifier = @"bucketCell";
    //if (NULL_TO_NIL([bucket objectForKey:@"description_text"]) || [[self.sections objectAtIndex:indexPath.section] isEqualToString:@"Event"]) {
        identifier = @"bucketAndDescriptionCell";
    //}
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
    
    UILabel* note = (UILabel*)[cell.contentView viewWithTag:1];
    [note setText:[bucket objectForKey:@"first_name"]];
    
    UILabel* description = (UILabel*)[cell.contentView viewWithTag:2];
    if (NULL_TO_NIL([bucket objectForKey:@"description_text"])) {
        [description setText:[bucket objectForKey:@"description_text"]];
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"Event"]) {
        [description setText:[NSString stringWithFormat:@"Created %@%@", [NSDate timeAgoActualFromDatetime:[bucket objectForKey:@"created_at"]], ([self assignMode] ? @" - Tap to Add Note" : @"")]];
    } else {
        [description setText:[NSString stringWithFormat:@"%@ Notes%@", [bucket objectForKey:@"items_count"], ([self assignMode] ? @" - Tap to Add Note" : [NSString stringWithFormat:@" - updated %@", [NSDate timeAgoActualFromDatetime:[bucket objectForKey:@"updated_at"]]])]];
    }
    
    return cell;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"requesting"] || [[self.sections objectAtIndex:indexPath.section] isEqualToString:@"new"]) {
        return 44.0f;
    }
    return 60.0f;
    if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"Event"] || NULL_TO_NIL([[[[self currentDictionary] objectForKey:[self.sections objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row] objectForKey:@"description_text"])) {
        return 60.0f;
    } else {
        return 44.0f;
    }
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self assignMode]) {
        if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"new"]) {
            NSLog(@"NEW STACK!");
            UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
            HCNewBucketIITableViewController* btvc = [storyboard instantiateViewControllerWithIdentifier:@"newBucketIITableViewController"];
            [btvc setDelegate:self.delegate];
            [self.navigationController pushViewController:btvc animated:YES];
        } else {
            [self.delegate addToStack:[[[self currentDictionary] objectForKey:[self.sections objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row]];
            [self.navigationController popViewControllerAnimated:YES];
        }
    } else {
        UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
        HCBucketTableViewController* btvc = [storyboard instantiateViewControllerWithIdentifier:@"bucketTableViewController"];
        [btvc setBucket:[[[self currentDictionary] objectForKey:[self.sections objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row]];
        [self.navigationController pushViewController:btvc animated:YES];
    }
}

- (NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if ([[self.sections objectAtIndex:section] isEqualToString:@"requesting"] || [[self.sections objectAtIndex:section] isEqualToString:@"new"]) {
        return nil;
    }
    return [self.sections objectAtIndex:section];
}


# pragma mark helpers

- (BOOL) assignMode
{
    return self.mode && [self.mode isEqualToString:@"assign"];
}


# pragma mark dictionary helpers

- (NSMutableDictionary*) currentDictionary
{
    NSString* key = self.searchBar.text ? [self.searchBar.text lowercaseString] : @"";
    if (!key || [key length] == 0) {
        return self.bucketsDictionary;
    }
    if (![self.bucketsSearchDictionary objectForKey:key]) {
        [self.bucketsSearchDictionary setObject:[self searchedDictionaryWithTerm:key] forKey:key];
    }
    return [self.bucketsSearchDictionary objectForKey:key];
}

- (NSMutableDictionary*) searchedDictionaryWithTerm:(NSString*)term
{
    term = [term lowercaseString];
    
    NSMutableDictionary* newDictionary = [[NSMutableDictionary alloc] init];
    NSMutableDictionary* oldDictionary = [term length] > 1 && [self.bucketsSearchDictionary objectForKey:[term substringToIndex:([term length]-1)]] ? [self.bucketsSearchDictionary objectForKey:[term substringToIndex:([term length]-1)]] : self.bucketsDictionary;
    
    for (NSString* key in [oldDictionary allKeys]) {
        NSArray* buckets = [oldDictionary objectForKey:key];
        NSMutableArray* newBuckets = [[NSMutableArray alloc] init];
        for (NSDictionary* bucket in buckets) {
            if ([[[bucket objectForKey:@"first_name"] lowercaseString] containsString:term]) {
                [newBuckets addObject:bucket];
            }
        }
        [newDictionary setObject:newBuckets forKey:key];
    }
    
    return newDictionary;
}


# pragma mark refresh controller

- (void) refreshChange
{
    if (requestMade)
        return;
    requestMade = YES;
    [[LXServer shared] requestPath:[NSString stringWithFormat:@"/users/%@/buckets.json", [[HCUser loggedInUser] userID]] withMethod:@"GET" withParamaters: nil
                           success:^(id responseObject) {
                               NSLog(@"response: %@", responseObject);
                               self.bucketsDictionary = [NSMutableDictionary dictionaryWithDictionary:responseObject];
                               requestMade = NO;
                               [self reloadScreen];
                           }
                           failure:^(NSError *error) {
                               NSLog(@"error: %@", [error localizedDescription]);
                               requestMade = NO;
                               [self reloadScreen];
                           }
     ];
    [self reloadScreen];
}

- (IBAction)refreshControllerChanged:(id)sender
{
    if (self.refreshControl.isRefreshing) {
        //Make server call here.
        [self refreshChange];
    }
}


# pragma mark toolbar actions

- (IBAction)addAction:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"openNewItemScreen" object:nil];
}


# pragma mark search bar delegate

- (BOOL) searchBarShouldBeginEditing:(UISearchBar *)sB
{
    return YES;
}

- (void) searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [self reloadScreen];
}

- (void) searchBarCancelButtonClicked:(UISearchBar *)sB
{
    [sB resignFirstResponder];
}

- (void) searchBarSearchButtonClicked:(UISearchBar *)sB
{
    NSLog(@"Go!");
    [sB resignFirstResponder];
    [self reloadScreen];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self.searchBar resignFirstResponder];
}


@end