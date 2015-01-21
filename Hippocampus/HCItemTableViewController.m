//
//  HCItemTableViewController.m
//  Hippocampus
//
//  Created by Will Schreiber on 7/8/14.
//  Copyright (c) 2014 LXV. All rights reserved.
//

#import "HCItemTableViewController.h"
#import "HCReminderViewController.h"
#import "HCBucketTableViewController.h"
#import "HCEditItemViewController.h"

#define NULL_TO_NIL(obj) ({ __typeof__ (obj) __obj = (obj); __obj == [NSNull null] ? nil : obj; })

@interface HCItemTableViewController ()

@end

@implementation HCItemTableViewController

@synthesize item;
@synthesize saveButton;
@synthesize sections;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    [self updateItemInfo];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self reloadScreen];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source

- (void) reloadScreen
{
    [self.tableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    self.sections = [[NSMutableArray alloc] init];
    
    [self.sections addObject:@"message"];
    if ([self.item objectForKey:@"media_urls"] && [[self.item objectForKey:@"media_urls"] count] > 0) {
        [self.sections addObject:@"media"];
    }
    [self.sections addObject:@"reminder"];
    if (NULL_TO_NIL([self.item objectForKey:@"reminder_date"])) {
        [self.sections addObject:@"type"];
    }
    [self.sections addObject:@"bucket"];
    
    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([[self.sections objectAtIndex:section] isEqualToString:@"type"]) {
        if (NULL_TO_NIL([self.item objectForKey:@"reminder_date"])) {
            return 1;
        }
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"message"]) {
        return 1;
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"media"]) {
        if ([self.item objectForKey:@"media_urls"] && [[self.item objectForKey:@"media_urls"] count] > 0) {
            return [[self.item objectForKey:@"media_urls"] count];
        }
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"reminder"]) {
        return 1;
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"bucket"]) {
        if ([self.item objectForKey:@"buckets"] && [[self.item objectForKey:@"buckets"] count] > 0) {
            return [[self.item objectForKey:@"buckets"] count];
        }
    }
    return 0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"type"]) {
        return [self tableView:tableView typeCellForIndexPath:indexPath];
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"message"]) {
        return [self tableView:tableView messageCellForIndexPath:indexPath];
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"media"]) {
        return [self tableView:tableView messageCellForIndexPath:indexPath];
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"reminder"]) {
        return [self tableView:tableView reminderCellForIndexPath:indexPath];
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"bucket"]) {
        return [self tableView:tableView bucketCellForIndexPath:indexPath];
    }
    return nil;
}

- (UITableViewCell*) tableView:(UITableView*)tableView typeCellForIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"labelCell" forIndexPath:indexPath];
    
    UILabel* label = (UILabel*)[cell.contentView viewWithTag:1];
    [label setText:[self.item objectForKey:@"item_type"]];
    
    return cell;
}

- (UITableViewCell*) tableView:(UITableView*)tableView messageCellForIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"itemCell" forIndexPath:indexPath];
    
    UILabel* note = (UILabel*)[cell.contentView viewWithTag:1];
    float leftMargin = note.frame.origin.x;
    float topMargin = note.frame.origin.y;
    float width = note.frame.size.width;
    [note removeFromSuperview];
    
    note = [[UILabel alloc] initWithFrame:CGRectMake(leftMargin, topMargin, width, [self heightForText:[self.item objectForKey:@"message"] width:width font:note.font])];
    [note setText:[self.item objectForKey:@"message"]];
    [note setTag:1];
    [note setNumberOfLines:0];
    [note setLineBreakMode:NSLineBreakByWordWrapping];
    [cell.contentView addSubview:note];
    
    UILabel* timestamp = (UILabel*)[cell.contentView viewWithTag:3];
    [timestamp setText:[NSString stringWithFormat:@"%@%@", [NSDate timeAgoInWordsFromDatetime:[self.item objectForKey:@"created_at"]], (nil ? [NSString stringWithFormat:@" - %@", @""] : @"")]];
    
    return cell;
}

- (UITableViewCell*) tableView:(UITableView*)tableView reminderCellForIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"reminderCell" forIndexPath:indexPath];
    
    UILabel* main =  (UILabel*)[cell.contentView viewWithTag:1];
    if (NULL_TO_NIL([self.item objectForKey:@"reminder_date"])) {
        [main setText:[NSDate timeAgoActualFromDatetime:[self.item objectForKey:@"reminder_date"]]];
    } else {
        [main setText:@"No Reminder Set!"];
    }
    
    UILabel* direction =  (UILabel*)[cell.contentView viewWithTag:3];
    if (NULL_TO_NIL([self.item objectForKey:@"reminder_date"])) {
        [direction setText:@"Tap to Change"];
    } else {
        [direction setText:@"Tap to Set"];
    }
    
    return cell;
}

- (UITableViewCell*) tableView:(UITableView*)tableView bucketCellForIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"bucketSelectCell" forIndexPath:indexPath];
    
    NSDictionary* bucket = [[self.item objectForKey:@"buckets"] objectAtIndex:indexPath.row];
    
    UILabel* label = (UILabel*)[cell.contentView viewWithTag:1];
    [label setText:[bucket objectForKey:@"first_name"]];
    
    return cell;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"message"]) {
        return [self heightForText:[self.item objectForKey:@"message"] width:280.0f font:[UIFont systemFontOfSize:17.0]] + 22.0f + 12.0f;
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"reminder"]) {
        return 56.0f;
    }
    return 44.0f;
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

- (NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if ([[self.sections objectAtIndex:section] isEqualToString:@"type"]) {
        return @"Note Type";
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"message"]) {
        return @"Note Message";
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"media"]) {
        return @"Images";
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"reminder"]) {
        return @"Reminder";
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"bucket"]) {
        return @"Assigned To";
    }
    return nil;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"reminder"]) {
        UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
        HCReminderViewController* itvc = (HCReminderViewController*)[storyboard instantiateViewControllerWithIdentifier:@"reminderViewController"];
        [itvc setItem:self.item];
        [itvc setDelegate:self];
        [self presentViewController:itvc animated:YES completion:nil];
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"bucket"]) {
        UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
        HCBucketTableViewController* itvc = (HCBucketTableViewController*)[storyboard instantiateViewControllerWithIdentifier:@"bucketTableViewController"];
        [itvc setBucket:[[self.item objectForKey:@"buckets"] objectAtIndex:indexPath.row]];
        [self.navigationController pushViewController:itvc animated:YES];
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"message"]) {
        UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
        HCEditItemViewController* itvc = (HCEditItemViewController*)[storyboard instantiateViewControllerWithIdentifier:@"editItemViewController"];
        [itvc setItem:self.item];
        [itvc setDelegate:self];
        [self presentViewController:itvc animated:YES completion:nil];
    }
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}


#pragma mark actions

- (void) saveReminder:(NSString*)reminder
{
    [self.item setObject:reminder forKey:@"reminder_date"];
    [[LXServer shared] requestPath:[NSString stringWithFormat:@"/items/%@.json", [self.item objectForKey:@"id"]] withMethod:@"PUT" withParamaters:@{@"item":self.item}
                           success:^(id responseObject) {
                               NSLog(@"successfully updated reminder date");
                           }
                           failure:^(NSError *error) {
                               NSLog(@"unsuccessfully updated reminder date");
                           }
     ];
    [self reloadScreen];
}

- (void) saveUpdatedMessage:(NSString*)updatedMessage
{
    [self.item setObject:updatedMessage forKey:@"message"];
    [[LXServer shared] requestPath:[NSString stringWithFormat:@"/items/%@.json", [self.item objectForKey:@"id"]] withMethod:@"PUT" withParamaters:@{@"item":self.item}
                           success:^(id responseObject) {
                               NSLog(@"successfully updated message");
                           }
                           failure:^(NSError *error) {
                               NSLog(@"unsuccessfully updated message");
                           }
     ];
    [self reloadScreen];
}

- (IBAction)saveAction:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}


- (void) updateItemInfo
{
    [[LXServer shared] requestPath:[NSString stringWithFormat:@"/items/%@.json", [self.item objectForKey:@"id"]] withMethod:@"GET" withParamaters:nil
                           success:^(id responseObject){
                               self.item = [NSMutableDictionary dictionaryWithDictionary:responseObject];
                               NSLog(@"response: %@", responseObject);
                               [self reloadScreen];
                           }
                           failure:^(NSError *error) {
                               NSLog(@"error! %@", [error localizedDescription]);
                           }
     ];
}



@end
