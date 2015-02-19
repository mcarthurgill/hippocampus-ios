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

#define NULL_TO_NIL(obj) ({ __typeof__ (obj) __obj = (obj); __obj == [NSNull null] ? nil : obj; })
#define SEARCH_DELAY 0.3f

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
    
    [self setupProperties];
    
    [self refreshChange];
    
    [self cacheComposeBucketController];
    
    //reload data to make sure it's catching assign mode
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1*NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self reloadScreen];
    });
}

- (void) viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    if ([self assignMode]) {
        [self setTitle:@"Add to Thread"];
        [self.navigationItem setRightBarButtonItem:nil];
        [self.navigationItem setLeftBarButtonItem:nil];
    }
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    //[self refreshChange];
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


- (void) setupProperties {
    //remove extra cell lines
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    self.bucketsSearchDictionary = [[NSMutableDictionary alloc] init];
    self.serverSearchDictionary = [[NSMutableDictionary alloc] init];
    
    requestMade = NO;
    
    //change back button text when new VC gets popped on the stack
    self.navigationItem.backBarButtonItem =
    [[UIBarButtonItem alloc] initWithTitle:@"hppcmps"
                                      style:UIBarButtonItemStyleBordered
                                     target:nil
                                     action:nil];
}



#pragma mark - Table view data source

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
    }
    return [self bucketCellForTableView:tableView cellForRowAtIndexPath:indexPath];
}

- (UITableViewCell*) indicatorCellForTableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"indicatorCell" forIndexPath:indexPath];
    UIActivityIndicatorView* iav = (UIActivityIndicatorView*) [cell.contentView viewWithTag:10];
    [iav startAnimating];
    return cell;
}

- (UITableViewCell*) newCellForTableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"newCell" forIndexPath:indexPath];
    UILabel* label = (UILabel*) [cell.contentView viewWithTag:1];
    [label setText:@"+ New Thread"];
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
    
    UILabel* description = (UILabel*)[cell.contentView viewWithTag:2];
    if (NULL_TO_NIL([bucket objectForKey:@"description_text"])) {
        [description setText:[bucket objectForKey:@"description_text"]];
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"Event"]) {
        [description setText:[NSString stringWithFormat:@"Created %@%@", [NSDate timeAgoActualFromDatetime:[bucket createdAt]], ([self assignMode] ? @" - Tap to Add Note" : @"")]];
    } else {
        [description setText:[NSString stringWithFormat:@"%@ Notes %@%@", [bucket itemsCount], [bucket isAllNotesBucket] ? @"Outstanding" : @"", ([self assignMode] ? @" - Tap to Add Note" : [NSString stringWithFormat:@" - updated %@", [NSDate timeAgoActualFromDatetime:[bucket updatedAt]]])]];
    }
    
    UILabel* blueDot = (UILabel*) [cell.contentView viewWithTag:4];
    if ([bucket isAllNotesBucket] && [bucket hasItems]) {
        [blueDot.layer setCornerRadius:4];
        [blueDot setClipsToBounds:YES];
        [blueDot setHidden:NO];
    } else {
        [blueDot setHidden:YES];
    }
    
    return cell;
}

- (UITableViewCell*) itemCellForTableView:(UITableView*)tableView withItem:(NSDictionary*)item cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"itemCell" forIndexPath:indexPath];
    
    UILabel* note = (UILabel*)[cell.contentView viewWithTag:1];
    UIFont* font = note.font;
    float leftMargin = note.frame.origin.x;
    float topMargin = note.frame.origin.y;
    float width = note.frame.size.width;
    [note removeFromSuperview];
    
    note = [[UILabel alloc] initWithFrame:CGRectMake(leftMargin, topMargin, width, [self heightForText:[item truncatedMessage] width:width font:font])];
    [note setFont:font];
    [note setText:[item truncatedMessage]];
    [note setTag:1];
    [note setNumberOfLines:0];
    [note setLineBreakMode:NSLineBreakByWordWrapping];
    [cell.contentView addSubview:note];
    
    UILabel* timestamp = (UILabel*)[cell.contentView viewWithTag:3];
    [timestamp setText:[NSString stringWithFormat:@"%@%@", ([item hasBucketsString] ? [NSString stringWithFormat:@"%@ - ", [item bucketsString]] : @""), [NSDate timeAgoInWordsFromDatetime:[item createdAt]]]];
    
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
        return [self heightForText:[item truncatedMessage] width:280.0f font:[UIFont fontWithName:@"HelveticaNeue-Light" size:17.0f]] + 22.0f + 12.0f;
        
    }
    
    return 64.0f;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self assignMode]) {
        
        if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"new"]) {
            UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Messages" bundle:[NSBundle mainBundle]];
            HCNewBucketIITableViewController* btvc = [storyboard instantiateViewControllerWithIdentifier:@"newBucketIITableViewController"];
            [btvc setDelegate:self.delegate];
            [self.navigationController pushViewController:btvc animated:YES];
        
        } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"Recent"] && !([[[[self currentDictionary] objectForKey:[self.sections objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row] hasID])) {
        
        } else {
            [self.delegate addToStack:[[[self currentDictionary] objectForKey:[self.sections objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row]];
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
            [self.navigationController pushViewController:btvc animated:YES];
        }
    
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if ([[self.sections objectAtIndex:section] isEqualToString:@"requesting"] || [[self.sections objectAtIndex:section] isEqualToString:@"new"]) {
        return nil;
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"searchResults"]) {
        return [NSString stringWithFormat:@"Notes With \"%@\"", [self searchTerm]];
    }
    return [self.sections objectAtIndex:section];
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
    [[LXServer shared] requestPath:[NSString stringWithFormat:@"/users/%@/buckets.json", [[HCUser loggedInUser] userID]] withMethod:@"GET" withParamaters: nil
                           success:^(id responseObject) {
                               self.bucketsDictionary = [NSMutableDictionary dictionaryWithDictionary:responseObject];
                               requestMade = NO;
                               [self reloadScreen];
                               if (![self assignMode]) {
                                   [self saveBucket];
                               }
                           }
                           failure:^(NSError *error) {
                               NSLog(@"error: %@", [error localizedDescription]);
                               requestMade = NO;
                               [self reloadScreen];
                           }
     ];
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
    if (!self.composeBucketController) {
        [self cacheComposeBucketController];
    }
    if ([[self drawFromDictionary] objectForKey:@"Recent"] && [[[[self drawFromDictionary] objectForKey:@"Recent"] firstObject] isAllNotesBucket]) {
        [self.composeBucketController setBucket:[[[self drawFromDictionary] objectForKey:@"Recent"] firstObject]];
        [self.composeBucketController setInitializeWithKeyboardUp:YES];
        [self.composeBucketController setScrollToBottom:YES];
        [self.navigationController pushViewController:self.composeBucketController animated:YES];
    }
}

- (IBAction)showReminders:(id)sender {
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Messages" bundle:[NSBundle mainBundle]];
    LXRemindersViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"remindersViewController"];
    [self.navigationController pushViewController:vc animated:YES]; 
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
    [[LXServer shared] requestPath:@"/search.json" withMethod:@"GET" withParamaters: @{ @"t" : term, @"user_id" : [[HCUser loggedInUser] userID] }
                           success:^(id responseObject) {
                               [self.serverSearchDictionary setObject:[self modifiedSearchArrayWithResponseObject:[responseObject objectForKey:@"items"]] forKey:[[responseObject objectForKey:@"term"] lowercaseString]];
                               [self reloadScreen];
                           }
                           failure:^(NSError* error) {
                               [self reloadScreen];
                           }
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





# pragma mark saving mechanism

- (void) saveBucket
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (self.bucketsDictionary) {
            [[NSUserDefaults standardUserDefaults] setObject:[self bucketToSave] forKey:@"buckets"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    });
}

- (NSMutableDictionary*) bucketToSave
{
    NSMutableDictionary* temp = [[NSMutableDictionary alloc] init];
    
    NSArray* keys = [self.bucketsDictionary allKeys];
    for (NSString* k in keys) {
        NSMutableArray* cur = [self.bucketsDictionary objectForKey:k];
        NSMutableArray* new = [[NSMutableArray alloc] init];
        for (NSDictionary* t in cur) {
            NSMutableDictionary* tDict = [[NSMutableDictionary alloc] initWithDictionary:t];
            NSArray* keys = [tDict allKeys];
            for (NSString* k in keys) {
                if (!NULL_TO_NIL([tDict objectForKey:k])) {
                    [tDict removeObjectForKey:k];
                }
            }
            [new addObject:tDict];
        }
        [temp setObject:new forKey:k];
    }
    
    return temp;
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
    NSMutableDictionary* oldDictionary = [term length] > 1 && [self.bucketsSearchDictionary objectForKey:[term substringToIndex:([term length]-1)]] ? [self.bucketsSearchDictionary objectForKey:[term substringToIndex:([term length]-1)]] : self.bucketsDictionary;
    
    for (NSString* key in [oldDictionary allKeys]) {
        NSArray* buckets = [oldDictionary objectForKey:key];
        NSMutableArray* newBuckets = [[NSMutableArray alloc] init];
        for (NSDictionary* bucket in buckets) {
            if ([[[bucket objectForKey:@"first_name"] lowercaseString] containsString:term]) {
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
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Messages" bundle:[NSBundle mainBundle]];
    self.composeBucketController = [storyboard instantiateViewControllerWithIdentifier:@"bucketViewController"];
}


@end
