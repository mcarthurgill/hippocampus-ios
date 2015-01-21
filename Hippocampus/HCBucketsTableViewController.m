//
//  HCBucketsTableViewController.m
//  Hippocampus
//
//  Created by Will Schreiber on 7/8/14.
//  Copyright (c) 2014 LXV. All rights reserved.
//

#import "HCBucketsTableViewController.h"
#import "HCBucketTableViewController.h"

#define NULL_TO_NIL(obj) ({ __typeof__ (obj) __obj = (obj); __obj == [NSNull null] ? nil : obj; })

@interface HCBucketsTableViewController ()

@end

@implementation HCBucketsTableViewController

@synthesize refreshControl;
@synthesize searchBar;
@synthesize sections;
@synthesize bucketsDictionary;

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
    
    requestMade = NO;
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
    [self.refreshControl endRefreshing];
    [self.tableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    self.sections = [[NSMutableArray alloc] init];
    
    if ([self.bucketsDictionary objectForKey:@"Recent"] && [[self.bucketsDictionary objectForKey:@"Recent"] count] > 0) {
        [self.sections addObject:@"Recent"];
    }
    if ([self.bucketsDictionary objectForKey:@"Other"] && [[self.bucketsDictionary objectForKey:@"Other"] count] > 0) {
        [self.sections addObject:@"Other"];
    }
    if ([self.bucketsDictionary objectForKey:@"Person"] && [[self.bucketsDictionary objectForKey:@"Person"] count] > 0) {
        [self.sections addObject:@"Person"];
    }
    if ([self.bucketsDictionary objectForKey:@"Event"] && [[self.bucketsDictionary objectForKey:@"Event"] count] > 0) {
        [self.sections addObject:@"Event"];
    }
    if ([self.bucketsDictionary objectForKey:@"Place"] && [[self.bucketsDictionary objectForKey:@"Place"] count] > 0) {
        [self.sections addObject:@"Place"];
    }
    if ([self.bucketsDictionary objectForKey:@"Journal"] && [[self.bucketsDictionary objectForKey:@"Journal"] count] > 0) {
        [self.sections addObject:@"Journal"];
    }
    
    // Return the number of sections.
    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([[self.sections objectAtIndex:section] isEqualToString:@"Recent"]) {
        return [[self.bucketsDictionary objectForKey:@"Recent"] count];
    }
    if ([[self.sections objectAtIndex:section] isEqualToString:@"Other"]) {
        return [[self.bucketsDictionary objectForKey:@"Other"] count];
    }
    if ([[self.sections objectAtIndex:section] isEqualToString:@"Person"]) {
        return [[self.bucketsDictionary objectForKey:@"Person"] count];
    }
    if ([[self.sections objectAtIndex:section] isEqualToString:@"Event"]) {
        return [[self.bucketsDictionary objectForKey:@"Event"] count];
    }
    if ([[self.sections objectAtIndex:section] isEqualToString:@"Place"]) {
        return [[self.bucketsDictionary objectForKey:@"Place"] count];
    }
    if ([[self.sections objectAtIndex:section] isEqualToString:@"Journal"]) {
        return [[self.bucketsDictionary objectForKey:@"Journal"] count];
    }
    // Return the number of rows in the section.
    return 0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self bucketCellForTableView:tableView cellForRowAtIndexPath:indexPath];
}

- (UITableViewCell*) bucketCellForTableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    NSDictionary* bucket = [[self.bucketsDictionary objectForKey:[self.sections objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row];
    
    NSString* identifier = @"bucketCell";
    if (NULL_TO_NIL([bucket objectForKey:@"description_text"])) {
        identifier = @"bucketAndDescriptionCell";
    }
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
    
    UILabel* note = (UILabel*)[cell.contentView viewWithTag:1];
    [note setText:[bucket objectForKey:@"first_name"]];
    
    if (NULL_TO_NIL([bucket objectForKey:@"description_text"])) {
        UILabel* description = (UILabel*)[cell.contentView viewWithTag:2];
        [description setText:[bucket objectForKey:@"description_text"]];
    }
    
    return cell;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (NULL_TO_NIL([[[self.bucketsDictionary objectForKey:[self.sections objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row] objectForKey:@"description_text"])) {
        return 60.0f;
    } else {
        return 44.0f;
    }
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    HCBucketTableViewController* btvc = [storyboard instantiateViewControllerWithIdentifier:@"bucketTableViewController"];
    [btvc setBucket:[[self.bucketsDictionary objectForKey:[self.sections objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row]];
    [self.navigationController pushViewController:btvc animated:YES];
}

- (NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [self.sections objectAtIndex:section];
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
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    UINavigationController* nc = [storyboard instantiateViewControllerWithIdentifier:@"searchNavigationController"];
    [self presentViewController:nc animated:NO completion:nil];
    return NO;
}


@end
