//
//  HCBucketsTableViewController.m
//  Hippocampus
//
//  Created by Will Schreiber on 7/8/14.
//  Copyright (c) 2014 LXV. All rights reserved.
//

#import "HCBucketsTableViewController.h"
#import "HCBucketTableViewController.h"

@interface HCBucketsTableViewController ()

@end

@implementation HCBucketsTableViewController

@synthesize refreshControl;
@synthesize searchBar;
@synthesize sections;
@synthesize allBuckets;

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
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self reloadScreen];
    [self refreshChange];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (void) reloadScreen
{
    self.allBuckets = [[NSMutableArray alloc] initWithArray:[HCBucket allBuckets]];
    [self.refreshControl endRefreshing];
    [self.tableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    self.sections = [[NSMutableArray alloc] init];
    
    [self.sections addObject:@"all"];
    
    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if ([[self.sections objectAtIndex:section] isEqualToString:@"all"]) {
        return self.allBuckets.count;
    }
    return 0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"all"]) {
        return [self bucketCellForTableView:tableView cellForRowAtIndexPath:indexPath];
    }
    return nil;
}

- (UITableViewCell*) bucketCellForTableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"itemCell" forIndexPath:indexPath];
    
    HCBucket* bucket = [self.allBuckets objectAtIndex:indexPath.row];
    
    UILabel* note = (UILabel*)[cell.contentView viewWithTag:1];
    [note setText:bucket.titleString];
    
    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    HCBucketTableViewController* btvc = [storyboard instantiateViewControllerWithIdentifier:@"bucketTableViewController"];
    if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"all"]) {
        [btvc setBucket:[self.allBuckets objectAtIndex:indexPath.row]];
    }
    [self.navigationController pushViewController:btvc animated:YES];
}

# pragma mark refresh controller

- (void) refreshChange
{
    [[[LXSession thisSession] user]
     getNewBucketsSuccess:^(id responseObject) {
         [self.refreshControl endRefreshing];
         [self reloadScreen];
     } failure:^(NSError *error) {
         [self.refreshControl endRefreshing];
         [self reloadScreen];
     }
     ];
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
}


# pragma mark search bar delegate

- (BOOL) searchBarShouldBeginEditing:(UISearchBar *)sB
{
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    UINavigationController* nc = [storyboard instantiateViewControllerWithIdentifier:@"searchNavigationController"];
    [self presentViewController:nc animated:NO completion:nil];
    return NO;
}


@end
