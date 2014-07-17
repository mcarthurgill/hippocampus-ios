//
//  HCSelectBucketTableViewController.m
//  Hippocampus
//
//  Created by Will Schreiber on 7/10/14.
//  Copyright (c) 2014 LXV. All rights reserved.
//

#import "HCSelectBucketTableViewController.h"

@interface HCSelectBucketTableViewController ()

@end

@implementation HCSelectBucketTableViewController

@synthesize addButton;
@synthesize searchBar;
@synthesize item;
@synthesize sections;
@synthesize bucketsArray;
@synthesize searchResultsArray;

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
    
    //NSLog(@"SECTIONS: \n %@", [HCBucket alphabetizedArray]);
    self.sections = [[NSMutableArray alloc] initWithArray:[NSArray alphabetUppercase]];
    [self.sections insertObject:@"Recent" atIndex:0];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
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
    if (self.searchBar.text && self.searchBar.text.length > 0) {
        self.searchResultsArray = [[NSMutableArray alloc] initWithArray:[HCBucket search:self.searchBar.text]];
    } else {
        NSArray* recents = [HCBucket mostRecent:5];
        self.bucketsArray = [[NSMutableArray alloc] initWithArray:[HCBucket alphabetizedArray]];
        if (recents && recents.count > 0) {
            [self.bucketsArray insertObject:recents atIndex:0];
        } else {
            [self.bucketsArray insertObject:[[NSArray alloc] init] atIndex:0];
        }
    }
    [self.tableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (self.searchBar.text && self.searchBar.text.length > 0) {
        return 1;
    }
    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.searchBar.text && self.searchBar.text.length > 0) {
        return self.searchResultsArray.count;
    }
    return [[self.bucketsArray objectAtIndex:section] count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    HCBucket* bucket = [self bucket:indexPath];
    
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
    if ([[self bucket:indexPath] descriptionText]) {
        return 60.0f;
    } else {
        return 44.0f;
    }
}

- (NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if ((!self.searchBar.text || self.searchBar.text.length == 0) && [[self.bucketsArray objectAtIndex:section] count] > 0) {
        return [self.sections objectAtIndex:section];
    }
    return nil;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.item assignAndSaveToBucket:[self bucket:indexPath]];
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (HCBucket*) bucket:(NSIndexPath*)indexPath
{
    
    if (self.searchBar.text && self.searchBar.text.length > 0) {
        return [self.searchResultsArray objectAtIndex:indexPath.row];
    } else {
        return [[self.bucketsArray objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    }
}


# pragma mark actions

- (IBAction)addAction:(id)sender
{
}


# pragma mark scroll view delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self.searchBar resignFirstResponder];
}


# pragma mark search bar delegate

- (void) searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [self reloadScreen];
}

- (void) searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [self reloadScreen];
}


@end
