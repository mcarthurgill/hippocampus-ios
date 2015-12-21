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


# pragma mark - Offline

- (void) removeItemFromNudges:(NSMutableDictionary*)item success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback
{
    NSDate *originalDate = [NSDate timeWithString:[item reminderDate]];
    NSMutableArray *nudges = [self nudgeKeysByDate];
    if (nudges) {
        NSMutableArray *nudgesCopy = [self nudgeKeysByDate];
        for (int i=0; i < nudgesCopy.count; i++) {
            NSDate *d = [NSDate timeWithString:[[[[self nudgeKeysByDate] objectAtIndex:i] allKeys] firstObject]];
            if ([NSDate date:originalDate isEqualTo:d]) {
                NSLog(@"***************");
                NSLog(@"removing key %@", [item localKey]);
                NSMutableArray *itemLocalKeys = [[[[[self nudgeKeysByDate] objectAtIndex:i] allValues] firstObject] mutableCopy];
                NSLog(@"localkeys before = %@", itemLocalKeys);
                [itemLocalKeys removeObject:[item localKey]];
                NSMutableDictionary *dateHash = [[nudges objectAtIndex:i] mutableCopy];
                [dateHash setObject:itemLocalKeys forKey:[[dateHash allKeys] firstObject]];
                [nudges replaceObjectAtIndex:i withObject:dateHash];
                NSLog(@"dateHash = %@", dateHash);
                [LXObjectManager assignLocal:nudges WithLocalKey:@"nudgeLocalKeys" alsoToDisk:YES];
                if (successCallback) {
                    successCallback(nil);
                }
            }
        }
    }
}

- (void) addItemToNudges:(NSMutableDictionary*)item withItemType:(NSString*)itemType andNewDate:(NSDate*)newDate success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback
{
    NSLog(@"*****add");
    NSDate *nextReminder = [NSDate timeWithString:[item determineNextReminderWithDate:newDate andItemType:itemType]];
    NSLog(@"next reminder = %@", nextReminder);
    NSDate *today = [NSDate date];
    NSLog(@"*******next Reminder = %@", nextReminder);
    NSMutableArray *nudges = [self nudgeKeysByDate];
    if (nextReminder) {
        NSLog(@"**inside add");
        NSMutableArray *nudgesCopy = [[self nudgeKeysByDate] mutableCopy];
        NSLog(@"**inside add 2222");

        for (int i=0; i < [nudgesCopy count]; i++) {
            NSLog(@"**inside FOR LOOP");

            NSDate *dateKey = [NSDate timeWithString:[[[nudges objectAtIndex:i] allKeys] firstObject]];
            NSLog(@"**GOT DATE KEY %@", dateKey);

            if ([NSDate date:nextReminder isEqualTo:dateKey]) {
                NSLog(@"THEY ARE EQUAL %@", dateKey);
                NSMutableArray *itemLocalKeys = [[[[nudges objectAtIndex:i] allValues] firstObject] mutableCopy];
                if (![itemLocalKeys containsObject:[item localKey]]) {
                    NSLog(@"***************");
                    NSLog(@"adding dictionary for %@", [item localKey]);
                    [itemLocalKeys addObject:[item localKey]];
                    NSMutableDictionary *dateHash = [[nudges objectAtIndex:i] mutableCopy];
                    [dateHash setObject:itemLocalKeys forKey:[[dateHash allKeys] firstObject]];
                    [nudges replaceObjectAtIndex:i withObject:dateHash];
                    [LXObjectManager assignLocal:nudges WithLocalKey:@"nudgeLocalKeys" alsoToDisk:YES];
                    NSLog(@"after addition = %@", [self nudgeKeysByDate]);
                    NSLog(@"***************");
                    return;
                }
            }
            
//            else if ([nextReminder timeIntervalSince1970] > [today timeIntervalSince1970]) {
//                NSLog(@"***************");
//                NSLog(@"creating new key for %@", [NSDate formattedStringFromDate:nextReminder]);
//                NSLog(@"***************");
//                NSMutableArray *itemLocalKeys = [[NSMutableArray alloc] initWithObjects:[item localKey], nil];
//                NSString *dateKey = [NSDate formattedStringFromDate:nextReminder];
//                NSMutableDictionary *dateHash = [[NSMutableDictionary alloc] init];
//                [dateHash setObject:itemLocalKeys forKey:dateKey];
//                [nudges insertObject:dateHash atIndex:i];
//                [LXObjectManager assignLocal:nudges WithLocalKey:@"nudgeLocalKeys" alsoToDisk:YES];
//                return; 
//            }
        }
    }
}
                     
- (void) makeOfflineReminderDateChange:(NSNotification*)notification success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback
{
    NSMutableDictionary *userInfo = [[notification userInfo] mutableCopy];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self updateNudgesDictionary:userInfo];
    });
}


- (void) updateNudgesDictionary:(NSMutableDictionary *)updatedItem
{
    NSMutableDictionary *item = [[updatedItem objectForKey:@"item"] mutableCopy];
    NSDate *newDate = [updatedItem objectForKey:@"newDate"];
    NSString *itemType = [updatedItem objectForKey:@"itemType"];
    if (item && newDate && itemType) {
        NSLog(@"*****in updateNudgesDictionary starting removal");
        [self removeItemFromNudges:item success:^(id responseObject){
            NSLog(@"*****in updateNudgesDictionary SUCCESS");
            [self addItemToNudges:item withItemType:itemType andNewDate:newDate success:^(id responseObject){
                NSLog(@"ADDED SUCCESSFUL");
                [self performSelectorOnMainThread:@selector(reloadScreen) withObject:nil waitUntilDone:NO];
            } failure:^(NSError *error){
                NSLog(@"ADDED FAIL");
                [self performSelectorOnMainThread:@selector(reloadScreen) withObject:nil waitUntilDone:NO];
            }];
        }failure:^(NSError *error){
            NSLog(@"*****in updateNudgesDictionary FAIL");
        }];
    } else if (item){ //remove nudge chosen
        [self removeItemFromNudges:item success:nil failure:nil];
    }
}

# pragma mark notifications

- (void) refreshedObject:(NSNotification*)notification
{
    [self reloadScreen];
}

- (void) reminderDateChanged:(NSNotification*)notification
{
    [self beginningActions:nil failure:^(NSError *error){
//        if ([LXServer errorBecauseOfBadConnection:error.code]) {
//            [self makeOfflineReminderDateChange:notification success:nil failure:nil];
//        }
    }];
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
