//
//  HCNotesTableViewController.m
//  Hippocampus
//
//  Created by Will Schreiber on 7/8/14.
//  Copyright (c) 2014 LXV. All rights reserved.
//

#import "HCNotesTableViewController.h"
#import "HCItemTableViewController.h"

@interface HCNotesTableViewController ()

@end

@implementation HCNotesTableViewController

@synthesize refreshControl;
@synthesize searchBar;
@synthesize sections;
@synthesize allItems;

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

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self refreshChange];
    [self reloadScreen];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (void) reloadScreen
{
    self.allItems = [[NSMutableArray alloc] initWithArray:[HCItem items:@"assigned" ascending:NO index:0 limit:2000]];
    self.outstandingItems = [[NSMutableArray alloc] initWithArray:[HCItem items:@"outstanding" ascending:YES index:0 limit:0]];
    [self.refreshControl endRefreshing];
    [self.tableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    self.sections = [[NSMutableArray alloc] init];
    
    if (self.outstandingItems.count > 0) {
        [self.sections addObject:@"outstanding"];
    }
    
    [self.sections addObject:@"all"];
    
    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if ([[self.sections objectAtIndex:section] isEqualToString:@"all"]) {
        return self.allItems.count;
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"outstanding"]) {
        return self.outstandingItems.count;
    }
    return 0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"all"]) {
        return [self itemCellForTableView:tableView withItem:[self.allItems objectAtIndex:indexPath.row] cellForRowAtIndexPath:indexPath];
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"outstanding"]) {
        return [self itemCellForTableView:tableView withItem:[self.outstandingItems objectAtIndex:indexPath.row] cellForRowAtIndexPath:indexPath];
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
    if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"all"]) {
        HCItem* item = [self.allItems objectAtIndex:indexPath.row];
        return [self heightForText:item.message width:280.0f font:[UIFont systemFontOfSize:17.0]] + 22.0f + 12.0f + 14.0f;
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"outstanding"]) {
        HCItem* item = [self.outstandingItems objectAtIndex:indexPath.row];
        return [self heightForText:item.message width:280.0f font:[UIFont systemFontOfSize:17.0]] + 22.0f + 12.0f + 14.0f;
    }
    return 44.0;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"all"]) {
        UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
        HCItemTableViewController* itvc = (HCItemTableViewController*)[storyboard instantiateViewControllerWithIdentifier:@"itemTableViewController"];
        [itvc setItem:[self.allItems objectAtIndex:indexPath.row]];
        [self.navigationController pushViewController:itvc animated:YES];
    }
    else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"outstanding"]) {
        UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
        HCItemTableViewController* itvc = (HCItemTableViewController*)[storyboard instantiateViewControllerWithIdentifier:@"selectBucketTableViewController"];
        [itvc setItem:[self.outstandingItems objectAtIndex:indexPath.row]];
        [self.navigationController pushViewController:itvc animated:YES];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if ([[self.sections objectAtIndex:section] isEqualToString:@"all"]) {
        return @"All Notes";
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"outstanding"]) {
        return @"Pending Action";
    }
    return nil;
}




# pragma mark refresh controller

- (void) refreshChange
{
    [[[LXSession thisSession] user]
     getNewItemsSuccess:^(id responseObject) {
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
