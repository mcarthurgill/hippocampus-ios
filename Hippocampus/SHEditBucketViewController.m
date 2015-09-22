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
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshedObject:) name:@"refreshedObject" object:nil];
}

- (void) refreshedObject:(NSNotification*)notification
{
    NSMutableDictionary* object = [[notification userInfo] mutableCopy];
    if ([[object localKey] isEqualToString:self.localKey]) {
        [self reloadScreen];
    }
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self reloadScreen]; 
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
    //NSLog(@"bucket: %@", [self bucket]);
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
            if ([[self bucket] belongsToCurrentUser]) {
                if (![[[[[self bucket] authorizedUsers] objectAtIndex:indexPath.row] phoneNumber] isEqualToString: [[[LXSession thisSession] user] phone]]) { //not you
                    [self showAlertWithTitle:@"Remove Collaborator?" andMessage:[NSString stringWithFormat:@"Are you sure you want to remove %@ from %@", [[[[self bucket] authorizedUsers] objectAtIndex:indexPath.row] name], [[self bucket] firstName]] andCancelButtonTitle:@"No" andOtherTitle:@"Yes" andTag:3 andAlertType:UIAlertViewStyleDefault andTextInput:nil andIndexPath:indexPath];
                } else { //you
                    [self showAlertWithTitle:@"Change your name in this bucket?" andMessage:nil andCancelButtonTitle:@"Cancel" andOtherTitle:@"Save" andTag:4 andAlertType:UIAlertViewStylePlainTextInput andTextInput:[[[[self bucket] authorizedUsers] objectAtIndex:indexPath.row] name] andIndexPath:indexPath];
                }
            } else if ([[[[[self bucket] authorizedUsers] objectAtIndex:indexPath.row] phoneNumber] isEqualToString: [[[LXSession thisSession] user] phone]]) { //you
                [self showAlertWithTitle:@"Change your name in this bucket?" andMessage:nil andCancelButtonTitle:@"Cancel" andOtherTitle:@"Save" andTag:4 andAlertType:UIAlertViewStylePlainTextInput andTextInput:[[[[self bucket] authorizedUsers] objectAtIndex:indexPath.row] name] andIndexPath:indexPath];
            }
        } else {
            UINavigationController* nc = [[UIStoryboard storyboardWithName:@"Seahorse" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"collaboratorsViewController"];
            SHCollaboratorsViewController* vc = [[nc viewControllers] firstObject];
            [vc setLocalKey:self.localKey];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"presentViewController" object:nil userInfo:@{@"viewController":nc,@"animated":@YES}];
        }
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"actions"]) {
        if ([[self.actions objectAtIndex:indexPath.row] isEqualToString:@"rename"]) {
            [self showAlertWithTitle:@"Rename Bucket" andMessage:nil andCancelButtonTitle:@"Cancel" andOtherTitle:@"Save" andTag:1 andAlertType:UIAlertViewStylePlainTextInput andTextInput:[[self bucket] firstName] andIndexPath:nil];
        } else if ([[self.actions objectAtIndex:indexPath.row] isEqualToString:@"delete"]) {
            if ([[self bucket] belongsToCurrentUser]) {
                [self showAlertWithTitle:[NSString stringWithFormat:@"Delete \"%@\"", [[self bucket] firstName]] andMessage:@"Are you sure you want to delete this bucket?" andCancelButtonTitle:@"Cancel" andOtherTitle:@"Yes" andTag:2 andAlertType:UIAlertViewStyleDefault andTextInput:nil andIndexPath:nil];
            } else {
                [self showAlertWithTitle:@"Not yours!" andMessage:@"You can't delete a bucket you didn't create." andCancelButtonTitle:@"Okay" andOtherTitle:nil andTag:0 andAlertType:UIAlertViewStyleDefault andTextInput:nil andIndexPath:nil];
            }
        }
    }
}


# pragma mark alert view delegate


- (void) showAlertWithTitle:(NSString*)title andMessage:(NSString*)message andCancelButtonTitle:(NSString*)cancel andOtherTitle:(NSString*)successTitle andTag:(NSInteger)tag andAlertType:(UIAlertViewStyle)alertStyle andTextInput:(NSString*)textInput andIndexPath:(NSIndexPath*)indexPath {
    UIAlertView* av = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:cancel otherButtonTitles:successTitle, nil];
    av.alertViewStyle = alertStyle;
    av.delegate = self;
    av.indexPath = indexPath;
    if (alertStyle == UIAlertViewStylePlainTextInput) {
        UITextField* textField = [av textFieldAtIndex:0];
        [textField setText:textInput];
        [textField setFont:[UIFont titleFontWithSize:16.0f]];
    }
    [av setTag:tag];
    [av show];
}

- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 1) {
        //rename
        if ([alertView cancelButtonIndex] != buttonIndex && [alertView textFieldAtIndex:0].text.length > 0) {
            //action!
            NSMutableDictionary* bucketTemp = [self bucket];
            [bucketTemp setObject:[alertView textFieldAtIndex:0].text forKey:@"first_name"];
            [bucketTemp saveRemote];
            [bucketTemp assignLocalVersionIfNeeded:YES];
            [self reloadScreen];
        }
    } else if (alertView.tag == 2) {
        //delete
        if ([alertView cancelButtonIndex] != buttonIndex) {
            //delete!
            [[self bucket] destroyBucket];
            [self.navigationController popToRootViewControllerAnimated:YES];
        }
    } else if (alertView.tag == 3) {
        //remove collaborator
        if ([alertView cancelButtonIndex] != buttonIndex) {
            //remove!
            [[self bucket] removeCollaboratorWithPhone:[[[[self bucket] authorizedUsers] objectAtIndex:alertView.indexPath.row] phoneNumber] success:nil failure:nil];
        }
    } else if (alertView.tag == 4) {
        //change user name for bucket
        if ([alertView cancelButtonIndex] != buttonIndex) {
            //change!
            NSMutableDictionary *bup = [[[[self bucket] authorizedUsers] objectAtIndex:alertView.indexPath.row] mutableCopy];
            [[self bucket] changeNameInBucketWithBucketUserPair:bup andNewName:[alertView textFieldAtIndex:0].text success:nil failure:nil]; 
        }
    }
}


@end



