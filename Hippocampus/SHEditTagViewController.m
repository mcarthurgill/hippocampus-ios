//
//  SHEditTagViewController.m
//  Hippocampus
//
//  Created by Will Schreiber on 10/30/15.
//  Copyright © 2015 LXV. All rights reserved.
//

#import "SHEditTagViewController.h"
#import "SHBucketActionTableViewCell.h"

static NSString *actionCellIdentifier = @"SHBucketActionTableViewCell";

@interface SHEditTagViewController ()

@end

@implementation SHEditTagViewController

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
    
    [self.tableView registerNib:[UINib nibWithNibName:actionCellIdentifier bundle:nil] forCellReuseIdentifier:actionCellIdentifier];
}

- (void) setupActions
{
    if ([[self tagObject] belongsToCurrentUser]) {
        self.actions = [@[@"renameTag", @"deleteTag"] mutableCopy];
    } else {
        self.actions = [@[] mutableCopy];
    }
}

- (void) setTitle
{
    if ([self tagObject]) {
        [self setTitle:[NSString stringWithFormat:@"Edit %@", [[self tagObject] tagName]]];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}



# pragma mark helpers

- (NSMutableDictionary*) tagObject
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
    if ([self.actions count] > 0) {
        [self.sections addObject:@"actions"];
    }
    return [self.sections count];
}

- (NSInteger) tableView:(UITableView *)tV numberOfRowsInSection:(NSInteger)section
{
    if ([[self.sections objectAtIndex:section] isEqualToString:@"actions"]) {
        return [self.actions count];
    }
    return 0;
}

- (UITableViewCell*) tableView:(UITableView *)tV cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"actions"]) {
        return [self tableView:tV actionCellForRowAtIndexPath:indexPath];
    }
    return nil;
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
    if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"actions"]) {
        return 60.0f;
    }
    return 44.0f;
}




# pragma mark section headers

- (NSString*) tableView:(UITableView *)tV titleForHeaderInSection:(NSInteger)section
{
    if ([[self.sections objectAtIndex:section] isEqualToString:@"actions"]) {
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
    
    if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"actions"]) {
        if ([[self.actions objectAtIndex:indexPath.row] isEqualToString:@"renameTag"]) {
            [self showAlertWithTitle:@"Rename Group" andMessage:nil andCancelButtonTitle:@"Cancel" andOtherTitle:@"Save" andTag:1 andAlertType:UIAlertViewStylePlainTextInput andTextInput:[[self tagObject] tagName] andIndexPath:nil];
        } else if ([[self.actions objectAtIndex:indexPath.row] isEqualToString:@"deleteTag"]) {
            if ([[self tagObject] belongsToCurrentUser]) {
                [self showAlertWithTitle:[NSString stringWithFormat:@"Delete \"%@\"", [[self tagObject] tagName]] andMessage:@"Are you sure you want to delete this group?" andCancelButtonTitle:@"Cancel" andOtherTitle:@"Yes" andTag:2 andAlertType:UIAlertViewStyleDefault andTextInput:nil andIndexPath:nil];
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
        [textField setAutocapitalizationType:UITextAutocapitalizationTypeWords];
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
            NSMutableDictionary* tempTag = [self tagObject];
            [tempTag saveRemoteWithNewAttributes:@{@"tag_name":[alertView textFieldAtIndex:0].text} success:nil failure:nil];
            [self reloadScreen];
        }
    } else if (alertView.tag == 2) {
        //delete
        if ([alertView cancelButtonIndex] != buttonIndex) {
            //delete!
            [[self tagObject] destroyRemote];
            [self.navigationController popToRootViewControllerAnimated:YES];
        }
    }
}

@end
