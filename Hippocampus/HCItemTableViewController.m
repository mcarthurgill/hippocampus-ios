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
#import "HCBucketsTableViewController.h"
#import <QuartzCore/QuartzCore.h>

#define NULL_TO_NIL(obj) ({ __typeof__ (obj) __obj = (obj); __obj == [NSNull null] ? nil : obj; })

@interface HCItemTableViewController ()

@end

@implementation HCItemTableViewController

@synthesize item;
@synthesize saveButton;
@synthesize sections;

@synthesize mediaDictionary;

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
    self.mediaDictionary = [[NSMutableDictionary alloc] init];
    
    unsavedChanges = NO;
    savingChanges = NO;
    
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
    [self updateButtonStatus];
}

- (void) updateButtonStatus
{
    if (!unsavedChanges) {
        [self.navigationItem.rightBarButtonItem  setEnabled:NO];
        [self.navigationItem.rightBarButtonItem setTitle:@"Saved"];
    } else if (savingChanges) {
        [self.navigationItem.rightBarButtonItem  setEnabled:NO];
        [self.navigationItem.rightBarButtonItem setTitle:@"Saving..."];
    } else {
        [self.navigationItem.rightBarButtonItem  setEnabled:YES];
        [self.navigationItem.rightBarButtonItem setTitle:@"Save"];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    self.sections = [[NSMutableArray alloc] init];
    
    if ([self.item objectForKey:@"message"] && [[self.item objectForKey:@"message"] length] > 0) {
        [self.sections addObject:@"message"];
    }
    
    if ([self.item objectForKey:@"media_urls"] && [[self.item objectForKey:@"media_urls"] count] > 0) {
        [self.sections addObject:@"media"];
    }
    
    [self.sections addObject:@"reminder"];
    if (NULL_TO_NIL([self.item objectForKey:@"reminder_date"])) {
        //[self.sections addObject:@"type"];
    }
    
    if ([self.item objectForKey:@"buckets"] && [[self.item objectForKey:@"buckets"] count] > 0) {
        [self.sections addObject:@"bucket"];
    }
    
    [self.sections addObject:@"actions"];
    
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
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"actions"]) {
        return 2;
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
        return [self tableView:tableView imageCellForIndexPath:indexPath];
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"reminder"]) {
        return [self tableView:tableView reminderCellForIndexPath:indexPath];
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"bucket"]) {
        return [self tableView:tableView bucketCellForIndexPath:indexPath];
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"actions"]) {
        return [self tableView:tableView actionCellForIndexPath:indexPath];
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

- (UITableViewCell*) tableView:(UITableView*)tableView imageCellForIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"mediaCell" forIndexPath:indexPath];
    
    UIActivityIndicatorView* aiv = (UIActivityIndicatorView*) [cell.contentView viewWithTag:10];
    [aiv startAnimating];
    
    UIImageView* iv = (UIImageView*)[cell.contentView viewWithTag:1];
    NSString* url = [[self.item objectForKey:@"media_urls"] objectAtIndex:indexPath.row];
    
    if ([self.mediaDictionary objectForKey:url]) {
        UIImage* i = [self.mediaDictionary objectForKey:url];
        [iv setFrame:CGRectMake(iv.frame.origin.x, iv.frame.origin.y, iv.frame.size.width, i.size.height*(iv.frame.size.width/i.size.width))];
        [iv setImage:[self.mediaDictionary objectForKey:url]];
        [iv setClipsToBounds:YES];
        [iv.layer setCornerRadius:8.0f];
    } else {
        [iv setImage:nil];
    }
    
    return cell;
}

- (UITableViewCell*) tableView:(UITableView*)tableView messageCellForIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"itemCell" forIndexPath:indexPath];
    
    UITextView *note = (UITextView*)[cell.contentView viewWithTag:1];

    float leftMargin = note.frame.origin.x;
    float topMargin = note.frame.origin.y;
    float width = note.frame.size.width;
    //wrong font but it was fucking up if i didn't set the font here.
    [note setFont:[UIFont fontWithName:@"Helvetica Neue" size:17.0f]];

    [note removeFromSuperview];
    
    note = [[UITextView alloc] initWithFrame:CGRectMake(leftMargin, topMargin, width, [self heightForText:[self.item objectForKey:@"message"] width:width font:note.font])];

    note.delegate = self;
    [note setText:[self.item objectForKey:@"message"]];
    [note setTag:1];
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
        [direction setText:[NSString stringWithFormat:@"Set to remind you %@. Tap to Change", [self.item objectForKey:@"item_type"]]];
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

- (UITableViewCell*) tableView:(UITableView*)tableView actionCellForIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"actionSelectCell" forIndexPath:indexPath];
    
    UILabel* label = (UILabel*)[cell.contentView viewWithTag:1];
    
    if (indexPath.row == 0) {
        [label setText:@"Add to Stack"];
    } else if (indexPath.row == 1) {
        [label setText:@"Delete"];
    }
    
    return cell;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"message"]) {
        return [self heightForText:[self.item objectForKey:@"message"] width:280.0f font:[UIFont systemFontOfSize:17.0]] + 22.0f + 12.0f;
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"reminder"]) {
        return 56.0f;
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"media"]) {
        if ([self.mediaDictionary objectForKey:[[self.item objectForKey:@"media_urls"] objectAtIndex:indexPath.row]]) {
            UIImage* i = [self.mediaDictionary objectForKey:[[self.item objectForKey:@"media_urls"] objectAtIndex:indexPath.row]];
            return 16 + i.size.height*(304/i.size.width);
        }
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
        return @"Reminder Frequency";
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"message"]) {
        return @"Note";
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"media"]) {
        return @"Images";
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"reminder"]) {
        return @"Reminder";
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"bucket"]) {
        return @"Stacks";
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"actions"]) {
        return @"Actions";
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
        
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"media"]) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[[self.item objectForKey:@"media_urls"] objectAtIndex:indexPath.row]]];
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"actions"]) {
        if (indexPath.row == 0) {
            UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
            HCBucketsTableViewController* itvc = (HCBucketsTableViewController*)[storyboard instantiateViewControllerWithIdentifier:@"bucketsTableViewController"];
            [itvc setMode:@"assign"];
            [itvc setDelegate:self];
            [self.navigationController pushViewController:itvc animated:YES];
        } else if (indexPath.row == 1) {
            [self showAlertViewWithTitle:@"Are you sure?" message:@"Deleting this note means it is gone forever."];
        }
    }
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}



#pragma mark put calls and updates

- (void) saveReminder:(NSString*)reminder withType:(NSString*)type
{
    unsavedChanges = YES;
    savingChanges = YES;
    [self.item setObject:reminder forKey:@"reminder_date"];
    [self.item setObject:type forKey:@"item_type"];
    [self showHUDWithMessage:[NSString stringWithFormat:@"Saving Reminder"]];
    [[LXServer shared] requestPath:[NSString stringWithFormat:@"/items/%@.json", [self.item objectForKey:@"id"]] withMethod:@"PUT" withParamaters:@{@"item":self.item}
                           success:^(id responseObject) {
                               NSLog(@"successfully updated reminder date");
                               unsavedChanges = NO;
                               savingChanges = NO;
                               [self hideHUD];
                               [self reloadScreen];
                           }
                           failure:^(NSError *error) {
                               NSLog(@"unsuccessfully updated reminder date");
                               unsavedChanges = YES;
                               savingChanges = NO;
                               [self hideHUD];
                               [self reloadScreen];
                           }
     ];
    [self reloadScreen];
}

- (void) saveUpdatedMessage:(NSString*)updatedMessage
{
    unsavedChanges = YES;
    savingChanges = YES;
    [self.item setObject:updatedMessage forKey:@"message"];
    [[LXServer shared] requestPath:[NSString stringWithFormat:@"/items/%@.json", [self.item objectForKey:@"id"]] withMethod:@"PUT" withParamaters:@{@"item":self.item}
                           success:^(id responseObject) {
                               NSLog(@"successfully updated message");
                               unsavedChanges = NO;
                               savingChanges = NO;
                               [self reloadScreen];
                           }
                           failure:^(NSError *error) {
                               NSLog(@"unsuccessfully updated reminder date");
                               unsavedChanges = YES;
                               savingChanges = NO;
                               [self reloadScreen];
                           }
     ];
    [self reloadScreen];
}


- (void) addToStack:(NSDictionary*)bucket
{
    unsavedChanges = YES;
    savingChanges = YES;
    [self showHUDWithMessage:[NSString stringWithFormat:@"Adding to the '%@' Stack", [bucket objectForKey:@"first_name"]]];
    [[LXServer shared] requestPath:@"/bucket_item_pairs.json" withMethod:@"POST" withParamaters:@{@"bucket_item_pair":@{@"bucket_id":[bucket objectForKey:@"id"], @"item_id":[self.item objectForKey:@"id"]}}
                           success:^(id responseObject) {
                               NSLog(@"successfully added to stack: %@", responseObject);
                               [self.item setObject:[responseObject objectForKey:@"buckets"] forKey:@"buckets"];
                               unsavedChanges = NO;
                               savingChanges = NO;
                               [self hideHUD];
                               if ([[self.item objectForKey:@"buckets"] count] == 1) {
                                   [[NSNotificationCenter defaultCenter] postNotificationName:@"reloadItems" object:nil userInfo:nil];
                               }
                               [self reloadScreen];
                           }
                           failure:^(NSError *error) {
                               NSLog(@"unsuccessfully added to stack");
                               unsavedChanges = YES;
                               savingChanges = NO;
                               [self hideHUD];
                               [self reloadScreen];
                           }
     ];
    [self reloadScreen];
}


- (IBAction)saveAction:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}




# pragma mark get calls


- (void) updateItemInfo
{
    [self getImages];
    [[LXServer shared] requestPath:[NSString stringWithFormat:@"/items/%@.json", [self.item objectForKey:@"id"]] withMethod:@"GET" withParamaters:nil
                           success:^(id responseObject){
                               self.item = [NSMutableDictionary dictionaryWithDictionary:responseObject];
                               NSLog(@"response: %@", responseObject);
                               [self getImages];
                               [self reloadScreen];
                           }
                           failure:^(NSError *error) {
                               NSLog(@"error! %@", [error localizedDescription]);
                           }
     ];
}


- (void) getImages
{
    if ([self.item objectForKey:@"media_urls"] && [[self.item objectForKey:@"media_urls"] count] > 0) {
        for (NSString* url in [self.item objectForKey:@"media_urls"]) {
            [SGImageCache getImageForURL:url thenDo:^(UIImage* image) {
                [self.mediaDictionary setObject:image forKey:url];
                [self reloadScreen];
            }];
        }
    }
}



# pragma mark hud delegate

- (void) showHUDWithMessage:(NSString*) message
{
    hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = message;
}

- (void) hideHUD
{
    [hud hide:YES];
}


# pragma mark alert

- (void) showAlertViewWithTitle:(NSString*)title message:(NSString*)message
{
    UIAlertView* av = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Delete", nil];
    [av show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        //do nothing. note was not deleted
    } else if (buttonIndex == 1) {
        [[LXServer shared] requestPath:[NSString stringWithFormat:@"/items/%@.json", [self.item objectForKey:@"id"]] withMethod:@"DELETE" withParamaters:nil
                               success:^(id responseObject){
                                   NSLog(@"response: %@", responseObject);
                                   [self.navigationController popToRootViewControllerAnimated:YES];
                               }
                               failure:^(NSError *error) {
                                   NSLog(@"error! %@", [error localizedDescription]);
                               }
         ];
    }
}



# pragma mark textview delegate

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    NSString *result = [textView.text stringByReplacingCharactersInRange:range withString:text];

    [NSRunLoop cancelPreviousPerformRequestsWithTarget:self];
    [self performSelector:@selector(saveUpdatedMessage:) withObject:result afterDelay:1.5];
    
    return YES;
}

- (void) textViewDidBeginEditing:(UITextView *)textView {
    unsavedChanges = YES;
    savingChanges = NO;
    [self updateButtonStatus];
}

@end
