//
//  HCItemTableViewController.m
//  Hippocampus
//
//  Created by Will Schreiber on 7/8/14.
//  Copyright (c) 2014 LXV. All rights reserved.
//

#import "HCItemTableViewController.h"
#import "HCReminderViewController.h"
#import "HCBucketViewController.h"
#import "HCBucketsTableViewController.h"
#import "HCContainerViewController.h"
#import <QuartzCore/QuartzCore.h>
@import MapKit;

#define NULL_TO_NIL(obj) ({ __typeof__ (obj) __obj = (obj); __obj == [NSNull null] ? nil : obj; })
#define IMAGE_FADE_IN_TIME 0.3f

@interface HCItemTableViewController ()

@end

@implementation HCItemTableViewController

@synthesize pageControllerDelegate;

@synthesize item;
@synthesize originalItem;
@synthesize saveButton;
@synthesize sections;
@synthesize bucketToRemove;

@synthesize messageTextView;

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
    
    [[self navItem] setTitle:[NSDate timeAgoInWordsFromDatetime:[self.item createdAt]]];
    
    self.originalItem = self.item;
    
    //remove extra cell lines
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    [self setLongPressGestureToRemoveBucket];
    
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

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self scrollUnderlyingControllerToNote];
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
        [[self navItem].rightBarButtonItem  setEnabled:NO];
        [[self navItem].rightBarButtonItem setTitle:@"Saved"];
    } else if (savingChanges) {
        [[self navItem].rightBarButtonItem  setEnabled:NO];
        [[self navItem].rightBarButtonItem setTitle:@"Saving..."];
    } else {
        [[self navItem].rightBarButtonItem  setEnabled:YES];
        [[self navItem].rightBarButtonItem setTitle:@"Save"];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    self.sections = [[NSMutableArray alloc] init];
    
    if ([self.item hasMessage]) {
        [self.sections addObject:@"message"];
    }
    
    if ([self.item hasMediaURLs]) {
        [self.sections addObject:@"media"];
    }
    
    [self.sections addObject:@"reminder"];
    if ([self.item hasReminder]) {
        //[self.sections addObject:@"type"];
    }
    
    if ([self.item hasBuckets]) {
        [self.sections addObject:@"bucket"];
    }
    
    [self.sections addObject:@"actions"];
    
    if ([self.item hasLocation]) {
        [self.sections addObject:@"location"];
    }
    
    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([[self.sections objectAtIndex:section] isEqualToString:@"type"]) {
        if ([self.item hasReminder]) {
            return 1;
        }
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"message"]) {
        return 1;
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"media"]) {
        if ([self.item hasMediaURLs]) {
            return [[self.item croppedMediaURLs] count];
        }
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"reminder"]) {
        return 1;
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"bucket"]) {
        if ([self.item hasBuckets]) {
            return [[self.item buckets] count];
        }
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"actions"]) {
        return 2;
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"location"]) {
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
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"media"]) {
        return [self tableView:tableView imageCellForIndexPath:indexPath];
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"reminder"]) {
        return [self tableView:tableView reminderCellForIndexPath:indexPath];
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"bucket"]) {
        return [self tableView:tableView bucketCellForIndexPath:indexPath];
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"actions"]) {
        return [self tableView:tableView actionCellForIndexPath:indexPath];
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"location"]) {
        return [self tableView:tableView mapCellForIndexPath:indexPath];
    }
    return nil;
}

- (UITableViewCell*) tableView:(UITableView*)tableView typeCellForIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"labelCell" forIndexPath:indexPath];
    
    UILabel* label = (UILabel*)[cell.contentView viewWithTag:1];
    [label setText:[self.item itemType]];
    
    return cell;
}

- (UITableViewCell*) tableView:(UITableView*)tableView imageCellForIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"mediaCell" forIndexPath:indexPath];
    
    UIActivityIndicatorView* aiv = (UIActivityIndicatorView*) [cell.contentView viewWithTag:10];
    [aiv startAnimating];
    
    UIImageView* iv = (UIImageView*)[cell.contentView viewWithTag:1];
    NSString* url = [[self.item croppedMediaURLs] objectAtIndex:indexPath.row];
    
    if ([self.mediaDictionary objectForKey:url]) {
        UIImage* i = [self.mediaDictionary objectForKey:url];
        [iv setFrame:CGRectMake(iv.frame.origin.x, iv.frame.origin.y, iv.frame.size.width, i.size.height*(iv.frame.size.width/i.size.width))];
        [iv setImage:[self.mediaDictionary objectForKey:url]];
        
        [iv setAlpha:0.0f];
        [UIView animateWithDuration:IMAGE_FADE_IN_TIME animations:^(void) {
            [iv setAlpha:1.0f];
        }];
        
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

    note.textContainer.lineFragmentPadding = 0;
    note.textContainerInset = UIEdgeInsetsZero;

    note.delegate = self;
    [note setText:[self.item message]];
    [note setTag:1];
    [cell.contentView addSubview:note];
    
    [self setMessageTextView:note];
    
    UILabel* timestamp = (UILabel*)[cell.contentView viewWithTag:3];
    [timestamp setHidden:YES];
    
    return cell;
}

- (UITableViewCell*) tableView:(UITableView*)tableView reminderCellForIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"reminderCell" forIndexPath:indexPath];
    
    UILabel* main =  (UILabel*)[cell.contentView viewWithTag:1];
    UILabel* direction =  (UILabel*)[cell.contentView viewWithTag:3];
    
    if ([self.item hasReminder]) {
        [main setText:[NSDate timeAgoActualFromDatetime:[self.item reminderDate]]];
        [main setTextColor:[UIColor blackColor]];
        [direction setText:[NSString stringWithFormat:@"Set to remind you %@. Tap to Change", [self.item objectForKey:@"item_type"]]];
    } else {
        [main setText:@"No Reminder Set!"];
        [main setTextColor:direction.textColor];
        [direction setText:@"Tap to Set"];
    }
    
    return cell;
}

- (UITableViewCell*) tableView:(UITableView*)tableView bucketCellForIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"bucketSelectCell" forIndexPath:indexPath];
    
    NSDictionary* bucket = [[self.item buckets] objectAtIndex:indexPath.row];
    
    UILabel* label = (UILabel*)[cell.contentView viewWithTag:1];
    [label setText:[bucket firstName]];
    
    return cell;
}

- (UITableViewCell*) tableView:(UITableView*)tableView actionCellForIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"actionSelectCell" forIndexPath:indexPath];
    
    UILabel* label = (UILabel*)[cell.contentView viewWithTag:1];
    
    UILabel* blueDot = (UILabel*) [cell.contentView viewWithTag:4];
    [blueDot setHidden:YES];
    
    if (indexPath.row == 0) {
        [label setText:@"Add to Thread"];
        if ([self.item isOutstanding]) {
            [blueDot.layer setCornerRadius:4];
            [blueDot setClipsToBounds:YES];
            [blueDot setHidden:NO];
        }
    } else if (indexPath.row == 1) {
        [label setText:@"Delete"];
    }
    
    return cell;
}

- (UITableViewCell*) tableView:(UITableView*)tableView mapCellForIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"mapCell" forIndexPath:indexPath];
    
    MKMapView* mv = (MKMapView*)[cell.contentView viewWithTag:1];
    
    MKPointAnnotation *annotation = [[MKPointAnnotation alloc] init];
    [annotation setCoordinate:[self.item location].coordinate];
    [annotation setTitle:[NSString stringWithFormat:@"%f, %f", [self.item location].coordinate.latitude, [self.item location].coordinate.longitude]];
    [mv addAnnotation:annotation];
    
    MKMapRect zoomRect = MKMapRectNull;
    MKMapPoint annotationPoint = MKMapPointForCoordinate(annotation.coordinate);
    MKMapRect pointRect = MKMapRectMake(annotationPoint.x, annotationPoint.y, 0.1, 0.1);
    zoomRect = MKMapRectUnion(zoomRect, pointRect);
    
    [mv setVisibleMapRect:zoomRect animated:NO];
    
    return cell;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"message"]) {
        return [self heightForText:[self.item message] width:280.0f font:[UIFont noteDisplay]] + 22.0f + 12.0f + 36.0f;
    
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"reminder"]) {
        return 56.0f;
    
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"media"]) {
        if ([self.mediaDictionary objectForKey:[[self.item croppedMediaURLs] objectAtIndex:indexPath.row]]) {
            UIImage* i = [self.mediaDictionary objectForKey:[[self.item croppedMediaURLs] objectAtIndex:indexPath.row]];
            return 16 + i.size.height*(304/i.size.width);
        }
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"location"]) {
        return 200.0f;
        
    }
    
    return 44.0f;
}

- (CGFloat) heightForText:(NSString*)text width:(CGFloat)width font:(UIFont*)font
{
    NSDictionary *attributes = @{NSFontAttributeName: font};
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
        return nil;
        return @"Note";
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"media"]) {
        return nil;
        return @"Images";
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"reminder"]) {
        return @"Reminder";
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"bucket"]) {
        return @"Threads";
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"actions"]) {
        return @"Actions";
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"location"]) {
        return @"Note Location";
    }
    return nil;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"reminder"]) {
        UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Messages" bundle:[NSBundle mainBundle]];
        HCReminderViewController* itvc = (HCReminderViewController*)[storyboard instantiateViewControllerWithIdentifier:@"reminderViewController"];
        [itvc setItem:self.item];
        [itvc setDelegate:self];
        [self presentViewController:itvc animated:YES completion:nil];
    
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"bucket"]) {
        UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Messages" bundle:[NSBundle mainBundle]];
        HCBucketViewController* itvc = (HCBucketViewController *)[storyboard instantiateViewControllerWithIdentifier:@"bucketViewController"];
        [itvc setBucket:[[self.item buckets] objectAtIndex:indexPath.row]];
        [self.navigationController pushViewController:itvc animated:YES];
    
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"message"]) {
        
    
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"media"]) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[[self.item mediaURLs] objectAtIndex:indexPath.row]]];
    
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"actions"]) {
        if (indexPath.row == 0) {
            UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Messages" bundle:[NSBundle mainBundle]];
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




# pragma mark helpers

- (UINavigationItem*) navItem
{
    if (self.pageControllerDelegate && self.pageControllerDelegate.navItem)
        return self.pageControllerDelegate.navItem;
    return self.navigationItem;
}




#pragma mark put calls and updates

- (void) saveReminder:(NSString*)reminder withType:(NSString*)type
{
    unsavedChanges = YES;
    savingChanges = YES;
    [self.item setObject:reminder forKey:@"reminder_date"];
    [self.item setObject:type forKey:@"item_type"];
    [self.item setObject:[NSString stringWithFormat:@"%f", [[NSDate date] timeIntervalSince1970]] forKey:@"device_request_timestamp"];
    
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
    [self.item setObject:[self.messageTextView text] forKey:@"message"];
    [self.item setObject:[NSString stringWithFormat:@"%f", [[NSDate date] timeIntervalSince1970]] forKey:@"device_request_timestamp"];
    
    [[LXServer shared] requestPath:[NSString stringWithFormat:@"/items/%@.json", [self.item objectForKey:@"id"]] withMethod:@"PUT" withParamaters:@{@"item":self.item}
                           success:^(id responseObject) {
                               NSLog(@"successfully updated message");
                               unsavedChanges = NO;
                               savingChanges = NO;
                               //[self reloadScreen];
                               [self updateBackgroundArrays];
                               [self updateButtonStatus];
                           }
                           failure:^(NSError *error) {
                               NSLog(@"unsuccessfully updated message");
                               unsavedChanges = YES;
                               savingChanges = NO;
                               [self reloadScreen];
                           }
     ];
    [self updateButtonStatus];
}


- (void) addToStack:(NSDictionary*)bucket
{
    unsavedChanges = YES;
    savingChanges = YES;
    [self showHUDWithMessage:[NSString stringWithFormat:@"Adding to the '%@' Thread", [bucket objectForKey:@"first_name"]]];
    [[LXServer shared] requestPath:@"/bucket_item_pairs.json" withMethod:@"POST" withParamaters:@{@"bucket_item_pair":@{@"bucket_id":[bucket objectForKey:@"id"], @"item_id":[self.item objectForKey:@"id"]}}
                           success:^(id responseObject) {
                               //NSLog(@"successfully added to stack: %@", responseObject);
                               [self.item setObject:[responseObject objectForKey:@"buckets"] forKey:@"buckets"];
                               [self.item setObject:@"assigned" forKey:@"status"];
                               unsavedChanges = NO;
                               savingChanges = NO;
                               [self hideHUD];
                               [self updateBackgroundArrays];
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
}

- (void) saveAction:(id)sender
{
    NSLog(@"save hit!");
    [self saveUpdatedMessage:nil];
    [self.messageTextView resignFirstResponder];
}


- (void) updateBackgroundArrays
{
    if (self.pageControllerDelegate) {
        [self.pageControllerDelegate updateItemsArrayWithOriginal:self.originalItem new:self.item];
        [self setOriginalItem:self.item];
    }
}

- (void) scrollUnderlyingControllerToNote
{
    if ([(HCContainerViewController*)[self.pageControllerDelegate parentViewController] delegate] && [[(HCContainerViewController*)[self.pageControllerDelegate parentViewController] delegate] respondsToSelector:@selector(scrollToNote:)]) {
        [[(HCContainerViewController*)[self.pageControllerDelegate parentViewController] delegate] scrollToNote:self.originalItem];
    }
}




# pragma mark get calls


- (void) updateItemInfo
{
    [self getImages];
    [[LXServer shared] requestPath:[NSString stringWithFormat:@"/items/%@.json", [self.item objectForKey:@"id"]] withMethod:@"GET" withParamaters:nil
                           success:^(id responseObject){
                               self.item = [NSMutableDictionary dictionaryWithDictionary:responseObject];
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
    if ([self.item croppedMediaURLs]) {
        for (NSString* url in [self.item croppedMediaURLs]) {
            [SGImageCache getImageForURL:url thenDo:^(UIImage* image) {
                if (![self.mediaDictionary objectForKey:url]) {
                    [self.mediaDictionary setObject:image forKey:url];
                    [self reloadScreen];
                }
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


# pragma  mark - AlertView Delegate

- (void) alertForRemovalFromBucket:(NSMutableDictionary *)bucket {
    UIAlertView * alert =[[UIAlertView alloc ] initWithTitle:@"Are you sure?"
                                                     message:[NSString stringWithFormat:@"Do you want you remove this note from the %@ thread?", [bucket firstName]]
                                                    delegate:self
                                           cancelButtonTitle:@"Cancel"
                                           otherButtonTitles: nil];
    [alert addButtonWithTitle:@"Remove"];
    [alert setTag:2];
    [self setBucketToRemove:bucket];
    [alert show];
}

- (void) showAlertViewWithTitle:(NSString*)title message:(NSString*)message
{
    UIAlertView* av = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Delete", nil];
    [av show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 2) {
        if (buttonIndex == 1) {
            NSLog(@"remove!!!!");
            [self destroyBucketItemPair];
        }
    } else {
        if (buttonIndex == 1) {
            [self deleteItem];
        }

    }
}

- (void) destroyBucketItemPair {
    [self showHUDWithMessage:@"Updating..."];
    [[LXServer shared] requestPath:@"/destroy_with_bucket_and_item.json" withMethod:@"DELETE" withParamaters:@{@"bucket_id":[bucketToRemove ID], @"item_id":[self.item ID]}
                           success:^(id responseObject){
                               [self.item setObject:[responseObject objectForKey:@"buckets"] forKey:@"buckets"];
                               [self.item setObject:[responseObject objectForKey:@"status"] forKey:@"status"];
                               unsavedChanges = NO;
                               savingChanges = NO;
                               [self hideHUD];
                               [self updateBackgroundArrays];
                               [self reloadScreen];
                           }
                           failure:^(NSError *error) {
                               NSLog(@"error! %@", [error localizedDescription]);
                               unsavedChanges = YES;
                               savingChanges = NO;
                               [self hideHUD];
                               [self reloadScreen];
                           }
     ];
    [self setBucketToRemove:nil];
}

- (void) deleteItem {
    [[LXServer shared] requestPath:[NSString stringWithFormat:@"/items/%@.json", [self.item objectForKey:@"id"]] withMethod:@"DELETE" withParamaters:nil
                           success:^(id responseObject){
                               [self.navigationController popToRootViewControllerAnimated:YES];
                           }
                           failure:^(NSError *error) {
                               NSLog(@"error! %@", [error localizedDescription]);
                           }
     ];
}

# pragma mark textview delegate

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    NSString *result = [textView.text stringByReplacingCharactersInRange:range withString:text];

    [NSRunLoop cancelPreviousPerformRequestsWithTarget:self];
    [self performSelector:@selector(saveUpdatedMessage:) withObject:result afterDelay:0.5];
    [self performSelector:@selector(updateTableViewCellSizes:) withObject:textView afterDelay:0];
    
    unsavedChanges = YES;
    savingChanges = NO;
    [self updateButtonStatus];
    
    return YES;
}

- (void) updateTableViewCellSizes:(UITextView *)textView {
    [textView invalidateIntrinsicContentSize];
    if (![self.item hasMessage]) {
        [self.tableView reloadData];
    } else {
        [self.tableView beginUpdates];
        [self.tableView endUpdates];
    }
}

- (void) textViewDidBeginEditing:(UITextView *)textView
{
    [textView setScrollEnabled:NO];
    unsavedChanges = YES;
    savingChanges = NO;
    [self updateButtonStatus];
}

- (void) textViewDidEndEditing:(UITextView *)textView
{
    [textView setScrollEnabled:NO];
}


# pragma mark - Gesture Recognizers

- (void) setLongPressGestureToRemoveBucket {
    UILongPressGestureRecognizer *lpgr = [[UILongPressGestureRecognizer alloc]
                                          initWithTarget:self action:@selector(handleLongPress:)];
    lpgr.minimumPressDuration = 0.5; //seconds
    lpgr.delegate = self;
    [self.tableView addGestureRecognizer:lpgr];
}

-(void)handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer
{
    CGPoint p = [gestureRecognizer locationInView:self.tableView];
    
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:p];
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"bucket"] && [[self.item buckets] objectAtIndex:indexPath.row]) {
            [self alertForRemovalFromBucket:[[self.item buckets] objectAtIndex:indexPath.row]];
        }
    }
}


@end
