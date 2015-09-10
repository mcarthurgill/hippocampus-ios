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
#import "SHItemViewController.h"

#define PAGE_COUNT 64

static NSString *itemCellIdentifier = @"SHItemTableViewCell";
static NSString *loadingCellIdentifier = @"SHLoadingTableViewCell";
static NSString *itemViewControllerIdentifier = @"SHItemViewController";

@interface SHSlackThoughtsViewController ()

@end

@implementation SHSlackThoughtsViewController

@synthesize localKey;
@synthesize shouldReload;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.tableView registerNib:[UINib nibWithNibName:itemCellIdentifier bundle:nil] forCellReuseIdentifier:itemCellIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:loadingCellIdentifier bundle:nil] forCellReuseIdentifier:loadingCellIdentifier];
    
    [self setupSettings];
    
    [self beginningActions];
    
    [self performSelectorOnMainThread:@selector(reloadScreen) withObject:nil waitUntilDone:NO];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    //[self beginningActions];
    [self reloadScreen];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    if ([self.textView isFirstResponder]) {
        [self.textView resignFirstResponder];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) setupSettings
{
    self.shouldReload = NO;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(bucketRefreshed:) name:@"bucketRefreshed" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removedItemFromBucket:) name:@"removedItemFromBucket" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshVCWithLocalKey:) name:@"refreshVCWithLocalKey" object:nil];
    
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
    [[self bucket] refreshFromServerWithSuccess:^(id responseObject){} failure:^(NSError* error){}];
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

- (void) refreshVCWithLocalKey:(NSNotification*)notification
{
    if ([[[notification userInfo] objectForKey:@"local_key"] isEqualToString:self.localKey]) {
        [self tryToReload];
    }
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

- (void) scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    [self checkForReload];
}

- (void) scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self checkForReload];
}

- (void) tryToReload
{
    if (![self.tableView isDragging] && ![self.tableView isDecelerating]) {
        [self reloadScreen];
        self.shouldReload = NO;
    } else {
        self.shouldReload = YES;
    }
}

- (void) checkForReload
{
    if (self.shouldReload) {
        [self reloadScreen];
        self.shouldReload = NO;
    }
}



# pragma mark table view data source and delegate

- (void) bucketRefreshed:(NSNotification*)notification
{
    if ([[notification userInfo] objectForKey:@"bucket"] && [[[[notification userInfo] objectForKey:@"bucket"] localKey] isEqualToString:self.localKey]) {
        //BUCKET MATCHES!
        [self performSelectorOnMainThread:@selector(reloadIfDifferentCountOfKeys:) withObject:[[notification userInfo] objectForKey:@"oldItemKeys"] waitUntilDone:NO];
    }
}

- (void) reloadIfDifferentCountOfKeys:(NSArray*)oldKeys
{
    NSLog(@"%lu, %lu", (unsigned long)[[[self bucket] itemKeys] count], (unsigned long)[oldKeys count]);
    if ([[[self bucket] itemKeys] count] == [oldKeys count]) {
        //NO CHANGES!
    } else {
        //[self scrollToBottom:YES];
        [self tryToReload];
    }
}

- (void) reloadScreen
{
    [self.tableView reloadData];
    [self setTitle:[[self bucket] firstName]];
    //NSLog(@"%@", [self bucket]);
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return MIN(PAGE_COUNT*(page+1), [[[self bucket] itemKeys] count]);
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
    [cell configureWithResponseObject:[@{@"local_key":[[[self bucket] itemKeys] objectAtIndex:indexPath.row], @"vc":self} mutableCopy]];
    return cell;
}

- (CGFloat) tableView:(UITableView *)tV estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSMutableDictionary* item = [LXObjectManager objectWithLocalKey:[[[self bucket] itemKeys] objectAtIndex:indexPath.row]];
    if (item) {
        return [item estimatedCellHeight] + ((![item belongsToCurrentUser] || ([self bucket] && [[self bucket] isCollaborativeThread])) ? 32.0f : 0.0f ) + (([item hasBuckets] && (![self bucket] || [[self bucket] isAllThoughtsBucket])) ? 30.0f : 0.0f );
    } else {
        return 44.0f;
    }
}

- (void) tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row+1 == [self.tableView numberOfRowsInSection:0] && [self.tableView numberOfRowsInSection:0] < [[[self bucket] itemKeys] count]) {
        page = page+1;
        [self reloadScreen];
        [self.tableView flashScrollIndicators];
    }
    //NSLog(@"actual %li height: %f", (long)indexPath.row, cell.frame.size.height);
}

- (void) tableView:(UITableView *)tV didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //NSLog(@"estimated %li height: %f", (long)indexPath.row, [self tableView:tV estimatedHeightForRowAtIndexPath:indexPath]);
    [tV deselectRowAtIndexPath:indexPath animated:YES];
    UIViewController* vc = [[UIStoryboard storyboardWithName:@"Seahorse" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:itemViewControllerIdentifier];
    [(SHItemViewController*)vc setLocalKey:[[[self bucket] itemKeys] objectAtIndex:indexPath.row]];
    [self.navigationController pushViewController:vc animated:YES];
}




# pragma mark toolbar delegate

- (void) didPressRightButton:(id)sender
{
    NSMutableDictionary* item = [NSMutableDictionary createItemWithMessage:self.textView.text];
    if ([self bucket] && [[self bucket] localKey] && ![[[self bucket] localKey] isEqualToString:[NSMutableDictionary allThoughtsLocalKey]]) {
        [item setObject:[[self bucket] localKey] forKey:@"bucket_local_key"];
        [item setObject:@"assigned" forKey:@"status"];
        [[LXObjectManager objectWithLocalKey:[NSMutableDictionary allThoughtsLocalKey]] addItem:item atIndex:0];
    }
    [[self bucket] addItem:item atIndex:0];
    
    [self reloadScreen];
    [self scrollToBottom:YES];
    
    [item saveRemote:^(id responseObject) {
        [self reloadScreen];
    }
           failure:^(NSError* error){
           }
     ];
    
    [super didPressRightButton:sender];
}


@end
