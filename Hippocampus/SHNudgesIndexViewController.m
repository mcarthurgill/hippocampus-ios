//
//  SHAllNudgesViewController.m
//  Hippocampus
//
//  Created by Joseph Gill on 12/8/15.
//  Copyright © 2015 LXV. All rights reserved.
//

#import "SHNudgesIndexViewController.h"
#import "SHItemTableViewCell.h"
#import "SHLoadingTableViewCell.h"
#import "SHItemViewController.h"

static NSString *itemCellIdentifier = @"SHItemTableViewCell";
static NSString *loadingCellIdentifier = @"SHLoadingTableViewCell";
static NSString *itemViewControllerIdentifier = @"SHItemViewController";

@interface SHNudgesIndexViewController ()

@end

@implementation SHNudgesIndexViewController

@synthesize tableView;

- (void)viewDidLoad {
    [super viewDidLoad];
        
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshedObject:) name:@"refreshedObject" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reminderDateChanged:) name:@"updatedReminderDate" object:nil];
    
    [self setupSettings];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self setupConstraints];
    [self beginningActions:nil failure:nil];
}

- (void) setupConstraints
{
    if (self.navigationController.navigationBar.frame.size.height == 0) {
        self.tableViewToTopLayoutGuideConstraint.constant = 44.0;
    } else {
        self.tableViewToTopLayoutGuideConstraint.constant = 0.0;
    }
    [self.view layoutIfNeeded];
}


# pragma mark - setup

- (void) setupSettings
{
    [self.view setBackgroundColor:[UIColor slightBackgroundColor]];
    [self.tableView setBackgroundColor:[UIColor slightBackgroundColor]];
    [self.tableView registerNib:[UINib nibWithNibName:itemCellIdentifier bundle:nil] forCellReuseIdentifier:itemCellIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:loadingCellIdentifier bundle:nil] forCellReuseIdentifier:loadingCellIdentifier];
    tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}

- (void) beginningActions:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[[LXSession thisSession] user] nudgeKeysWithSuccess:^(id responseObject){
            [self performSelectorOnMainThread:@selector(reloadScreen) withObject:nil waitUntilDone:NO];
            if (successCallback) {
                successCallback(responseObject);
            }
        }failure:^(NSError *error){
            [self performSelectorOnMainThread:@selector(reloadScreen) withObject:nil waitUntilDone:NO];
            if (failureCallback) {
                failureCallback(error);
            }
        }];
    });
}


# pragma mark helpers

- (NSMutableArray*) nudgeKeysByDate
{
    return [[LXObjectManager objectWithLocalKey:@"nudgeLocalKeys"] mutableCopy];
}

- (NSMutableArray*) nudgeKeysForSection:(NSInteger)indexPathSection
{
    return [[[[[self nudgeKeysByDate] objectAtIndex:indexPathSection] allValues] firstObject] mutableCopy];
}

- (NSString*) itemLocalKeyForIndexPath:(NSIndexPath*)indexPath
{
    return [[self nudgeKeysForSection:indexPath.section] objectAtIndex:indexPath.row];
}

- (NSString*) dateAsStringForSection:(NSInteger)section
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    NSDate *d = [NSDate timeWithString:[[[[self nudgeKeysByDate] objectAtIndex:section] allKeys] firstObject]];
    NSDate *today = [NSDate date];
    if ([NSDate date:d isEqualTo:today]) {
        return @"Today";
    } else {
        [formatter setDateFormat:@"EEE, MMMM d, yyyy"];
        return [formatter stringFromDate:d];
    }
}

- (void) removeItemFromNudges:(NSMutableDictionary*)item success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback
{
    NSDate *originalDate = [NSDate timeWithString:[item reminderDate]];
    if ([self nudgeKeysByDate]) {
        for (NSDictionary *itemHash in [self nudgeKeysByDate]) {
            NSDate *d = [NSDate timeWithString:[[itemHash allKeys] firstObject]];
            if ([NSDate date:originalDate isEqualTo:d]) {
                NSMutableDictionary *mutableItemHash = [itemHash mutableCopy];
                [[[mutableItemHash allValues] firstObject] removeObject:[item localKey]];
                if (successCallback) {
                    successCallback(nil);
                }
            }
        }
    }
}

- (void) addItemToNudges:(NSMutableDictionary*)item withItemType:(NSString*)itemType andNewDate:(NSDate*)newDate
{
    NSDate *nextReminder = [NSDate timeWithString:[item determineNextReminderWithDate:newDate andItemType:itemType]];
    if (nextReminder) {
        for (NSDictionary *itemHash in [self nudgeKeysByDate]) {
            NSDate *dateKey = [NSDate timeWithString:[[itemHash allKeys] firstObject]];
            if ([NSDate date:nextReminder isEqualTo:dateKey]) {
                NSMutableDictionary *mutableItemHash = [itemHash mutableCopy];
                if (![[[mutableItemHash allValues] firstObject] containsObject:[item localKey]]) {
                    [[[mutableItemHash allValues] firstObject] addObject:[item localKey]];
                    [self reloadScreen];
                }
            }
        }
    }
}
                     
- (void) makeOfflineReminderDateChange:(NSNotification*)notification
{
    NSMutableDictionary *userInfo = [[notification userInfo] mutableCopy];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self updateNudgesDictionary:userInfo];
    });
}

# pragma mark notifications

- (void) refreshedObject:(NSNotification*)notification
{
    [self reloadScreen];
}

- (void) reminderDateChanged:(NSNotification*)notification
{
    [self beginningActions:nil failure:^(NSError *error){
        if ([LXServer errorBecauseOfBadConnection:error.code]) {
            [self makeOfflineReminderDateChange:notification];
        }
    }];
}

- (void) updateNudgesDictionary:(NSMutableDictionary *)updatedItem
{
    NSMutableDictionary *item = [[updatedItem objectForKey:@"item"] mutableCopy];
    NSDate *newDate = [updatedItem objectForKey:@"newDate"];
    NSString *itemType = [updatedItem objectForKey:@"itemType"];
    if (item && newDate && itemType) {
        [self removeItemFromNudges:item success:^(id responseObject){
            [self addItemToNudges:item withItemType:itemType andNewDate:newDate];
        }failure:nil];
    } else if (item){ //remove nudge chosen
        [self removeItemFromNudges:item success:nil failure:nil];
    }
}
# pragma mark table view delegate and data source

- (void) reloadScreen
{
    [self.tableView reloadData];
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[self nudgeKeysByDate] count];
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)indexPathSection
{
    return [[self nudgeKeysForSection:indexPathSection] count];
}

- (UITableViewCell*) tableView:(UITableView *)tV cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([LXObjectManager objectWithLocalKey:[self itemLocalKeyForIndexPath:indexPath]]) {
        return [self tableView:tV nudgeCellForRowAtIndexPath:indexPath];
    } else {
        [[LXObjectManager defaultManager] refreshObjectWithKey:[self itemLocalKeyForIndexPath:indexPath] success:nil failure:nil];
        return [self tableView:tV loadingCellForRowAtIndexPath:indexPath];
    }
    return nil;
}

- (UITableViewCell*) tableView:(UITableView *)tV nudgeCellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SHItemTableViewCell* cell = (SHItemTableViewCell*)[self.tableView dequeueReusableCellWithIdentifier:itemCellIdentifier];
    [cell setShouldInvert:NO];
    [cell configureWithItemLocalKey:[self itemLocalKeyForIndexPath:indexPath]];
    [cell layoutIfNeeded];
    return cell;
}


- (UITableViewCell*) tableView:(UITableView *)tV loadingCellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SHLoadingTableViewCell* cell = (SHLoadingTableViewCell*)[self.tableView dequeueReusableCellWithIdentifier:loadingCellIdentifier];
    [cell setShouldInvert:NO];
    [cell configureWithResponseObject:[@{@"local_key":[self itemLocalKeyForIndexPath:indexPath]} mutableCopy]];
    return cell;
}

- (void) tableView:(UITableView *)tV didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tV deselectRowAtIndexPath:indexPath animated:YES];
    UIViewController* vc = [[UIStoryboard storyboardWithName:@"Seahorse" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:itemViewControllerIdentifier];
    [(SHItemViewController*)vc setLocalKey:[self itemLocalKeyForIndexPath:indexPath]];
    [self.navigationController pushViewController:vc animated:YES];
}


# pragma mark section headers

- (NSString*) tableView:(UITableView *)tV titleForHeaderInSection:(NSInteger)section
{
    return [self dateAsStringForSection:section];
}

- (CGFloat) tableView:(UITableView *)tV heightForHeaderInSection:(NSInteger)section
{
    if ([self tableView:tV titleForHeaderInSection:section])
        return 36.0f;
    return 0;
}

- (UIView*) tableView:(UITableView *)tV viewForHeaderInSection:(NSInteger)section
{
    if (![self tableView:tV titleForHeaderInSection:section])
        return nil;
    
    UIView* header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, [self tableView:tV heightForHeaderInSection:section])];
    [header setBackgroundColor:[UIColor SHLighterGray]];
    
    UILabel* title = [[UILabel alloc] initWithFrame:CGRectMake(16, 0, header.frame.size.width, header.frame.size.height)];
    [title setText:[[self tableView:tV titleForHeaderInSection:section] uppercaseString]];
    [title setFont:[UIFont titleFontWithSize:12.0f]];
    [title setTextColor:[UIColor lightGrayColor]];
    
    [header addSubview:title];
    
    return header;
}



# pragma mark - Added from Messages
- (CGFloat) tableView:(UITableView *)tV estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSMutableDictionary* item = [LXObjectManager objectWithLocalKey:[self itemLocalKeyForIndexPath:indexPath]];
    if (item && [item objectForKey:@"estimated_row_height"]) {
        return [[item objectForKey:@"estimated_row_height"] floatValue];
    } else {
        return 83.0f;
    }
}

- (void) tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSMutableDictionary* item = [LXObjectManager objectWithLocalKey:[self itemLocalKeyForIndexPath:indexPath]];
    if (item) {
        [item addEstimatedRowHeight:cell.frame.size.height];
    }
    [self prePermissionsDelegate:@"notifications" message:@"Enable notifications to get a nudge for each of these notes."];
}

@end
