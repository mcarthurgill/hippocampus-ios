//
//  SHSlackThoughtsViewController.m
//  Hippocampus
//
//  Created by Will Schreiber on 8/9/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import "SHSlackThoughtsViewController.h"
#import "SHItemTableViewCell.h"
#import "SHLoadingTableViewCell.h"

#define THOUGHT_LEFT_SIDE_MARGIN 29.0f
#define THOUGHT_RIGHT_SIDE_MARGIN 27.0f
#define THOUGHT_TOP_SIDE_MARGIN 18.0f
#define THOUGHT_BOTTOM_SIDE_MARGIN 18.0f

#define PAGE_COUNT 64

static NSString *itemCellIdentifier = @"SHItemTableViewCell";
static NSString *loadingCellIdentifier = @"SHLoadingTableViewCell";

@interface SHSlackThoughtsViewController ()

@end

@implementation SHSlackThoughtsViewController

@synthesize localKey;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.tableView registerNib:[UINib nibWithNibName:itemCellIdentifier bundle:nil] forCellReuseIdentifier:itemCellIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:loadingCellIdentifier bundle:nil] forCellReuseIdentifier:loadingCellIdentifier];
    
    [self setupSettings];
    [self beginningActions];
    
    [self reloadScreen];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    //[self reloadScreen];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    //[self scrollToBottomAnimated];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
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
    
    page = 0;
    
    self.bounces = YES;
    self.shakeToClearEnabled = YES;
    self.keyboardPanningEnabled = YES;
    self.shouldScrollToBottomAfterKeyboardShows = YES;
    self.inverted = YES;
    
    [self.textView setPlaceholder:@"What's on your mind?..."];
    [self.textView setFont:[UIFont inputFont]];
    
    [self.tableView setBackgroundColor:[UIColor slightBackgroundColor]];
    [self.tableView setRowHeight:UITableViewAutomaticDimension];
    [self.tableView setTableFooterView:[[UIView alloc] initWithFrame:CGRectZero]];
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
    if ([[[self bucket] itemKeys] count] > 0) {
        if ([self.tableView numberOfSections] > 0 && [self.tableView numberOfRowsInSection:0] > 0) {
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:animated];
        }
    }
}

- (void) scrollToTop:(BOOL)animated
{
    if ([[[self bucket] itemKeys] count] > 0) {
        if ([self.tableView numberOfSections] > 0 && [self.tableView numberOfRowsInSection:0] > 0) {
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:(MAX(1, [self.tableView numberOfRowsInSection:0])-1) inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:animated];
        }
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
    //[[[[self.parentViewController navigationController] navigationBar] topItem] setTitle:[[self bucket] firstName]];
    [self setTitle:[[self bucket] firstName]];
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return MIN(PAGE_COUNT*(page+1), [[[self bucket] itemKeys] count]);
    return [[[self bucket] itemKeys] count];
}

- (UITableViewCell*) tableView:(UITableView *)tV cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([LXObjectManager objectWithLocalKey:[[[self bucket] itemKeys] objectAtIndex:indexPath.row]]) {
        return [self tableView:tV itemCellForRowAtIndexPath:indexPath];
    } else {
        [[LXObjectManager defaultManager] refreshObjectWithKey:[[[self bucket] itemKeys] objectAtIndex:indexPath.row]
                                                       success:^(id responseObject){
                                                           //[self.tableView reloadData];
                                                       } failure:nil
         ];
        return [self tableView:tV loadingCellForRowAtIndexPath:indexPath];
    }
}

- (UITableViewCell*) tableView:(UITableView *)tV itemCellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SHItemTableViewCell* cell = (SHItemTableViewCell*)[self.tableView dequeueReusableCellWithIdentifier:itemCellIdentifier];
    [cell configureWithItemLocalKey:[[[self bucket] itemKeys] objectAtIndex:indexPath.row] bucketLocalKey:self.localKey];
    [cell layoutIfNeeded];
    return cell;
}

- (UITableViewCell*) tableView:(UITableView *)tV loadingCellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SHLoadingTableViewCell* cell = (SHLoadingTableViewCell*)[self.tableView dequeueReusableCellWithIdentifier:loadingCellIdentifier];
    //[cell configureWithItemLocalKey:[[[self bucket] itemKeys] objectAtIndex:indexPath.row]];
    return cell;
}

- (CGFloat) tableView:(UITableView *)tV estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //return [self tableView:tV cellForRowAtIndexPath:indexPath].frame.size.height;
    NSMutableDictionary* item = [[self bucket] itemAtIndex:indexPath.row];
    return [[item message] heightForTextWithWidth:([[UIScreen mainScreen] bounds].size.width-(THOUGHT_LEFT_SIDE_MARGIN+THOUGHT_RIGHT_SIDE_MARGIN)) font:[UIFont itemContentFont]] + THOUGHT_TOP_SIDE_MARGIN + THOUGHT_BOTTOM_SIDE_MARGIN;
}

- (void) tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row+1 == [self.tableView numberOfRowsInSection:0] && [self.tableView numberOfRowsInSection:0] < [[[self bucket] itemKeys] count]) {
        page = page+1;
        [self reloadScreen];
    }
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
