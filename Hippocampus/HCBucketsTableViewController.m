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
@synthesize bucketsArray;

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
    
    self.sections = [[NSMutableArray alloc] initWithArray:[NSArray alphabetUppercase]];
    [self.sections insertObject:@"Recent" atIndex:0];
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
    NSArray* recents = [HCBucket mostRecent:5];
    self.bucketsArray = [[NSMutableArray alloc] initWithArray:[HCBucket alphabetizedArray]];
    if (recents && recents.count > 0) {
        [self.bucketsArray insertObject:recents atIndex:0];
    } else {
        [self.bucketsArray insertObject:[[NSArray alloc] init] atIndex:0];
    }
    [self.refreshControl endRefreshing];
    [self.tableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [[self.bucketsArray objectAtIndex:section] count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self bucketCellForTableView:tableView cellForRowAtIndexPath:indexPath];
}

- (UITableViewCell*) bucketCellForTableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    HCBucket* bucket = [[self.bucketsArray objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    
    NSString* identifier = @"bucketCell";
    if ([bucket descriptionText]) {
        identifier = @"bucketAndDescriptionCell";
    }
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
    
    UILabel* note = (UILabel*)[cell.contentView viewWithTag:1];
    [note setAttributedText:[bucket titleAttributedString]];
    
    if ([bucket descriptionText]) {
        UILabel* description = (UILabel*)[cell.contentView viewWithTag:2];
        [description setText:[bucket descriptionText]];
    }
    
    return cell;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([(HCBucket*)[[self.bucketsArray objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] descriptionText]) {
        return 60.0f;
    } else {
        return 44.0f;
    }
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    HCBucketTableViewController* btvc = [storyboard instantiateViewControllerWithIdentifier:@"bucketTableViewController"];
    [btvc setBucket:[[self.bucketsArray objectAtIndex:indexPath.section] objectAtIndex:indexPath.row]];
    [self.navigationController pushViewController:btvc animated:YES];
}

- (NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if ([[self.bucketsArray objectAtIndex:section] count] > 0) {
        return [self.sections objectAtIndex:section];
    }
    return nil;
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
