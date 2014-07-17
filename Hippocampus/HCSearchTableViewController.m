//
//  HCSearchTableViewController.m
//  Hippocampus
//
//  Created by Will Schreiber on 7/8/14.
//  Copyright (c) 2014 LXV. All rights reserved.
//

#import "HCSearchTableViewController.h"
#import "HCBucketTableViewController.h"
#import "HCItemTableViewController.h"

@interface HCSearchTableViewController ()

@end

@implementation HCSearchTableViewController

@synthesize searchBar;
@synthesize doneButton;

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
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.searchBar becomeFirstResponder];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (void) reloadScreen
{
    self.bucketsArray = [[NSMutableArray alloc] initWithArray:[HCBucket search:self.searchBar.text]];
    self.itemsArray = [[NSMutableArray alloc] initWithArray:[HCItem search:self.searchBar.text]];
    [self.tableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    self.sections = [[NSMutableArray alloc] init];
    
    [self.sections addObject:@"items"];
    [self.sections addObject:@"buckets"];
    
    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([[self.sections objectAtIndex:section] isEqualToString:@"items"]) {
        return self.itemsArray.count;
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"buckets"]) {
        return self.bucketsArray.count;
    }
    return 0;
}



- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"items"]) {
        return [self itemCellForTableView:tableView withItem:[self.itemsArray objectAtIndex:indexPath.row] cellForRowAtIndexPath:indexPath];
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"buckets"]) {
        return [self bucketCellForTableView:tableView cellForRowAtIndexPath:indexPath];
    }
    return nil;
}


- (UITableViewCell*) itemCellForTableView:(UITableView*)tableView withItem:(HCItem*)item cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"itemCell" forIndexPath:indexPath];
    
    UILabel* note = (UILabel*)[cell.contentView viewWithTag:1];
    float leftMargin = note.frame.origin.x;
    float topMargin = note.frame.origin.y;
    float width = note.frame.size.width;
    [note removeFromSuperview];
    
    note = [[UILabel alloc] initWithFrame:CGRectMake(leftMargin, topMargin, width, [self heightForText:item.message width:width font:note.font])];
    [note setText:item.message];
    [note setTag:1];
    [note setNumberOfLines:0];
    [note setLineBreakMode:NSLineBreakByWordWrapping];
    [cell.contentView addSubview:note];
    
    UILabel* timestamp = (UILabel*)[cell.contentView viewWithTag:3];
    [timestamp setText:[NSString stringWithFormat:@"%@%@", [NSDate timeAgoInWordsFromDatetime:item.createdAt], ([item bucket] ? [NSString stringWithFormat:@" - %@", [item bucket].titleString] : @"")]];
    
    //NSLog(@"INFO ON ITEM:\n%@\n%@\n%@", item.message, item.itemID, item.bucketID);
    return cell;
}

- (UITableViewCell*) bucketCellForTableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    HCBucket* bucket = [self.bucketsArray objectAtIndex:indexPath.row];
    
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

- (CGFloat) heightForText:(NSString*)text width:(CGFloat)width font:(UIFont*)font
{
    NSDictionary *attributes = @{NSFontAttributeName: font};
    // NSString class method: boundingRectWithSize:options:attributes:context is
    // available only on ios7.0 sdk.
    CGRect rect = [text boundingRectWithSize:CGSizeMake(width, 100000)
                                     options:NSStringDrawingUsesLineFragmentOrigin
                                  attributes:attributes
                                     context:nil];
    return rect.size.height;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"items"]) {
        HCItem* item = [self.itemsArray objectAtIndex:indexPath.row];
        return [self heightForText:item.message width:280.0f font:[UIFont systemFontOfSize:17.0]] + 22.0f + 12.0f;
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"buckets"] && [(HCBucket*)[self.bucketsArray objectAtIndex:indexPath.row] descriptionText]) {
        return 60.0f;
    }
    return 44.0;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"items"]) {
        UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
        HCItemTableViewController* itvc = (HCItemTableViewController*)[storyboard instantiateViewControllerWithIdentifier:@"itemTableViewController"];
        [itvc setItem:[self.itemsArray objectAtIndex:indexPath.row]];
        [self.navigationController pushViewController:itvc animated:YES];
    }
    else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"buckets"]) {
        UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
        HCBucketTableViewController* itvc = (HCBucketTableViewController*)[storyboard instantiateViewControllerWithIdentifier:@"bucketTableViewController"];
        [itvc setBucket:[self.bucketsArray objectAtIndex:indexPath.row]];
        [self.navigationController pushViewController:itvc animated:YES];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if ([[self.sections objectAtIndex:section] isEqualToString:@"items"] && self.itemsArray.count > 0) {
        return @"Notes";
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"buckets"] && self.bucketsArray.count > 0) {
        return @"Stacks";
    }
    return nil;
}


# pragma mark actions

- (IBAction)doneAction:(id)sender
{
    [self dismissViewControllerAnimated:NO completion:nil];
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
