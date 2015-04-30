//
//  LXRemindersViewController.m
//  Hippocampus
//
//  Created by Joseph McArthur Gill on 2/11/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import "LXRemindersViewController.h"
#import "HCItemTableViewController.h"
#import "HCContainerViewController.h"
#import "HCItemTableViewCell.h"
#import "HCIndicatorTableViewCell.h"
#import "HCExplanationTableViewCell.h"

#define PICTURE_HEIGHT_IN_CELL 280
#define PICTURE_MARGIN_TOP_IN_CELL 8

@interface LXRemindersViewController ()

@end

@implementation LXRemindersViewController

@synthesize tableView;
@synthesize sections;
@synthesize allItems;
@synthesize page;

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.navigationItem setTitle:@"Upcoming Nudges"];
    [self setupProperties];
    [self refreshChange];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) setupProperties {
    shouldContinueRequesting = YES;
    requestMade = NO;
    self.allItems = [[NSMutableArray alloc] init];
    self.page = 0;
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
    
    if (requestMade) {
        [self.sections addObject:@"requesting"];
    } else if (self.allItems.count == 0) {
        [self.sections addObject:@"explanation"];
    }
    
    [self.sections addObject:@"all"];
    
    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if ([[self.sections objectAtIndex:section] isEqualToString:@"all"]) {
        return self.allItems.count;
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"requesting"]) {
        return 1;
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"explanation"]) {
        return 1;
    }
    return 0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"all"]) {
        [self shouldRequestMoreItems];
        return [self itemCellForTableView:self.tableView withItem:[self.allItems objectAtIndex:indexPath.row] cellForRowAtIndexPath:indexPath];
    } else if([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"requesting"]) {
        return [self indicatorCellForTableView:self.tableView cellForRowAtIndexPath:indexPath];
    } else if([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"explanation"]) {
        return [self explanationCellForTableView:self.tableView cellForRowAtIndexPath:indexPath];
    }
    return nil;
}

- (UITableViewCell*) itemCellForTableView:(UITableView*)tableView withItem:(NSDictionary*)item cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    HCItemTableViewCell *cell = (HCItemTableViewCell*)[self.tableView dequeueReusableCellWithIdentifier:@"itemCell" forIndexPath:indexPath];
    [cell configureWithItem:item];
    return cell;
}

- (UITableViewCell*) indicatorCellForTableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    HCIndicatorTableViewCell *cell = (HCIndicatorTableViewCell*)[self.tableView dequeueReusableCellWithIdentifier:@"indicatorCell" forIndexPath:indexPath];
    [cell configureAndBeginAnimation];
    return cell;
}

- (UITableViewCell*) explanationCellForTableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    HCExplanationTableViewCell *cell = (HCExplanationTableViewCell*)[self.tableView dequeueReusableCellWithIdentifier:@"explanationCell" forIndexPath:indexPath];
    [cell configureWithText:@"You have not set any reminders. Tap a note you've made and set one."]; 
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
        NSDictionary *item = [self.allItems objectAtIndex:indexPath.row];
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
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"explanation"]) {
        return 120.0f;
    }
    return 44.0;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"all"]) {
        UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Messages" bundle:[NSBundle mainBundle]];
        HCContainerViewController* itvc = (HCContainerViewController*)[storyboard instantiateViewControllerWithIdentifier:@"containerViewController"];
        [itvc setItem:[self.allItems objectAtIndex:indexPath.row]];
        [itvc setItems:[self allItems]];
        [itvc setDelegate:self];
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
    [[LXServer shared] getUpcomingRemindersWithPage:self.page
        success:^(id responseObject){
            requestMade = NO;
            NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange:
                                   NSMakeRange(0,[[responseObject objectForKey:@"reminders"] count])];
            if (indexes.count == 0) {
                shouldContinueRequesting = NO;
                [self shouldShowExplanationCell];
            }
            [self.allItems insertObjects:[responseObject objectForKey:@"reminders"] atIndexes:indexes];
            if ([[responseObject objectForKey:@"reminders"] count] > 0) {
                [self incrementPage];
                [self reloadScreenToIndex:0];
            }
        } failure:^(NSError *error){
            NSLog(@"error: %@", [error localizedDescription]);
            requestMade = NO;
            [self reloadScreenToIndex:0];
        }];
}

- (void) shouldShowExplanationCell {
    if (self.allItems.count == 0) {
        [self.tableView reloadData];
    }
}

- (void) shouldRequestMoreItems
{
    NSArray *visibleRows = [self.tableView indexPathsForVisibleRows];
    NSIndexPath *lastRow = [visibleRows lastObject];
    if (lastRow.row == self.allItems.count && requestMade == NO && shouldContinueRequesting == YES) {
        [self refreshChange];
    }
}

- (void) incrementPage {
    self.page = self.page + 1;
}

@end
