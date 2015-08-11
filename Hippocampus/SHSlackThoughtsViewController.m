//
//  SHSlackThoughtsViewController.m
//  Hippocampus
//
//  Created by Will Schreiber on 8/9/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import "SHSlackThoughtsViewController.h"
#import "SHItemTableViewCell.h"

#define THOUGHT_LEFT_SIDE_MARGIN 29.0f
#define THOUGHT_RIGHT_SIDE_MARGIN 27.0f
#define THOUGHT_TOP_SIDE_MARGIN 18.0f
#define THOUGHT_BOTTOM_SIDE_MARGIN 18.0f

static NSString *itemCellIdentifier = @"SHItemTableViewCell";

@interface SHSlackThoughtsViewController ()

@end

@implementation SHSlackThoughtsViewController

@synthesize localKey;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.tableView registerNib:[UINib nibWithNibName:itemCellIdentifier bundle:nil] forCellReuseIdentifier:itemCellIdentifier];
    
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
    // Dispose of any resources that can be recreated.
}

- (void) setupSettings
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(bucketRefreshed:) name:@"bucketRefreshed" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removedItemFromBucket:) name:@"removedItemFromBucket" object:nil];
    
    [self.tableView setContentInset:UIEdgeInsetsMake(-64, 0, 0, 0)];
    
    self.bounces = YES;
    self.shakeToClearEnabled = YES;
    self.keyboardPanningEnabled = YES;
    self.shouldScrollToBottomAfterKeyboardShows = YES;
    self.inverted = YES;
    
    [self.textView setPlaceholder:@"What's on your mind?..."];
    [self.textView setFont:[UIFont inputFont]];
    
    [self.tableView setBackgroundColor:[UIColor slightBackgroundColor]];
    [self.tableView setRowHeight:UITableViewAutomaticDimension];
}

- (void) beginningActions
{
    [[self bucket] refreshFromServerWithSuccess:nil failure:nil];
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

- (void) removedItemFromBucket:(NSNotification*)notification
{
    [self reloadScreen];
}



# pragma mark scrolling helpers

- (void) scrollToBottomAnimated
{
    [self scrollToBottom:YES];
}

- (void) scrollToBottom:(BOOL)animated
{
    if ([[[self bucket] items] count] > 0) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:animated];
    }
}

- (void) scrollToTop:(BOOL)animated
{
    if ([[[self bucket] items] count] > 0) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:([[[self bucket] items] count]-1) inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:animated];
    }
}

- (BOOL) scrollViewShouldScrollToTop:(UIScrollView *)scrollView
{
    [super scrollViewShouldScrollToTop:scrollView];
    BOOL should = YES;
    if (should) {
        [self scrollToTop:YES];
    }
    return NO;
}



# pragma mark table view data source and delegate

- (void) bucketRefreshed:(NSNotification*)notification
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,0.01*NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self reloadScreen];
        [self scrollToBottom:YES];
    });
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
    SHItemTableViewCell* cell = (SHItemTableViewCell*)[self.tableView dequeueReusableCellWithIdentifier:itemCellIdentifier];
    
    [cell configureWithItem:[[self bucket] itemAtIndex:indexPath.row]];
    
    //NSLog(@"item key: %@", [[[self bucket] itemAtIndex:indexPath.row] localKey]);
    
    return cell;
}

- (CGFloat) tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSMutableDictionary* item = [[self bucket] itemAtIndex:indexPath.row];
    return [[item message] heightForTextWithWidth:([[UIScreen mainScreen] bounds].size.width-(THOUGHT_LEFT_SIDE_MARGIN+THOUGHT_RIGHT_SIDE_MARGIN)) font:[UIFont itemContentFont]] + THOUGHT_TOP_SIDE_MARGIN + THOUGHT_BOTTOM_SIDE_MARGIN;
}


# pragma mark toolbar delegate

- (void) didPressRightButton:(id)sender
{
    NSMutableDictionary* item = [NSMutableDictionary createItemWithMessage:self.textView.text];
    [[self bucket] addItem:item atIndex:0];
    
    [self reloadScreen];
    [self scrollToBottom:YES];
    
    [item saveBoth:^(id responseObject) {
         [[NSMutableDictionary dictionaryWithDictionary:responseObject] saveLocal];
         [self reloadScreen];
     }
     failure:^(NSError* error){
     }
    ];
    
    [super didPressRightButton:sender];
}


@end
