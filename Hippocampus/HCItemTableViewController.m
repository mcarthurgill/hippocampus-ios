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
#import "HCPopUpViewController.h"
@import MapKit;
#import "LXAppDelegate.h"

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
@synthesize actions;
@synthesize bucketToRemove;
@synthesize moviePlayerController;

@synthesize messageTextView;

@synthesize mediaDictionary;

@synthesize mediaView;
@synthesize player, playerLayer, asset, playerItem;

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
    
    [self setNavTitle];
    
    self.originalItem = self.item;
    
    //remove extra cell lines
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableView.allowsMultipleSelectionDuringEditing = NO;
    
    [self setLongPressGestureToRemoveBucket];
    
    self.mediaDictionary = [[NSMutableDictionary alloc] init];
    
    [self setUnsavedChanges:NO andSavingChanges:NO];
    
    [self updateItemInfo];
    
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self reloadScreen];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
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

- (void) setNavTitle
{
    if ([self.item createdAt]) {
        [[self navItem] setTitle:[NSDate timeAgoInWordsFromDatetime:[self.item createdAt]]];
    }
}

- (void) reloadScreen
{
    [self setNavTitle];
    [self.tableView reloadData];
}

- (void) setUnsavedChanges:(BOOL)updatedUnsavedChanges andSavingChanges:(BOOL)updatedSavingChanges
{
    unsavedChanges = updatedUnsavedChanges;
    savingChanges = updatedSavingChanges;
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

- (void) setActionsArray
{
    if (!self.actions || [self.actions count] == 0) {
        self.actions = [[NSMutableArray alloc] init];
        
        [self.actions addObject:@"assign"];
        if ([self.item messageIsOneWord] && [self.item notBlank] && [self.item lettersOnly]) {
            [self.actions addObject:@"define"];
        }
        if ([self.item notBlank] || [self.item hasMediaURLs]) {
            [self.actions addObject:@"copy"];
        }
        if ([self.item notBlank] && [self.item message] && [[self.item message] length] < 200 && ![self.item messageIsOnlyLinks]) {
            [self.actions addObject:@"search"];
        }
        if ([self.item belongsToCurrentUser]) {
            [self.actions addObject:@"delete"];
        }
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    self.sections = [[NSMutableArray alloc] init];
    
    if ([self.item hasItemUserName] && [self.item hasCollaborativeThread]) {
        [self.sections addObject:@"addedBy"];
    }
    
    if ([self.item hasMessage] && ![self.item messageIsOnlyLinks]) {
        [self.sections addObject:@"message"];
    }
    
    if ([self.item hasMediaURLs]) {
        [self.sections addObject:@"media"];
    }
    
    if ([self.item hasAudioURL]) {
        [self.sections addObject:@"audio"];
    }
    
    if ([self.item hasLinks]) {
        [self.sections addObject:@"links"];
    }
    
    [self.sections addObject:@"reminder"];
    
    if ([self.item hasBuckets]) {
        [self.sections addObject:@"bucket"];
    }
    
    [self.sections addObject:@"actions"];
    
    if ([self.item hasLocation]) {
        //[self.sections addObject:@"location"];
    }
    
    [self setActionsArray];
    
    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([[self.sections objectAtIndex:section] isEqualToString:@"type"]) {
        if ([self.item hasReminder]) {
            return 1;
        }
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"addedBy"]) {
        return 1;
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"message"]) {
        return 1;
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"media"]) {
        if ([self.item hasMediaURLs]) {
            return [[self.item croppedMediaURLs] count];
        }
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"audio"]) {
        return 1;
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"links"]) {
        if ([self.item hasLinks]) {
            return [[self.item links] count];
        }
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"reminder"]) {
        return 1;
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"bucket"]) {
        if ([self.item hasBuckets]) {
            return [[self.item buckets] count];
        }
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"actions"]) {
        return [self.actions count];
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"location"]) {
        return 1;
    }
    return 0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"type"]) {
        return [self tableView:tableView typeCellForIndexPath:indexPath];
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"addedBy"]) {
        return [self tableView:tableView addedByCellForIndexPath:indexPath];
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"message"]) {
        return [self tableView:tableView messageCellForIndexPath:indexPath];
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"media"]) {
        return [self tableView:tableView imageCellForIndexPath:indexPath];
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"audio"]) {
        return [self tableView:tableView audioCellForIndexPath:indexPath];
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"links"]) {
        return [self tableView:tableView linkCellForIndexPath:indexPath];
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

- (UITableViewCell*) tableView:(UITableView*)tableView addedByCellForIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"addedByCell" forIndexPath:indexPath];
    
    UILabel* label = (UILabel*)[cell.contentView viewWithTag:1];
    [label setText:[NSString stringWithFormat:@"Added by %@.", [self.item itemUserName]]];
    
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
        if ([url isImageUrl]) {
            UIImage* i = [self.mediaDictionary objectForKey:url];
            [iv setFrame:CGRectMake(iv.frame.origin.x, iv.frame.origin.y, iv.frame.size.width, i.size.height*(iv.frame.size.width/i.size.width))];
            
            if (![iv image]) {
                [iv setImage:[self.mediaDictionary objectForKey:url]];
                [iv setAlpha:0.0f];
                [UIView animateWithDuration:IMAGE_FADE_IN_TIME animations:^(void) {
                    [iv setAlpha:1.0f];
                }];
            }
            
            [iv setClipsToBounds:YES];
            [iv.layer setCornerRadius:8.0f];
        }
    } else {
        [iv setImage:nil];
    }
    
    UILongPressGestureRecognizer* longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressMedia:)];
    [longPress setMinimumPressDuration:0.15f];
    [iv addGestureRecognizer:longPress];
    [iv setUserInteractionEnabled:YES];
    [iv setExclusiveTouch:YES];
    
    return cell;
}

- (UITableViewCell*) tableView:(UITableView*)tableView audioCellForIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"audioCell" forIndexPath:indexPath];
    
    UILabel* label = (UILabel*) [cell.contentView viewWithTag:1];
    [label setText:@"Play Audio"];
    
    return cell;
}

- (UITableViewCell*) tableView:(UITableView*)tableView linkCellForIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"linkSelectCell" forIndexPath:indexPath];
    
    UILabel* label = (UILabel*)[cell.contentView viewWithTag:1];
    [label setText:[[self.item links] objectAtIndex:indexPath.row]];
    
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
        NSString* text = @"Tap to Set";
        NSDate* date = [NSDate timeWithString:[self.item reminderDate]];
        if ([self.item onceReminder]) {
            text = [NSString stringWithFormat:@"%@ %li (%@), %li", [[NSArray months] objectAtIndex:[date monthIndex]], (long)[date dayInteger], [[NSArray daysOfWeek] objectAtIndex:[date dayOfWeekIndex]], (long)[date yearInteger] ];
        } else if ([self.item yearlyReminder]) {
            text = [NSString stringWithFormat:@"every %@ %li", [[NSArray months] objectAtIndex:[date monthIndex]], (long)[date dayInteger]];
        } else if ([self.item monthlyReminder]) {
            text = [NSString stringWithFormat:@"the %li of each month", (long)[date dayInteger]];
        } else if ([self.item weeklyReminder]) {
            text = [NSString stringWithFormat:@"every %@", [date dayOfWeek]];
        } else if ([self.item dailyReminder]) {
            text = @"every day";
        }
        //[main setText:[NSDate timeAgoActualFromDatetime:[self.item reminderDate]]];
        [main setText:text];
        [main setTextColor:[UIColor blackColor]];
        [direction setText:[NSString stringWithFormat:@"Set to nudge you %@. Tap to Change", [self.item objectForKey:@"item_type"]]];
    } else {
        [main setText:@"No Nudge Set!"];
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
    
    UIImageView* collaboratorsImageView = (UIImageView*) [cell.contentView viewWithTag:32];
    if ([bucket isCollaborativeThread]) {
        [collaboratorsImageView setHidden:NO];
    } else {
        [collaboratorsImageView setHidden:YES];
    }
    
    return cell;
}

- (UITableViewCell*) tableView:(UITableView*)tableView actionCellForIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:([[self.actions objectAtIndex:indexPath.row] isEqualToString:@"search"] ? @"actionSelectWideCell" : @"actionSelectCell") forIndexPath:indexPath];
    
    UILabel* label = (UILabel*)[cell.contentView viewWithTag:1];
    
    UILabel* blueDot = (UILabel*) [cell.contentView viewWithTag:4];
    [blueDot setHidden:YES];
    
    if ([[self.actions objectAtIndex:indexPath.row] isEqualToString:@"assign"]) {
        [label setText:@"Add to Collection"];
        if ([self.item isOutstanding]) {
            [blueDot.layer setCornerRadius:4];
            [blueDot setClipsToBounds:YES];
            [blueDot setHidden:NO];
        }
    } else if ([[self.actions objectAtIndex:indexPath.row] isEqualToString:@"delete"]) {
        [label setText:@"Delete Thought"];
    } else if ([[self.actions objectAtIndex:indexPath.row] isEqualToString:@"define"]) {
        [label setText:@"Define"];
    } else if ([[self.actions objectAtIndex:indexPath.row] isEqualToString:@"copy"]) {
        [label setText:@"Copy"];
    } else if ([[self.actions objectAtIndex:indexPath.row] isEqualToString:@"search"]) {
        [label setText:[NSString stringWithFormat:@"Google Search This Thought"]];
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
        return [self heightForText:[self.item message] width:(self.view.frame.size.width-20.0f) font:[UIFont noteDisplay]] + 22.0f + 12.0f + 36.0f + [UIApplication sharedApplication].statusBarFrame.size.height;
        
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"reminder"]) {
        return 56.0f;
        
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"media"]) {
        if ([self.mediaDictionary objectForKey:[[self.item croppedMediaURLs] objectAtIndex:indexPath.row]]) {
            UIImage* i = [self.mediaDictionary objectForKey:[[self.item croppedMediaURLs] objectAtIndex:indexPath.row]];
            return 16 + i.size.height*(304/i.size.width);
        }
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"location"]) {
        return 200.0f;
        
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"links"]) {
        return 52.0f;
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"audio"]) {
        return 52.0f;
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
        return @"Nudge Frequency";
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"message"]) {
        return nil;
        return @"Thought";
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"media"]) {
        return nil;
        return @"Images";
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"audio"]) {
        return @"Audio Clip";
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"links"]) {
        return @"Links";
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"reminder"]) {
        return @"Nudge";
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"bucket"]) {
        return @"Collections";
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"actions"]) {
        return @"Actions";
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"location"]) {
        return @"Thought Location";
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
        
        
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"links"]) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[[self.item links] objectAtIndex:indexPath.row]]];
        
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"media"]) {
        NSString *urlString = [[self.item croppedMediaURLs] objectAtIndex:indexPath.row];
        NSUInteger indexOfVideoUrl = [self.item indexOfMatchingVideoUrl:urlString];
        if (indexOfVideoUrl != -1) {
            NSURL *movieURL = [NSURL URLWithString:[[self.item mediaURLs] objectAtIndex:indexOfVideoUrl]];
            self.moviePlayerController = [[MPMoviePlayerViewController alloc] initWithContentURL:movieURL];
            [self presentMoviePlayerViewControllerAnimated:self.moviePlayerController];
            [self.moviePlayerController.moviePlayer play];
        } else {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
        }
        
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"audio"]) {
        
        
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"actions"]) {
        if ([[self.actions objectAtIndex:indexPath.row] isEqualToString:@"assign"]) {
            UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Messages" bundle:[NSBundle mainBundle]];
            HCBucketsTableViewController* itvc = (HCBucketsTableViewController*)[storyboard instantiateViewControllerWithIdentifier:@"bucketsTableViewController"];
            [itvc setMode:@"assign"];
            [itvc setDelegate:self];
            [self.navigationController pushViewController:itvc animated:YES];
        } else if ([[self.actions objectAtIndex:indexPath.row] isEqualToString:@"delete"]) {
            [self showAlertViewWithTitle:@"Are you sure?" message:@"Deleting this note means it is gone forever."];
        } else if ([[self.actions objectAtIndex:indexPath.row] isEqualToString:@"define"]) {
            //if ([UIReferenceLibraryViewController dictionaryHasDefinitionForTerm:@"word"]) {
            UIReferenceLibraryViewController* ref = [[UIReferenceLibraryViewController alloc] initWithTerm:[self.item firstWord]];
            [self presentViewController:ref animated:YES completion:nil];
            //}
        } else if ([[self.actions objectAtIndex:indexPath.row] isEqualToString:@"copy"]) {
            UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
            pasteboard.string = [self.item message];
            if ([self.item croppedMediaURLs] && [[self.item croppedMediaURLs] count] > 0) {
                NSMutableArray* images = [[NSMutableArray alloc] init];
                for (NSString* url in [self.item croppedMediaURLs]) {
                    if ([self.mediaDictionary objectForKey:url]) {
                        [images addObject:[self.mediaDictionary objectForKey:url]];
                    }
                }
                [pasteboard setImages:(NSArray*)images];
            }
            [self showHUDWithMessage:@"Copying"];
            [self performSelector:@selector(hideHUD) withObject:nil afterDelay:0.5f];
        } else if ([[self.actions objectAtIndex:indexPath.row] isEqualToString:@"search"]) {
            NSString* searchQuery = [NSString stringWithFormat:@"http://google.com/search?q=%@", (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL,(CFStringRef)[self.item message],NULL,(CFStringRef)@"!*'();:@&=+$,/?%#[]",kCFStringEncodingUTF8 ))];
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:searchQuery]];
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
    [self setUnsavedChanges:YES andSavingChanges:YES];
    
    [self.item setObject:reminder forKey:@"reminder_date"];
    [self.item setObject:type forKey:@"item_type"];
    [self.item setObject:[NSString stringWithFormat:@"%f", [[NSDate date] timeIntervalSince1970]] forKey:@"device_request_timestamp"];
    
    [self showHUDWithMessage:[NSString stringWithFormat:@"Setting Nudge"]];
    
    [[LXServer shared] saveReminderForItem:self.item
                                   success:^(id responseObject) {
                                       [self setUnsavedChanges:NO andSavingChanges:NO];
                                       [self hideHUD];
                                       [self reloadScreen];
                                   }failure:^(NSError *error){
                                       NSLog(@"unsuccessfully updated reminder date");
                                       [self setUnsavedChanges:YES andSavingChanges:NO];
                                       [self hideHUD];
                                       [self reloadScreen];
                                   }];
}

- (void) saveUpdatedMessage:(NSString*)updatedMessage
{
    [self setUnsavedChanges:YES andSavingChanges:YES];
    [self.item setObject:[self.messageTextView text] forKey:@"message"];
    [self.item setObject:[NSString stringWithFormat:@"%f", [[NSDate date] timeIntervalSince1970]] forKey:@"device_request_timestamp"];
    
    [[LXServer shared] saveUpdatedMessageForItem:self.item
                                         success:^(id responseObject){
                                             [self setUnsavedChanges:NO andSavingChanges:NO];
                                             [self updateBackgroundArrays];
                                         }failure:^(NSError *error) {
                                             [self setUnsavedChanges:YES andSavingChanges:NO];
                                             [self reloadScreen];
                                         }];
}


- (void) addToStack:(NSDictionary*)bucket
{
    [self setUnsavedChanges:YES andSavingChanges:YES];
    
    [self showHUDWithMessage:[NSString stringWithFormat:@"Adding to the '%@' Collection", [bucket objectForKey:@"first_name"]]];
    
    [[LXServer shared] addItem:self.item toBucket:bucket
                       success:^(id responseObject){
                           [self.item setObject:[responseObject objectForKey:@"buckets"] forKey:@"buckets"];
                           [self.item setObject:@"assigned" forKey:@"status"];
                           [self setUnsavedChanges:NO andSavingChanges:NO];
                           [self hideHUD];
                           [self updateBackgroundArrays];
                           [self reloadScreen];
                           [self updateBucketInBackground:bucket];
                       }failure:^(NSError *error){
                           NSLog(@"unsuccessfully added to stack");
                           [self setUnsavedChanges:YES andSavingChanges:NO];
                           [self hideHUD];
                           [self reloadScreen];
                       }];
}

- (void) saveAction:(id)sender
{
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
    
    [[LXServer shared] updateItemInfoWithItem:self.item
                                      success:^(id responseObject){
                                          self.item = [NSMutableDictionary dictionaryWithDictionary:responseObject];
                                          [self getImages];
                                          [self reloadScreen];
                                      }
                                      failure:^(NSError *error){
                                          NSLog(@"error! %@", [error localizedDescription]);
                                      }];
}


- (void) getImages
{
    if ([self.item croppedMediaURLs]) {
        for (NSString* url in [self.item croppedMediaURLs]) {
            if ([url isImageUrl]) {
                [SGImageCache getImageForURL:url].then(^(UIImage* image) {
                    if (![self.mediaDictionary objectForKey:url]) {
                        [self.mediaDictionary setObject:image forKey:url];
                        [self reloadScreen];
                    }
                });
            }
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

- (void) alertForRemovalFromBucket:(NSMutableDictionary *)bucket
{
    UIAlertView * alert =[[UIAlertView alloc ] initWithTitle:@"Are you sure?"
                                                     message:[NSString stringWithFormat:@"Do you want to remove this note from the %@ collection?", [bucket firstName]]
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

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
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

- (void) destroyBucketItemPair
{
    [self setUnsavedChanges:YES andSavingChanges:YES];
    [self showHUDWithMessage:@"Updating..."];
    
    [[LXServer shared] removeItem:self.item fromBucket:self.bucketToRemove
                          success:^(id responseObject){
                              [self.item setObject:[responseObject objectForKey:@"buckets"] forKey:@"buckets"];
                              [self.item setObject:[responseObject objectForKey:@"status"] forKey:@"status"];
                              [self setUnsavedChanges:NO andSavingChanges:NO];
                              [self hideHUD];
                              [self updateBackgroundArrays];
                              [self reloadScreen];
                              [self updateBucketInBackground:self.bucketToRemove];
                          }failure:^(NSError *error) {
                              NSLog(@"error! %@", [error localizedDescription]);
                              [self setUnsavedChanges:YES andSavingChanges:NO];
                              [self hideHUD];
                              [self reloadScreen];
                          }];
}

- (void) updateBucketInBackground:(NSDictionary*)bucket
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[LXServer shared] getBucketShowWithPage:0 bucketID:[bucket ID] success:^(id responseObject){
            self.bucketToRemove = nil;
        }failure:nil];
    });
}

- (void) deleteItem
{
    [self.item deleteItemWithSuccess:nil failure:nil];
    [self.navigationController popToRootViewControllerAnimated:YES];
}

# pragma mark textview delegate

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    NSString *result = [textView.text stringByReplacingCharactersInRange:range withString:text];
    
    [NSRunLoop cancelPreviousPerformRequestsWithTarget:self];
    [self performSelector:@selector(saveUpdatedMessage:) withObject:result afterDelay:0.5];
    [self performSelector:@selector(updateTableViewCellSizes:) withObject:textView afterDelay:0];
    
    [self setUnsavedChanges:YES andSavingChanges:NO];
    
    
    return YES;
}

- (void) updateTableViewCellSizes:(UITextView *)textView
{
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
    [self setUnsavedChanges:YES andSavingChanges:NO];
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

# pragma mark long press media

- (void) longPressMedia:(UILongPressGestureRecognizer*)gesture
{
    if (gesture.state == UIGestureRecognizerStateCancelled || gesture.state == UIGestureRecognizerStateFailed || gesture.state == UIGestureRecognizerStateEnded) {
        if (self.mediaView) {
            [self.mediaView removeFromSuperview];
            [self setMediaView:nil];
        }
        if (self.player) {
            [self.player pause];
            [self setPlayer:nil];
            [self setAsset:nil];
            [self setPlayerItem:nil];
            [self setPlayerLayer:nil];
        }
        [[[[UIApplication sharedApplication] delegate] window] setWindowLevel:UIWindowLevelNormal];
    }
    
    else if (!self.mediaView) {
        
        id cell = [gesture view];
        while (![cell isKindOfClass:[UITableViewCell class]]) {
            cell = [cell superview];
        }
        
        int index = (int)[[self.tableView indexPathForCell:cell] row];
        [[[[UIApplication sharedApplication] delegate] window] setWindowLevel:UIWindowLevelStatusBar+1];
        // Get main window reference
        UIWindow* mainWindow = (((LXAppDelegate *)[UIApplication sharedApplication].delegate).window);
        
        NSString *url = [[self.item croppedMediaURLs] objectAtIndex:index];
        NSUInteger indexOfVideoUrl = [self.item indexOfMatchingVideoUrl:url];
        
        // Create a full-screen subview
        self.mediaView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, [[UIScreen mainScreen] applicationFrame].size.width, [[UIScreen mainScreen] applicationFrame].size.height+[[UIApplication sharedApplication] statusBarFrame].size.height)];
        // Set up some properties of the subview
        self.mediaView.backgroundColor = [UIColor blackColor];
        [self.mediaView setContentMode:UIViewContentModeScaleAspectFit];
        
        if (indexOfVideoUrl != -1) {
            //VIDEO
            
            if (!self.player) {
                
                self.asset = [AVAsset assetWithURL:[NSURL URLWithString:[[self.item mediaURLs] objectAtIndex:indexOfVideoUrl]]];
                if (!self.playerItem) {
                    self.playerItem = [[AVPlayerItem alloc] initWithAsset:self.asset];
                }
                if (!self.player) {
                    self.player = [[AVPlayer alloc] initWithPlayerItem:self.playerItem];
                    self.player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
                    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidReachEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:[self.player currentItem]];
                }
                
                if (!self.playerLayer) {
                    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
                    [self.playerLayer setVideoGravity:AVLayerVideoGravityResizeAspect];
                    [self.playerLayer setFrame:self.mediaView.frame];
                    [self.mediaView.layer addSublayer:self.playerLayer];
                }
                [self.player play];
                
            }
            
        } else {
            
            //IMAGE
            if ([self.item hasID]) {
                if ([SGImageCache haveImageForURL:url]) {
                    [self.mediaView setImage:[SGImageCache imageForURL:url]];
                } else if (![self.mediaView.image isEqual:[SGImageCache imageForURL:url]]) {
                    self.mediaView.image = nil;
                    [SGImageCache getImageForURL:url].then(^(UIImage* image) {
                        if (image) {
                            self.mediaView.image = image;
                        }
                    });
                }
            } else {
                if ([NSData dataWithContentsOfFile:url] && ![self.mediaView.image isEqual:[UIImage imageWithData:[NSData dataWithContentsOfFile:url]]]) {
                    self.mediaView.image = [UIImage imageWithData:[NSData dataWithContentsOfFile:url]];
                }
            }
            
        }
        
        // Add the subview to the main window
        [mainWindow addSubview:self.mediaView];
    }
}

- (void) playerItemDidReachEnd:(NSNotification*)notification
{
    AVPlayerItem *p = [notification object];
    [p seekToTime:kCMTimeZero];
}


@end
