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
#import "HCChangeBucketTypeViewController.h"

#define NULL_TO_NIL(obj) ({ __typeof__ (obj) __obj = (obj); __obj == [NSNull null] ? nil : obj; })
#define SEARCH_DELAY 0.05f
#define IMAGE_FADE_IN_TIME 0.3f
#define PICTURE_HEIGHT_IN_CELL 280
#define PICTURE_MARGIN_TOP_IN_CELL 8
#define HEADER_HEIGHT 40.0f

@interface HCBucketsTableViewController ()

@end

@implementation HCBucketsTableViewController

@synthesize mode;
@synthesize delegate;

@synthesize refreshControl;
@synthesize searchBar;
@synthesize sections;
@synthesize collapsedSections;
@synthesize bucketsDictionary;
@synthesize bucketsSearchDictionary;
@synthesize serverSearchDictionary;
@synthesize cachedDiskDictionary;

@synthesize composeBucketController;

@synthesize groupAlertView;

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
        [btvc setInitializeWithKeyboardUp:YES];
        [btvc setBucket:[[NSMutableDictionary alloc] initWithDictionary:[self allNotesDictionary]]];
        [btvc setDelegate:self];
        [self.navigationController pushViewController:btvc animated:NO];
    }
    
    if (![self assignMode]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(saveCollapsedSections) name:@"applicationWillResignActive" object:nil];
    }
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.bucketsDictionary = nil;
    self.cachedDiskDictionary = nil;
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"collapsed-sections"]) {
        self.collapsedSections = [[NSMutableDictionary alloc] initWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:@"collapsed-sections"]];
    } else {
        self.collapsedSections = [[NSMutableDictionary alloc] init];
    }
    
    [self refreshChange];
    [self reloadScreen];

    if ([self assignMode]) {
        [self setTitle:@"Add to Collection"];
        [self.navigationItem setRightBarButtonItem:nil];
        [self.navigationItem setLeftBarButtonItem:nil];
    }
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self handleVisitAndPermissions];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.searchBar resignFirstResponder];
}

- (void) viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    if (![self assignMode]) {
        [self saveCollapsedSections];
    }
}

- (void) saveCollapsedSections
{
    if (![self assignMode] && ![self searchActivated]) {
        [[NSUserDefaults standardUserDefaults] setObject:self.collapsedSections forKey:@"collapsed-sections"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) handleVisitAndPermissions
{
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
    
    if ([[self currentDictionary] objectForKey:@"groups"] && [[[self currentDictionary] objectForKey:@"groups"] count] > 0) {
        for (int i = 0; i < [[[self currentDictionary] objectForKey:@"groups"] count]; ++i) {
            if ([[[[[self currentDictionary] objectForKey:@"groups"] objectAtIndex:i] objectForKey:@"sorted_buckets"] count] > 0) {
                [self.sections addObject:[NSString stringWithFormat:@"%i", i]];
            }
        }
    }
    
    if ([[self currentDictionary] objectForKey:@"buckets"] && [[[self currentDictionary] objectForKey:@"buckets"] count] > 0) {
        if ([self assignMode] || (![self searchActivated] && [[[self currentDictionary] objectForKey:@"Recent"] count]-1) < [[[self currentDictionary] objectForKey:@"buckets"] count]) {
            [self.sections addObject:@"buckets"];
        }
    }
    
    if ([self searchActivated] && ![self assignMode]) {
        [self.sections addObject:@"searchResults"];
    }
    
    if ([self assignMode] && [[LXAddressBook thisBook] permissionGranted] && [[[self currentDictionary] objectForKey:@"Contacts"] count] > 0) {
        [self.sections addObject:@"Contacts"];
    }
    
    if (![self assignMode] && ![self searchActivated]) {
        [self.sections addObject:@"info"];
    }
    
    // Return the number of sections.
    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([self sectionIsCollapsed:section]) {
        return 0;
    }
    if ([[self.sections objectAtIndex:section] isEqualToString:@"new"]) {
        return 1;
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"Recent"]) {
        return [[[self currentDictionary] objectForKey:@"Recent"] count];
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"buckets"]) {
        return [[[self currentDictionary] objectForKey:@"buckets"] count];
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"requesting"]) {
        return 1;
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"searchResults"]) {
        return [[self searchArray] count];
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"Contacts"]) {
        return [[[self currentDictionary] objectForKey:@"Contacts"] count];
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"info"]) {
        return 1;
    } else {
        //these are groups
        return [[[[[self currentDictionary] objectForKey:@"groups"] objectAtIndex:[[self.sections objectAtIndex:section] integerValue]] objectForKey:@"sorted_buckets"] count];
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
    [textView setText:[NSString stringWithFormat:@"SMS entry: +1 (615) 724-9333%@\n\n%@ Thoughts\n%@ Collections\n\nHippocampus %@\nMade with <3 in Nashville", ([[[LXSession thisSession] user] email] ? @"\nEmail entry: thought@hppcmps.com" : @""), [[[[LXSession thisSession] user] numberItems] formattedString], [[[[LXSession thisSession] user] numberBuckets] formattedString], [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"] ]];
    return cell;
}

- (UITableViewCell*) bucketCellForTableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    NSDictionary* bucket = [self bucketAtIndexPath:indexPath];
    
    NSString* identifier = @"bucketCell";
    //if (NULL_TO_NIL([bucket objectForKey:@"description_text"]) || [[self.sections objectAtIndex:indexPath.section] isEqualToString:@"Event"]) {
        identifier = @"bucketAndDescriptionCell";
    //}
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
    
    UILabel* note = (UILabel*)[cell.contentView viewWithTag:1];

    [note setText:[bucket objectForKey:@"first_name"]];
    if (NULL_TO_NIL([bucket bucketType]) && [[bucket bucketType] isEqualToString:@"Person"]) {
        [note boldSubstring:[[note.text componentsSeparatedByString:@" "] objectAtIndex:0]];
    } else if ([bucket isAllNotesBucket]) {
        [note boldSubstring:[note text]];
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
        return [self heightForText:[item truncatedMessage] width:(self.view.frame.size.width-40.0f) font:[UIFont noteDisplay]] + 22.0f + 12.0f + 14.0f + additional + 4.0f;
        
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"info"]) {
        
        return 240.0f;
        
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
            [self.delegate addToStack:[self bucketAtIndexPath:indexPath]];
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
            [btvc setBucket:[[self bucketAtIndexPath:indexPath] mutableCopy]];
            [btvc setDelegate:self];
            [self.navigationController pushViewController:btvc animated:YES];
        }
    
    }
}

- (NSDictionary*) bucketAtIndexPath:(NSIndexPath*) indexPath
{
    if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"Recent"]) {
        return [[[self currentDictionary] objectForKey:@"Recent"] objectAtIndex:indexPath.row];
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"buckets"]) {
        return [[[self currentDictionary] objectForKey:@"buckets"] objectAtIndex:indexPath.row];
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"searchResults"]) {
        return [[self searchArray] objectAtIndex:indexPath.row];
    } else {
        return [[[[[self currentDictionary] objectForKey:@"groups"] objectAtIndex:[[self.sections objectAtIndex:indexPath.section] integerValue]] objectForKey:@"sorted_buckets"] objectAtIndex:indexPath.row];
    }
}

- (NSDictionary*) groupAtIndexPath:(NSIndexPath*)indexPath
{
    NSInteger section = indexPath.section;
    if ([[self.sections objectAtIndex:section] isEqualToString:@"Recent"]) {
        
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"requesting"] || [[self.sections objectAtIndex:section] isEqualToString:@"new"] || [[self.sections objectAtIndex:section] isEqualToString:@"searchResults"] || [[self.sections objectAtIndex:section] isEqualToString:@"Contacts"] || [[self.sections objectAtIndex:section] isEqualToString:@"info"] || [[self.sections objectAtIndex:section] isEqualToString:@"buckets"]) {
        return nil;
    } else if ([[self.sections objectAtIndex:section] integerValue] < [[[self currentDictionary] objectForKey:@"groups"] count]) {
        return [[[self currentDictionary] objectForKey:@"groups"] objectAtIndex:[[self.sections objectAtIndex:section] integerValue]];
    }
    return nil;
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
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"buckets"]) {
        return [[[self currentDictionary] objectForKey:@"groups"] count] == 0 ? @"All"  : @"Ungrouped";
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"Recent"]) {
        return @"Recent";
    } else if ([[self.sections objectAtIndex:section] integerValue] < [[[self currentDictionary] objectForKey:@"groups"] count]) {
        return [NSString stringWithFormat:@"%@", [[[[self currentDictionary] objectForKey:@"groups"] objectAtIndex:[[self.sections objectAtIndex:section] integerValue]] objectForKey:@"group_name"]];
    }
    return nil;
}

- (UIView*) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (![self tableView:tableView titleForHeaderInSection:section]) {
        return nil;
    }
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, HEADER_HEIGHT)];
    [view setBackgroundColor:[UIColor colorWithRed:241.0f/255.0f green:241.0f/255.0f blue:241.0f/255.0f alpha:1.0]];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, HEADER_HEIGHT)];
    [label setFont:[UIFont boldSystemFontOfSize:14]];
    [label setText:[self tableView:tableView titleForHeaderInSection:section]];
    [label setTextAlignment:NSTextAlignmentCenter];
    [view addSubview:label];
    
    UILabel *displayedLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.tableView.frame.size.width-HEADER_HEIGHT, 0, HEADER_HEIGHT, HEADER_HEIGHT)];
    [displayedLabel setText:([self sectionIsCollapsed:section] ? @"+" : @"-")];
    [displayedLabel setTextAlignment:NSTextAlignmentCenter];
    [view addSubview:displayedLabel];
    
    UIButton* sectionButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, HEADER_HEIGHT)];
    [sectionButton setBackgroundColor:[UIColor clearColor]];
    [sectionButton setTag:section];
    [sectionButton addTarget:self action:@selector(sectionTapped:) forControlEvents:UIControlEventTouchUpInside];
    [view addSubview:sectionButton];
    
    UILabel *line = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 1)];
    [line setBackgroundColor:[UIColor whiteColor]];
    [view addSubview:line];
    
    UILongPressGestureRecognizer *lpgr = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleSectionLongPress:)];
    lpgr.minimumPressDuration = 0.3; //seconds
    lpgr.delegate = self;
    [sectionButton addGestureRecognizer:lpgr];
    
    return view;
}

- (void) sectionTapped:(UIButton*)sender
{
    if ([self sectionIsCollapsed:[sender tag]]) {
        [self uncollapseSection:[sender tag]];
    } else {
        [self collapseSection:[sender tag]];
    }
}

- (BOOL) sectionIsCollapsed:(NSInteger)section
{
    if ([self searchActivated] || !self.collapsedSections)
        return NO;
    return [self.collapsedSections objectForKey:[self.sections objectAtIndex:section]] && [[self.collapsedSections objectForKey:[self.sections objectAtIndex:section]] isEqualToNumber:@YES];
}

- (void) collapseSection:(NSInteger)section
{
    [self.collapsedSections setObject:@YES forKey:[self.sections objectAtIndex:section]];
    [self reloadScreen];
}

- (void) uncollapseSection:(NSInteger)section
{
    [self.collapsedSections removeObjectForKey:[self.sections objectAtIndex:section]];
    [self reloadScreen];
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return [self tableView:tableView titleForHeaderInSection:section] ? HEADER_HEIGHT : 0;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSDictionary *bucket = [self bucketAtIndexPath:indexPath];
        if ([bucket belongsToCurrentUser]) {
            [self setBucketToDelete:bucket];
            [self alertForDeletion];
        } else {
            UIAlertView* av = [[UIAlertView alloc] initWithTitle:@"Whoops!" message:@"You can't delete this collection since you didn't create it." delegate:self cancelButtonTitle:@"Okay." otherButtonTitles:nil];
            [av show];
        }
    }
}

- (void) alertForDeletion
{
    UIAlertView * alert =[[UIAlertView alloc ] initWithTitle:@"Delete this collection?" message:@"This will also delete all thoughts that only belong to this collection." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles: nil];
    [alert addButtonWithTitle:@"Delete Collection"];
    [alert setTag:(NSInteger)99999999999999];
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1 && alertView.tag == (NSInteger)99999999999999) {
        if (self.bucketToDelete && ![self.bucketToDelete isAllNotesBucket] && ![self assignMode] && [self.bucketToDelete belongsToCurrentUser]) {
            [self showHUDWithMessage:@"Deleting Collection..."];
            [[LXServer shared] deleteBucketWithBucketID:[self.bucketToDelete ID] success:^(id responseObject){
                [self refreshChange];
            }failure:^(NSError *error){
                [self hideHUD];
            }];
        }
    } else if (buttonIndex == 1) {
        NSString* title = [[alertView textFieldAtIndex: 0] text];
        if ([title length] > 0) {
            [self showHUDWithMessage:@"Updating Group"];
            NSString* groupID = [NSString stringWithFormat:@"%ld", (long)alertView.tag];
            [[LXServer shared] requestPath:[NSString stringWithFormat:@"/groups/%@.json", groupID] withMethod:@"PUT" withParamaters:@{@"group":@{@"group_name":title}}
                                   success:^(id responseObject) {
                                       [self hideHUD];
                                       [self refreshChange];
                                       [self showHUDWithMessage:@"Refreshing"];
                                   }
                                   failure:^(NSError* error) {
                                       [self hideHUD];
                                   }
             ];
        } else {
            UIAlertView* av = [[UIAlertView alloc] initWithTitle:@"Whoops!" message:@"You must enter a name for this group!" delegate:nil cancelButtonTitle:@"Okay." otherButtonTitles:nil];
            [av show];
        }
    }
    [self setGroupAlertView:nil];
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
        //NSLog(@"allBuckets: %@", responseObject);
        self.bucketsSearchDictionary = [[NSMutableDictionary alloc] init];
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
    NSString *other2 = @"Map";
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
        //[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(searchWithCurrentText) object:nil];
        //[self performSelector:@selector(searchWithCurrentText) withObject:nil afterDelay:SEARCH_DELAY];
        [self searchWithCurrentText];
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
    ASAPIClient *apiClient = [ASAPIClient apiClientWithApplicationID:@"FVGQB7HR19" apiKey:@"ddecc3b35feb56ab0a9d2570ac964a82"];
    ASRemoteIndex *index = [apiClient getIndex:@"Item"];
    ASQuery* query = [ASQuery queryWithFullTextQuery:term];
    query.numericFilters = [NSString stringWithFormat:@"user_ids_array=%@", [[[LXSession thisSession] user] userID]];
    [index search:query
          success:^(ASRemoteIndex *index, ASQuery *query, NSDictionary *answer) {
              // answer object contains a "hits" attribute that contains all results
              // each result contains your attributes and a _highlightResult attribute that contains highlighted version of your attributes
              [self.serverSearchDictionary setObject:[answer objectForKey:@"hits"] forKey:[[query fullTextQuery] lowercaseString]];
              [self reloadScreen];
          } failure:nil
     ];
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
    
    //NSLog(@"keys: %@", [oldDictionary allKeys]);

    for (NSString* key in [oldDictionary allKeys]) {
        NSString *keyToSearch = [key isEqualToString:@"Contacts"] ? @"name" : @"first_name";
        if ([key isEqualToString:@"Recent"] || [key isEqualToString:@"buckets"] || [key isEqualToString:@"Contacts"]) {
            NSArray* buckets = [oldDictionary objectForKey:key];
            NSMutableArray* newBuckets = [[NSMutableArray alloc] init];
            for (NSDictionary* bucket in buckets) {
                if ([[[bucket objectForKey:keyToSearch] lowercaseString] rangeOfString:term].length > 0) {
                    [newBuckets addObject:bucket];
                }
            }
            [newDictionary setObject:newBuckets forKey:key];
        } else if ([key isEqualToString:@"groups"]) {
            NSMutableArray* newGroups = [[NSMutableArray alloc] init];
            for (NSDictionary* group in [oldDictionary objectForKey:@"groups"]) {
                if ([[[group groupName] lowercaseString] rangeOfString:term].length > 0) {
                    [newGroups addObject:group];
                } else {
                    NSMutableDictionary* newGroup = [[NSMutableDictionary alloc] initWithDictionary:group];
                    NSArray* buckets = [group objectForKey:@"sorted_buckets"];
                    NSMutableArray* newBuckets = [[NSMutableArray alloc] init];
                    for (NSDictionary* bucket in buckets) {
                        if ([[[bucket objectForKey:keyToSearch] lowercaseString] rangeOfString:term].length > 0) {
                            [newBuckets addObject:bucket];
                        }
                    }
                    if ([newBuckets count] > 0) {
                        [newGroup setObject:newBuckets forKey:@"sorted_buckets"];
                        [newGroups addObject:newGroup];
                    }
                }
            }
            [newDictionary setObject:newGroups forKey:@"groups"];
        }
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
    UILongPressGestureRecognizer *lpgr = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    lpgr.minimumPressDuration = 0.3; //seconds
    lpgr.delegate = self;
    [self.tableView addGestureRecognizer:lpgr];
}

- (void) handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer
{
    CGPoint p = [gestureRecognizer locationInView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:p];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan && cell.isHighlighted) {
        NSDictionary *bucket = [self bucketAtIndexPath:indexPath];
        if (bucket && ![bucket isAllNotesBucket] && ![self assignMode] && ![[self.sections objectAtIndex:indexPath.section] isEqualToString:@"searchResults"]) {
            //UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Messages" bundle:[NSBundle mainBundle]];
            //HCBucketDetailsViewController* dvc = (HCBucketDetailsViewController*)[storyboard instantiateViewControllerWithIdentifier:@"detailsViewController"];
            //[dvc setBucket:[[[[self currentDictionary] objectForKey:[self.sections objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row] mutableCopy]];
            //[self.navigationController pushViewController:dvc animated:YES];
            
            UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Messages" bundle:[NSBundle mainBundle]];
            HCChangeBucketTypeViewController* vc = [storyboard instantiateViewControllerWithIdentifier:@"changeBucketTypeViewController"];
            NSMutableDictionary* temp = [bucket mutableCopy];
            if ([self groupAtIndexPath:indexPath]) {
                [temp setObject:[self groupAtIndexPath:indexPath] forKey:@"group"];
            }
            [vc setBucketDict:temp];
            [vc setDelegate:self];
            [self.navigationController presentViewController:vc animated:YES completion:nil];
        }
    }
}

- (void) handleSectionLongPress:(UILongPressGestureRecognizer*)gestureRecognizer
{
    NSLog(@"section: %li", (long)gestureRecognizer.view.tag);
    if (!self.groupAlertView) {
        NSDictionary* group = [self groupAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:gestureRecognizer.view.tag]];
        if (group) {
            self.groupAlertView = [[UIAlertView alloc] initWithTitle:@"Change Group Name" message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Save", nil];
            [self.groupAlertView setAlertViewStyle:UIAlertViewStylePlainTextInput];
            [self.groupAlertView setTag:[[group ID] integerValue]];
            [[self.groupAlertView textFieldAtIndex:0] setText:[group groupName]];
            [self.groupAlertView show];
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
        [[LXServer shared] createContactCardWithBucket:bucket andContact:[contact mutableCopy]
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




# pragma mark sorting collections delegate

-(void)updateBucketGroup:(NSMutableDictionary *)updatedBucket
{
    [self sendRequestForUpdatedBucket];
}


@end


