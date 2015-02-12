//
//  LXRemindersViewController.m
//  Hippocampus
//
//  Created by Joseph McArthur Gill on 2/11/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import "LXRemindersViewController.h"
#import "HCItemTableViewController.h"

@interface LXRemindersViewController ()

@end

@implementation LXRemindersViewController

@synthesize tableView;
@synthesize sections;
@synthesize allItems;
@synthesize page;

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.navigationItem setTitle:@"Upcoming Reminders"];
    self.allItems = [[NSMutableArray alloc] init];
    [self refreshChange];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Table view data source

- (void) reloadScreenToIndex:(NSUInteger)index
{
    [self.tableView reloadData];
    [self setTableScrollToIndex:index];
}

- (void) setTableScrollToIndex:(NSInteger)index
{
    if (self.allItems.count > 0) {
        NSIndexPath *ipath = [NSIndexPath indexPathForRow:index-1 inSection: 0];
        [self.tableView scrollToRowAtIndexPath: ipath atScrollPosition: UITableViewScrollPositionTop animated: NO];
    }
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
        return self.allItems.count;
    }
    return 0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"all"]) {
        return [self itemCellForTableView:self.tableView withItem:[self.allItems objectAtIndex:indexPath.row] cellForRowAtIndexPath:indexPath];
    }
    return nil;
}

- (UITableViewCell*) itemCellForTableView:(UITableView*)tableView withItem:(NSDictionary*)item cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"reminderCell" forIndexPath:indexPath];
    
    UILabel* note = (UILabel*)[cell.contentView viewWithTag:1];
    [note setText: [item objectForKey:@"message"]];
    [note setLineBreakMode:NSLineBreakByWordWrapping];
    [note setNumberOfLines:0];
    
    UILabel* timestamp = (UILabel*)[cell.contentView viewWithTag:2];
    [timestamp setText:[NSString stringWithFormat:@"%@%@", [NSString stringWithFormat:@"%@ - ", [item objectForKey:@"item_type"]], [NSDate formattedDateFromString:[item objectForKey:@"next_reminder_date"]]]];
    
    //NSLog(@"INFO ON ITEM:\n%@\n%@\n%@", item.message, item.itemID, item.bucketID);
    return cell;
}

- (CGFloat) heightForText:(NSString*)text width:(CGFloat)width font:(UIFont*)font
{
    if (!text || [text length] == 0) {
        return 0.0f;
    }
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
        NSDictionary* item = [self.allItems objectAtIndex:indexPath.row];
        return [self heightForText:[[item objectForKey:@"message"] truncated:320] width:280.0f font:[UIFont systemFontOfSize:17.0]] + 22.0f + 12.0f + 14.0f;
    }
    return 44.0;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"all"]) {
        UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Messages" bundle:[NSBundle mainBundle]];
        HCItemTableViewController* itvc = (HCItemTableViewController*)[storyboard instantiateViewControllerWithIdentifier:@"itemTableViewController"];
        [itvc setItem:[self.allItems objectAtIndex:indexPath.row]];
        [self.navigationController pushViewController:itvc animated:YES];
    }
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}




# pragma mark - reload/requests

- (void) refreshChange
{
    if (requestMade)
        return;
    requestMade = YES;
    [self getReminders];
}

- (void) getReminders {
    [[LXServer shared] requestPath:[NSString stringWithFormat:@"/users/%@/reminders.json", [[HCUser loggedInUser] userID]] withMethod:@"GET" withParamaters: @{ @"page":[NSString stringWithFormat:@"%d", self.page]}
                           success:^(id responseObject) {
                               NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange:
                                                      NSMakeRange(0,[[responseObject objectForKey:@"reminders"] count])];
                               [self.allItems insertObjects:[responseObject objectForKey:@"reminders"] atIndexes:indexes];
                               requestMade = NO;
                               if ([[responseObject objectForKey:@"reminders"] count] > 0) {
                                   [self incrementPage];
                                   [self reloadScreenToIndex:0];
                               }
                           }
                           failure:^(NSError *error) {
                               NSLog(@"error: %@", [error localizedDescription]);
                               requestMade = NO;
                               [self reloadScreenToIndex:0];
                           }
     ];
}



- (void) incrementPage {
    self.page = self.page + 1;
}

@end
