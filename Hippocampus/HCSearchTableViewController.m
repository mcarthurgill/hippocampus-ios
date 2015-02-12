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

#define NULL_TO_NIL(obj) ({ __typeof__ (obj) __obj = (obj); __obj == [NSNull null] ? nil : obj; })

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
    
    self.bucketsArray = [[NSMutableArray alloc] init];
    self.itemsArray = [[NSMutableArray alloc] init];
    
    requestMade = NO;
    
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (!self.searchBar.text || [self.searchBar.text length] == 0) {
        [self.searchBar becomeFirstResponder];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (void) reloadScreen
{
    [self.tableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    self.sections = [[NSMutableArray alloc] init];
    
    if (requestMade) {
        [self.sections addObject:@"requesting"];
    }
    
    [self.sections addObject:@"buckets"];
    [self.sections addObject:@"items"];
    
    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([[self.sections objectAtIndex:section] isEqualToString:@"items"]) {
        return self.itemsArray.count;
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"buckets"]) {
        return self.bucketsArray.count;
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"requesting"]) {
        return 1;
    }
    return 0;
}



- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"items"]) {
        return [self itemCellForTableView:tableView withItem:[self.itemsArray objectAtIndex:indexPath.row] cellForRowAtIndexPath:indexPath];
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"buckets"]) {
        return [self bucketCellForTableView:tableView cellForRowAtIndexPath:indexPath];
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"requesting"]) {
        return [self indicatorCellForTableView:tableView cellForRowAtIndexPath:indexPath];
    }
    return nil;
}

- (UITableViewCell*) indicatorCellForTableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"indicatorCell" forIndexPath:indexPath];
    UIActivityIndicatorView* iav = (UIActivityIndicatorView*) [cell.contentView viewWithTag:10];
    [iav startAnimating];
    return cell;
}

- (UITableViewCell*) itemCellForTableView:(UITableView*)tableView withItem:(NSDictionary*)item cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"itemCell" forIndexPath:indexPath];
    
    UILabel* note = (UILabel*)[cell.contentView viewWithTag:1];
    float leftMargin = note.frame.origin.x;
    float topMargin = note.frame.origin.y;
    float width = note.frame.size.width;
    [note removeFromSuperview];
    
    note = [[UILabel alloc] initWithFrame:CGRectMake(leftMargin, topMargin, width, [self heightForText:[[item objectForKey:@"message"] truncated:320] width:width font:note.font])];
    [note setText:[[item objectForKey:@"message"] truncated:320]];
    [note setTag:1];
    [note setNumberOfLines:0];
    [note setLineBreakMode:NSLineBreakByWordWrapping];
    [cell.contentView addSubview:note];
    
    UILabel* timestamp = (UILabel*)[cell.contentView viewWithTag:3];
    [timestamp setText:[NSString stringWithFormat:@"%@%@", (NULL_TO_NIL([item objectForKey:@"buckets_string"]) ? [NSString stringWithFormat:@"%@ - ", [item objectForKey:@"buckets_string"]] : @""), [NSDate timeAgoInWordsFromDatetime:[item objectForKey:@"created_at_server"]]]];
    
    //NSLog(@"INFO ON ITEM:\n%@\n%@\n%@", item.message, item.itemID, item.bucketID);
    return cell;
}

- (UITableViewCell*) bucketCellForTableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    NSDictionary* bucket = [self.bucketsArray objectAtIndex:indexPath.row];
    
    NSString* identifier = @"bucketCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
    
    UILabel* note = (UILabel*)[cell.contentView viewWithTag:1];
    [note setText:[bucket objectForKey:@"first_name"]];
    
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
        NSDictionary* item = [self.itemsArray objectAtIndex:indexPath.row];
        return [self heightForText:[[item objectForKey:@"message"] truncated:320] width:280.0f font:[UIFont fontWithName:@"HelveticaNeue-Light" size:17.0f]] + 22.0f + 12.0f;
    }
    return 44.0;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"items"]) {
        UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
        HCItemTableViewController* itvc = (HCItemTableViewController*)[storyboard instantiateViewControllerWithIdentifier:@"itemTableViewController"];
        NSMutableDictionary* dict = [[NSMutableDictionary alloc] initWithDictionary:[self.itemsArray objectAtIndex:indexPath.row]];
        [dict setObject:[dict objectForKey:@"item_id"] forKey:@"id"];
        [itvc setItem:dict];
        [self.navigationController pushViewController:itvc animated:YES];
    }
    else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"buckets"]) {
        UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
        HCBucketTableViewController* itvc = (HCBucketTableViewController*)[storyboard instantiateViewControllerWithIdentifier:@"bucketTableViewController"];
        NSMutableDictionary* dict = [[NSMutableDictionary alloc] initWithDictionary:[self.bucketsArray objectAtIndex:indexPath.row]];
        [dict setObject:[dict objectForKey:@"bucket_id"] forKey:@"id"];
        [itvc setBucket:dict];
        [self.navigationController pushViewController:itvc animated:YES];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if ([[self.sections objectAtIndex:section] isEqualToString:@"items"] && self.itemsArray.count > 0) {
        return @"Notes";
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"buckets"] && self.bucketsArray.count > 0) {
        return @"Threads";
    }
    return nil;
}


# pragma mark actions

- (IBAction)doneAction:(id)sender
{
    //[self dismissViewControllerAnimated:NO completion:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"openNewItemScreen" object:nil];
}


# pragma mark scroll view delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self.searchBar resignFirstResponder];
}


# pragma mark search bar delegate

- (void) searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    //[self reloadScreen];
}

- (void) searchBarCancelButtonClicked:(UISearchBar *)sB
{
    [sB resignFirstResponder];
}

- (void) searchBarSearchButtonClicked:(UISearchBar *)sB
{
    [self searchWithTerm:sB.text];
    [sB resignFirstResponder];
}

- (void) searchWithTerm:(NSString*)term
{
    requestMade = YES;
    [[LXServer shared] requestPath:@"/search.json" withMethod:@"GET" withParamaters: @{ @"t" : term }
                           success:^(id responseObject) {
                               requestMade = NO;
                               self.bucketsArray = [[NSMutableArray alloc] initWithArray:[responseObject objectForKey:@"buckets"]];
                               self.itemsArray = [[NSMutableArray alloc] initWithArray:[responseObject objectForKey:@"items"]];
                               [self reloadScreen];
                           }
                           failure:^(NSError* error) {
                               requestMade = NO;
                               [self reloadScreen];
                           }
     ];
    [self reloadScreen];
}

@end
