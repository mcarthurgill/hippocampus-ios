//
//  HCBucketsTableViewController.m
//  Hippocampus
//
//  Created by Will Schreiber on 7/8/14.
//  Copyright (c) 2014 LXV. All rights reserved.
//

#import "HCBucketsTableViewController.h"
#import "HCBucketViewController.h"
#import "HCItemTableViewController.h"
#import "HCNewBucketIITableViewController.h"
#import "HCContainerViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "LXRemindersViewController.h"
#import "HCRandomItemViewController.h"
#import "HCLocationNotesViewController.h"
#import "HCItemTableViewCell.h"
#import "HCIndicatorTableViewCell.h"
#import "HCBucketDetailsViewController.h"
#import "HCContactTableViewCell.h"
#import <AudioToolbox/AudioToolbox.h>
#import "LXAppDelegate.h"
#import "HCPopUpViewController.h"
#import "HCPermissionViewController.h"

#define NULL_TO_NIL(obj) ({ __typeof__ (obj) __obj = (obj); __obj == [NSNull null] ? nil : obj; })
#define SEARCH_DELAY 0.3f
#define IMAGE_FADE_IN_TIME 0.3f
#define PICTURE_HEIGHT_IN_CELL 280
#define PICTURE_MARGIN_TOP_IN_CELL 8

@interface HCBucketsTableViewController ()

@end

@implementation HCBucketsTableViewController

@synthesize mode;
@synthesize delegate;

@synthesize refreshControl;
@synthesize searchBar;
@synthesize sections;
@synthesize bucketsDictionary;
@synthesize bucketsSearchDictionary;
@synthesize serverSearchDictionary;
@synthesize cachedDiskDictionary;

@synthesize composeBucketController;

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
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshChangeAfterDelay) name:@"appAwake" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pushItemTableView:) name:@"pushItemTableView" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pushBucketViewController:) name:@"pushBucketView" object:nil];
    
    [self setupProperties];

    //reload data to make sure it's catching assign mode
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1*NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self reloadScreen];
    });
    
    if ([self allNotesDictionary]) {
        UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Messages" bundle:[NSBundle mainBundle]];
        HCBucketViewController* btvc = [storyboard instantiateViewControllerWithIdentifier:@"bucketViewController"];
        [btvc setBucket:[[NSMutableDictionary alloc] initWithDictionary:[self allNotesDictionary]]];
        [btvc setDelegate:self];
        [self.navigationController pushViewController:btvc animated:NO];
    }
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.bucketsDictionary = nil;
    self.cachedDiskDictionary = nil;
    
    [self refreshChange];
    [self reloadScreen];

    if ([self assignMode]) {
        [self setTitle:@"Add to Collection"];
        [self.navigationItem setRightBarButtonItem:nil];
        [self.navigationItem setLeftBarButtonItem:nil];
    }
    
    //    if (![[[LXSession thisSession] user] completedSetup] && ![self assignMode]) {
    //        [self setTitle:[NSString stringWithFormat:@"Hippocampus | %@", [[[[LXSession thisSession] user] setupCompletion] formattedPercentage]]];
    //    }
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
//    if ([[LXSetup theSetup] shouldPromptForCompletion] && [self.navigationController.visibleViewController isKindOfClass:[HCBucketsTableViewController class]] && ![self assignMode]) {
//        [self showSetup];
//    }
    
    if ([self.navigationController.visibleViewController isKindOfClass:[HCBucketsTableViewController class]]) {
        if ([[LXSetup theSetup] visitedThisScreen:self withAssignMode:[self assignMode]]) {
            NSLog(@"already visited buckets table view controller %@", [self assignMode] ? @"with assign mode" : @"");
            if ([self assignMode]) {
                [self getAddressBookPermissionIfUndetermined];
            }
        } else {
            NSLog(@"have not visited buckets table view controller %@", [self assignMode] ? @"with assign mode" : @"");
            if ([self assignMode]) {
                UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Messages" bundle:[NSBundle mainBundle]];
                HCPopUpViewController* vc = [storyboard instantiateViewControllerWithIdentifier:@"popUpViewController"];
                [vc setImageForScreenshotImageView:[[LXSetup theSetup] takeScreenshot]];
                [vc setImageForMainImageView:[UIImage imageNamed:@"assign-screen.jpg"]];
                [vc setMainLabelText:@"Thoughts belong to collections. Assign this thought to an existing collection or create a new one."];
                [self.navigationController presentViewController:vc animated:NO completion:nil];
            } else {
                UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Messages" bundle:[NSBundle mainBundle]];
                HCPopUpViewController* vc = [storyboard instantiateViewControllerWithIdentifier:@"popUpViewController"];
                [vc setImageForScreenshotImageView:[[LXSetup theSetup] takeScreenshot]];
                [vc setImageForMainImageView:[UIImage imageNamed:@"compose-screen.jpg"]];
                [vc setMainLabelText:@"Welcome! Tap 'Compose' in the top right corner to add a thought."];
                [self.navigationController presentViewController:vc animated:NO completion:nil];
            }
        }
    }
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.searchBar resignFirstResponder];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void) setupProperties
{
    //remove extra cell lines
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    self.bucketsSearchDictionary = [[NSMutableDictionary alloc] init];
    self.serverSearchDictionary = [[NSMutableDictionary alloc] init];
    
    requestMade = NO;
    
    [self setLongPressGestureToRemoveBucket];
    
    //change back button text when new VC gets popped on the stack
    self.navigationItem.backBarButtonItem =
    [[UIBarButtonItem alloc] initWithTitle:@""
                                      style:UIBarButtonItemStyleBordered
                                     target:nil
                                     action:nil];
}



#pragma mark - Table view data source

- (void) refreshChangeAfterDelay
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.05*NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self refreshChange];
    });
}

- (void) reloadScreen
{
    [self.refreshControl endRefreshing];
    [self.tableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    self.sections = [[NSMutableArray alloc] init];
    
    if ([self assignMode]) {
        [self.sections addObject:@"new"];
    }
    
    if (requestMade && !self.refreshControl.isRefreshing && (![self currentDictionary] || [[[self currentDictionary] allKeys] count] == 0)) {
        [self.sections addObject:@"requesting"];
    }
    
    if ([[self currentDictionary] objectForKey:@"Recent"] && [[[self currentDictionary] objectForKey:@"Recent"] count] > 0) {
        [self.sections addObject:@"Recent"];
    }
    if ([[self currentDictionary] objectForKey:@"Other"] && [[[self currentDictionary] objectForKey:@"Other"] count] > 0) {
        [self.sections addObject:@"Other"];
    }
    if ([[self currentDictionary] objectForKey:@"Person"] && [[[self currentDictionary] objectForKey:@"Person"] count] > 0) {
        [self.sections addObject:@"Person"];
    }
    if ([[self currentDictionary] objectForKey:@"Event"] && [[[self currentDictionary] objectForKey:@"Event"] count] > 0) {
        [self.sections addObject:@"Event"];
    }
    if ([[self currentDictionary] objectForKey:@"Place"] && [[[self currentDictionary] objectForKey:@"Place"] count] > 0) {
        [self.sections addObject:@"Place"];
    }
    
    if ([self searchActivated] && ![self assignMode]) {
        [self.sections addObject:@"searchResults"];
    }
    
    if ([self assignMode] && [[LXAddressBook thisBook] permissionGranted] && [[[self currentDictionary] objectForKey:@"Contacts"] count] > 0) {
        [self.sections addObject:@"Contacts"];
    }
    
    if (![self assignMode]) {
        [self.sections addObject:@"info"];
    }
    
    // Return the number of sections.
    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([[self.sections objectAtIndex:section] isEqualToString:@"new"]) {
        return 1;
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"Recent"]) {
        return [[[self currentDictionary] objectForKey:@"Recent"] count];
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"Other"]) {
        return [[[self currentDictionary] objectForKey:@"Other"] count];
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"Person"]) {
        return [[[self currentDictionary] objectForKey:@"Person"] count];
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"Event"]) {
        return [[[self currentDictionary] objectForKey:@"Event"] count];
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"Place"]) {
        return [[[self currentDictionary] objectForKey:@"Place"] count];
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"requesting"]) {
        return 1;
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"searchResults"]) {
        return [[self searchArray] count];
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"Contacts"]) {
        return [[[self currentDictionary] objectForKey:@"Contacts"] count];
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"info"]) {
        return 1;
    }
    // Return the number of rows in the section.
    return 0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"requesting"]) {
        return [self indicatorCellForTableView:tableView cellForRowAtIndexPath:indexPath];
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"new"]) {
        return [self newCellForTableView:tableView cellForRowAtIndexPath:indexPath];
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"searchResults"]) {
        return [self itemCellForTableView:tableView withItem:[[self searchArray] objectAtIndex:indexPath.row] cellForRowAtIndexPath:indexPath];
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"Contacts"]) {
        return [self contactsCellForTableView:tableView withContact:[[[self currentDictionary] objectForKey:@"Contacts"] objectAtIndex:indexPath.row] cellForRowAtIndexPath:indexPath];
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"info"]) {
        return [self infoCellForTableView:tableView cellForRowAtIndexPath:indexPath];
    }
    return [self bucketCellForTableView:tableView cellForRowAtIndexPath:indexPath];
}

- (UITableViewCell*) indicatorCellForTableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    HCIndicatorTableViewCell *cell = (HCIndicatorTableViewCell*)[tableView dequeueReusableCellWithIdentifier:@"indicatorCell" forIndexPath:indexPath];
    [cell configureAndBeginAnimation];
    return cell;
}

- (UITableViewCell*) newCellForTableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"newCell" forIndexPath:indexPath];
    UILabel* label = (UILabel*) [cell.contentView viewWithTag:1];
    [label setText:@"+ New Collection"];
    return cell;
}

- (UITableViewCell*) infoCellForTableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"infoCell" forIndexPath:indexPath];
    UITextView* textView = (UITextView*) [cell.contentView viewWithTag:2];
    [textView setText:[NSString stringWithFormat:@"Text thoughts to: +1 (615) 724-9333\n\n%@ Thoughts\n%@ Collections\n\nHippocampus %@\nMade with <3 in Nashville", [[[[LXSession thisSession] user] numberItems] formattedString], [[[[LXSession thisSession] user] numberBuckets] formattedString], [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"] ]];
    return cell;
}

- (UITableViewCell*) bucketCellForTableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    NSDictionary* bucket = [[[self currentDictionary] objectForKey:[self.sections objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row];
    NSString* identifier = @"bucketCell";
    //if (NULL_TO_NIL([bucket objectForKey:@"description_text"]) || [[self.sections objectAtIndex:indexPath.section] isEqualToString:@"Event"]) {
        identifier = @"bucketAndDescriptionCell";
    //}
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
    
    UILabel* note = (UILabel*)[cell.contentView viewWithTag:1];

    [note setText:[bucket objectForKey:@"first_name"]];
    if (NULL_TO_NIL([bucket bucketType]) && [[bucket bucketType] isEqualToString:@"Person"]) {
        [note boldSubstring:[[note.text componentsSeparatedByString:@" "] objectAtIndex:0]];
    }
    
    UILabel* description = (UILabel*)[cell.contentView viewWithTag:2];
    if (NULL_TO_NIL([bucket objectForKey:@"description_text"])) {
        [description setText:[bucket objectForKey:@"description_text"]];
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"Event"]) {
        [description setText:[NSString stringWithFormat:@"Created %@%@", [NSDate timeAgoActualFromDatetime:[bucket createdAt]], ([self assignMode] ? @" - Tap to Add Thought" : @"")]];
    } else {
        if ([bucket isAllNotesBucket] && [[bucket itemsCount] integerValue] == 0) {
            [description setText:[NSString stringWithFormat:@"%@ Thought%@", [[[[LXSession thisSession] user] numberItems] formattedString], ([[bucket itemsCount] integerValue] == 1 ? @"" : @"s")]];
        } else {
            [description setText:[NSString stringWithFormat:@"%@ Thought%@ %@%@", [bucket itemsCount], ([[bucket itemsCount] integerValue] == 1 ? @"" : @"s"), [bucket isAllNotesBucket] ? @"Outstanding" : @"", ([self assignMode] ? @" - Tap to Add Thought" : [NSString stringWithFormat:@" - updated %@", [NSDate timeAgoActualFromDatetime:[bucket updatedAt]]])]];
        }
    }
    
    UILabel* blueDot = (UILabel*) [cell.contentView viewWithTag:4];
    if ([bucket hasUnseenItems] || ([bucket isAllNotesBucket] && [bucket hasItems])) {
        [blueDot.layer setCornerRadius:4];
        [blueDot setClipsToBounds:YES];
        [blueDot setHidden:NO];
    } else {
        [blueDot setHidden:YES];
    }
    
    UIImageView* collaboratorsImageView = (UIImageView*) [cell.contentView viewWithTag:32];
    if ([bucket isCollaborativeThread]) {
        [collaboratorsImageView setHidden:NO];
    } else {
        [collaboratorsImageView setHidden:YES];
    }
    
    return cell;
}

- (UITableViewCell*) itemCellForTableView:(UITableView*)tableView withItem:(NSDictionary*)item cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    HCItemTableViewCell *cell = (HCItemTableViewCell*)[tableView dequeueReusableCellWithIdentifier:@"itemCell" forIndexPath:indexPath];
    [cell configureWithItem:item];
    return cell;
}

- (UITableViewCell*) contactsCellForTableView:(UITableView*)tableView withContact:(NSDictionary*)contact cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    HCContactTableViewCell *cell = (HCContactTableViewCell*)[tableView dequeueReusableCellWithIdentifier:@"contactCell" forIndexPath:indexPath];
    [cell configureWithContact:contact];
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
    if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"requesting"] || [[self.sections objectAtIndex:indexPath.section] isEqualToString:@"new"]) {
        
        return 44.0f;
        
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"searchResults"]) {
        
        NSDictionary* item = [[self searchArray] objectAtIndex:indexPath.row];
        
        int additional = 0;
        if ([item hasMediaURLs]) {
            int numImages = 0;
            for (NSString *url in [item mediaURLs]) {
                if ([url isImageUrl]) {
                    numImages++;
                }
            }
            additional = (PICTURE_MARGIN_TOP_IN_CELL+PICTURE_HEIGHT_IN_CELL)*numImages;
        }
        return [self heightForText:[item truncatedMessage] width:280.0f font:[UIFont noteDisplay]] + 22.0f + 12.0f + 14.0f + additional + 4.0f;
        
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"info"]) {
        
        return 180.0f;
        
    }
    
    return 64.0f;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"info"]) {
        return;
    }
    
    if ([self assignMode]) {
        
        if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"new"]) {
            UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Messages" bundle:[NSBundle mainBundle]];
            HCNewBucketIITableViewController* btvc = [storyboard instantiateViewControllerWithIdentifier:@"newBucketIITableViewController"];
            [btvc setDelegate:self.delegate];
            [self.navigationController pushViewController:btvc animated:YES];
        } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"Contacts"]) {
            [self createBucketFromContact:[[[self currentDictionary] objectForKey:@"Contacts"] objectAtIndex:indexPath.row]];
        } else {
            [self.delegate addToStack:[[[self currentDictionary] objectForKey:[self.sections objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row]];
            [self updateAllBucketsInBackground];
            [self.navigationController popViewControllerAnimated:YES];
        }
    
    } else {
        
        if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"searchResults"]) {
            UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Messages" bundle:[NSBundle mainBundle]];
            HCContainerViewController* itvc = (HCContainerViewController*)[storyboard instantiateViewControllerWithIdentifier:@"containerViewController"];
            [itvc setItem:[[self searchArray] objectAtIndex:indexPath.row]];
            [itvc setItems:[self searchArray]];
            [itvc setDelegate:self];
            [self.navigationController pushViewController:itvc animated:YES];
        
        } else {
            UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Messages" bundle:[NSBundle mainBundle]];
            HCBucketViewController* btvc = [storyboard instantiateViewControllerWithIdentifier:@"bucketViewController"];
            [btvc setBucket:[[[self currentDictionary] objectForKey:[self.sections objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row]];
            [btvc setDelegate:self];
            [self.navigationController pushViewController:btvc animated:YES];
        }
    
    }
}

- (void) updateAllBucketsInBackground
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[LXServer shared] getAllBucketsWithSuccess:^(id responseObject){
            [self reloadScreen];
        }failure:nil];
    });
}

- (NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if ([[self.sections objectAtIndex:section] isEqualToString:@"requesting"] || [[self.sections objectAtIndex:section] isEqualToString:@"new"]) {
        return nil;
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"searchResults"]) {
        return [NSString stringWithFormat:@"Thoughts With \"%@\"", [self searchTerm]];
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"Contacts"]) {
        return @"Contacts";
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"info"]) {
        return @"Info";
    }
    return [NSString stringWithFormat:@"%@ Collections",[self.sections objectAtIndex:section]];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSDictionary *bucket = [[[self currentDictionary] objectForKey:[self.sections objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row];
        if (bucket && ![bucket isAllNotesBucket] && ![self assignMode] && [bucket belongsToCurrentUser]) {
            [self showHUDWithMessage:@"Deleting Collection..."];
            [[LXServer shared] deleteBucketWithBucketID:[bucket ID] success:^(id responseObject){
                [self refreshChange];
            }failure:^(NSError *error){
                [self hideHUD];
            }];
        }
    }
}



# pragma mark helpers

- (BOOL) assignMode
{
    return self.mode && [self.mode isEqualToString:@"assign"];
}

- (BOOL) searchActivated
{
    NSString* key = self.searchBar.text ? [self.searchBar.text lowercaseString] : @"";
    return key && [key length] > 0;
}




# pragma mark refresh controller

- (void) refreshChange
{
    if (requestMade)
        return;
    requestMade = YES;
    [[LXServer shared] getAllBucketsWithSuccess:^(id responseObject) {
            self.bucketsDictionary = [NSMutableDictionary dictionaryWithDictionary:responseObject];
            requestMade = NO;
            [self reloadScreen];
            [self hideHUD];
    } failure:^(NSError *error) {
        NSLog(@"error: %@", [error localizedDescription]);
        requestMade = NO;
        [self hideHUD];
        [self reloadScreen];
    }];
}

- (IBAction)refreshControllerChanged:(id)sender
{
    if (self.refreshControl.isRefreshing) {
        [self refreshChange];
    }
}


# pragma mark toolbar actions

- (IBAction)composeButtonClicked:(id)sender
{
    NSDictionary* allNotesDict = [self allNotesDictionary];
    if (allNotesDict) {
        UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Messages" bundle:[NSBundle mainBundle]];
        HCBucketViewController* btvc = [storyboard instantiateViewControllerWithIdentifier:@"bucketViewController"];
        [btvc setInitializeWithKeyboardUp:YES];
        [btvc setBucket:[[NSMutableDictionary alloc] initWithDictionary:allNotesDict]];
        [btvc setDelegate:self];
        [self.navigationController pushViewController:btvc animated:YES];
    }
}

- (IBAction)moreButtonClicked:(id)sender
{
    NSString *other1 = @"Nudges";
    NSString *other2 = @"Thoughts Nearby";
    NSString *other3 = @"Random Thought";
    NSString *cancelTitle = @"Cancel";
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:cancelTitle destructiveButtonTitle:nil otherButtonTitles:other1, other2, other3, nil];
    
    [actionSheet showInView:self.view];
}



# pragma mark search bar delegate

- (BOOL) searchBarShouldBeginEditing:(UISearchBar *)sB
{
    return YES;
}

- (void) searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    if (![self assignMode]) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(searchWithCurrentText) object:nil];
        [self performSelector:@selector(searchWithCurrentText) withObject:nil afterDelay:SEARCH_DELAY];
    }
    [self reloadScreen];
}

- (void) searchBarCancelButtonClicked:(UISearchBar *)sB
{
    [sB resignFirstResponder];
}

- (void) searchBarSearchButtonClicked:(UISearchBar *)sB
{
    [sB resignFirstResponder];
    if (![self assignMode]) {
        [self searchWithCurrentText];
    }
    [self reloadScreen];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self.searchBar resignFirstResponder];
}

- (void) searchWithCurrentText
{
    [self searchWithTerm:[self.searchBar.text lowercaseString]];
}

- (void) searchWithTerm:(NSString*)term
{
    [[LXServer shared] getSearchResults:term
                                success:^(id responseObject) {
                                    [self.serverSearchDictionary setObject:[self modifiedSearchArrayWithResponseObject:[responseObject objectForKey:@"items"]] forKey:[[responseObject objectForKey:@"term"] lowercaseString]];
                                    [self reloadScreen];
                                }
                                failure:^(NSError* error) {
                                    [self reloadScreen];
                                }];
}


- (NSMutableArray*) modifiedSearchArrayWithResponseObject:(id)responseObject
{
    NSMutableArray* itemsArray = [[NSMutableArray alloc] init];
    for (NSDictionary* d in responseObject) {
        NSMutableDictionary* dict = [[NSMutableDictionary alloc] initWithDictionary:d];
        [dict setObject:[dict objectForKey:@"item_id"] forKey:@"id"];
        [itemsArray addObject:dict];
    }
    return itemsArray;
}


# pragma mark dictionary helpers

- (NSMutableDictionary*) currentDictionary
{
    if ([self assignMode]) {
        [self removeAllNotesOptionFromDictionaries];
    }
    NSString* key = self.searchBar.text ? [self.searchBar.text lowercaseString] : @"";
    if (!key || [key length] == 0) {
        return [self drawFromDictionary];
    }
    if (![self.bucketsSearchDictionary objectForKey:key]) {
        [self.bucketsSearchDictionary setObject:[self searchedDictionaryWithTerm:key] forKey:key];
    }
    return [self.bucketsSearchDictionary objectForKey:key];
}

- (void) removeAllNotesOptionFromDictionaries
{
    if (self.bucketsDictionary && [self.bucketsDictionary objectForKey:@"Recent"] && [[self.bucketsDictionary objectForKey:@"Recent"] count] > 0 && [[[self.bucketsDictionary objectForKey:@"Recent"] firstObject] isAllNotesBucket]) {
        NSMutableArray* new = [[NSMutableArray alloc] initWithArray:[self.bucketsDictionary objectForKey:@"Recent"]];
        [new removeObjectAtIndex:0];
        [self.bucketsDictionary setObject:new forKey:@"Recent"];
    }
    if (self.cachedDiskDictionary && [self.cachedDiskDictionary objectForKey:@"Recent"] && [[self.cachedDiskDictionary objectForKey:@"Recent"] count] > 0 && [[[self.cachedDiskDictionary objectForKey:@"Recent"] firstObject] isAllNotesBucket]) {
        NSMutableArray* new = [[NSMutableArray alloc] initWithArray:[self.cachedDiskDictionary objectForKey:@"Recent"]];
        [new removeObjectAtIndex:0];
        [self.cachedDiskDictionary setObject:new forKey:@"Recent"];
    }
}

- (NSMutableDictionary*) drawFromDictionary
{
    NSMutableDictionary* temp = [self threadsOnlyDictionary];
    if ([self assignMode] && [[LXAddressBook thisBook] permissionGranted]) {
        [temp setObject:[[LXAddressBook thisBook] contactsForAssignment] forKey:@"Contacts"];
    }
    return temp;
}

- (NSMutableDictionary*) threadsOnlyDictionary
{
    if (!self.bucketsDictionary || [[self.bucketsDictionary allKeys] count] == 0) {
        if (!self.cachedDiskDictionary) {
            self.cachedDiskDictionary = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:@"buckets"]];
        }
        return self.cachedDiskDictionary;
    }
    return self.bucketsDictionary;
}

- (NSMutableDictionary*) searchedDictionaryWithTerm:(NSString*)term
{
    term = [term lowercaseString];
    
    NSMutableDictionary* newDictionary = [[NSMutableDictionary alloc] init];
    NSMutableDictionary* oldDictionary = [term length] > 1 && [self.bucketsSearchDictionary objectForKey:[term substringToIndex:([term length]-1)]] ? [self.bucketsSearchDictionary objectForKey:[term substringToIndex:([term length]-1)]] : [self drawFromDictionary];

    for (NSString* key in [oldDictionary allKeys]) {
        NSArray* buckets = [oldDictionary objectForKey:key];
        NSMutableArray* newBuckets = [[NSMutableArray alloc] init];
        NSString *keyToSearch = [key isEqualToString:@"Contacts"] ? @"name" : @"first_name";
        for (NSDictionary* bucket in buckets) {
            if ([[[bucket objectForKey:keyToSearch] lowercaseString] rangeOfString:term].length > 0) {
                [newBuckets addObject:bucket];
            }
        }
        [newDictionary setObject:newBuckets forKey:key];
    }
    
    return newDictionary;
}

- (NSMutableArray*) searchArray
{
    NSString* key = self.searchBar.text ? [self.searchBar.text lowercaseString] : @"";
    if (!key || [key length] == 0) {
        return [[NSMutableArray alloc] init];
    }
    NSString* tempKey = [NSString stringWithString:key];
    while (tempKey && [tempKey length] > 0 && ![self.serverSearchDictionary objectForKey:tempKey]) {
        tempKey = [tempKey substringToIndex:([tempKey length]-1)];
    }
    return [self.serverSearchDictionary objectForKey:tempKey];
}

- (NSString*) searchTerm
{
    NSString* key = self.searchBar.text ? [self.searchBar.text lowercaseString] : @"";
    if (!key || [key length] == 0) {
        return nil;
    }
    NSString* tempKey = [NSString stringWithString:key];
    while (tempKey && [tempKey length] > 0 && ![self.serverSearchDictionary objectForKey:tempKey]) {
        tempKey = [tempKey substringToIndex:([tempKey length]-1)];
    }
    return tempKey;
}

- (void) cacheComposeBucketController
{
    //UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Messages" bundle:[NSBundle mainBundle]];
    //self.composeBucketController = [storyboard instantiateViewControllerWithIdentifier:@"bucketViewController"];
}



# pragma mark helpers

- (NSDictionary*) allNotesDictionary
{
    //NSLog(@"self.currentDictionary = %@", [self currentDictionary]);
    NSMutableDictionary* cachedDraw = [self drawFromDictionary];
    if (cachedDraw && [cachedDraw objectForKey:@"Recent"] && [[cachedDraw objectForKey:@"Recent"] firstObject] && [[[cachedDraw objectForKey:@"Recent"] firstObject] isAllNotesBucket]) {
        return [[cachedDraw objectForKey:@"Recent"] firstObject];
    }
    return nil;
}


# pragma mark - HCSendRequestForUpdatedBuckets

- (void) sendRequestForUpdatedBucket
{
    [self refreshChange];
}



# pragma mark - Action Sheet Delegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Messages" bundle:[NSBundle mainBundle]];
    
    if (buttonIndex == 0) {
        LXRemindersViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"remindersViewController"];
        [self.navigationController pushViewController:vc animated:YES];
    }
    if (buttonIndex == 1) {
        HCLocationNotesViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"locationNotesViewController"];
        [self.navigationController pushViewController:vc animated:YES];
    }
    if (buttonIndex == 2) {
        HCRandomItemViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"randomItemViewController"];
        [self.navigationController pushViewController:vc animated:YES];
    }
    if (buttonIndex == 3) {
        NSLog(@"Cancel pressed --> Cancel ActionSheet");
    }
}



# pragma mark - Gesture Recognizers

- (void) setLongPressGestureToRemoveBucket
{
    UILongPressGestureRecognizer *lpgr = [[UILongPressGestureRecognizer alloc]
                                          initWithTarget:self action:@selector(handleLongPress:)];
    lpgr.minimumPressDuration = 0.7; //seconds
    lpgr.delegate = self;
    [self.tableView addGestureRecognizer:lpgr];
}

-(void)handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer
{
    CGPoint p = [gestureRecognizer locationInView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:p];
    
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        NSDictionary *bucket = [[[self currentDictionary] objectForKey:[self.sections objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row];
        if (bucket && ![bucket isAllNotesBucket] && ![self assignMode]) {
            UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Messages" bundle:[NSBundle mainBundle]];
            HCBucketDetailsViewController* dvc = (HCBucketDetailsViewController*)[storyboard instantiateViewControllerWithIdentifier:@"detailsViewController"];
            [dvc setBucket:[[[[self currentDictionary] objectForKey:[self.sections objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row] mutableCopy]];
            [self.navigationController pushViewController:dvc animated:YES];
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


# pragma mark - AddressBook

- (void) getAddressBookPermissionIfUndetermined
{
    if ([self assignMode] && ![[LXAddressBook thisBook] permissionDetermined] && ![[LXAddressBook thisBook] alreadyAskedPermission]) {
        [[LXAddressBook thisBook] setAlreadyAskedPermission:YES]; 
        UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Messages" bundle:[NSBundle mainBundle]];
        HCPermissionViewController* vc = [storyboard instantiateViewControllerWithIdentifier:@"permissionViewController"];
        [vc setImageForScreenshotImageView:[[LXSetup theSetup] takeScreenshot]];
        [vc setImageForMainImageView:[UIImage imageNamed:@"permission-screen.jpg"]];
        [vc setMainLabelText:@"Use your contacts to easily create collections about people you already know."];
        [vc setPermissionType:@"contacts"]; 
        [vc setDelegate:self];
        [vc setButtonText:@"Grant Contact Permission"];
        [self.navigationController presentViewController:vc animated:NO completion:nil];
    }
}


- (void) permissionsDelegate
{
    [self reloadScreen];
}

# pragma mark - create bucket from contacts
- (void) createBucketFromContact:(NSMutableDictionary*)contact
{
    [self showHUDWithMessage:@"Creating Collection"];
    
    [[LXServer shared] createBucketWithFirstName:[contact name] andBucketType:@"Person"
                                         success:^(id responseObject) {
                                             [self hideHUD];
                                             NSDictionary* bucket = responseObject;
                                             [self createContactCardWithBucket:bucket andContact:contact];
                                             [self.delegate addToStack:bucket];
                                             [self.navigationController popToViewController:[[(HCItemTableViewController*)self.delegate pageControllerDelegate] parentViewController] animated:YES];
                                         }failure:^(NSError* error) {
                                             [self hideHUD];
                                             UIAlertView* av = [[UIAlertView alloc] initWithTitle:@"Whoops!" message:@"There was an error creating the collection." delegate:self cancelButtonTitle:@"Try Again" otherButtonTitles:nil];
                                             [av show];
                                         }];

}

- (void) createContactCardWithBucket:(NSDictionary*)bucket andContact:(NSMutableDictionary*)contact
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[LXServer shared] createContactCardWithBucket:bucket andContact:contact
            success:^(id responseObject) {
                NSLog(@"contact created successfully responseObject = %@", responseObject);
            } failure:^(NSError *error) {
                NSLog(@"whoops");
            }];
    });
}


# pragma mark - Setup


-(void)showSetup
{
    UIImage *img = [[LXSetup theSetup] takeScreenshot];
    
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Messages" bundle:[NSBundle mainBundle]];
    HCSetupViewController* btvc = [storyboard instantiateViewControllerWithIdentifier:@"setupViewController"];
    [btvc setScreenshot:img];
    [UIView animateWithDuration:0.5
                     animations:^{
                         self.navigationController.view.alpha = 0.1;
                     }
                     completion:^(BOOL finished){
                         [self presentViewController:btvc animated:NO completion:nil];
                         [UIView animateWithDuration:0.5
                                          animations:^{
                                              self.navigationController.view.alpha = 1;
                                          }
                                          completion:^(BOOL finished){
                                              
                                          }];
                     }];
}



# pragma mark pushing view controllers (push notifications)

- (void) pushBucketViewController:(NSNotification*)notification
{
    [self.navigationController popToRootViewControllerAnimated:NO];
    NSMutableDictionary* b = [[NSMutableDictionary alloc] initWithObjectsAndKeys:[[notification userInfo] objectForKey:@"bucket_id"], @"id", nil];
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Messages" bundle:[NSBundle mainBundle]];
    HCBucketViewController* btvc = [storyboard instantiateViewControllerWithIdentifier:@"bucketViewController"];
    [btvc setBucket:b];
    [btvc setDelegate:self];
    [self.navigationController pushViewController:btvc animated:NO];
}

- (void) pushItemTableView:(NSNotification*)notification
{
    NSMutableDictionary* i = [[NSMutableDictionary alloc] initWithObjectsAndKeys:[[notification userInfo] objectForKey:@"item_id"], @"id", nil];
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Messages" bundle:[NSBundle mainBundle]];
    HCContainerViewController* itvc = (HCContainerViewController*)[storyboard instantiateViewControllerWithIdentifier:@"containerViewController"];
    [itvc setItem:i];
    [itvc setItems:[[NSMutableArray alloc] initWithObjects:i, nil]];
    [itvc setDelegate:self];
    [self.navigationController pushViewController:itvc animated:NO];
}




@end


