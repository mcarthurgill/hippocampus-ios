//
//  SHEditBucketViewController.m
//  Hippocampus
//
//  Created by Will Schreiber on 9/16/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import "SHEditBucketViewController.h"

#import "SHCollaboratorTableViewCell.h"
#import "SHBucketActionTableViewCell.h"
#import "SHCollaboratorsViewController.h"

static NSString *collaboratorCellIdentifier = @"SHCollaboratorTableViewCell";
static NSString *actionCellIdentifier = @"SHBucketActionTableViewCell";

@interface SHEditBucketViewController ()

@end

@implementation SHEditBucketViewController

@synthesize localKey;
@synthesize sections;
@synthesize actions;
@synthesize tableView;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupSettings];
    [self setupActions];
    
    //NSLog(@"bucket: %@", [self bucket]);
}

- (void) setupSettings
{
    [self setTitle];
    
    [self.view setBackgroundColor:[UIColor slightBackgroundColor]];
    [self.tableView setBackgroundColor:[UIColor slightBackgroundColor]];
    
    [self.tableView setRowHeight:UITableViewAutomaticDimension];
    [self.tableView setEstimatedRowHeight:91.0f];
    [self.tableView setTableFooterView:[[UIView alloc] initWithFrame:CGRectZero]];
    
    [self.tableView registerNib:[UINib nibWithNibName:collaboratorCellIdentifier bundle:nil] forCellReuseIdentifier:collaboratorCellIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:actionCellIdentifier bundle:nil] forCellReuseIdentifier:actionCellIdentifier];
}

- (void) setupActions
{
    if ([[self bucket] belongsToCurrentUser]) {
        self.actions = [@[@"rename", @"delete"] mutableCopy];
    } else {
        self.actions = [@[@"rename"] mutableCopy];
    }
}

- (void) setTitle
{
    if ([self bucket]) {
        [self setTitle:[NSString stringWithFormat:@"Edit %@", [[self bucket] firstName]]];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}



# pragma mark helpers

- (NSMutableDictionary*) bucket
{
    return [LXObjectManager objectWithLocalKey:self.localKey];
}



# pragma mark table view delegate

- (void) reloadScreen
{
    [self setTitle];
    [self.tableView reloadData];
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tV
{
    self.sections = [[NSMutableArray alloc] init];
    [self.sections addObject:@"collaborators"];
    if ([self.actions count] > 0) {
        [self.sections addObject:@"actions"];
    }
    return [self.sections count];
}

- (NSInteger) tableView:(UITableView *)tV numberOfRowsInSection:(NSInteger)section
{
    if ([[self.sections objectAtIndex:section] isEqualToString:@"collaborators"]) {
        return ([[self bucket] authorizedUsers] ? [[[self bucket] authorizedUsers] count] : 0) + 1;
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"actions"]) {
        return [self.actions count];
    }
    return 0;
}

- (UITableViewCell*) tableView:(UITableView *)tV cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"collaborators"]) {
        return [self tableView:tV collaboratorCellForRowAtIndexPath:indexPath];
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"actions"]) {
        return [self tableView:tV actionCellForRowAtIndexPath:indexPath];
    }
    return nil;
}

- (UITableViewCell*) tableView:(UITableView *)tV collaboratorCellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SHCollaboratorTableViewCell* cell = (SHCollaboratorTableViewCell*)[self.tableView dequeueReusableCellWithIdentifier:collaboratorCellIdentifier];
    if ([[self bucket] authorizedUsers] && indexPath.row < [[[self bucket] authorizedUsers] count]) {
        [cell configureWithLocalKey:self.localKey delegate:self collaborator:[[[self bucket] authorizedUsers] objectAtIndex:indexPath.row]];
    } else {
        [cell configureWithLocalKey:self.localKey delegate:self collaborator:nil];
    }
    [cell layoutIfNeeded];
    return cell;
}

- (UITableViewCell*) tableView:(UITableView *)tV actionCellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SHBucketActionTableViewCell* cell = (SHBucketActionTableViewCell*)[self.tableView dequeueReusableCellWithIdentifier:actionCellIdentifier];
    [cell configureWithLocalKey:self.localKey delegate:self action:[self.actions objectAtIndex:indexPath.row]];
    [cell layoutIfNeeded];
    return cell;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"collaborators"]) {
        return 60.0f;
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"actions"]) {
        return 60.0f;
    }
    return 44.0f;
}




# pragma mark section headers

- (NSString*) tableView:(UITableView *)tV titleForHeaderInSection:(NSInteger)section
{
    if ([[self.sections objectAtIndex:section] isEqualToString:@"collaborators"]) {
        return @"Collaborators";
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"actions"]) {
        return @"Actions";
    }
    return nil;
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




# pragma mark actions

- (void) tableView:(UITableView *)tV didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"collaborators"]) {
        if ([[self bucket] authorizedUsers] && indexPath.row < [[[self bucket] authorizedUsers] count]) {
            //current collaborator
        } else {
            UINavigationController* nc = [[UIStoryboard storyboardWithName:@"Seahorse" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"collaboratorsViewController"];
            SHCollaboratorsViewController* vc = [[nc viewControllers] firstObject];
            [vc setLocalKey:self.localKey];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"presentViewController" object:nil userInfo:@{@"viewController":nc,@"animated":@YES}];
        }
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"actions"]) {
        if ([[self.actions objectAtIndex:indexPath.row] isEqualToString:@"rename"]) {
            UIAlertView* av = [[UIAlertView alloc] initWithTitle:@"Rename Bucket" message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Go", nil];
            av.alertViewStyle = UIAlertViewStylePlainTextInput;
            UITextField* textField = [av textFieldAtIndex:0];
            [textField setText:[[self bucket] firstName]];
            [textField setFont:[UIFont titleFontWithSize:16.0f]];
            [av setTag:1];
            [av show];
        } else if ([[self.actions objectAtIndex:indexPath.row] isEqualToString:@"delete"]) {
        }
    }
}


# pragma mark alert view delegate

- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 1) {
        //rename
        if ([alertView cancelButtonIndex] != buttonIndex && [alertView textFieldAtIndex:0].text.length > 0) {
            //action!
            NSMutableDictionary* bucketTemp = [self bucket];
            [bucketTemp setObject:[alertView textFieldAtIndex:0].text forKey:@"first_name"];
            [bucketTemp saveRemote];
            [bucketTemp assignLocalVersionIfNeeded];
            [self reloadScreen];
        }
    }
}


@end



