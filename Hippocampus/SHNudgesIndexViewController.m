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
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatedNudgeLocalKeys:) name:@"updatedNudgeLocalKeys" object:nil];
    [self setupSettings];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self beginningActions];
    [self reloadScreen];
}

# pragma mark - setup

- (void) setupSettings
{
    [self.view setBackgroundColor:[UIColor slightBackgroundColor]];
    [self.tableView registerNib:[UINib nibWithNibName:itemCellIdentifier bundle:nil] forCellReuseIdentifier:itemCellIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:loadingCellIdentifier bundle:nil] forCellReuseIdentifier:loadingCellIdentifier];
}

- (void) beginningActions
{
    [[[LXSession thisSession] user] nudgeKeysWithSuccess:nil failure:nil];
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
    return [NSDate formattedDateFromString:[[[[self nudgeKeysByDate] objectAtIndex:section] allKeys] firstObject]];
}

# pragma mark notifications

- (void) updatedNudgeLocalKeys:(NSNotification*)notification
{
    //replace/move/remove item_local_key in allNudgesKey
    [self reloadScreen];
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
        [[LXObjectManager defaultManager] refreshObjectWithKey:[self itemLocalKeyForIndexPath:indexPath]
                                                       success:^(id responseObject){
//                                                           [self.tableView beginUpdates];
//                                                           [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
//                                                           [self.tableView endUpdates];
                                                       }failure:nil
         ];
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
    [cell configureWithResponseObject:[@{@"local_key":[self itemLocalKeyForIndexPath:indexPath]} mutableCopy]];
    [cell invertIfUpsideDown];
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
    [self prePermissionsDelegate:@"notifications" message:[NSString stringWithFormat:@"Enable notifications to get a nudge on the morning of %@%@.", [NSDate timeAgoActualFromDatetime:[item reminderDate]], [item message] && [[item message] length] > 0 ? [NSString stringWithFormat:@" about the thought: \"%@.\"", [item message]] : @""]];

}

@end
