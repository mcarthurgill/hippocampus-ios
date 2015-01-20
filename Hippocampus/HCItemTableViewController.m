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
    
    [self.sections addObject:@"type"];
    [self.sections addObject:@"message"];
    [self.sections addObject:@"reminder"];
    [self.sections addObject:@"bucket"];
    
    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([[self.sections objectAtIndex:section] isEqualToString:@"type"]) {
        return 1;
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"message"]) {
        return 1;
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"reminder"]) {
        return 1;
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"bucket"]) {
        return 1;
    }
    return 0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"type"]) {
        return [self tableView:tableView typeCellForIndexPath:indexPath];
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"message"]) {
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
    [label setText:self.item.itemType];
    
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
    
    note = [[UILabel alloc] initWithFrame:CGRectMake(leftMargin, topMargin, width, [self heightForText:item.message width:width font:note.font])];
    [note setText:item.message];
    [note setTag:1];
    [note setNumberOfLines:0];
    [note setLineBreakMode:NSLineBreakByWordWrapping];
    [cell.contentView addSubview:note];
    
    UILabel* timestamp = (UILabel*)[cell.contentView viewWithTag:3];
    [timestamp setText:[NSString stringWithFormat:@"%@%@", [NSDate timeAgoInWordsFromDatetime:item.createdAt], ([item bucket] ? [NSString stringWithFormat:@" - %@", [item bucket].titleString] : @"")]];
    
    return cell;
}

- (UITableViewCell*) tableView:(UITableView*)tableView reminderCellForIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"reminderCell" forIndexPath:indexPath];
    
    UILabel* main =  (UILabel*)[cell.contentView viewWithTag:1];
    if ([self.item reminder]) {
        [main setText:[NSDate timeAgoActualFromDatetime:self.item.reminderDate]];
    } else {
        [main setText:@"No Reminder Set!"];
    }
    
    UILabel* direction =  (UILabel*)[cell.contentView viewWithTag:3];
    if ([self.item reminder]) {
        [direction setText:@"Tap to Change"];
    } else {
        [direction setText:@"Tap to Set"];
    }
    
    return cell;
}

- (UITableViewCell*) tableView:(UITableView*)tableView bucketCellForIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"labelSelectCell" forIndexPath:indexPath];
    
    UILabel* label = (UILabel*)[cell.contentView viewWithTag:1];
    [label setText:[[self.item bucket] titleString]];
    
    return cell;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"message"]) {
        return [self heightForText:self.item.message width:280.0f font:[UIFont systemFontOfSize:17.0]] + 22.0f + 12.0f;
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
        [itvc setBucket:self.item.bucket];
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
    [self.item setReminderDate:reminder];
    [self.item saveWithSuccess:^(id responseObject) {
            NSLog(@"SUCCESS!: %@", responseObject);
            [self.navigationController popViewControllerAnimated:YES];
        } failure:^(NSError* error) {
            NSLog(@"FAIL! %@", [error localizedDescription]);
        }];
}

- (void) saveUpdatedMessage:(NSString*)updatedMessage
{
    [self.item setMessage:updatedMessage];
    [self.item saveWithSuccess:^(id responseObject) {
        NSLog(@"SUCCESS!: %@", responseObject);
        [self.navigationController popViewControllerAnimated:YES];
    } failure:^(NSError* error) {
        NSLog(@"FAIL! %@", [error localizedDescription]);
    }];
}

- (IBAction)saveAction:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}



@end
