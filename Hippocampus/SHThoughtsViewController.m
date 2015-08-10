//
//  SHThoughtsViewController.m
//  Hippocampus
//
//  Created by Will Schreiber on 8/7/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import "SHThoughtsViewController.h"

#define THOUGHT_LEFT_SIDE_MARGIN 31.0f
#define THOUGHT_RIGHT_SIDE_MARGIN 31.0f
#define THOUGHT_TOP_SIDE_MARGIN 18.0f
#define THOUGHT_BOTTOM_SIDE_MARGIN 18.0f

@interface SHThoughtsViewController ()

@end

@implementation SHThoughtsViewController

@synthesize localKey;
@synthesize tableView;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupSettings];
    [self beginningActions];
}

- (void) viewDidAppear:(BOOL)animated
{
    [self reloadScreen];
    [self scrollToBottomAnimated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void) setupSettings
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(bucketRefreshed:) name:@"bucketRefreshed" object:nil];
    
    [self.tableView setRowHeight:UITableViewAutomaticDimension];
    [self.tableView setEstimatedRowHeight:100.0f];
}

- (void) beginningActions
{
    [[self bucket] refreshFromServerWithSuccess:nil failure:nil];
    
    [self scrollToBottom:NO];
}


# pragma mark herlps

- (NSMutableDictionary*) bucket
{
    if ([LXObjectManager objectWithLocalKey:self.localKey]) {
        return [LXObjectManager objectWithLocalKey:self.localKey];
    } else if ([localKey isEqualToString:[NSMutableDictionary allThoughtsLocalKey]]) {
        return [@{@"id":@0, @"first_name":@"All Thoughts", @"object_type":@"all-thoughts"} mutableCopy];
    } else {
        return [@{} mutableCopy];
    }
}

# pragma mark action helpers

- (void) scrollToBottomAnimated
{
    [self scrollToBottom:YES];
}

- (void) scrollToBottom:(BOOL)animated
{
    if ([[[self bucket] items] count] > 0) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:([[[self bucket] items] count]-1) inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:animated];
    }
}


# pragma mark table view data source and delegate

- (void) bucketRefreshed:(NSNotification*)notification
{
    [self reloadScreen];
    [self scrollToBottom:YES];
}

- (void) reloadScreen
{
    [self.tableView reloadData];
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[[self bucket] items] count];
}

- (UITableViewCell*) tableView:(UITableView *)tV cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tV dequeueReusableCellWithIdentifier:@"itemCell" forIndexPath:indexPath];
    
    NSMutableDictionary* item = [[self bucket] itemAtIndex:indexPath.row];
    
    UILabel* label = (UILabel*)[cell.contentView viewWithTag:1];
    [label setFont:[UIFont itemContentFont]];
    [label setText:[item message]];
    
    return cell;
}

- (CGFloat) tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSMutableDictionary* item = [[self bucket] itemAtIndex:indexPath.row];
    return [[item message] heightForTextWithWidth:([[UIScreen mainScreen] bounds].size.width-(THOUGHT_LEFT_SIDE_MARGIN+THOUGHT_RIGHT_SIDE_MARGIN)) font:[UIFont itemContentFont]] + THOUGHT_TOP_SIDE_MARGIN + THOUGHT_BOTTOM_SIDE_MARGIN;
}

@end
